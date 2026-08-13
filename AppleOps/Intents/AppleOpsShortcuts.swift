import AppIntents

struct AppleOpsShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerLatestBuildIntent(),
            phrases: [
                "触发 \(.applicationName) 最新构建",
                "构建 \(.applicationName) 最新版本"
            ]
        )
        AppShortcut(
            intent: CheckBuildStatusIntent(),
            phrases: [
                "查看 \(.applicationName) 构建状态",
                "检查 \(.applicationName) 构建"
            ]
        )
        AppShortcut(
            intent: CheckWDAStatusIntent(),
            phrases: [
                "查看 \(.applicationName) WDA 状态",
                "检查 \(.applicationName) WDA"
            ]
        )
        AppShortcut(
            intent: CaptureScreenshotIntent(),
            phrases: [
                "用 \(.applicationName) 截屏",
                "让 \(.applicationName) 截图"
            ]
        )
        AppShortcut(
            intent: ReadVerificationCodeIntent(),
            phrases: [
                "读取 \(.applicationName) 验证码",
                "用 \(.applicationName) 读取验证码"
            ]
        )
    }
}
