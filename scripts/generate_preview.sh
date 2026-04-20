#!/usr/bin/env bash
set -euo pipefail

# 功能：生成 README 用的演示截图。
# 函数简介：构建应用并输出离线 PNG 预览图。

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p docs/images/generated
swift run codex-hud --render-demo-screenshot docs/images/generated/codex-hud-preview.png
echo "已生成预览图：$ROOT_DIR/docs/images/generated/codex-hud-preview.png"
