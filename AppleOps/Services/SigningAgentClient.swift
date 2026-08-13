import Foundation

struct SigningInfo: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let detail: String
}

struct SigningAgentClient {
    let baseURL: String

    func listInfo() async throws -> [SigningInfo] {
        let url = URL(string: baseURL + "/signing")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        return (try? JSONDecoder().decode([SigningInfo].self, from: data)) ?? []
    }
}
