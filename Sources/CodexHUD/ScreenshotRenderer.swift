// 功能：渲染用于 README 与发布页展示的 PNG 截图。
// 函数简介：通过 SwiftUI 离屏渲染，将营销视图写入指定文件路径。

import AppKit
import Foundation
import SwiftUI

enum ScreenshotRenderer {
    @MainActor
    static func renderMarketingScreenshot(snapshot: DashboardSnapshot, to outputURL: URL) throws {
        // 关键逻辑：营销截图关闭底部动作区，避免和真实菜单操作混淆。
        let view = DashboardSurfaceView(
            snapshot: snapshot,
            errorMessage: nil,
            showsFooterActions: false,
            isRefreshing: false,
            onRefresh: {},
            onExport: {},
            onOpenCodexHome: {},
            onOpenRepository: {},
            onOpenProject: { _ in },
            onQuit: {}
        )
        .frame(width: 1220, height: 1540, alignment: .topLeading)

        // 关键逻辑：使用 `NSHostingView` 缓存显示，避免 `ImageRenderer` 在 ScrollView 下出现布局漂移。
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(x: 0, y: 0, width: 1220, height: 1540)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmapRepresentation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw NSError(domain: "CodexHUD", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无法创建截图缓存"])
        }

        bitmapRepresentation.size = hostingView.bounds.size
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRepresentation)

        guard let pngData = bitmapRepresentation.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "CodexHUD", code: 1004, userInfo: [NSLocalizedDescriptionKey: "无法编码 PNG 数据"])
        }

        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: outputURL, options: .atomic)
    }
}
