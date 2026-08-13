import AppIntents
import Foundation

struct TriggerLatestBuildIntent: AppIntent {
    static var title: LocalizedStringResource { "Trigger Latest Build" }
    static var description: IntentDescription { "Trigger the latest configured GitHub Actions build." }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        let owner = defaults.string(forKey: "GitHubOwner") ?? "yiyeshi0-hash"
        let repo = defaults.string(forKey: "GitHubRepo") ?? "LiveContainer-Tinker"
        let token = defaults.string(forKey: "GitHubToken") ?? ""
        let client = GitHubClient(token: token)
        let workflows = try await client.listWorkflows(owner: owner, repo: repo)
        guard let workflow = workflows.first else {
            return .result(value: "No workflow found")
        }
        try await client.triggerWorkflow(owner: owner, repo: repo, workflowID: workflow.id)
        return .result(value: "Triggered \(workflow.name)")
    }
}

struct CheckBuildStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Build Status" }
    static var description: IntentDescription { "Check the latest GitHub Actions build status." }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        let owner = defaults.string(forKey: "GitHubOwner") ?? "yiyeshi0-hash"
        let repo = defaults.string(forKey: "GitHubRepo") ?? "LiveContainer-Tinker"
        let token = defaults.string(forKey: "GitHubToken") ?? ""
        let client = GitHubClient(token: token)
        let runs = try await client.listRuns(owner: owner, repo: repo)
        guard let run = runs.first else {
            return .result(value: "No runs")
        }
        return .result(value: "\(run.displayTitle ?? run.name ?? "Build") \(run.status) \(run.conclusion ?? "")")
    }
}

struct CheckWDAStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check WDA Status" }
    static var description: IntentDescription { "Check whether WebDriverAgent is reachable." }

    func perform() async throws -> some IntentResult {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let client = WDAClient(baseURL: base)
        return .result(value: await client.isReady() ? "WDA ready" : "WDA offline")
    }
}

struct CaptureScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource { "Capture Screenshot" }
    static var description: IntentDescription { "Capture the iPhone screen through WebDriverAgent." }

    func perform() async throws -> some IntentResult {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let image = try await WDAClient(baseURL: base).screenshot()
        return .result(value: image.pngData()?.base64EncodedString() ?? "")
    }
}

struct ReadVerificationCodeIntent: AppIntent {
    static var title: LocalizedStringResource { "Read Verification Code" }
    static var description: IntentDescription { "Take a screenshot, run OCR, and return 6-digit verification codes." }

    func perform() async throws -> some IntentResult {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let client = WDAClient(baseURL: base)
        let image = try await client.screenshot()
        let texts = try client.recognizedText(in: image)
        let codes = client.verificationCodes(from: texts)
        return .result(value: codes.isEmpty ? "No code" : codes.joined(separator: ", "))
    }
}

struct CheckMachineStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Machine Status" }
    static var description: IntentDescription { "Check a remote machine agent status." }

    @Parameter(title: "Machine URL")
    var machineURL: String

    func perform() async throws -> some IntentResult {
        let status = try await MachineAgentClient(baseURL: machineURL).status()
        return .result(value: status)
    }
}

struct RunMachineCommandIntent: AppIntent {
    static var title: LocalizedStringResource { "Run Machine Command" }
    static var description: IntentDescription { "Run a command on a remote machine agent." }

    @Parameter(title: "Machine URL")
    var machineURL: String
    @Parameter(title: "Command")
    var command: String

    func perform() async throws -> some IntentResult {
        let output = try await MachineAgentClient(baseURL: machineURL).run(command: command)
        return .result(value: output)
    }
}
