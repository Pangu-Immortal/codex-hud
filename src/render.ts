/**
 * 功能：把 HUD 快照渲染为终端顶部状态区。
 * 函数简介：生成固定高度的 ASCII / ANSI HUD 文本，供 wrapper 周期性重绘。
 */

import path from "node:path";
import type { HudSnapshot } from "./types";

export const HUD_HEIGHT = 3;

export function renderHud(snapshot: HudSnapshot, terminalColumns: number): string[] {
  const workspaceName = path.basename(snapshot.workspace) || snapshot.workspace;
  const statusText =
    ` Codex HUD | ${workspaceName} | 会话 ${snapshot.interactiveSessions}` +
    ` | Agent ${snapshot.backgroundAgents}` +
    ` | 热线程 ${snapshot.hotThreads}` +
    ` | WARN ${snapshot.warnings}` +
    ` | ERROR ${snapshot.errors} `;

  const recentThread = snapshot.recentThreadTitle.length > 0
    ? ` 最近线程: ${snapshot.recentThreadTitle} `
    : " 最近线程: n/a ";

  const recentTools = snapshot.recentTools.length > 0
    ? ` 最近工具: ${snapshot.recentTools.join(", ")} `
    : " 最近工具: none ";

  return [
    applyStyle(fitLine(statusText, terminalColumns), 45),
    applyStyle(fitLine(recentThread, terminalColumns), 39),
    applyStyle(fitLine(recentTools, terminalColumns), 31)
  ];
}

export function renderSnapshotText(snapshot: HudSnapshot): string {
  const projectLines = snapshot.projects.slice(0, 5).map((item) =>
    `- ${item.workspaceActive ? "[ACTIVE] " : ""}${item.name}: 会话 ${item.interactiveSessions}, 线程 ${item.hotThreads}, Agent ${item.backgroundAgents}`
  );
  const warningLines = snapshot.warningEvents.slice(0, 3).map((item) =>
    `- ${item.level} ${item.target}: ${item.body}`
  );

  return [
    "[Codex HUD Snapshot]",
    `workspace: ${snapshot.workspace}`,
    `codexHome: ${snapshot.codexHome}`,
    `activeWorkspaceRoots: ${snapshot.activeWorkspaceRoots.length}`,
    `interactiveSessions: ${snapshot.interactiveSessions}`,
    `backgroundAgents: ${snapshot.backgroundAgents}`,
    `hotThreads: ${snapshot.hotThreads}`,
    `warnings: ${snapshot.warnings}`,
    `errors: ${snapshot.errors}`,
    `recentThread: ${snapshot.recentThreadTitle}`,
    `recentTools: ${snapshot.recentTools.join(", ") || "none"}`,
    "projects:",
    ...(projectLines.length > 0 ? projectLines : ["- none"]),
    "warningsList:",
    ...(warningLines.length > 0 ? warningLines : ["- none"])
  ].join("\n");
}

function fitLine(content: string, columns: number): string {
  if (columns <= 0) {
    return content;
  }

  if (content.length >= columns) {
    return content.slice(0, Math.max(columns - 1, 0)).padEnd(columns, " ");
  }

  return content.padEnd(columns, " ");
}

function applyStyle(content: string, colorCode: number): string {
  return `\u001B[48;5;${colorCode}m\u001B[38;5;255m${content}\u001B[0m`;
}
