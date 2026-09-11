# CaiPaw-Learning

> 把 [QwenPaw](https://github.com/agentscope-ai/QwenPaw) **完整重构一遍** —— 换掉整个技术框架，拆成两个子系统。
>
> ⚠️ **这不是交付项目，是学习项目。**
> 目标不是「做出一个 Agent」，是**在做出它的每一步里，看懂每一行**。
> 所以进度慢、步子小、每步都有笔记，都是**故意**的。

---

## 1. 重构什么

|  | QwenPaw（上游参照） | 本项目（重构后） |
|---|---|---|
| **Agent 内核** | AgentScope 2.0 | **LangChain / LangGraph** |
| **服务层** | Python 单体 | **子系统 ①** Python + FastAPI |
| **业务后端** | Python | **子系统 ②** JDK 17 + SpringBoot + MyBatis + MySQL + Redis |
| **前端** | React + Tauri | **Vue 3 + Vite** |
| **模型来源** | 多供应商 | 开发期外部 API → 后期**自建 OpenAI 兼容推理服务** |
| **最终形态** | 单体 | **两个 Docker 子系统 + vLLM** |

**终点是完整重构，路径是「最小闭环 → 逐步复杂」。**
当前进度见 **[`docs/任务清单-粗粒度.md`](docs/任务清单-粗粒度.md)**（24 个功能模块 `M01`~`M24`）。

> QwenPaw 源码**只作本地只读参照，不入库**（`.gitignore` §6.3）。
> 需要它时自行 clone 到 `qwenpaw-project/`。所有重构代码都是自己写的，不抄。

---

## 2. ⚙️ 需要的资源

### 2.1 软件依赖

> 📌 **「何时需要」那一列很重要 —— 表里大部分现在都用不着。**
> 阶段 A 只需要 **Python 3.11 + 一个模型 API key**。**别提前装。**

| 软件 | 版本 | 用途 | 何时需要 |
|---|---|---|---|
| **Python** | **3.11** | 子系统 ① | **现在**（阶段 A） |
| [conda](https://docs.conda.io/) | 任意 | 管理 `caipaw-agent` 环境 | **现在** |
| 一个模型 API key | — | 开发期调模型 | **现在** |
| **JDK** | **17** | 子系统 ② | 阶段 C |
| **MySQL** | **8.x** | 子系统 ② 业务库 | 阶段 C |
| **Redis** | **7.x** | 子系统 ② 会话 / 限流 | 阶段 C |
| **Node.js** | **20 LTS+** | 前端 `web/` | 阶段 D |
| **pnpm** | 9+ | 前端包管理 | 阶段 D |
| **Docker** + compose | 24+ | 起两个子系统 | 阶段 E（部署） |

**Maven 不用单独装** —— 子系统 ② 用仓库内的 Maven Wrapper（`./mvnw`）。

### 2.2 服务器侧（后期才用到）

> ⚠️ **本节刻意只写规则，不写具体值。**
> 主机别名 / IP / 绝对路径 / GPU 型号 / 推理服务端口这些**一律不写进入库文件** ——
> 真值在 `docs/服务器运维手册.md`，**那份不入库**（`.gitignore` 已挡）。

| 资源 | 说明 |
|---|---|
| Linux 服务器 | 用于最终部署 + 跑推理；**接入方式见 `docs/服务器运维手册.md`** |
| GPU | 服务器侧推理用；**型号与分配见运维手册** |
| 推理服务 | 自建 OpenAI 兼容端点，绑 `127.0.0.1`，**不对外暴露**（E10） |
| 服务器约定 | **只 `git pull`，不在服务器上改源码**（E8） |

> 服务器链路细节在 `docs/服务器运维手册.md`（**该文件不入库，仅本地可读**）。

### 2.3 硬件

开发机只要有 CPU 就够 —— 模型跑在服务器上，开发期直接调外部 API。

---

## 3. 🚀 快速开始

```bash
# 1. 克隆
git clone https://github.com/caiqiyue/CaiPaw-Learning.git
cd CaiPaw-Learning

# 2. ★ 启用提交前防线（每个克隆都要做一次，这是本地配置，不随仓库走）
git config core.hooksPath .githooks

# 3. （可选）克隆上游参照物 —— 不入库，但要读
git clone https://github.com/agentscope-ai/QwenPaw.git qwenpaw-project

# 4. 建 Python 环境（子系统 ①）
conda create -n caipaw-agent python=3.11 -y
conda activate caipaw-agent

# 5. 配环境变量 —— ★ 别跳过，M01 就要用
cp .env.example .env
#    然后编辑 .env，填入你自己的 API key
#    ⚠️ .env **不入库**；仓库里只有 .env.example（占位符）

# 6. 跑标准验证入口
bash init.sh
```

> ⚠️ **第 2 步别跳过。** 它启用 `.githooks/pre-commit`，**在你 commit 时自动拦截
> 服务器标识信息和密钥**（硬约束 E2 / E11）。
> 不做这一步，那些东西会直接进 Git —— **而一旦进了 Git，就永久留在历史里**。

`init.sh` 是**唯一验证入口**，**检测式**：有什么子系统就查什么，现在还没有任何子系统，
它会打印「跳过验证」并以退出码 0 结束 —— **这是正常的，不是失败**。

---

## 4. 📁 目录结构

```text
CaiPaw-Learning/
├── README.md                      ← 本文件
├── AGENTS.md / CLAUDE.md          ← 给 AI 的操作手册（硬约束在这里）
├── init.sh                        ← 标准启动路径 / 唯一验证入口
├── requirements.txt               ← 子系统 ① 运行时依赖
├── requirements-dev.txt           ← 子系统 ① 开发工具（ruff / mypy / pytest）
├── feature_list.json              ← 工作队列（WIP=1）
├── claude-progress.md             ← 当前进度快照 + Session 日志
├── session-handoff.md             ← 跨 session 交接
├── clean-state-checklist.md       ← 收班前检查
├── .claude/                       ← Hook 防线：拦截「一步写太大」
│
├── docs/                          ← ★★ 整个目录【不入库】，全部私有
│   ├── 核心宗旨.md                 ← 最高纲领
│   ├── 服务器运维手册.md            ← 服务器链路
│   ├── harness机制.md              ← 通用 harness SOP
│   ├── harness机制_CaiPaw-Learning.md ← 本项目 harness 规格
│   ├── 任务清单-粗粒度.md           ← ★ 外层进度：M01~M24
│   ├── 进度/                       ← ★ 内层进度（开工某个模块时才写）
│   └── 计划/                       ← AI 技能生成的 plan / 实施计划
│
├── learning-notes/                ← ★ 真正的产物：每一步的学习笔记
├── assets/                        ← 学习笔记引用的图片
│
├── agent-service/                 ← 子系统 ①（Python + FastAPI + LangGraph）
├── business-service/              ← 子系统 ②（SpringBoot + MyBatis）
├── web/                           ← 前端（Vue 3）
├── deploy/                        ← docker-compose
└── qwenpaw-project/               ← 上游参照答案，只读【不入库】
```

> ⚠️ 最后 5 个目录**现在还不存在**，这是**故意的** ——
> 「一次只建当前阶段需要的那一个目录，绝不提前把空目录全建出来」。

---

## 5. 📖 该读哪个文档

| 你想知道 | 读这个 |
|---|---|
| 这个项目到底要干嘛、为什么这么干 | `docs/核心宗旨.md` |
| **下一步做什么** | `docs/任务清单-粗粒度.md` + `feature_list.json` |
| 规则和纪律（**L1~L7** 学习纪律） | `AGENTS.md` |
| harness 怎么搭的、怎么运转 | `docs/harness机制_CaiPaw-Learning.md` |
| 每一步学到了什么 | `learning-notes/` |
| 服务器怎么连、怎么部署 | `docs/服务器运维手册.md` |

---

## 6. 💻 跨平台说明

本项目在 **Windows / macOS / Linux** 三端流转，权威运行环境是 **Linux（服务器）**。

**换行符**：`.gitattributes` 已锁死 —— 文本一律 **LF**，只有 `.bat`/`.cmd`/`.ps1` 是 CRLF。
`mvnw` / `gradlew` **没有扩展名**，Git 认不出来，所以单独声明了（漏了这条，Windows 上
checkout 成 CRLF 后拿到 Linux 会直接报 `bad interpreter: ...^M`）。

**Windows** 没有原生 bash，`init.sh` 和 `.claude/hooks/` 都需要 **Git Bash**
（装 Git for Windows 时自带）。在 PowerShell 里这样跑：

```powershell
bash init.sh
```

**macOS** 自带的是 bash 3.2，`init.sh` 刻意避开了 bash 4+ 语法。

**中文文件名**（`核心宗旨.md` / `任务清单-粗粒度.md` 等）在 Linux 上可能被 Git 转义显示，
建议设一次：

```bash
git config --global core.quotepath false   # 中文文件名正常显示
git config --global core.autocrlf input    # 配合 .gitattributes，别让 Git 再改换行
```

---

## 7. 🚫 这个项目不做什么

- **不做** 多租户、性能调优、高可用、完整 CI/CD
- **不做** 生产级加固

**其余 QwenPaw 的功能全部在册**，只是很多排在很后期（`M21`~`M24` 等）。
「很后期」≠「不做」—— 唯一的例外是上面那两条。

---

## 8. 许可

学习项目。QwenPaw 上游为 Apache 2.0，本仓库不包含其代码。
