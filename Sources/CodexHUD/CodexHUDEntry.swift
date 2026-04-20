// 功能：定义程序统一入口，并在截图模式与菜单栏模式之间切换。
// 函数简介：解析命令行参数，必要时直接输出 PNG 截图，否则启动 SwiftUI 菜单栏应用。

import AppKit

enum AppBootstrap {
    // 关键逻辑：在整个应用生命周期中复用同一份运行时配置。
    static let runtime = AppRuntime(arguments: CommandLine.arguments)
}

@main
enum CodexHUDEntry {
    static func main() async {
        // 关键逻辑：先处理离线截图模式，避免拉起完整菜单栏应用。
        if let screenshotURL = AppBootstrap.runtime.screenshotOutputURL {
            do {
                try await MainActor.run {
                    try ScreenshotRenderer.renderMarketingScreenshot(
                        snapshot: DashboardSnapshot.demo,
                        to: screenshotURL
                    )
                }
            } catch {
                fputs("截图生成失败：\(error.localizedDescription)\n", stderr)
                exit(1)
            }
            return
        }

        // 关键逻辑：普通模式直接进入菜单栏应用。
        await MainActor.run {
            CodexHUDApplication.main()
        }
    }
}
