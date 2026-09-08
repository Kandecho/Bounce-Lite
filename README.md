# Bounce Lite

Bounce Lite 是一个面向轻量休闲桌面用户的放松型数字玩具。当前已完成 V0.1.2 Vitality–Physics Separation 核心重构与机器验证，正在等待人工试玩；正式素材、正式音频和精修视觉仍未制作。

## 名称

- Project Name：`Bounce Lite`
- UI Title：`Bouncing Ball`

项目名用于仓库、目录和开发文档；界面标题用于概念图中的窗口标题。二者不得混用。

## 当前状态

- 当前阶段：`V0.1.2 - Vitality–Physics Separation`
- Phase 0 规格日期：`2026-09-08`
- V0.1.2 状态：`Physics/Vitality、Surface Response 与视觉数据边界已实现并通过机器验证；等待人工试玩`
- Godot 工程状态：`main scene 可运行`
- Git 状态：`本地仓库，main 分支，不设置远端`

当前原型包含 CharacterBody2D Ball、独立 BallVitalityModel、纯计算 SurfaceResponseModel、鼠标 Paddle、Endless Rules、Combo、活跃计时、Rest/Wake 和程序化 Core/Glow/Trail。不存在 Game Over，也没有主题切换、正式资产或竞技系统。

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
- [`docs/superpowers/specs/2026-09-08-v0.1.2-vitality-physics-separation-design.md`](docs/superpowers/specs/2026-09-08-v0.1.2-vitality-physics-separation-design.md)：当前 Physics/Vitality、Surface Response、事件与视觉边界
- [`docs/superpowers/plans/2026-09-08-v0.1.2-vitality-physics-separation.md`](docs/superpowers/plans/2026-09-08-v0.1.2-vitality-physics-separation.md)：当前逐项 TDD 重构与验收计划
- [`docs/superpowers/specs/2026-09-08-v0.1-core-gameplay-design.md`](docs/superpowers/specs/2026-09-08-v0.1-core-gameplay-design.md)：V0.1/V0.1.1 历史 Energy-driven 设计基线
- [`docs/superpowers/plans/2026-09-08-v0.1-core-gameplay.md`](docs/superpowers/plans/2026-09-08-v0.1-core-gameplay.md)：V0.1/V0.1.1 历史实施计划

## 概念图

| Theme | 原始文件 | 归档副本 |
| --- | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` |

归档副本与原文件的字节数和 SHA-256 已核对一致。概念图是视觉基准，不是已批准的运行时素材。

## 当前 V0.1.2 实现

已实现：

- 独立 Velocity、固定重力与封闭矩形中的确定性运动；
- 统一 Surface Response；Wall/Top 轻微耗散，Ground 强耗散；
- Vitality 只因碰撞变化，不直接重建 Velocity；
- Paddle 采用普通响应、固定 impulse、最大速度限制与 Vitality 恢复；
- Ground 清零 Combo 但继续游戏；
- ACTIVE / DECAYING / RESTING 与 Paddle Wake；
- 只表达 Vitality 亮度/范围的 Glow 与只表达 Velocity 长度/宽度的 Trail；
- Paddle / Wall / Ground squash/stretch、Ground 短暂变暗与 Wake 亮起；
- 宽度接近球直径、只由实际速度控制的连续双层光迹；
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

人工试玩可直接双击根目录 `run-playtest.bat`。游戏关闭后控制台会保留退出码和错误日志。辅助模式：

```powershell
.\run-playtest.bat --editor
.\run-playtest.bat --test
.\run-playtest.bat --check
```

当前重构测试基线：`TEST PASS: 173 checks`；fresh headless editor import 与主场景 600 帧运行均退出 `0`。碰撞前 Vitality、Paddle impulse、Velocity 独立性和 Velocity-only Trail 四项变异均被测试捕获并已恢复。

主要目录：

```text
assets/{concept,sprites,ui,effects,audio}/
scenes/
scripts/
docs/
```

## 下一步

停止在 V0.1.2 人工试玩门。试玩重点是 Ground 小跳/滚动后的自然休眠、Paddle 重新注入运动、Trail/Glow 信息分工、Wake 可靠性，以及是否存在空中冻结、接球减速或速度失控；未获得反馈前不进入后续功能或主题制作。
