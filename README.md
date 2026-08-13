# AppleOps

AppleOps 是一个双向兼容 iOS 工具 App：

- 旧版跑马灯 Siri / 快捷指令：中文 AppIntent 触发
- iOS 27 灵动岛 Siri AI：英文 AppIntent + View Annotation 触发
- App 界面：中文

## 功能

- 云构建看板：GitHub Actions 工作流、Run、Job、Step、Artifact
- 签名/设备管理：通过 Agent 获取 App ID、证书、设备信息
- 远程机器控制：通过 HTTP Agent 执行命令、查看状态
- WDA：截屏、OCR、验证码、点击、滑动、回到主屏

## 构建

仓库根目录包含 `project.yml`，云构建使用 GitHub Actions 的 Xcode 27 arm64 runner。
