/**
 * 功能：定义 CLI HUD 的核心类型。
 * 函数简介：统一描述命令参数、状态快照、进程、线程和日志事件。
 */

export interface CliOptions {
  command: "run" | "snapshot";
  codexHome: string;
  refreshMs: number;
  hotThreadWindowMs: number;
  rawJson: boolean;
  childCommand: string[];
}

export interface ProcessSnapshot {
  pid: number;
  cpu: number;
  memory: number;
  startedAtText: string;
  command: string;
  cwd: string | null;
  kind: "interactive" | "app-server";
}

export interface ThreadSnapshot {
  id: string;
  title: string;
  cwd: string;
  updatedAtMs: number;
  model: string | null;
  reasoningEffort: string | null;
}

export interface WarningSnapshot {
  level: string;
  target: string;
  body: string;
  timestampMs: number;
}

export interface ProjectSnapshot {
  path: string;
  name: string;
  interactiveSessions: number;
  hotThreads: number;
  backgroundAgents: number;
  appServers: number;
  latestTitles: string[];
  latestModels: string[];
}

export interface HudSnapshot {
  workspace: string;
  codexHome: string;
  generatedAtMs: number;
  interactiveSessions: number;
  appServers: number;
  backgroundAgents: number;
  hotThreads: number;
  warnings: number;
  errors: number;
  recentThreadTitle: string;
  recentThreadCwd: string;
  recentTools: string[];
  projects: ProjectSnapshot[];
  processes: ProcessSnapshot[];
  warningEvents: WarningSnapshot[];
}
