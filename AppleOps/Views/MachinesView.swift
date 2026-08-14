import SwiftUI

struct MachinesView: View {
    @EnvironmentObject private var store: AppleOpsStore
    @AppStorage("MinecraftServerBaseURL") private var mcBaseURL = OPanelConfig.baseURL
    @AppStorage("MinecraftServerToken") private var mcToken = ""
    @State private var newName = ""
    @State private var newURL = ""
    @State private var command = ""
    @State private var mcCommand = ""
    @State private var gameruleKey = ""
    @State private var gameruleValue = ""
    @State private var motdText = ""
    @State private var output = ""
    @State private var mcOutput = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Forge / OPanel") {
                    TextField("OPanel 地址", text: $mcBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Token", text: $mcToken)
                    HStack {
                        Button("状态") {
                            Task { await checkMCStatus() }
                        }
                        Button("重启") {
                            Task { await restartMC() }
                        }
                        Button("停止", role: .destructive) {
                            Task { await stopMC() }
                        }
                    }
                    TextField("后台指令", text: $mcCommand)
                    Button("发送指令") {
                        Task { await sendMCCommand() }
                    }
                    .disabled(mcCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !mcOutput.isEmpty {
                        Text(mcOutput)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                Section("OPanel 开放 API") {
                    HStack {
                        Button("指令列表") {
                            Task { await runOPanel { try await client.serverCommands() } }
                        }
                        Button("最新日志") {
                            Task { await runOPanel { try await client.latestLog() } }
                        }
                        Button("玩家") {
                            Task { await runOPanel { try await client.players() } }
                        }
                    }
                    HStack {
                        Button("游戏规则") {
                            Task { await runOPanel { try await client.gamerules() } }
                        }
                        Button("存档") {
                            Task { await runOPanel { try await client.saves() } }
                        }
                        Button("白名单") {
                            Task { await runOPanel { try await client.whitelist() } }
                        }
                    }
                    HStack {
                        Button("重载") {
                            Task { await runOPanel { try await client.reload() } }
                        }
                        Button("属性") {
                            Task { await runOPanel { try await client.serverProperties() } }
                        }
                        Button("开白名单") {
                            Task { await runOPanel { try await client.toggleWhitelist(enabled: true) } }
                        }
                        Button("关白名单") {
                            Task { await runOPanel { try await client.toggleWhitelist(enabled: false) } }
                        }
                    }
                    HStack {
                        TextField("规则名", text: $gameruleKey)
                        TextField("值", text: $gameruleValue)
                        Button("设置规则") {
                            Task { await setGamerule() }
                        }
                    }
                    HStack {
                        TextField("新 MOTD", text: $motdText)
                        Button("改 MOTD") {
                            Task { await updateMOTD() }
                        }
                    }
                }

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
                        .appleOpsMachineAnnotation(machine.id.uuidString)
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
            UserDefaults.standard.set(command, forKey: "PresetCommand")
            command = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkMCStatus() async {
        do {
            let summary = try await MinecraftServerClient(baseURL: mcBaseURL, token: mcToken).statusSummary()
            mcOutput = summary
        } catch {
            mcOutput = error.localizedDescription
        }
    }

    private func restartMC() async {
        do {
            let response = try await MinecraftServerClient(baseURL: mcBaseURL, token: mcToken).restart()
            mcOutput = "重启：\(response)"
        } catch {
            mcOutput = error.localizedDescription
        }
    }

    private func stopMC() async {
        do {
            let response = try await MinecraftServerClient(baseURL: mcBaseURL, token: mcToken).stop()
            mcOutput = "停止：\(response)"
        } catch {
            mcOutput = error.localizedDescription
        }
    }

    private func sendMCCommand() async {
        do {
            let response = try await MinecraftServerClient(baseURL: mcBaseURL, token: mcToken).send(command: mcCommand)
            mcOutput = "已发送：\(mcCommand)\n\(response)"
            mcCommand = ""
        } catch {
            mcOutput = error.localizedDescription
        }
    }

    private var client: MinecraftServerClient {
        MinecraftServerClient(baseURL: mcBaseURL, token: mcToken)
    }

    private func runOPanel(_ operation: () async throws -> String) async {
        do {
            mcOutput = try await operation()
        } catch {
            mcOutput = error.localizedDescription
        }
    }

    private func setGamerule() async {
        let key = gameruleKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = gameruleValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !value.isEmpty else {
            mcOutput = "请填写规则名和值"
            return
        }
        await runOPanel { try await client.setGamerule(key: key, value: value) }
    }

    private func updateMOTD() async {
        let motd = motdText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !motd.isEmpty else {
            mcOutput = "请填写 MOTD"
            return
        }
        await runOPanel { try await client.setMOTD(motd) }
    }
}
