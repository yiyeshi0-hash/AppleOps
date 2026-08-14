import Foundation

enum OPanelConfig {
    static let baseURL = "http://192.168.3.121:3000"
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

struct MinecraftServerClient {
    let baseURL: String
    let token: String

    func statusSummary() async throws -> String {
        let version = try await get("/api/version", as: OPanelVersion.self)
        let info = try await get("/api/info", as: OPanelInfo.self)
        let monitor = try await get("/api/monitor", as: OPanelMonitor.self)
        let players = try await get("/api/players/list", as: OPanelPlayers.self)
        let cpu = info.system?.cpuName ?? "未知 CPU"
        let tps = monitor.tps.map { String(format: "%.1f", $0) } ?? "?"
        let memory = monitor.memory.map { String(format: "%.0f%%", $0) } ?? "?"
        let playerCount = players.players?.count ?? 0
        return "Forge \(version.version ?? "?")，TPS \(tps)，内存 \(memory)，在线 \(playerCount) 人，\(cpu)"
    }

    func restart() async throws -> String {
        try await post("/api/control/restart", body: nil)
    }

    func stop() async throws -> String {
        try await post("/api/control/stop", body: nil)
    }

    func send(command: String) async throws -> String {
        try await post("/api/terminal", body: command)
    }

    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw MinecraftServerError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MinecraftServerError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post(_ path: String, body: String?) async throws -> String {
        guard let url = URL(string: baseURL + path) else {
            throw MinecraftServerError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpBody = body.data(using: .utf8)
        }
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MinecraftServerError.invalidResponse
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        return "请求已发送"
    }
}
