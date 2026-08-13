import SwiftUI

struct DevicesView: View {
    @EnvironmentObject private var store: AppleOpsStore
    @State private var wdaReady: Bool?
    @State private var screenshot: UIImage?
    @State private var codes: [String] = []
    @State private var signingInfo: [SigningInfo] = []
    @State private var errorMessage: String?

    private var wdaClient: WDAClient {
        WDAClient(baseURL: store.wdaBaseURL)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("WDA") {
                    TextField("WDA 地址", text: $store.wdaBaseURL)
                    Button("检查状态") {
                        Task { await checkWDA() }
                    }
                    if let wdaReady {
                        Label(wdaReady ? "WDA 在线" : "WDA 离线", systemImage: wdaReady ? "checkmark.circle" : "xmark.circle")
                            .foregroundStyle(wdaReady ? .green : .red)
                    }
                    Button("截屏") {
                        Task { await capture() }
                    }
                    Button("读取验证码") {
                        Task { await readCode() }
                    }
                    if !codes.isEmpty {
                        Text("验证码候选: \(codes.joined(separator: ", "))")
                    }
                    if let screenshot {
                        Image(uiImage: screenshot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                    }
                }

                Section("签名/设备 Agent") {
                    TextField("Agent 地址", text: $store.agentBaseURL)
                    Button("刷新") {
                        Task { await loadSigningInfo() }
                    }
                    ForEach(signingInfo) { item in
                        LabeledContent(item.name, value: item.detail)
                    }
                }

                if let errorMessage {
                    Section("错误") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("签名/设备")
        }
    }

    private func checkWDA() async {
        wdaReady = await wdaClient.isReady()
    }

    private func capture() async {
        do {
            screenshot = try await wdaClient.screenshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func readCode() async {
        do {
            let image = try await wdaClient.screenshot()
            let texts = try wdaClient.recognizedText(in: image)
            codes = wdaClient.verificationCodes(from: texts)
            screenshot = image
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadSigningInfo() async {
        do {
            signingInfo = try await SigningAgentClient(baseURL: store.agentBaseURL).listInfo()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
