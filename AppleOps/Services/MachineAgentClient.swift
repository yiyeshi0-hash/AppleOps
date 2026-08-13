import Foundation

struct MachineHost: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var baseURL: String
    var lastStatus: String?
}

enum MachineAgentError: LocalizedError {
    case invalidResponse
    case unreachable(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "机器 Agent 返回了无效响应"
        case .unreachable(let message):
            return message
        }
    }
}

struct MachineAgentClient {
    let baseURL: String

    func status() async throws -> String {
        try await get(path: "/status")
    }

    func run(command: String) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL + "/command")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["command": command])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MachineAgentError.unreachable("机器 Agent 执行失败")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func get(path: String) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: URL(string: baseURL + path)!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MachineAgentError.unreachable("机器 Agent 不可达")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
