// 功能：定义菜单栏 HUD 的主界面。
// 函数简介：渲染摘要、指标卡片、项目分组、进程列表、活动流与操作区。

import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: DashboardStore
    let showsFooterActions: Bool

    var body: some View {
        DashboardSurfaceView(
            snapshot: store.snapshot,
            errorMessage: store.lastErrorMessage,
            showsFooterActions: showsFooterActions,
            isRefreshing: store.isRefreshing,
            onRefresh: {
                Task { await store.refreshNow() }
            },
            onExport: {
                Task { await store.exportDiagnosticsToDesktop() }
            },
            onOpenCodexHome: {
                store.openCodexHome()
            },
            onOpenRepository: {
                store.openRepository()
            },
            onOpenProject: { project in
                store.openProject(project)
            },
            onQuit: {
                store.quit()
            }
        )
        .task {
            store.startMonitoringIfNeeded()
        }
    }
}

struct DashboardSurfaceView: View {
    let snapshot: DashboardSnapshot
    let errorMessage: String?
    let showsFooterActions: Bool
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onExport: () -> Void
    let onOpenCodexHome: () -> Void
    let onOpenRepository: () -> Void
    let onOpenProject: (ProjectSnapshot) -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            // 关键逻辑：用分层渐变提升识别度，让菜单栏面板在深色系统下也有独立品牌感。
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                    Color(red: 0.05, green: 0.07, blue: 0.11),
                    Color(red: 0.03, green: 0.04, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection
                    metricsSection
                    projectsSection
                    processesSection
                    threadsSection
                    activitySection
                    warningsSection
                    notesSection
                    if showsFooterActions {
                        footerSection
                    }
                }
                .padding(18)
            }
        }
        .frame(minWidth: 540, idealWidth: 560, maxWidth: 640, minHeight: 780, idealHeight: 840, maxHeight: 920)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Codex HUD")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("OpenAI Codex 的实时菜单栏作战面板")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text("最近刷新：\(Formatters.timestamp(snapshot.generatedAt))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HealthBadge(health: snapshot.health)
                    statusCapsule
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.99, green: 0.80, blue: 0.38))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.33, green: 0.18, blue: 0.08))
                    )
            }
        }
        .padding(18)
        .background(panelBackground)
    }

    private var statusCapsule: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRefreshing ? Color(red: 0.36, green: 0.78, blue: 1.0) : Formatters.healthColor(snapshot.health))
                .frame(width: 10, height: 10)
            Text(isRefreshing ? "刷新中" : "监控中")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("核心指标")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                MetricCard(title: "运行会话", value: "\(snapshot.interactiveSessionCount)", subtitle: "交互式 Codex 进程")
                MetricCard(title: "后台 Agent", value: "\(snapshot.backgroundAgentCount)", subtitle: "spawn edges + jobs")
                MetricCard(title: "热点线程", value: "\(snapshot.hotThreadCount)", subtitle: "最近 15 分钟更新")
                MetricCard(title: "告警", value: "\(snapshot.warningCount + snapshot.errorCount)", subtitle: "WARN \(snapshot.warningCount) / ERROR \(snapshot.errorCount)")
            }
        }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("项目视图")

            ForEach(snapshot.projects) { project in
                Button {
                    onOpenProject(project)
                } label: {
                    ProjectCard(project: project)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var processesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("运行进程")

            if snapshot.processes.isEmpty {
                EmptyStateCard(text: "未发现正在运行的 Codex 进程。")
            } else {
                ForEach(snapshot.processes.prefix(6)) { process in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: process.kind == .interactive ? "terminal.fill" : "server.rack")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(process.kind == .interactive ? Color.cyan : Color.orange)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(process.kind == .interactive ? "交互会话 #\(process.pid)" : "App Server #\(process.pid)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(process.workingDirectory.map { Formatters.pathTail($0) } ?? "未知目录")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.70))

                            Text("CPU \(Formatters.percentage(process.cpuPercent)) · MEM \(Formatters.percentage(process.memoryPercent)) · 运行 \(process.elapsedTimeText)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.56))
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(panelBackground)
                }
            }
        }
    }

    private var threadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("热点线程")

            if snapshot.hotThreads.isEmpty {
                EmptyStateCard(text: "最近没有热点线程。")
            } else {
                ForEach(snapshot.hotThreads.prefix(6)) { thread in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(thread.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            Spacer()

                            Text(Formatters.relativeTime(from: thread.updatedAt))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.55))
                        }

                        Text(Formatters.pathTail(thread.cwd))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.68))

                        HStack(spacing: 8) {
                            TinyBadge(text: thread.source.uppercased(), color: Color(red: 0.19, green: 0.45, blue: 0.82))
                            if let model = thread.model {
                                TinyBadge(text: model, color: Color(red: 0.45, green: 0.31, blue: 0.92))
                            }
                            if let reasoning = thread.reasoningEffort {
                                TinyBadge(text: reasoning, color: Color(red: 0.09, green: 0.68, blue: 0.58))
                            }
                        }
                    }
                    .padding(14)
                    .background(panelBackground)
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("实时信号流")

            if snapshot.activitySignals.isEmpty {
                EmptyStateCard(text: "还没有足够的活动信号。")
            } else {
                ForEach(snapshot.activitySignals.prefix(8)) { signal in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: Formatters.signalIcon(signal.kind))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Formatters.signalColor(signal.kind))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(signal.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(signal.subtitle)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.68))
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(Formatters.relativeTime(from: signal.timestamp))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.48))
                    }
                    .padding(14)
                    .background(panelBackground)
                }
            }
        }
    }

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("最近告警")

            if snapshot.recentWarnings.isEmpty {
                EmptyStateCard(text: "最近日志中没有 WARN 或 ERROR。")
            } else {
                ForEach(snapshot.recentWarnings.prefix(5)) { warning in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(warning.level.uppercased()) · \(warning.target)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(Formatters.relativeTime(from: warning.timestamp))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.48))
                        }

                        Text(warning.body.isEmpty ? "无日志正文" : warning.body)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .lineLimit(3)
                    }
                    .padding(14)
                    .background(panelBackground)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("诊断说明")

            ForEach(snapshot.notes, id: \.self) { note in
                Text(note)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(panelBackground)
            }
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("操作")

            HStack(spacing: 10) {
                ActionButton(title: "立即刷新", icon: "arrow.clockwise", accent: .cyan, action: onRefresh)
                ActionButton(title: "导出诊断", icon: "square.and.arrow.up", accent: .orange, action: onExport)
            }

            HStack(spacing: 10) {
                ActionButton(title: "打开 .codex", icon: "folder.fill", accent: .green, action: onOpenCodexHome)
                ActionButton(title: "项目仓库", icon: "link", accent: .purple, action: onOpenRepository)
                ActionButton(title: "退出", icon: "power", accent: .red, action: onQuit)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 2)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct HealthBadge: View {
    let health: DashboardHealth

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Formatters.healthColor(health))
                .frame(width: 12, height: 12)
            Text(health.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Formatters.healthColor(health).opacity(0.22))
        )
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))

            Text(value)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct ProjectCard: View {
    let project: ProjectSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(project.displayName)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if project.workspaceActive {
                    TinyBadge(text: "ACTIVE", color: Color(red: 0.12, green: 0.70, blue: 0.54))
                }

                Spacer()

                if let lastUpdatedAt = project.lastUpdatedAt {
                    Text(Formatters.relativeTime(from: lastUpdatedAt))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.52))
                }
            }

            Text(Formatters.pathTail(project.path, maxComponents: 3))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.64))

            HStack(spacing: 8) {
                TinyBadge(text: "会话 \(project.interactiveSessions)", color: Color(red: 0.13, green: 0.53, blue: 0.92))
                TinyBadge(text: "线程 \(project.hotThreads)", color: Color(red: 0.44, green: 0.35, blue: 0.95))
                TinyBadge(text: "Agent \(project.backgroundAgents)", color: Color(red: 0.95, green: 0.52, blue: 0.18))
                if project.appServers > 0 {
                    TinyBadge(text: "Srv \(project.appServers)", color: Color(red: 0.14, green: 0.70, blue: 0.56))
                }
            }

            if !project.latestModelNames.isEmpty {
                Text(project.latestModelNames.joined(separator: " · "))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.80))
            }

            if let title = project.latestTitles.first {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.66))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct TinyBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.78))
            )
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.82))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.68))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
    }
}
