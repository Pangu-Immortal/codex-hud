// 功能：提供 HUD 视图所需的时间、数字、路径与标签格式化工具。
// 函数简介：统一人类可读文本，避免在视图层散落重复格式化逻辑。

import Foundation
import SwiftUI

enum Formatters {
    private static func makeRelativeFormatter() -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter
    }

    static func relativeTime(from date: Date) -> String {
        makeRelativeFormatter().localizedString(for: date, relativeTo: .now)
    }

    static func timestamp(_ date: Date) -> String {
        makeDateFormatter().string(from: date)
    }

    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    static func pathTail(_ path: String, maxComponents: Int = 2) -> String {
        let components = path.split(separator: "/").map(String.init)
        guard components.count > maxComponents else {
            return path
        }
        return "…/" + components.suffix(maxComponents).joined(separator: "/")
    }

    static func healthColor(_ health: DashboardHealth) -> Color {
        switch health {
        case .healthy:
            return Color(red: 0.17, green: 0.72, blue: 0.46)
        case .busy:
            return Color(red: 0.97, green: 0.62, blue: 0.20)
        case .warning:
            return Color(red: 0.96, green: 0.27, blue: 0.32)
        case .idle:
            return Color(red: 0.45, green: 0.50, blue: 0.58)
        }
    }

    static func signalColor(_ kind: ActivitySignalKind) -> Color {
        switch kind {
        case .process:
            return Color(red: 0.18, green: 0.60, blue: 0.95)
        case .thread:
            return Color(red: 0.50, green: 0.45, blue: 0.98)
        case .agent:
            return Color(red: 0.99, green: 0.55, blue: 0.18)
        case .warning:
            return Color(red: 0.95, green: 0.24, blue: 0.27)
        }
    }

    static func signalIcon(_ kind: ActivitySignalKind) -> String {
        switch kind {
        case .process:
            return "bolt.horizontal.circle.fill"
        case .thread:
            return "point.3.connected.trianglepath.dotted"
        case .agent:
            return "sparkles.rectangle.stack.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
}
