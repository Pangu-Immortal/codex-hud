// 功能：管理 HUD 的刷新循环、状态发布、诊断导出与本地打开动作。
// 函数简介：作为 SwiftUI 视图的唯一状态源，调度数据采集并处理用户操作。

import AppKit
import Foundation
import OSLog

private let appModelLogger = Logger(subsystem: "com.panguimmortal.codex-hud", category: "app-model")

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var snapshot: DashboardSnapshot = .empty
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var isRefreshing = false

    private let baseRuntime: AppRuntime
    private let preferences: DashboardPreferences
    private var refreshTask: Task<Void, Never>?
    private var hasStarted = false

    init(runtime: AppRuntime, preferences: DashboardPreferences) {
        baseRuntime = runtime
        self.preferences = preferences
    }

    deinit {
        refreshTask?.cancel()
    }

    func startMonitoringIfNeeded() {
        guard !hasStarted else {
            return
        }
        hasStarted = true

        // 关键逻辑：首次进入后立即刷新，再按固定节奏轮询，保证菜单栏数据始终热更新。
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            await refreshNow()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(preferences.snapshot.refreshIntervalSeconds))
                } catch {
                    break
                }
                await refreshNow()
            }
        }
    }

    func refreshNow() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // 关键逻辑：将阻塞 IO 迁移到后台线程，避免菜单栏动画卡顿。
            let runtime = baseRuntime.applying(preferences.snapshot)
            let newSnapshot = try await Task.detached(priority: .utility) {
                try CodexSnapshotBuilder(runtime: runtime).loadSnapshot()
            }.value

            snapshot = newSnapshot
            lastErrorMessage = nil
        } catch {
            appModelLogger.error("刷新失败：\(error.localizedDescription, privacy: .public)")
            lastErrorMessage = error.localizedDescription
        }
    }

    func exportDiagnosticsToDesktop() async {
        let desktopURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Desktop")
            .appendingPathComponent("codex-hud-diagnostics-\(Int(Date().timeIntervalSince1970)).json")

        do {
            // 关键逻辑：导出的是当前内存快照，确保 UI 与 issue 附件完全一致。
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let exportPayload = DiagnosticExportPayload(
                exportedAt: .now,
                configuration: preferences.snapshot,
                snapshot: snapshot
            )
            let data = try encoder.encode(exportPayload)
            try data.write(to: desktopURL, options: .atomic)
            lastErrorMessage = "诊断已导出到：\(desktopURL.path)"
        } catch {
            lastErrorMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    func openCodexHome() {
        let effectiveRuntime = baseRuntime.applying(preferences.snapshot)
        NSWorkspace.shared.open(effectiveRuntime.codexHome)
    }

    func openProject(_ project: ProjectSnapshot) {
        NSWorkspace.shared.open(URL(fileURLWithPath: project.path))
    }

    func openRepository() {
        if let repositoryURL = URL(string: "https://github.com/Pangu-Immortal/codex-hud") {
            NSWorkspace.shared.open(repositoryURL)
        }
    }

    func openSettings() {
        // 关键逻辑：直接触发系统设置窗口命令，避免在菜单栏里再造一套弹层设置。
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
