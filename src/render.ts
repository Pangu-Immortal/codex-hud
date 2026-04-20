/**
 * 功能：把 HUD 快照渲染为终端顶部状态区。
 * 函数简介：生成固定高度的 ASCII / ANSI HUD 文本，供 wrapper 周期性重绘。
 */

import path from "node:path";
import type { HudSnapshot, RenderOptions } from "./types";

const FULL_HEIGHT = 3;
const COMPACT_HEIGHT = 2;

export function renderHud(snapshot: HudSnapshot, terminalColumns: number, options: RenderOptions): string[] {
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

  if (options.compact) {
    return [
      applyStyle(fitLine(statusText, terminalColumns), options.theme, 0),
      applyStyle(fitLine(recentThread, terminalColumns), options.theme, 1)
    ];
  }

  return [
    applyStyle(fitLine(statusText, terminalColumns), options.theme, 0),
    applyStyle(fitLine(recentThread, terminalColumns), options.theme, 1),
    applyStyle(fitLine(recentTools, terminalColumns), options.theme, 2)
  ];
}

export function renderSnapshotText(snapshot: HudSnapshot, options: RenderOptions): string {
  const projectLines = snapshot.projects.slice(0, options.projectLimit).map((item) =>
    `- ${item.workspaceActive ? "[ACTIVE] " : ""}${item.name}: 会话 ${item.interactiveSessions}, 线程 ${item.hotThreads}, Agent ${item.backgroundAgents}`
  );
  const warningLines = snapshot.warningEvents.slice(0, options.warningLimit).map((item) =>
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

export function getHudHeight(options: RenderOptions): number {
  return options.compact ? COMPACT_HEIGHT : FULL_HEIGHT;
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

function applyStyle(content: string, theme: RenderOptions["theme"], lineIndex: number): string {
  if (theme === "plain") {
    return content;
  }

  const palette = theme === "amber"
    ? [208, 214, 220]
    : [45, 39, 31];

  const background = palette[Math.min(lineIndex, palette.length - 1)];
  return `\u001B[48;5;${background}m\u001B[38;5;255m${content}\u001B[0m`;
}
