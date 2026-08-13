import SwiftUI

struct RunDetailView: View {
    let run: GitHubRun
    @EnvironmentObject private var store: AppleOpsStore
    @State private var jobs: [GitHubJob] = []
    @State private var artifacts: [GitHubArtifact] = []
    @State private var errorMessage: String?

    private var client: GitHubClient {
        GitHubClient(token: store.githubToken)
    }

    var body: some View {
        List {
            Section("构建") {
                LabeledContent("状态", value: run.status)
                if let conclusion = run.conclusion {
                    LabeledContent("结果", value: conclusion)
                }
                if let createdAt = run.createdAt {
                    LabeledContent("创建时间", value: createdAt)
                }
            }

            if let errorMessage {
                Section("错误") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Jobs") {
                ForEach(jobs) { job in
                    JobCard(job: job)
                }
            }

            Section("Artifacts") {
                ForEach(artifacts) { artifact in
                    LabeledContent(artifact.name, value: artifact.sizeInBytes.map { "\($0) bytes" } ?? "未知")
                }
            }
        }
        .navigationTitle(run.displayTitle ?? "构建详情")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            jobs = try await client.jobs(owner: store.githubOwner, repo: store.githubRepo, runID: run.id)
            artifacts = try await client.artifacts(owner: store.githubOwner, repo: store.githubRepo, runID: run.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct JobCard: View {
    let job: GitHubJob

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                Text(job.name)
                    .font(.headline)
            }
            ForEach(job.steps ?? []) { step in
                HStack {
                    Image(systemName: stepIcon(step))
                        .foregroundStyle(stepColor(step))
                    Text(step.name)
                    Spacer()
                    if let conclusion = step.conclusion {
                        Text(conclusion)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        if job.status == "in_progress" { return "clock" }
        return job.conclusion == "success" ? "checkmark.circle" : "xmark.circle"
    }

    private var color: Color {
        if job.status == "in_progress" { return .orange }
        return job.conclusion == "success" ? .green : .red
    }

    private func stepIcon(_ step: GitHubStep) -> String {
        if step.status == "in_progress" { return "circle.dotted" }
        return step.conclusion == "success" ? "checkmark.circle" : "xmark.circle"
    }

    private func stepColor(_ step: GitHubStep) -> Color {
        if step.status == "in_progress" { return .orange }
        return step.conclusion == "success" ? .green : .red
    }
}
