# Clean State Checklist

> 收班前逐条勾。**全勾才收班。** 任何一条不勾 = 这个 session 没结束干净。

## 官方 6 项（逐字复制 `docs/harness机制.md` §2.3 第 7 步）

- [ ] The standard startup path still works.
- [ ] The standard verification path still runs.
- [ ] Current progress is recorded in the progress log.
- [ ] Feature state reflects what is actually passing versus unverified.
- [ ] No half-finished step is left undocumented.
- [ ] The next session can continue without manual repair.

## 本项目对照（把上面 6 条落到具体命令）

- [ ] **标准启动路径** = `./init.sh` 跑通（空仓库时打印跳过提示也 OK）
- [ ] **标准验证路径** = `./init.sh` 内该子系统的 lint + typecheck + test 全绿
- [ ] **进度已记录** = `claude-progress.md` 的 `## Session Log` 追加了本 session
- [ ] **状态不浮夸** = `feature_list.json` 里 `passing` 的行 `evidence` **非空**；
      没真跑过的**不许**标 `passing`，标 `partial` 或 `in_progress` 并写清差在哪
- [ ] **没有半成品没文档化** = 改了一半的东西，已在 `claude-progress.md` 写明「改到哪、下一步接什么」
- [ ] **下个 session 能直接继续** = 新开一个会话，只读 `docs/核心宗旨.md` +
      `feature_list.json` + `claude-progress.md` 就能在 **3 分钟**内接上班

## ★ 本项目追加 2 项（学习项目特有，不可省）

- [ ] **L3 笔记已写** = `learning-notes/step-NNN-*.md` 已产出，含：
      新概念 / 关键代码位置 / **认知落差** / 自测结果
- [ ] **L4 自测已做** = 用户**自己动手改了一处**（参数 / 分支 / 输入），
      **先预测了结果**，实际结果记进了笔记

> 依据：`AGENTS.md` §5 Definition of Done 第 4 条。
> **没有笔记 = 这一步没完成**，哪怕代码跑通了。

## 反模式自查（勾完上面顺手扫一眼）

- [ ] 没有「顺手多改了」的东西混进这个 commit（L2 越界）
- [ ] 没有抄 `qwenpaw-project/` 里的代码（E5）
- [ ] 没有把后面任务的细粒度步骤**提前**拆出来（拆解纪律）
- [ ] commit message 引用了 feature ID（E1）
