// 功能：定义菜单栏应用本体与状态栏标签。
// 函数简介：设置 Dock 可见性、承载菜单栏窗口，并绑定 HUD 主视图。

import AppKit
import SwiftUI

struct CodexHUDApplication: App {
    @StateObject private var store = DashboardStore(runtime: AppBootstrap.runtime)

    init() {
        // 关键逻辑：将应用设为 accessory，默认只出现在菜单栏中，不占用 Dock。
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView(store: store, showsFooterActions: true)
        } label: {
            MenuBarLabel(snapshot: store.snapshot, isRefreshing: store.isRefreshing)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

private struct MenuBarLabel: View {
    let snapshot: DashboardSnapshot
    let isRefreshing: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath.circle.fill" : "bolt.horizontal.circle.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Formatters.healthColor(snapshot.health))
            Text("\(snapshot.interactiveSessionCount)·\(snapshot.backgroundAgentCount)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Codex HUD")
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text("当前版本将设置项保持为极简形态：采集源固定为 `~/.codex`，刷新周期由命令行参数控制。后续会补齐可视化设置面板。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
    }
}
