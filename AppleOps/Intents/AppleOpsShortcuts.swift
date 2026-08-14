import AppIntents

struct AppleOpsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerLatestBuildIntent(),
            phrases: [
                "触发 \(.applicationName) 最新构建",
                "构建 \(.applicationName) 最新版本",
                "Trigger \(.applicationName) latest build",
                "Build \(.applicationName) latest version"
            ]
        )
        AppShortcut(
            intent: CheckBuildStatusIntent(),
            phrases: [
                "查看 \(.applicationName) 构建状态",
                "检查 \(.applicationName) 构建",
                "Check \(.applicationName) build status",
                "Check \(.applicationName) builds"
            ]
        )
        AppShortcut(
            intent: CheckWDAStatusIntent(),
            phrases: [
                "查看 \(.applicationName) WDA 状态",
                "检查 \(.applicationName) WDA",
                "Check \(.applicationName) WDA status",
                "Check \(.applicationName) WDA"
            ]
        )
        AppShortcut(
            intent: CaptureScreenshotIntent(),
            phrases: [
                "用 \(.applicationName) 截屏",
                "让 \(.applicationName) 截图",
                "Take a screenshot with \(.applicationName)",
                "Use \(.applicationName) to screenshot"
            ]
        )
        AppShortcut(
            intent: ReadVerificationCodeIntent(),
            phrases: [
                "读取 \(.applicationName) 验证码",
                "用 \(.applicationName) 读取验证码",
                "Read \(.applicationName) verification code",
                "Use \(.applicationName) to read verification code"
            ]
        )
        AppShortcut(
            intent: PressHomeIntent(),
            phrases: [
                "让 \(.applicationName) 回到主屏",
                "用 \(.applicationName) 按主屏键",
                "Go home in \(.applicationName)",
                "Press home in \(.applicationName)"
            ]
        )
        AppShortcut(
            intent: CheckSigningStatusIntent(),
            phrases: [
                "查看 \(.applicationName) 签名状态",
                "检查 \(.applicationName) 签名和设备",
                "Check \(.applicationName) signing status",
                "Check \(.applicationName) signing and devices"
            ]
        )
        AppShortcut(
            intent: CheckFirstMachineStatusIntent(),
            phrases: [
                "查看 \(.applicationName) 默认机器状态",
                "检查 \(.applicationName) 第一台机器",
                "Check \(.applicationName) default machine status",
                "Check \(.applicationName) first machine"
            ]
        )
        AppShortcut(
            intent: RunPresetCommandIntent(),
            phrases: [
                "运行 \(.applicationName) 预设命令",
                "执行 \(.applicationName) 预设命令",
                "Run \(.applicationName) preset command",
                "Execute \(.applicationName) preset command"
            ]
        )
        AppShortcut(
            intent: MinecraftServerStatusIntent(),
            phrases: [
                "查看 \(.applicationName) Forge 服务器状态",
                "查看 \(.applicationName) 模组服务器状态",
                "Check \(.applicationName) Forge server status",
                "Check \(.applicationName) Forge server"
            ]
        )
        AppShortcut(
            intent: RestartMinecraftServerIntent(),
            phrases: [
                "重启 \(.applicationName) Forge 服务器",
                "重启 \(.applicationName) 模组服务器",
                "Restart \(.applicationName) Forge server",
                "Restart \(.applicationName) Forge"
            ]
        )
        AppShortcut(
            intent: StopMinecraftServerIntent(),
            phrases: [
                "停止 \(.applicationName) Forge 服务器",
                "停止 \(.applicationName) 模组服务器",
                "Stop \(.applicationName) Forge server",
                "Stop \(.applicationName) Forge"
            ]
        )
        AppShortcut(
            intent: SendMinecraftCommandIntent(),
            phrases: [
                "给 \(.applicationName) Forge 服务器发送指令",
                "给 \(.applicationName) 模组服务器发送指令",
                "Send \(.applicationName) Forge server command",
                "Run \(.applicationName) Forge server command"
            ]
        )
    }
}

extension Notification.Name {
    static let openToolsScreen = Notification.Name("openToolsScreen")
    static let searchTools = Notification.Name("searchTools")
}
