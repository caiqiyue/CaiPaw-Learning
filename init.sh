#!/usr/bin/env bash
# ============================================================
# CaiPaw-Learning — 标准启动路径 / 唯一验证入口
# ============================================================
# 跨平台：Linux / macOS / Windows(git-bash) 都能跑。
#   ⚠️ Windows 没有原生 bash —— 用 Git for Windows 自带的 **Git Bash**。
#      在 PowerShell / cmd 里装好 Git 后执行： bash init.sh
#   ⚠️ macOS 自带的是 bash 3.2，本脚本刻意不用 bash 4+ 的语法。
#
# 设计：**检测式**。项目会分阶段长出三个子项目，所以本脚本
#       「有什么查什么」；空仓库时也不报错，只提示跳过。
#
# 阶段 → 目录对应：
#   阶段 A/B  agent-service/      子系统 ①（Python + FastAPI + LangGraph）
#   阶段 C    business-service/   子系统 ②（Java + SpringBoot + MyBatis）
#   阶段 D    web/                前端（Vue 3 + Vite + TS）
#   阶段 E    deploy/             docker-compose（本脚本不管，由 e2e 覆盖）
#
# 纪律：**任何一步失败立即退出**。baseline 坏了就先修，不开新 feature。
# ============================================================

set -e

# 切到仓库根（= 本脚本所在目录），这样从任何路径调用都对。
cd "$(dirname "$0")"

echo "=== CaiPaw-Learning Harness Initialization ==="
echo "repo: $(pwd)"

# ---------- 工具探测 ----------
# macOS / Linux 通常只有 python3；Windows git-bash 常常只有 python。两个都试。
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  PY=""
fi

# need <命令> <给人看的提示>
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ 找不到命令: $1"
    echo "   $2"
    exit 1
  }
}

RAN=0

# ---------- 子系统 ① agent-service（Python）----------
if [ -d "agent-service" ]; then
  RAN=1
  cd agent-service

  if [ -z "$PY" ]; then
    echo "❌ 找不到 python / python3，请先激活 conda 环境：conda activate caipaw-agent"
    exit 1
  fi
  echo "python: $($PY --version 2>&1)"

  echo "--- [①/静态] ruff + mypy ---"
  need ruff "pip install ruff（或 conda install -c conda-forge ruff）"
  need mypy "pip install mypy"
  ruff check . || { echo "❌ ruff failed"; exit 1; }
  mypy .       || { echo "❌ mypy failed"; exit 1; }

  echo "--- [①/单元] pytest ---"
  "$PY" -m pytest -q || { echo "❌ pytest failed"; exit 1; }

  cd ..
fi

# ---------- 子系统 ② business-service（Java）----------
if [ -d "business-service" ]; then
  RAN=1
  cd business-service

  if [ ! -f "./mvnw" ]; then
    echo "❌ 找不到 ./mvnw（Maven Wrapper）。本阶段一律用 Wrapper，不依赖全局 mvn。"
    exit 1
  fi
  # 容错：仓库里 mvnw 的「可执行位」可能没被 Git 记录下来（Windows 上常见）。
  if [ -x "./mvnw" ]; then MVN="./mvnw"; else MVN="sh ./mvnw"; fi

  echo "java: $(java -version 2>&1 | head -1)"
  echo "--- [②/构建] mvnw test ---"
  $MVN -B -ntp test || { echo "❌ mvn test failed"; exit 1; }

  cd ..
fi

# ---------- 前端 web（Vue 3）----------
if [ -d "web" ]; then
  RAN=1
  cd web

  need pnpm "corepack enable  （或 npm i -g pnpm）"

  echo "--- [前端] lint + typecheck + test ---"
  pnpm lint           || { echo "❌ eslint failed"; exit 1; }
  pnpm typecheck      || { echo "❌ vue-tsc failed"; exit 1; }
  pnpm test --run     || { echo "❌ vitest failed"; exit 1; }

  cd ..
fi

if [ "$RAN" -eq 0 ]; then
  echo "⚠️  还没有任何子系统目录，跳过验证。"
  echo "   阶段 A 从 agent-service/ 开始（见 docs/任务清单-粗粒度.md 的 M01）。"
fi

echo "=== ✅ Baseline verification passed ==="
echo "Next steps: 1) 读 feature_list.json  2) 只挑一个 in_progress  3) 跑通再动下一个"
