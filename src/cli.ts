/**
 * 功能：解析 CLI 参数。
 * 函数简介：支持 snapshot 与 run 两种模式，并解析 codex-home、刷新频率和热线程窗口。
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { CliOptions, HudConfigFile, HudTheme } from "./types";

const DEFAULT_CODEX_HOME = path.join(os.homedir(), ".codex");
const DEFAULT_REFRESH_MS = 1_000;
const DEFAULT_HOT_THREAD_WINDOW_MS = 15 * 60 * 1_000;
const DEFAULT_THEME: HudTheme = "cyan";
const DEFAULT_PROJECT_LIMIT = 5;
const DEFAULT_WARNING_LIMIT = 3;
const DEFAULT_CONFIG_PATH = path.join(os.homedir(), ".codex-hud.json");

export function parseCli(argv: string[]): CliOptions {
  const args = [...argv];
  const command = normalizeCommand(args.shift());
  const config = loadConfigFile();

  let codexHome = config.codexHome ? path.resolve(config.codexHome) : DEFAULT_CODEX_HOME;
  let refreshMs = normalizePositiveNumber(config.refreshMs, DEFAULT_REFRESH_MS);
  let hotThreadWindowMs = normalizePositiveNumber(config.hotThreadWindowMs, DEFAULT_HOT_THREAD_WINDOW_MS);
  let rawJson = false;
  let childCommand: string[] = ["codex"];
  let compact = config.compact ?? false;
  let inline = config.inline ?? false;
  let theme = config.theme ?? DEFAULT_THEME;
  let projectLimit = normalizePositiveNumber(config.projectLimit, DEFAULT_PROJECT_LIMIT);
  let warningLimit = normalizePositiveNumber(config.warningLimit, DEFAULT_WARNING_LIMIT);

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

    if (current === "--theme") {
      const nextValue = args.shift();
      if (!nextValue || !isHudTheme(nextValue)) {
        throw new Error("--theme 仅支持 cyan | amber | plain");
      }
      theme = nextValue;
      continue;
    }

    if (current === "--compact") {
      compact = true;
      continue;
    }

    if (current === "--inline") {
      inline = true;
      continue;
    }

    if (current === "--project-limit") {
      const nextValue = args.shift();
      if (!nextValue) {
        throw new Error("--project-limit 缺少数值");
      }
      projectLimit = Number(nextValue);
      continue;
    }

    if (current === "--warning-limit") {
      const nextValue = args.shift();
      if (!nextValue) {
        throw new Error("--warning-limit 缺少数值");
      }
      warningLimit = Number(nextValue);
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
    childCommand,
    compact,
    inline,
    theme,
    projectLimit,
    warningLimit
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

function loadConfigFile(): HudConfigFile {
  const configPath = process.env.CODEX_HUD_CONFIG
    ? path.resolve(process.env.CODEX_HUD_CONFIG)
    : DEFAULT_CONFIG_PATH;

  if (!fs.existsSync(configPath)) {
    return {};
  }

  try {
    const raw = JSON.parse(fs.readFileSync(configPath, "utf8")) as HudConfigFile;
    return raw;
  } catch {
    return {};
  }
}

function normalizePositiveNumber(value: number | undefined, fallback: number): number {
  if (typeof value !== "number" || Number.isNaN(value) || value <= 0) {
    return fallback;
  }
  return value;
}

function isHudTheme(value: string): value is HudTheme {
  return value === "cyan" || value === "amber" || value === "plain";
}
