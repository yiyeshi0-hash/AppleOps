import Combine
import Foundation

@MainActor
final class AppleOpsStore: ObservableObject {
    static let shared = AppleOpsStore()

    @Published var githubToken: String {
        didSet { UserDefaults.standard.set(githubToken, forKey: "GitHubToken") }
    }
    @Published var githubOwner: String {
        didSet { UserDefaults.standard.set(githubOwner, forKey: "GitHubOwner") }
    }
    @Published var githubRepo: String {
        didSet { UserDefaults.standard.set(githubRepo, forKey: "GitHubRepo") }
    }
    @Published var wdaBaseURL: String {
        didSet { UserDefaults.standard.set(wdaBaseURL, forKey: "WDABaseURL") }
    }
    @Published var agentBaseURL: String {
        didSet { UserDefaults.standard.set(agentBaseURL, forKey: "AgentBaseURL") }
    }

    @Published var machines: [MachineHost] {
        didSet {
            if let data = try? JSONEncoder().encode(machines) {
                UserDefaults.standard.set(data, forKey: "Machines")
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        githubToken = defaults.string(forKey: "GitHubToken") ?? ""
        githubOwner = defaults.string(forKey: "GitHubOwner") ?? "yiyeshi0-hash"
        githubRepo = defaults.string(forKey: "GitHubRepo") ?? "LiveContainer-Tinker"
        wdaBaseURL = defaults.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        agentBaseURL = defaults.string(forKey: "AgentBaseURL") ?? "http://192.168.3.234:18081"
        if let data = defaults.data(forKey: "Machines"),
           let hosts = try? JSONDecoder().decode([MachineHost].self, from: data) {
            machines = hosts
        } else {
            machines = []
        }
    }
}
