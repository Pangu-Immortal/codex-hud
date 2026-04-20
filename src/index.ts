#!/usr/bin/env node
/**
 * 功能：CLI HUD 主入口。
 * 函数简介：解析命令，输出快照或启动带 HUD 的 Codex wrapper。
 */

import process from "node:process";
import { parseCli } from "./cli";
import { collectHudSnapshot } from "./collectors";
import { renderSnapshotText } from "./render";
import { runWithHud } from "./wrapper";

async function main(): Promise<void> {
  try {
    const options = parseCli(process.argv.slice(2));

    if (options.command === "snapshot") {
      const snapshot = await collectHudSnapshot(options.codexHome, options.hotThreadWindowMs, process.cwd());
      if (options.rawJson) {
        process.stdout.write(`${JSON.stringify(snapshot, null, 2)}\n`);
      } else {
        process.stdout.write(`${renderSnapshotText(snapshot)}\n`);
      }
      return;
    }

    const exitCode = await runWithHud(options);
    process.exitCode = exitCode;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    process.stderr.write(`codex-hud 错误：${message}\n`);
    process.exitCode = 1;
  }
}

void main();
