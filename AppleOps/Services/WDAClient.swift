import Foundation
import UIKit
import Vision

enum WDAClientError: LocalizedError {
    case invalidResponse
    case unreachable(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "WDA 返回了无效响应"
        case .unreachable(let message):
            return message
        }
    }
}

struct WDAClient {
    let baseURL: String

    private var sessionURL: URL { URL(string: baseURL + "/session")! }

    func isReady() async -> Bool {
        guard let url = URL(string: baseURL + "/status") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        return (try? await URLSession.shared.data(for: request)) != nil
    }

    func createSession() async throws -> String {
        var request = URLRequest(url: sessionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["capabilities": [:]])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WDAClientError.unreachable("WDA 会话创建失败")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let id = json?["sessionId"] as? String { return id }
        if let value = json?["value"] as? [String: Any], let id = value["sessionId"] as? String { return id }
        throw WDAClientError.invalidResponse
    }

    func screenshot() async throws -> UIImage {
        let url = URL(string: baseURL + "/screenshot")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WDAClientError.unreachable("WDA 截屏失败")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let raw = json["value"] as? String,
              let imageData = Data(base64Encoded: raw),
              let image = UIImage(data: imageData) else {
            throw WDAClientError.invalidResponse
        }
        return image
    }

    func recognizedText(in image: UIImage) throws -> [String] {
        guard let cgImage = image.cgImage else { throw WDAClientError.invalidResponse }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        return request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
    }

    func verificationCodes(from texts: [String]) -> [String] {
        let joined = texts.joined(separator: " ")
        let compact = joined.replacingOccurrences(of: "\\s|-", with: "", options: .regularExpression)
        var codes: [String] = []
        let pattern = "\\b[0-9]{6}\\b"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(joined.startIndex..<joined.endIndex, in: joined)
            codes += regex.matches(in: joined, range: range).compactMap {
                Range($0.range, in: joined).map { String(joined[$0]) }
            }
            let compactRange = NSRange(compact.startIndex..<compact.endIndex, in: compact)
            codes += regex.matches(in: compact, range: compactRange).compactMap {
                Range($0.range, in: compact).map { String(compact[$0]) }
            }
        }
        return Array(Set(codes)).sorted()
    }

    func tap(x: Int, y: Int) async throws {
        let sessionID = try await createSession()
        let body: [String: Any] = [
            "actions": [
                [
                    "type": "pointer",
                    "id": "finger1",
                    "parameters": ["pointerType": "touch"],
                    "actions": [
                        ["type": "pointerMove", "duration": 0, "x": x, "y": y],
                        ["type": "pointerDown", "button": 0],
                        ["type": "pause", "duration": 0.1],
                        ["type": "pointerUp", "button": 0],
                    ],
                ]
            ]
        ]
        try await post("/session/\(sessionID)/actions", body: body)
    }

    func swipe(fromX: Int, fromY: Int, toX: Int, toY: Int, duration: Double = 0.5) async throws {
        let sessionID = try await createSession()
        let body: [String: Any] = [
            "fromX": fromX,
            "fromY": fromY,
            "toX": toX,
            "toY": toY,
            "duration": duration,
        ]
        try await post("/session/\(sessionID)/wda/dragfromtoforduration", body: body)
    }

    func home() async throws {
        try await post("/wda/homescreen")
    }

    private func post(_ path: String, body: [String: Any]? = nil) async throws {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WDAClientError.unreachable("WDA 请求失败: \(path)")
        }
    }
}
