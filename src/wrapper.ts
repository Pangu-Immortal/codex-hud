/**
 * 功能：在同一终端中包裹 Codex CLI 并绘制 HUD。
 * 函数简介：直接继承当前终端 stdio 运行子命令，顶部保留 HUD，底部正常跑 Codex CLI。
 */

import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";
import { collectHudSnapshot } from "./collectors";
import { getHudHeight, renderHud } from "./render";
import type { CliOptions } from "./types";

export async function runWithHud(options: CliOptions): Promise<number> {
  const command = buildChildCommand(options.childCommand);
  if (shouldBypassHud(command)) {
    return await runPassthrough(command.file, command.args);
  }

  const renderOptions = {
    compact: options.compact,
    theme: options.theme,
    projectLimit: options.projectLimit,
    warningLimit: options.warningLimit
  };
  const hudHeight = getHudHeight(renderOptions);
  const terminal = process.stdout;
  const input = process.stdin;
  const columns = terminal.columns || 120;
  const rows = terminal.rows || 40;

  if (!terminal.isTTY || !input.isTTY) {
    throw new Error("codex-hud run 需要在交互式终端中执行");
  }

  // 关键逻辑：wrapper 自己进入 alt-screen，并在顶部预留 HUD 行，子进程直接复用这个终端。
  terminal.write("\u001B[?1049h");
  terminal.write("\u001B[2J");
  terminal.write("\u001B[H");
  terminal.write(`\u001B[${hudHeight + 1};${rows}r`);
  terminal.write(`\u001B[${hudHeight + 1};1H`);

  const child = spawn(command.file, command.args, {
    cwd: process.cwd(),
    env: {
      ...process.env,
      TERM: process.env.TERM ?? "xterm-256color"
    },
    stdio: "inherit"
  });

  let disposed = false;
  let refreshTimer: NodeJS.Timeout | null = null;
  let exitCode = 0;

  const restoreTerminal = (): void => {
    if (disposed) {
      return;
    }
    disposed = true;
    if (refreshTimer) {
      clearInterval(refreshTimer);
      refreshTimer = null;
    }
    terminal.write("\u001B[r");
    terminal.write("\u001B[?1049l");
  };

  const refreshHud = async (): Promise<void> => {
    try {
      const snapshot = await collectHudSnapshot(options.codexHome, options.hotThreadWindowMs, process.cwd());
      const lines = renderHud(snapshot, terminal.columns || columns, renderOptions);
      terminal.write("\u001B7");
      terminal.write("\u001B[1;1H");
      for (let index = 0; index < hudHeight; index += 1) {
        terminal.write("\u001B[2K");
        terminal.write(lines[index] ?? "".padEnd(terminal.columns || columns, " "));
        if (index < hudHeight - 1) {
          terminal.write("\n");
        }
      }
      terminal.write("\u001B8");
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      terminal.write("\u001B7");
      terminal.write("\u001B[1;1H");
      terminal.write("\u001B[2K");
      terminal.write(`\u001B[41m HUD 错误: ${message.slice(0, Math.max((terminal.columns || columns) - 10, 10))} \u001B[0m`);
      terminal.write("\u001B8");
    }
  };

  await refreshHud();
  refreshTimer = setInterval(() => {
    void refreshHud();
  }, options.refreshMs);

  process.stdout.on("resize", () => {
    const nextRows = process.stdout.rows || rows;
    terminal.write(`\u001B[${hudHeight + 1};${nextRows}r`);
    void refreshHud();
  });

  process.on("SIGINT", () => {
    child.kill("SIGINT");
  });

  process.on("SIGTERM", () => {
    child.kill("SIGTERM");
  });

  child.on("error", (error) => {
    restoreTerminal();
    process.stderr.write(`codex-hud 子进程错误：${error.message}\n`);
    process.exit(1);
  });

  child.on("exit", (code) => {
    exitCode = code ?? 0;
    restoreTerminal();
    process.exitCode = exitCode;
  });

  return await waitForExit(() => disposed, () => exitCode);
}

function buildChildCommand(rawCommand: string[]): { file: string; args: string[] } {
  const [file = "codex", ...restArgs] = rawCommand;
  const resolvedFile = resolveExecutable(file);
  const args = [...restArgs];

  if (pathLooksLikeCodex(resolvedFile) && !args.includes("--no-alt-screen")) {
    args.unshift("--no-alt-screen");
  }

  return { file: resolvedFile, args };
}

function pathLooksLikeCodex(file: string): boolean {
  const normalized = file.toLowerCase();
  return normalized === "codex" || normalized.endsWith(`${path.sep}codex`) || normalized.endsWith(`${path.sep}codex.exe`);
}

function resolveExecutable(file: string): string {
  if (path.isAbsolute(file)) {
    return file;
  }

  return file;
}

async function waitForExit(isDisposed: () => boolean, getExitCode: () => number): Promise<number> {
  while (!isDisposed()) {
    await new Promise<void>((resolve) => {
      setTimeout(resolve, 100);
    });
  }
  return getExitCode();
}

function shouldBypassHud(command: { file: string; args: string[] }): boolean {
  if (!pathLooksLikeCodex(command.file)) {
    return false;
  }

  return command.args.includes("--version")
    || command.args.includes("-V")
    || command.args.includes("--help")
    || command.args.includes("-h");
}

async function runPassthrough(file: string, args: string[]): Promise<number> {
  return await new Promise<number>((resolve, reject) => {
    const child = spawn(file, args, {
      cwd: process.cwd(),
      env: process.env,
      stdio: "inherit"
    });

    child.on("error", (error) => {
      reject(error);
    });

    child.on("exit", (code) => {
      resolve(code ?? 0);
    });
  });
}
