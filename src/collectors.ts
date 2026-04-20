/**
 * 功能：采集 Codex CLI HUD 所需的本地状态。
 * 函数简介：读取进程、SQLite、全局状态和日志，生成终端 HUD 快照。
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import initSqlJs from "sql.js";
import psList from "ps-list";
import type { Database, SqlJsStatic } from "sql.js";
import type {
  HudSnapshot,
  ProcessSnapshot,
  ProjectSnapshot,
  ThreadSnapshot,
  WarningSnapshot
} from "./types";

let sqlRuntimePromise: Promise<SqlJsStatic> | null = null;
const execFileAsync = promisify(execFile);

export async function collectHudSnapshot(
  codexHome: string,
  hotThreadWindowMs: number,
  workspace: string
): Promise<HudSnapshot> {
  const activeWorkspaceRoots = collectActiveWorkspaceRoots(path.join(codexHome, ".codex-global-state.json"));
  const processes = await collectProcesses();
  const threads = await collectThreads(path.join(codexHome, "state_5.sqlite"));
  const backgroundAgents = await collectBackgroundAgentCount(path.join(codexHome, "state_5.sqlite"), hotThreadWindowMs);
  const warningEvents = await collectWarnings(path.join(codexHome, "logs_2.sqlite"));
  const recentTools = collectRecentTools(path.join(codexHome, "log", "codex-tui.log"));
  const hotThresholdMs = Date.now() - hotThreadWindowMs;
  const hotThreads = threads.filter((item) => item.updatedAtMs >= hotThresholdMs);
  const threadsForProjects = hotThreads.length > 0 ? hotThreads : threads.slice(0, 12);
  const projects = buildProjects(processes, threadsForProjects, backgroundAgents.byPath, activeWorkspaceRoots);
  const warningCount = warningEvents.filter((item) => item.level.toUpperCase() === "WARN").length;
  const errorCount = warningEvents.filter((item) => item.level.toUpperCase() === "ERROR").length;
  const mostRecentThread = hotThreads[0] ?? threads[0] ?? null;

  return {
    workspace,
    codexHome,
    generatedAtMs: Date.now(),
    activeWorkspaceRoots,
    interactiveSessions: processes.filter((item) => item.kind === "interactive").length,
    appServers: processes.filter((item) => item.kind === "app-server").length,
    backgroundAgents: backgroundAgents.total,
    hotThreads: hotThreads.length,
    warnings: warningCount,
    errors: errorCount,
    recentThreadTitle: mostRecentThread?.title ?? "",
    recentThreadCwd: mostRecentThread?.cwd ?? "",
    recentTools,
    projects,
    processes,
    warningEvents
  };
}

async function collectProcesses(): Promise<ProcessSnapshot[]> {
  const listed = await psList();
  const resolvedEntries = await Promise.all(
    listed
      .filter((item) => {
        const normalizedCommand = `${item.name} ${item.cmd ?? ""}`.trim();
        return isRealCodexProcess(item.name, normalizedCommand);
      })
      .map(async (item) => {
        const normalizedCommand = `${item.name} ${item.cmd ?? ""}`.trim();
        const lowerCommand = normalizedCommand.toLowerCase();
        const isAppServer = lowerCommand.includes("app-server");
        const cwd = await resolveWorkingDirectory(item.pid, normalizedCommand);
        return {
          pid: item.pid,
          parentPid: item.ppid ?? null,
          cpu: item.cpu ?? 0,
          memory: item.memory ?? 0,
          startedAtText: item.started ?? item.ppid?.toString() ?? "",
          command: normalizedCommand,
          cwd,
          kind: isAppServer ? "app-server" as const : "interactive" as const
        };
      })
  );

  return dedupeProcesses(resolvedEntries)
    .sort((left, right) => right.pid - left.pid);
}

async function collectThreads(stateDbPath: string): Promise<ThreadSnapshot[]> {
  if (!fs.existsSync(stateDbPath)) {
    return [];
  }

  const database = await openDatabase(stateDbPath);
  try {
    const rows = executeQuery(
      database,
      `
        SELECT
          id,
          title,
          cwd,
          updated_at_ms,
          model,
          reasoning_effort
        FROM threads
        WHERE archived = 0
        ORDER BY updated_at_ms DESC
        LIMIT 120
      `
    );

    return rows.map((row) => ({
      id: toStringValue(row.id),
      title: toStringValue(row.title),
      cwd: toStringValue(row.cwd),
      updatedAtMs: Number(row.updated_at_ms ?? 0),
      model: nullableStringValue(row.model),
      reasoningEffort: nullableStringValue(row.reasoning_effort)
    }));
  } finally {
    database.close();
  }
}

async function collectBackgroundAgentCount(
  stateDbPath: string,
  hotThreadWindowMs: number
): Promise<{ total: number; byPath: Map<string, number> }> {
  if (!fs.existsSync(stateDbPath)) {
    return { total: 0, byPath: new Map<string, number>() };
  }

  const database = await openDatabase(stateDbPath);
  try {
    const hotThresholdMs = Date.now() - hotThreadWindowMs;
    const edgeRows = executeQuery(
      database,
      `
        SELECT
          t.cwd AS cwd,
          COUNT(*) AS count
        FROM thread_spawn_edges e
        JOIN threads t ON t.id = e.child_thread_id
        WHERE t.archived = 0
          AND t.updated_at_ms >= ${hotThresholdMs}
        GROUP BY t.cwd
      `
    );

    const jobRows = executeQuery(
      database,
      `
        SELECT
          COUNT(*) AS count
        FROM agent_jobs
        WHERE LOWER(status) IN ('running', 'queued', 'in_progress', 'pending')
      `
    );

    const byPath = new Map<string, number>();
    let total = 0;

    for (const row of edgeRows) {
      const cwd = toStringValue(row.cwd);
      const count = Number(row.count ?? 0);
      byPath.set(cwd, count);
      total += count;
    }

    total += Number(jobRows[0]?.count ?? 0);
    return { total, byPath };
  } finally {
    database.close();
  }
}

async function collectWarnings(logDbPath: string): Promise<WarningSnapshot[]> {
  if (!fs.existsSync(logDbPath)) {
    return [];
  }

  const database = await openDatabase(logDbPath);
  try {
    const rows = executeQuery(
      database,
      `
        SELECT
          ts,
          level,
          target,
          SUBSTR(COALESCE(feedback_log_body, ''), 1, 180) AS body
        FROM logs
        WHERE level IN ('WARN', 'ERROR')
        ORDER BY ts DESC
        LIMIT 20
      `
    );

    return rows.map((row) => ({
      level: toStringValue(row.level),
      target: toStringValue(row.target),
      body: toStringValue(row.body),
      timestampMs: Number(row.ts ?? 0) * 1_000
    }));
  } finally {
    database.close();
  }
}

function collectRecentTools(logPath: string): string[] {
  if (!fs.existsSync(logPath)) {
    return [];
  }

  const text = fs.readFileSync(logPath, "utf8").slice(-200_000);
  const matches = [...text.matchAll(/ToolCall:\s+([A-Za-z0-9_.]+)/g)].map((item) => item[1]);
  return matches.slice(-6);
}

function buildProjects(
  processes: ProcessSnapshot[],
  threads: ThreadSnapshot[],
  backgroundAgentsByPath: Map<string, number>,
  activeWorkspaceRoots: string[]
): ProjectSnapshot[] {
  const grouped = new Map<string, ProjectAccumulator>();
  const activeWorkspaceSet = new Set(activeWorkspaceRoots);

  for (const process of processes) {
    if (!process.cwd) {
      continue;
    }
    const key = process.cwd;
    const accumulator = grouped.get(key) ?? createAccumulator(key);
    if (process.kind === "interactive") {
      accumulator.interactiveSessions += 1;
    } else {
      accumulator.appServers += 1;
    }
    grouped.set(key, accumulator);
  }

  for (const thread of threads) {
    const accumulator = grouped.get(thread.cwd) ?? createAccumulator(thread.cwd);
    accumulator.hotThreads += 1;
    if (thread.title.length > 0 && accumulator.latestTitles.length < 3) {
      accumulator.latestTitles.push(thread.title);
    }
    if (thread.model && !accumulator.latestModels.includes(thread.model)) {
      accumulator.latestModels.push(thread.model);
    }
    grouped.set(thread.cwd, accumulator);
  }

  for (const [cwd, count] of backgroundAgentsByPath.entries()) {
    const accumulator = grouped.get(cwd) ?? createAccumulator(cwd);
    accumulator.backgroundAgents += count;
    grouped.set(cwd, accumulator);
  }

  return [...grouped.values()]
    .map((item) => ({
      path: item.path,
      name: path.basename(item.path) || item.path,
      workspaceActive: activeWorkspaceSet.has(item.path),
      interactiveSessions: item.interactiveSessions,
      hotThreads: item.hotThreads,
      backgroundAgents: item.backgroundAgents,
      appServers: item.appServers,
      latestTitles: item.latestTitles,
      latestModels: item.latestModels
    }))
    .sort((left, right) => {
      const leftScore = left.interactiveSessions + left.hotThreads + left.backgroundAgents;
      const rightScore = right.interactiveSessions + right.hotThreads + right.backgroundAgents;
      return rightScore - leftScore;
    });
}

function isRealCodexProcess(name: string, command: string): boolean {
  const lowerName = name.toLowerCase();
  const lowerCommand = command.toLowerCase();

  if (lowerCommand.includes("codex-hud")) {
    return false;
  }

  if (lowerName === "node" && (lowerCommand.includes(`${path.sep}bin${path.sep}codex`) || lowerCommand.includes("\\bin\\codex"))) {
    return false;
  }

  if (lowerCommand.includes("codex app-server")) {
    return true;
  }

  if (lowerCommand.includes("/codex/codex") || lowerCommand.includes("\\codex\\codex.exe")) {
    return true;
  }

  if (lowerName === "codex" || lowerName === "codex.exe") {
    return true;
  }

  return /(^|[\s/\\])codex(\.exe)?($|[\s"])/i.test(command);
}

function collectActiveWorkspaceRoots(globalStatePath: string): string[] {
  if (!fs.existsSync(globalStatePath)) {
    return [];
  }

  try {
    const raw = JSON.parse(fs.readFileSync(globalStatePath, "utf8")) as {
      ["active-workspace-roots"]?: unknown;
    };
    const roots = raw["active-workspace-roots"];
    if (!Array.isArray(roots)) {
      return [];
    }
    return roots.filter((item): item is string => typeof item === "string");
  } catch {
    return [];
  }
}

async function resolveWorkingDirectory(pid: number, command: string): Promise<string | null> {
  const byProc = resolveWorkingDirectoryFromProc(pid);
  if (byProc) {
    return byProc;
  }

  const byLsof = await resolveWorkingDirectoryFromLsof(pid);
  if (byLsof) {
    return byLsof;
  }

  return extractCwdFromCommand(command);
}

function resolveWorkingDirectoryFromProc(pid: number): string | null {
  if (process.platform !== "linux") {
    return null;
  }

  try {
    return fs.realpathSync(`/proc/${pid}/cwd`);
  } catch {
    return null;
  }
}

async function resolveWorkingDirectoryFromLsof(pid: number): Promise<string | null> {
  if (process.platform !== "darwin") {
    return null;
  }

  try {
    const { stdout } = await execFileAsync("/usr/sbin/lsof", ["-a", "-d", "cwd", "-p", String(pid), "-Fn"]);
    const line = stdout
      .split("\n")
      .find((item) => item.startsWith("n"));
    return line ? line.slice(1) : null;
  } catch {
    return null;
  }
}

function dedupeProcesses(processes: ProcessSnapshot[]): ProcessSnapshot[] {
  const pidSet = new Set(processes.map((item) => item.pid));
  return processes.filter((item) => {
    if (item.kind !== "interactive") {
      return true;
    }
    if (!item.parentPid) {
      return true;
    }
    if (!pidSet.has(item.parentPid)) {
      return true;
    }
    return !item.command.toLowerCase().includes(`${path.sep}codex${path.sep}codex`);
  });
}

function createAccumulator(targetPath: string): ProjectAccumulator {
  return {
    path: targetPath,
    interactiveSessions: 0,
    hotThreads: 0,
    backgroundAgents: 0,
    appServers: 0,
    latestTitles: [],
    latestModels: []
  };
}

async function openDatabase(filePath: string): Promise<Database> {
  const sqlRuntime = await getSqlRuntime();
  const fileBuffer = fs.readFileSync(filePath);
  return new sqlRuntime.Database(fileBuffer);
}

async function getSqlRuntime(): Promise<SqlJsStatic> {
  if (!sqlRuntimePromise) {
    sqlRuntimePromise = initSqlJs({});
  }
  return sqlRuntimePromise;
}

function executeQuery(database: Database, sql: string): Record<string, unknown>[] {
  const result = database.exec(sql);
  if (result.length === 0) {
    return [];
  }

  const [first] = result;
  const columns = first.columns;
  return first.values.map((row) => {
    const shaped: Record<string, unknown> = {};
    columns.forEach((column, index) => {
      shaped[column] = row[index];
    });
    return shaped;
  });
}

function extractCwdFromCommand(command: string): string | null {
  const homeDir = os.homedir();
  const patterns = [
    new RegExp(`${escapeRegex(homeDir)}[^\\s'"]+`, "g"),
    /\/Users\/[^\s'"]+/g,
    /[A-Za-z]:\\[^\s'"]+/g
  ];

  for (const pattern of patterns) {
    const matches = command.match(pattern);
    if (matches && matches.length > 0) {
      return matches[0];
    }
  }

  return null;
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function toStringValue(value: unknown): string {
  if (typeof value === "string") {
    return value;
  }
  if (typeof value === "number") {
    return String(value);
  }
  return "";
}

function nullableStringValue(value: unknown): string | null {
  const normalized = toStringValue(value);
  return normalized.length > 0 ? normalized : null;
}

interface ProjectAccumulator {
  path: string;
  interactiveSessions: number;
  hotThreads: number;
  backgroundAgents: number;
  appServers: number;
  latestTitles: string[];
  latestModels: string[];
}
