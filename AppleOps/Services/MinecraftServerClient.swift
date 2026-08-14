import Foundation

enum OPanelConfig {
    static let baseURL = "https://192.168.3.121:8443"
}

struct OPanelVersion: Decodable {
    let serverType: String?
    let version: String?
    let mcdr: Bool?
}

struct OPanelInfo: Decodable {
    let maxPlayerCount: Int?
    let port: Int?
    let whitelist: Bool?
    let uptime: Int?
    let system: OPanelSystem?
    let ingameTime: OPanelIngameTime?
}

struct OPanelSystem: Decodable {
    let cpuName: String?
    let cpuThread: Int?
    let memory: Int64?
}

struct OPanelIngameTime: Decodable {
    let mspt: Double?
}

struct OPanelMonitor: Decodable {
    let tps: Double?
    let memory: Double?
    let jvmMemory: Double?
    let cpu: Double?
}

struct OPanelPlayers: Decodable {
    let maxPlayerCount: Int?
    let whitelist: Bool?
    let players: [String]?
}

struct OPanelProperties: Decodable {
    let properties: String?
}

enum MinecraftServerError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "OPanel 地址无效"
        case .invalidResponse:
            return "OPanel 返回无效响应"
        case .serverError(let message):
            return message
        }
    }
}

final class OPanelTrustDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

struct MinecraftServerClient {
    let baseURL: String
    let token: String
    private let session: URLSession

    init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
        let configuration = URLSessionConfiguration.ephemeral
        self.session = URLSession(configuration: configuration, delegate: OPanelTrustDelegate(), delegateQueue: nil)
    }

    func statusSummary() async throws -> String {
        let version = try await requestJSON("/api/version", as: OPanelVersion.self)
        let info = try await requestJSON("/api/info", as: OPanelInfo.self)
        let monitor = try await requestJSON("/api/monitor", as: OPanelMonitor.self)
        let players = try await requestJSON("/api/players/list", as: OPanelPlayers.self)
        let cpu = info.system?.cpuName ?? "unknown CPU"
        let tps = monitor.tps.map { String(format: "%.1f", $0) } ?? "?"
        let memory = monitor.memory.map { String(format: "%.0f%%", $0) } ?? "?"
        let playerCount = players.players?.count ?? 0
        return "Forge \(version.version ?? "?")，TPS \(tps)，内存 \(memory)，在线 \(playerCount) 人，\(cpu)"
    }

    func serverCommands() async throws -> String {
        try await requestText("/api/terminal")
    }

    func latestLog() async throws -> String {
        try await requestText("/api/logs/latest.log")
    }

    func players() async throws -> String {
        try await requestText("/api/players/list")
    }

    func gamerules() async throws -> String {
        try await requestText("/api/gamerules")
    }

    func setGamerule(key: String, value: String) async throws -> String {
        var components = URLComponents(string: baseURL + "/api/gamerules")!
        components.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "value", value: value),
        ]
        try await requestData(url: components.url!, method: "PATCH", body: nil)
        return "已设置 \(key)=\(value)"
    }

    func saves() async throws -> String {
        try await requestText("/api/saves")
    }

    func whitelist() async throws -> String {
        try await requestText("/api/whitelist")
    }

    func toggleWhitelist(enabled: Bool) async throws -> String {
        try await requestText("/api/whitelist/\(enabled ? "enable" : "disable")", method: "POST")
    }

    func reload() async throws -> String {
        try await requestText("/api/control/reload", method: "POST")
    }

    func restart() async throws -> String {
        try await requestText("/api/control/restart", method: "POST")
    }

    func stop() async throws -> String {
        try await requestText("/api/control/stop", method: "POST")
    }

    func send(command: String) async throws -> String {
        try await requestText("/api/terminal", method: "POST", body: command)
    }

    func setMOTD(_ motd: String) async throws -> String {
        let encoded = Data(motd.utf8).base64EncodedString()
        try await requestText("/api/info/motd", method: "POST", body: encoded)
        return "MOTD 已更新"
    }

    func serverProperties() async throws -> String {
        let response = try await requestJSON("/api/control/properties", as: OPanelProperties.self)
        guard let encoded = response.properties,
              let data = Data(base64Encoded: encoded) else {
            return "无法解析 server.properties"
        }
        return String(data: data, encoding: .utf8) ?? "无法解码 server.properties"
    }

    private func requestText(_ path: String, method: String = "GET", body: String? = nil) async throws -> String {
        guard let url = URL(string: baseURL + path) else {
            throw MinecraftServerError.invalidURL
        }
        let data = try await requestData(url: url, method: method, body: body)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func requestJSON<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        let data = try await requestText(path)
        return try JSONDecoder().decode(T.self, from: Data(data.utf8))
    }

    private func requestData(url: URL, method: String, body: String?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpBody = body.data(using: .utf8)
        }
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MinecraftServerError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw MinecraftServerError.serverError("OPanel \(http.statusCode): \(text)")
        }
        return data
    }
}
