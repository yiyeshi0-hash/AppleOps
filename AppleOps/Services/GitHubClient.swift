import Foundation

enum GitHubClientError: LocalizedError {
    case invalidResponse
    case http(Int, String)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "GitHub returned an invalid response"
        case .http(let code, let message):
            return "GitHub HTTP \(code): \(message)"
        case .missingToken:
            return "请先填写 GitHub Token"
        }
    }
}

struct GitHubClient {
    let token: String
    private let base = URL(string: "https://api.github.com")!

    private func request<T: Decodable>(path: String) async throws -> T {
        guard !token.isEmpty else { throw GitHubClientError.missingToken }
        guard var url = URL(string: "https://api.github.com/\(path)") else {
            throw GitHubClientError.invalidResponse
        }
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "per_page", value: "20")]
            if let newURL = components.url { url = newURL }
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GitHubClientError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    private func post(path: String, body: [String: Any]) async throws {
        guard !token.isEmpty else { throw GitHubClientError.missingToken }
        guard let url = URL(string: "https://api.github.com/\(path)") else {
            throw GitHubClientError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GitHubClientError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func listWorkflows(owner: String, repo: String) async throws -> [GitHubWorkflow] {
        struct Response: Codable {
            let workflows: [GitHubWorkflow]
        }
        let response: Response = try await request(path: "repos/\(owner)/\(repo)/actions/workflows")
        return response.workflows
    }

    func listRuns(owner: String, repo: String) async throws -> [GitHubRun] {
        struct Response: Codable {
            let workflowRuns: [GitHubRun]
        }
        let response: Response = try await request(path: "repos/\(owner)/\(repo)/actions/runs")
        return response.workflowRuns
    }

    func triggerWorkflow(owner: String, repo: String, workflowID: Int, ref: String = "main") async throws {
        try await post(path: "repos/\(owner)/\(repo)/actions/workflows/\(workflowID)/dispatches", body: ["ref": ref])
    }

    func jobs(owner: String, repo: String, runID: Int) async throws -> [GitHubJob] {
        struct Response: Codable {
            let jobs: [GitHubJob]
        }
        let response: Response = try await request(path: "repos/\(owner)/\(repo)/actions/runs/\(runID)/jobs")
        return response.jobs
    }

    func artifacts(owner: String, repo: String, runID: Int) async throws -> [GitHubArtifact] {
        struct Response: Codable {
            let artifacts: [GitHubArtifact]
        }
        let response: Response = try await request(path: "repos/\(owner)/\(repo)/actions/runs/\(runID)/artifacts")
        return response.artifacts
    }
}
