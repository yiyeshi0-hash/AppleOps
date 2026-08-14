import AppIntents
import Foundation

struct TriggerLatestBuildIntent: AppIntent {
    static var title: LocalizedStringResource { "Trigger Latest Build" }
    static var description: IntentDescription { "Trigger the latest configured GitHub Actions build." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let owner = defaults.string(forKey: "GitHubOwner") ?? "yiyeshi0-hash"
        let repo = defaults.string(forKey: "GitHubRepo") ?? "LiveContainer-Tinker"
        let token = defaults.string(forKey: "GitHubToken") ?? ""
        let client = GitHubClient(token: token)
        let workflows = try await client.listWorkflows(owner: owner, repo: repo)
        guard let workflow = workflows.first else {
        return .result(dialog: "No workflow found")
        }
        try await client.triggerWorkflow(owner: owner, repo: repo, workflowID: workflow.id)
        return .result(dialog: "Triggered \(workflow.name)")
    }
}

struct CheckBuildStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Build Status" }
    static var description: IntentDescription { "Check the latest GitHub Actions build status." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let owner = defaults.string(forKey: "GitHubOwner") ?? "yiyeshi0-hash"
        let repo = defaults.string(forKey: "GitHubRepo") ?? "LiveContainer-Tinker"
        let token = defaults.string(forKey: "GitHubToken") ?? ""
        let client = GitHubClient(token: token)
        let runs = try await client.listRuns(owner: owner, repo: repo)
        guard let run = runs.first else {
        return .result(dialog: "No runs")
        }
        return .result(dialog: "\(run.displayTitle ?? run.name ?? "Build") \(run.status) \(run.conclusion ?? "")")
    }
}

struct CheckWDAStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check WDA Status" }
    static var description: IntentDescription { "Check whether WebDriverAgent is reachable." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let client = WDAClient(baseURL: base)
        return .result(dialog: await client.isReady() ? "WDA ready" : "WDA offline")
    }
}

struct CaptureScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource { "Capture Screenshot" }
    static var description: IntentDescription { "Capture the iPhone screen through WebDriverAgent." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let image = try await WDAClient(baseURL: base).screenshot()
        return .result(dialog: "Screenshot captured")
    }
}

struct ReadVerificationCodeIntent: AppIntent {
    static var title: LocalizedStringResource { "Read Verification Code" }
    static var description: IntentDescription { "Take a screenshot, run OCR, and return 6-digit verification codes." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        let client = WDAClient(baseURL: base)
        let image = try await client.screenshot()
        let texts = try client.recognizedText(in: image)
        let codes = client.verificationCodes(from: texts)
        return .result(dialog: IntentDialog(stringLiteral: codes.isEmpty ? "No code" : codes.joined(separator: ", ")))
    }
}

struct CheckMachineStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Machine Status" }
    static var description: IntentDescription { "Check a remote machine agent status." }

    @Parameter(title: "Machine URL")
    var machineURL: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let status = try await MachineAgentClient(baseURL: machineURL).status()
        return .result(dialog: IntentDialog(stringLiteral: status))
    }
}

struct RunMachineCommandIntent: AppIntent {
    static var title: LocalizedStringResource { "Run Machine Command" }
    static var description: IntentDescription { "Run a command on a remote machine agent." }

    @Parameter(title: "Machine URL")
    var machineURL: String
    @Parameter(title: "Command")
    var command: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let output = try await MachineAgentClient(baseURL: machineURL).run(command: command)
        return .result(dialog: IntentDialog(stringLiteral: output))
    }
}

struct PressHomeIntent: AppIntent {
    static var title: LocalizedStringResource { "Press Home" }
    static var description: IntentDescription { "Send the WDA home-screen command." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let base = UserDefaults.standard.string(forKey: "WDABaseURL") ?? "http://127.0.0.1:8100"
        try await WDAClient(baseURL: base).home()
        return .result(dialog: "Pressed home")
    }
}

struct CheckSigningStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check Signing Status" }
    static var description: IntentDescription { "Check Apple signing and device information through the configured agent." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let agent = UserDefaults.standard.string(forKey: "AgentBaseURL") ?? "http://192.168.3.234:18081"
        let info = try await SigningAgentClient(baseURL: agent).listInfo()
        let summary = info.map { "\($0.name): \($0.detail)" }.joined(separator: ", ")
        return .result(dialog: IntentDialog(stringLiteral: summary.isEmpty ? "No signing info" : summary))
    }
}

struct CheckFirstMachineStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Check First Machine Status" }
    static var description: IntentDescription { "Check the first configured machine agent status." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "Machines"),
           let machines = try? JSONDecoder().decode([MachineHost].self, from: data),
           let first = machines.first {
            let status = try await MachineAgentClient(baseURL: first.baseURL).status()
        return .result(dialog: "\(first.name): \(status)")
        }
        return .result(dialog: "No machine configured")
    }
}

struct RunPresetCommandIntent: AppIntent {
    static var title: LocalizedStringResource { "Run Preset Command" }
    static var description: IntentDescription { "Run the preset command on the first configured machine." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let command = defaults.string(forKey: "PresetCommand") ?? ""
        guard !command.isEmpty else {
        return .result(dialog: "No preset command")
        }
        if let data = defaults.data(forKey: "Machines"),
           let machines = try? JSONDecoder().decode([MachineHost].self, from: data),
           let first = machines.first {
            let output = try await MachineAgentClient(baseURL: first.baseURL).run(command: command)
        return .result(dialog: IntentDialog(stringLiteral: output))
        }
        return .result(dialog: "No machine configured")
    }
}

struct MinecraftServerStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Forge Server Status" }
    static var description: IntentDescription { "Check the OPanel Forge server status, TPS, memory, and online players." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let baseURL = defaults.string(forKey: "MinecraftServerBaseURL") ?? OPanelConfig.baseURL
        let token = defaults.string(forKey: "MinecraftServerToken") ?? ""
        guard !token.isEmpty else {
            return .result(dialog: "OPanel Token is not configured")
        }
        let summary = try await MinecraftServerClient(baseURL: baseURL, token: token).statusSummary()
        return .result(dialog: IntentDialog(stringLiteral: summary))
    }
}

struct RestartMinecraftServerIntent: AppIntent {
    static var title: LocalizedStringResource { "Restart Forge Server" }
    static var description: IntentDescription { "Safely restart the OPanel Forge server." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let baseURL = defaults.string(forKey: "MinecraftServerBaseURL") ?? OPanelConfig.baseURL
        let token = defaults.string(forKey: "MinecraftServerToken") ?? ""
        guard !token.isEmpty else {
            return .result(dialog: "OPanel Token is not configured")
        }
        let response = try await MinecraftServerClient(baseURL: baseURL, token: token).restart()
        return .result(dialog: IntentDialog(stringLiteral: "Forge server restart request sent: \(response)"))
    }
}

struct StopMinecraftServerIntent: AppIntent {
    static var title: LocalizedStringResource { "Stop Forge Server" }
    static var description: IntentDescription { "Safely stop the OPanel Forge server." }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let baseURL = defaults.string(forKey: "MinecraftServerBaseURL") ?? OPanelConfig.baseURL
        let token = defaults.string(forKey: "MinecraftServerToken") ?? ""
        guard !token.isEmpty else {
            return .result(dialog: "OPanel Token is not configured")
        }
        let response = try await MinecraftServerClient(baseURL: baseURL, token: token).stop()
        return .result(dialog: IntentDialog(stringLiteral: "Forge server stop request sent: \(response)"))
    }
}

struct SendMinecraftCommandIntent: AppIntent {
    static var title: LocalizedStringResource { "Send Forge Command" }
    static var description: IntentDescription { "Send a command to the OPanel Forge server." }

    @Parameter(title: "Command")
    var command: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults.standard
        let baseURL = defaults.string(forKey: "MinecraftServerBaseURL") ?? OPanelConfig.baseURL
        let token = defaults.string(forKey: "MinecraftServerToken") ?? ""
        guard !token.isEmpty else {
            return .result(dialog: "OPanel Token is not configured")
        }
        let response = try await MinecraftServerClient(baseURL: baseURL, token: token).send(command: command)
        return .result(dialog: IntentDialog(stringLiteral: "Sent command: \(command). \(response)"))
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenToolsScreenIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Tools Screen" }
    var target: ToolsScreenEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .openToolsScreen, object: target.id)
        return .result(dialog: "Opened Tools")
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.search)
struct SearchToolsIntent: ShowInAppSearchResultsIntent {
    static var title: LocalizedStringResource { "Search Tools" }
    nonisolated static let searchScopes: [StringSearchScope] = [.general]

    @Parameter(title: "Criteria")
    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .searchTools, object: criteria.term)
        return .result(dialog: "Search opened")
    }
}
