# Bounce Lite

Bounce Lite 是一个面向轻量休闲桌面用户的放松型数字玩具。Phase 0 已完成，用户已批准进入 V0.1 项目初始化；当前已有可被 Godot 4.7 加载的最小工程，但没有主场景、游戏逻辑或正式素材。

## 名称

- Project Name：`Bounce Lite`
- UI Title：`Bouncing Ball`

项目名用于仓库、目录和开发文档；界面标题用于概念图中的窗口标题。二者不得混用。

## 当前状态

- 当前阶段：`V0.1 - Project Initialization`（初始化基线已建立）
- Phase 0 规格日期：`2026-09-08`
- V0.1 状态：`项目初始化已获授权；玩法实现尚未授权`
- Godot 工程状态：`已初始化；无 main scene`
- Git 状态：`本地仓库，main 分支，不设置远端`

当前初始化只落地技术基线与目录骨架。Ball、Paddle、碰撞、Timer、状态流和视觉制作仍需后续任务明确授权。

## 技术基线

| 项目 | 当前基线 |
| --- | --- |
| Engine | Godot `4.7.stable.official.5b4e0cb0f`，仅完成只读核验 |
| Renderer | `Compatibility`（已写入工程） |
| Target Platform | `Windows` |
| Concept Reference Resolution | `1448 × 1086`（4:3） |
| Game Design Resolution | `960 × 720`（4:3） |
| Scaling | 等比缩放；非 4:3 窗口使用 letterbox / pillarbox |
| Scripting | GDScript 候选；当前无脚本 |

## 文档导航

- [`AGENTS.md`](AGENTS.md)：Agent 工作边界与治理规则
- [`phase-0-plan.md`](phase-0-plan.md)：Phase 0 执行基线与验收标准
- [`docs/project_overview.md`](docs/project_overview.md)：产品定位、阶段路线与角色
- [`docs/visual_spec.md`](docs/visual_spec.md)：布局、主题、色彩、UI、动效与可访问性规格
- [`docs/asset_registry.md`](docs/asset_registry.md)：完整资产树与逐项登记
- [`docs/development_notes.md`](docs/development_notes.md)：环境证据、决策、风险和待确认事项

## 概念图

| Theme | 原始文件 | 归档副本 |
| --- | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` |

归档副本与原文件的字节数和 SHA-256 已核对一致。概念图是视觉基准，不是已批准的运行时素材。

## 当前初始化边界

当前已完成：创建最小 `project.godot`、基础空目录、Git 忽略规则与本地版本库；同步已确认规格。

当前未授权：创建场景或脚本、实现 Ball/Paddle/碰撞/游戏循环/计时/计分、实现音效或动画、制作 Demo、生产正式素材、设置 Git 远端。

## 运行与构建

用 Godot 4.7 打开根目录即可检查工程设置。当前没有 main scene，因此没有游戏运行、导出或构建步骤。

初始化目录：

```text
assets/{concept,sprites,ui,effects,audio}/
scenes/
scripts/
docs/
```

## 下一步

下一步应先确认 V0.1 玩法实现任务的范围与验收标准，再创建场景或脚本。项目初始化完成不等于玩法制作已经开始。
