/**
 * 功能：解析 CLI 参数。
 * 函数简介：支持 snapshot 与 run 两种模式，并解析 codex-home、刷新频率和热线程窗口。
 */

import os from "node:os";
import path from "node:path";
import type { CliOptions } from "./types";

const DEFAULT_CODEX_HOME = path.join(os.homedir(), ".codex");
const DEFAULT_REFRESH_MS = 1_000;
const DEFAULT_HOT_THREAD_WINDOW_MS = 15 * 60 * 1_000;

export function parseCli(argv: string[]): CliOptions {
  const args = [...argv];
  const command = normalizeCommand(args.shift());

  let codexHome = DEFAULT_CODEX_HOME;
  let refreshMs = DEFAULT_REFRESH_MS;
  let hotThreadWindowMs = DEFAULT_HOT_THREAD_WINDOW_MS;
  let rawJson = false;
  let childCommand: string[] = ["codex"];

  while (args.length > 0) {
    const current = args.shift();
    if (!current) {
      continue;
    }

    if (current === "--codex-home") {
      const nextValue = args.shift();
      if (!nextValue) {
        throw new Error("--codex-home 缺少路径值");
      }
      codexHome = path.resolve(nextValue);
      continue;
    }

    if (current === "--refresh-ms") {
      const nextValue = args.shift();
      if (!nextValue) {
        throw new Error("--refresh-ms 缺少数值");
      }
      refreshMs = Number(nextValue);
      continue;
    }

    if (current === "--hot-thread-ms") {
      const nextValue = args.shift();
      if (!nextValue) {
        throw new Error("--hot-thread-ms 缺少数值");
      }
      hotThreadWindowMs = Number(nextValue);
      continue;
    }

    if (current === "--json") {
      rawJson = true;
      continue;
    }

    if (current === "--") {
      childCommand = args.length > 0 ? [...args] : ["codex"];
      break;
    }

    if (command === "run" && childCommand.length === 1 && childCommand[0] === "codex") {
      childCommand = [current, ...args];
      break;
    }

    throw new Error(`未知参数：${current}`);
  }

  return {
    command,
    codexHome,
    refreshMs,
    hotThreadWindowMs,
    rawJson,
    childCommand
  };
}

function normalizeCommand(raw: string | undefined): "run" | "snapshot" {
  if (!raw || raw === "run") {
    return "run";
  }

  if (raw === "snapshot") {
    return "snapshot";
  }

  throw new Error(`未知命令：${raw}`);
}
