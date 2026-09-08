# Bounce Lite

Bounce Lite 是一个面向轻量休闲桌面用户的放松型数字玩具。当前已完成 V0.1.1 重力衰弱调整的代码与机器验证，正在等待人工试玩；正式素材、正式音频和精修视觉仍未制作。

## 名称

- Project Name：`Bounce Lite`
- UI Title：`Bouncing Ball`

项目名用于仓库、目录和开发文档；界面标题用于概念图中的窗口标题。二者不得混用。

## 当前状态

- 当前阶段：`V0.1.1 - Gravity Decay Tuning`
- Phase 0 规格日期：`2026-09-08`
- V0.1.1 状态：`固定重力、Ground 损耗和视觉反馈已实现；等待人工试玩`
- Godot 工程状态：`main scene 可运行`
- Git 状态：`本地仓库，main 分支，不设置远端`

当前原型包含 CharacterBody2D Ball、独立能量模型、鼠标 Paddle、Endless Rules、Combo、活跃计时、Rest/Wake 和程序化 Core/Glow/Trail。不存在 Game Over，也没有主题切换、正式资产或竞技系统。

## 技术基线

| 项目 | 当前基线 |
| --- | --- |
| Engine | Godot `4.7.stable.official.5b4e0cb0f`，仅完成只读核验 |
| Renderer | `Compatibility`（已写入工程） |
| Target Platform | `Windows` |
| Concept Reference Resolution | `1448 × 1086`（4:3） |
| Game Design Resolution | `960 × 720`（4:3） |
| Scaling | 等比缩放；非 4:3 窗口使用 letterbox / pillarbox |
| Scripting | GDScript |

## 文档导航

- [`AGENTS.md`](AGENTS.md)：Agent 工作边界与治理规则
- [`phase-0-plan.md`](phase-0-plan.md)：Phase 0 执行基线与验收标准
- [`docs/project_overview.md`](docs/project_overview.md)：产品定位、阶段路线与角色
- [`docs/visual_spec.md`](docs/visual_spec.md)：布局、主题、色彩、UI、动效与可访问性规格
- [`docs/asset_registry.md`](docs/asset_registry.md)：完整资产树与逐项登记
- [`docs/development_notes.md`](docs/development_notes.md)：环境证据、决策、风险和待确认事项
- [`docs/superpowers/specs/2026-09-08-v0.1-core-gameplay-design.md`](docs/superpowers/specs/2026-09-08-v0.1-core-gameplay-design.md)：Endless 能量循环、组件职责、接口与测试设计
- [`docs/superpowers/plans/2026-09-08-v0.1-core-gameplay.md`](docs/superpowers/plans/2026-09-08-v0.1-core-gameplay.md)：逐项 TDD 实施计划与机器验收命令

## 概念图

| Theme | 原始文件 | 归档副本 |
| --- | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` |

归档副本与原文件的字节数和 SHA-256 已核对一致。概念图是视觉基准，不是已批准的运行时素材。

## 当前 V0.1 实现

已实现：

- 固定重力、封闭矩形中的确定性碰撞响应；
- Wall/Top 轻微耗能、Ground 明显耗能；
- Paddle 命中恢复到正常活跃能量，不叠加加速；
- Ground 清零 Combo 但继续游戏；
- ACTIVE / DECAYING / RESTING 与 Paddle Wake；
- 随活跃程度变化的程序化 Glow / Trail；
- Paddle / Wall / Ground squash/stretch、Ground 短暂变暗与 Wake 亮起；
- 宽度接近球直径、由 Energy 与实际速度共同控制的连续双层光迹；
- 纯文字 `COMBO N` 与 `TIME MM:SS`。

未实现且仍不属于当前范围：Game Over、Classic/Recover、排行榜、主题切换、Paddle 分区、障碍物、正式素材、正式音频和复杂视觉精修。

## 运行与构建

用 Godot 4.7 打开根目录并运行项目。窗口设计分辨率为 `960×720`。

控制：移动鼠标水平控制 Paddle；Ball 进入 RESTING 后，快速且持续地移动 Paddle 约 80 ms 可将其唤醒。

命令行运行：

```powershell
& 'D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe' --path 'D:\hangk\Documents\Bounce Lite'
```

运行确定性测试：

```powershell
& 'D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe' --headless --path 'D:\hangk\Documents\Bounce Lite' --script res://tests/test_runner.gd
```

当前机器基线：`TEST PASS: 112 checks`；主场景已无头运行 600 帧且没有脚本或运行期错误。

主要目录：

```text
assets/{concept,sprites,ui,effects,audio}/
scenes/
scripts/
docs/
```

## 下一步

停止在 V0.1.1 人工试玩门。试玩后重点判断自然衰弱与休眠、接球恢复活力、Ground 损耗感、速度变化，以及是否愿意主动接球维持运动；未获得反馈前不进入后续功能或主题制作。
