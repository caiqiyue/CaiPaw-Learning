# assets/ —— 图片仓库

> **本目录只放图片**，服务于 `learning-notes/` 里的学习笔记。
>
> 📌 本目录**入库**（见 `.gitignore` §6.4）。不入库的话，笔记里引用的图会全部显示不出来。

---

## 放什么

| ✅ 放 | ❌ 不放 |
|---|---|
| 截图（终端输出、网页界面、报错现场） | 模型权重、数据集（`.gitignore` §4 已挡） |
| 架构图 / 流程图 / 时序图 | 源码文件、配置文件 |
| 一次 agent run 的 trace 截图 | 几 MB 的无压缩大图 |
| 手绘草图（拍照也行） | 别人的版权图（别传非自己产出的东西） |

## 命名规范

跟着引用它的笔记走：

```text
assets/step-NNN-<简短英文描述>.<ext>
```

例：

```text
assets/step-001-response-shape.png
assets/step-003-tool-call-flow.png
assets/m03-langgraph-condition-edge.png   ← 跨多篇笔记共用的图，用模块号
```

- 小写英文 + 短横线，不用中文文件名（跨平台 / Git 都可能出问题）
- 同一张图被多篇笔记引用 → 用 `M0N-` 前缀，别在每篇笔记下都存一份

## 怎么引用

在 `learning-notes/*.md` 里用**相对路径**：

```markdown
![第一次 LLM 调用的响应结构](../assets/step-001-response-shape.png)
```

⚠️ 路径是 `../assets/`，因为笔记在 `learning-notes/` 下、图在 `assets/` 下，两者平级。

## 体积纪律

- 单张图**控制在 500 KB 以内**，超了就压缩或截图时缩小窗口
- 动图优先转成 GIF 或几张静图，别传视频（`.gitattributes` 已把视频标为二进制，但仓库会变大）
- 提交前扫一眼体积：

```bash
du -sh assets/                      # 总量
find assets -size +500k -type f     # 找出超标的单张
```
