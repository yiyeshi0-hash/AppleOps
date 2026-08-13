import SwiftUI

struct BuildsView: View {
    @EnvironmentObject private var store: AppleOpsStore
    @State private var workflows: [GitHubWorkflow] = []
    @State private var runs: [GitHubRun] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var client: GitHubClient {
        GitHubClient(token: store.githubToken)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("配置") {
                    SecureField("GitHub Token", text: $store.githubToken)
                    TextField("Owner", text: $store.githubOwner)
                    TextField("Repo", text: $store.githubRepo)
                    Button("加载工作流和构建") {
                        Task { await load() }
                    }
                    .disabled(store.githubToken.isEmpty || isLoading)
                }

                if let errorMessage {
                    Section("错误") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("工作流") {
                    ForEach(workflows) { workflow in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workflow.name)
                                    .font(.headline)
                                Text(workflow.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("触发") {
                                Task { await trigger(workflow) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section("最近构建") {
                    ForEach(runs) { run in
                        NavigationLink(value: run) {
                            RunRow(run: run)
                                .appleOpsAnnotation("\(run.id)")
                        }
                    }
                }
            }
            .navigationTitle("云构建")
            .navigationDestination(for: GitHubRun.self) { run in
                RunDetailView(run: run)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            workflows = try await client.listWorkflows(owner: store.githubOwner, repo: store.githubRepo)
            runs = try await client.listRuns(owner: store.githubOwner, repo: store.githubRepo)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func trigger(_ workflow: GitHubWorkflow) async {
        do {
            try await client.triggerWorkflow(owner: store.githubOwner, repo: store.githubRepo, workflowID: workflow.id)
            runs = try await client.listRuns(owner: store.githubOwner, repo: store.githubRepo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct RunRow: View {
    let run: GitHubRun

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(run.displayTitle ?? run.name ?? "构建 #\(run.runNumber ?? run.id)")
                .font(.headline)
            HStack {
                Text(statusText)
                if let conclusion = run.conclusion {
                    Text(conclusion)
                }
                Spacer()
                Text(run.runNumber.map { "#\($0)" } ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }

    private var statusText: String {
        switch run.status {
        case "completed":
            return run.conclusion == "success" ? "成功" : "失败"
        case "in_progress":
            return "进行中"
        case "queued":
            return "排队中"
        default:
            return run.status
        }
    }
}
