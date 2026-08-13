import Foundation

struct GitHubWorkflow: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let path: String
    let state: String?
}

struct GitHubRun: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let displayTitle: String?
    let runNumber: Int?
    let status: String
    let conclusion: String?
    let headSha: String?
    let createdAt: String?
    let updatedAt: String?
    let htmlURL: String?
}

struct GitHubJob: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
    let steps: [GitHubStep]?
    let startedAt: String?
    let completedAt: String?
}

struct GitHubStep: Codable, Identifiable, Hashable {
    let name: String
    let number: Int
    let status: String
    let conclusion: String?
    let startedAt: String?
    let completedAt: String?

    var id: Int { number }
}

struct GitHubArtifact: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let sizeInBytes: Int?
    let expired: Bool?
    let archiveDownloadURL: String?
}
