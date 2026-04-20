// 功能：定义菜单栏应用本体与状态栏标签。
// 函数简介：设置 Dock 可见性、承载菜单栏窗口，并绑定 HUD 主视图。

import AppKit
import SwiftUI

struct CodexHUDApplication: App {
    @StateObject private var preferences = DashboardPreferences()
    @StateObject private var store: DashboardStore

    init() {
        // 关键逻辑：将应用设为 accessory，默认只出现在菜单栏中，不占用 Dock。
        NSApplication.shared.setActivationPolicy(.accessory)
        let preferences = DashboardPreferences()
        _preferences = StateObject(wrappedValue: preferences)
        _store = StateObject(wrappedValue: DashboardStore(runtime: AppBootstrap.runtime, preferences: preferences))
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView(store: store, preferences: preferences, showsFooterActions: true)
        } label: {
            MenuBarLabel(snapshot: store.snapshot, isRefreshing: store.isRefreshing)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: preferences)
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
            if snapshot.errorCount > 0 {
                Text("!\(snapshot.errorCount)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
            } else if snapshot.warningCount > 0 {
                Text("+\(snapshot.warningCount)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var preferences: DashboardPreferences

    var body: some View {
        Form {
            Section("数据源") {
                TextField("自定义 Codex 目录（留空使用 ~/.codex）", text: $preferences.codexHomePathOverride)
                    .textFieldStyle(.roundedBorder)
                Text("如果你维护多套 Codex 环境，或把 `.codex` 放到其他目录，这里可以直接覆盖默认路径。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("刷新与窗口") {
                Picker("刷新频率", selection: $preferences.refreshIntervalSeconds) {
                    ForEach(DashboardPreferences.refreshIntervalOptions, id: \.self) { value in
                        Text("\(Int(value)) 秒").tag(value)
                    }
                }

                Picker("热点线程窗口", selection: $preferences.hotThreadWindowSeconds) {
                    ForEach(DashboardPreferences.hotWindowOptions, id: \.self) { value in
                        Text("\(Int(value / 60)) 分钟").tag(value)
                    }
                }
            }

            Section("筛选") {
                Picker("项目范围", selection: $preferences.projectScope) {
                    ForEach(DashboardProjectScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }

                Picker("告警列表", selection: $preferences.warningFilter) {
                    ForEach(DashboardWarningFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            }

            Section("显示数量") {
                Stepper("项目卡片：\(preferences.maxVisibleProjects)", value: $preferences.maxVisibleProjects, in: 3...12)
                Stepper("进程行数：\(preferences.maxVisibleProcesses)", value: $preferences.maxVisibleProcesses, in: 3...12)
                Stepper("线程行数：\(preferences.maxVisibleThreads)", value: $preferences.maxVisibleThreads, in: 3...12)
                Stepper("信号流：\(preferences.maxVisibleSignals)", value: $preferences.maxVisibleSignals, in: 4...16)
                Stepper("告警行数：\(preferences.maxVisibleWarnings)", value: $preferences.maxVisibleWarnings, in: 3...12)
            }

            Section("说明") {
                Text("所有设置都会持久化到本地 `UserDefaults`。修改后 HUD 会按新的刷新频率和热点窗口重新采集。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Button("恢复默认设置") {
                    preferences.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 520, height: 500)
    }
}
