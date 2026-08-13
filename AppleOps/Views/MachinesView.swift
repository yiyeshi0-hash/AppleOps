import SwiftUI

struct MachinesView: View {
    @EnvironmentObject private var store: AppleOpsStore
    @State private var newName = ""
    @State private var newURL = ""
    @State private var command = ""
    @State private var output = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("添加机器") {
                    TextField("名称", text: $newName)
                    TextField("Agent 地址", text: $newURL)
                    Button("添加") {
                        addMachine()
                    }
                }

                Section("机器") {
                    ForEach(store.machines) { machine in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(machine.name)
                                    .font(.headline)
                                Spacer()
                                Text(machine.lastStatus ?? "未知")
                                    .foregroundStyle(.secondary)
                            }
                            Text(machine.baseURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button("删除", role: .destructive) {
                                store.machines.removeAll { $0.id == machine.id }
                            }
                        }
                    }
                }

                Section("执行命令") {
                    TextField("命令", text: $command)
                    Button("运行") {
                        Task { await runCommand() }
                    }
                    if !output.isEmpty {
                        Text(output)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                if let errorMessage {
                    Section("错误") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("远程机器")
        }
    }

    private func addMachine() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = newURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !url.isEmpty else { return }
        store.machines.append(MachineHost(name: name, baseURL: url))
        newName = ""
        newURL = ""
    }

    private func runCommand() async {
        guard let machine = store.machines.first else {
            errorMessage = "请先添加机器"
            return
        }
        do {
            output = try await MachineAgentClient(baseURL: machine.baseURL).run(command: command)
            command = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
