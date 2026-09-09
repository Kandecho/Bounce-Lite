# Bounce Lite Development Notes

## 1. 记录范围

本文件记录 Phase 0、V0.1 项目初始化与 Endless 核心原型实现的环境证据、决策、偏差、风险和待确认事项。未来候选方案不视为已经授权。

记录日期：`2026-09-08`；最近实现同步：`2026-09-09`。历史章节保留当时状态，当前结论见 §17。

时区：`Asia/Shanghai`

## 2. 工作区基线

| 项目 | 事实 |
| --- | --- |
| 项目路径 | `D:\hangk\Documents\Bounce Lite` |
| 初始文件 | `AGENTS.md`、`phase-0-plan.md`、`day-raw.png`、`night-raw.png` |
| Git | 本地仓库；`main` 分支；不设置远端 |
| Git 操作 | 用户已批准 `git init`；不创建 worktree、不推送 |
| 项目状态 | V0.1.3 Bug Fixes & Frozen Visual Presentation 已实现并机器验证；等待人工试玩 |

## 3. Engine 与辅助环境证据

### Godot

候选目录存在：

```text
D:\Apps\Godot_v4.7-stable_win64
```

发现的可执行文件：

```text
D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64.exe
D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe
```

只读版本查询结果：

```text
4.7.stable.official.5b4e0cb0f
```

两个可执行文件均以退出码 `0` 完成版本查询。该句记录 Phase 0 初始核验；随后已按用户授权创建工程并完成 headless editor 与主场景验证。

### 系统

| 项目 | 检测值 |
| --- | --- |
| OS | Microsoft Windows 10.0.26200 |
| OS Architecture | X64 |
| Process Architecture | X64 |
| PowerShell | 7.6.5 |
| Native Argument Passing | Windows |
| Python | 3.14.5 |
| Python Launcher | `C:\Users\hangk\AppData\Local\Programs\Python\Launcher\py.exe` |
| Node | v24.15.0 |
| Node Executable | `C:\Program Files\nodejs\node.exe` |

Python 的当前环境未安装 Pillow；Phase 0 没有安装依赖，而是使用系统图像 API 完成只读采样。

## 4. 概念图归档证据

| Theme | 原文件 | 归档副本 | Bytes | SHA-256 | 结果 |
| --- | --- | --- | ---: | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` | 1,174,596 | `52E4759BA7D8A47AD74E76567263340319522EBE0C1B83EA6C0F0B66762821B3` | 一致 |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` | 995,996 | `A68E6CF40E567B83FD73BDBDF0C23C31AEC85EDC40091D6045B4FB6D1C01D406` | 一致 |

原文件未移动、覆盖、裁切、压缩、调色或转码。

## 5. 已确认决策

| 日期 | 决策 | 依据 / 确认人 | 影响 |
| --- | --- | --- | --- |
| 2026-09-08 | Project Name 为 `Bounce Lite` | 用户直接要求 | 用于目录、工程和文档 |
| 2026-09-08 | UI Title 为 `Bouncing Ball` | 用户直接要求 | 用于窗口标题，两种名称不得混用 |
| 2026-09-08 | Traffic Light 为装饰 | 用户直接要求 | 无点击、焦点或窗口控制语义 |
| 2026-09-08 | Concept Reference 为 1448×1086 | 源图测量与用户要求 | 只用于分析和换算 |
| 2026-09-08 | Game Design Resolution 为 960×720 | 用户确认的计划 | 4:3、等比缩放 |
| 2026-09-08 | Renderer 默认 Compatibility | 用户确认的计划 | V0.1 初始化时复述并写入 |
| 2026-09-08 | Target Platform 默认 Windows | 用户确认的计划 | 其他平台属于范围变化 |
| 2026-09-08 | Phase 0 不创建 Godot 工程 | 用户确认的边界 | 停止在规格和文档阶段 |
| 2026-09-08 | Start/Pause/Game Over 使用极简文字 UI | 用户直接确认 | 无按钮边框、卡片或复杂面板；层级由排版与透明度表达 |
| 2026-09-08 | 字体优先 Inter / Noto Sans | 用户直接确认 | 使用开源方案；正式发布前复核实际字体文件授权 |
| 2026-09-08 | 目标用户为轻量休闲桌面小游戏用户 | 用户直接确认 | 产品定位不以竞技或长局压力驱动 |
| 2026-09-08 | 核心体验为可随时开始/结束的放松数字玩具 | 用户直接确认 | 不设置固定单局时长目标 |
| 2026-09-08 | 鼠标水平控制 Paddle；键盘非 V0.1 必需输入 | 用户直接确认 | 输入设计以桌面鼠标为基线 |
| 2026-09-08 | 难度不单调递增，也不制造必然失败阶段 | 用户直接确认 | 允许低强度随机速度、轨迹、事件或不确定性变化 |
| 2026-09-08 | V0.1 不包含排行榜、最高分压力或连续生存挑战 | 用户直接确认 | 竞技目标排除在当前版本范围外 |
| 2026-09-08 | V0.1 不实现主题切换，只保留 Light/Dark 规格 | 用户直接确认 | 不建立主题切换状态或设置入口 |
| 2026-09-08 | Light 次级文字按可读性调整 | 用户直接确认 | Version/Footer Token 加深为 `#5E7190` |
| 2026-09-08 | Glow / Trail 路线在开发阶段确定 | 用户直接确认 | 初始化阶段不选择 Shader、Sprite 或 Particle 路线 |
| 2026-09-08 | 进入 V0.1 项目初始化；建立本地 Git 且无远端 | 用户直接确认 | 允许创建最小工程和目录骨架，不授权玩法实现 |
| 2026-09-08 | V0.1 只实现 Endless 原型且不存在 Game Over | 用户直接确认 | Ground 清零 Combo、明显耗能并继续反弹 |
| 2026-09-08 | 采用 CharacterBody2D + 独立 BallEnergyModel | 用户直接确认 | 运动碰撞与能量规则解耦；不采用 RigidBody2D 或完全手写碰撞 |
| 2026-09-08 | Energy 是维持模型，不是积累模型 | 用户直接确认 | 环境只耗能；Paddle 把 `current_energy` 恢复到 `max_energy`，不无限叠加 |
| 2026-09-08 | 状态从 Energy 导出 | 用户直接确认 | ACTIVE / DECAYING / RESTING 不直接控制任意速度 |
| 2026-09-08 | RESTING 时由有效 Paddle 运动 Wake | 用户直接确认；已被 V0.1.3 取代 | 历史实现使用速度阈值持续约 80 ms |
| 2026-09-08 | V0.1 初始原型采用无重力、封闭矩形、确定性反弹 | 用户直接确认；已被 V0.1.1 部分取代 | 初始机器验证基线；V0.1.1 改为固定重力 |
| 2026-09-08 | TDD 只覆盖确定性规则 | 用户直接确认 | 美感、布局和声音体验留给人工试玩 |
| 2026-09-08 | V0.1.1 加入固定重力 `520 px/s²` | 用户确认短设计 | 重力独立于 Energy；Ball 自然倾向落地 |
| 2026-09-08 | V0.1.1 Ground Energy Retention 调整为 `0.65` | 用户确认短设计 | 反弹高度随落地次数明显衰减 |
| 2026-09-08 | V0.1.1 增加差异化碰撞与 Wake 视觉反馈 | 用户直接确认 | 只动画 Ball；不增加正式动画系统、Shader 或粒子 |
| 2026-09-08 | V0.1.2 废弃 Energy-driven Motion | 用户直接确认 | Velocity 属于 Physics；Vitality 属于 Ball State，二者不互相替代 |
| 2026-09-08 | BallVitalityModel 不持有 Surface 规则 | 用户直接确认 | 只应用 delta、clamp Vitality 并结算 ActivityState |
| 2026-09-08 | 所有碰撞统一由 SurfaceResponseModel 纯计算 | 用户直接确认 | 使用碰撞前 Velocity/Vitality；先应用 Velocity，再应用 Vitality delta |
| 2026-09-08 | Resting 使用低 Vitality + Ground 低速联合门槛 | 用户确认设计文档 | 避免 Wall 损耗导致空中冻结，保留小跳/滚动阶段 |
| 2026-09-08 | Trail 只表达 Velocity，Glow 只表达 Vitality | 用户直接确认 | 两类视觉信息不再共享单一 activity 乘积 |
| 2026-09-08 | V0.1.3 使用 Resting Wake Impulse | 用户直接确认 | 不新增状态；DECAYING 仍可由正常 Paddle Collision 救回 |
| 2026-09-08 | RESTING 使用短暂休息窗口 | 用户直接确认 | 默认 `0.12 s` 内拒绝 Wake，避免刚停稳即被旧输入弹起 |
| 2026-09-08 | Wake 保持二元状态判断与连续冲量强度 | 用户直接确认 | 弱冲量保持 RESTING；强冲量恢复约 15% 最大 Vitality 并进入 DECAYING |
| 2026-09-08 | 三通道原则冻结为核心视觉原则 | 用户直接确认 | Ball Glow = Vitality，Trail = Velocity，Paddle Feedback = Interaction；三者不得合并 |
| 2026-09-08 | Paddle Feedback 不留长期视觉状态 | 用户直接确认 | 取消常驻 Glow 与常驻 edge line；可见性问题优先调基础色，不加图层 |
| 2026-09-08 | Ball 核心改为荧光青系 | 用户直接确认 | H 189 恒定，`S = lerp(0.42, 0.58, v)`，`V = lerp(0.42, 1.00, v)`；概念图白球被取代 |
| 2026-09-08 | Trail 改为离散残影，固定时间采样 | 用户直接确认 | 采样间隔 `0.085 s`；速度决定数量、间距与透明度；不加入 Vitality 权重 |
| 2026-09-08 | Paddle 基础色 `#45786E` | 用户直接确认 | 去饱和方向，与 Ball 青色区分；Paddle 是输入工具，不是第二个生命体 |
| 2026-09-08 | RESTING Glow 使用状态地板 `0.25` | 用户直接确认 | 必须是状态常量；休眠期 Vitality 衰减趋近于零，推导值守不住 |
| 2026-09-08 | 概念图对玩法对象的基准地位终止 | 由上述三项决定推出并经用户确认 | 概念图适用范围收窄为布局、窗口框架与排版 |

## 6. 视觉分析记录

### 已验证事实

- 两张图均为 1448×1086、4:3；
- Light 图明确显示四段淡蓝拖尾，属于 `Light + Moving` 证据；
- Dark 图没有可见拖尾，但单帧不能证明 Dark Theme 禁用拖尾；
- Light Paddle 的高饱和核心区域约为 `232×28 px`；
- Dark Paddle 的高饱和核心区域约为 `220×26 px`；
- Light 标题代表色 `#1E2E46` 对 `#F5F9FE` 约 `12.95:1`；
- Light 版本文字代表色 `#7689A5` 对 `#F5F9FE` 约 `3.37:1`；
- Light Timer 数字代表色 `#536A93` 对 `#F5FAFE` 约 `5.19:1`；
- Light Footer 代表色 `#667A9F` 对 `#FEFEFF` 约 `4.30:1`；
- Dark 标题 `#FFFFFF` 对 `#242B37` 约 `14.23:1`；
- Dark 版本文字 `#AAAFBB` 对 `#242B37` 约 `6.48:1`；
- Dark Timer `#FFFFFF` 对 `#252B35` 约 `14.23:1`；
- Dark Footer `#A4A9B2` 对 `#282D37` 约 `5.85:1`。

色值来自概念图指定像素或区域极值，只作为概念参考。透明、模糊和背景混合会改变最终显示，V0.1 必须在实际渲染中重新测量。

### 风格决策

本地 UI/UX 规则检索将 Claymorphism、Liquid Glass 和 Soft UI Evolution 列为近邻方向。概念图并没有 Claymorphism 常见的 3–4 px 厚边框和强烈双阴影，因此视觉规格采用：

> 克制的 Soft UI Evolution + 有限透明/玻璃感

Liquid Glass 只作为材质语言参考，不要求实现折射或复杂动态玻璃。该选择减少性能风险，并更贴近概念图的细边框、柔和阴影和留白。

## 7. 与推荐默认值的偏差

| 项目 | 推荐 | 当前事实 | 偏差 |
| --- | --- | --- | --- |
| Godot | 4.x / 指定安装目录 | 4.7 stable 已核验 | 无 |
| Renderer | Compatibility | 已写入 `project.godot` 并通过加载验证 | 无 |
| Platform | Windows | 当前系统为 Windows x64 | 无 |
| Design Resolution | 960×720 | 已写入规格 | 无 |
| Git | 建立本地版本基线 | 本地 `main` 仓库、无远端 | 无 |
| 图像分析 | 可使用 Pillow | 当前 Python 无 Pillow | 无阻塞；未安装依赖，使用系统 API |

## 8. 待确认事项

| ID | 事项 | 当前结论 | 确认人 | 对 V0.1 的影响 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Q001 | 主题切换触发方式 | V0.1 不实现主题切换；保留双主题设计规格 | 用户 | 无切换状态或设置入口 | 已确认 |
| Q002 | Start/Pause/Game Over 最终视觉 | 极简文字 UI，无按钮边框、卡片或复杂面板 | 用户 | 视觉方向已解除阻塞；交互映射另行规划 | 已确认 |
| Q003 | 字体家族与授权 | 优先 Inter / Noto Sans；发布前复核实际文件授权 | 用户 | 字体方向已解除阻塞；字体资产尚未引入 | 已确认 |
| Q004 | Light 次级文字对比度 | Version/Footer 使用 `#5E7190` | 用户 | 代表对比度达到 4.5:1 目标 | 已确认 |
| Q005 | Glow/Trail/Particles 实现路线 | V0.1 使用程序化多层圆形 Glow 与历史位置 Trail；不使用 Particles | 用户范围 + V0.1 技术评估 | 满足低成本原型验证；正式路线仍待后续评估 | 原型已确认 |
| Q006 | Git 初始化时间 | V0.1 项目初始化时建立本地仓库，不设置远端 | 用户 | 建立本地版本基线 | 已确认 |
| Q007 | 目标用户、单局节奏、输入方式 | 休闲桌面用户；无固定时长；鼠标水平控制 Paddle；键盘非必需 | 用户 | 已建立玩法规划约束 | 已确认 |
| Q008 | 概念图 `v0.1` 文案规则 | 与正式构建版本绑定 | 用户 | 影响版本显示和发布流程 | 待确认 |

## 9. 风险登记

### 技术风险

- 当前 Glow 使用多层程序化圆形，Trail 最多 16 个采样；机器验证未发现运行错误，但尚未在目标硬件测量帧时间。
- Ground 的 restitution、tangent retention、Vitality retention 与 settle 门槛是耦合体验参数；确定性测试只能证明结算顺序，不能证明休眠节奏自然。
- 低速 Ground 持续接触可能在连续物理帧产生多次响应；最终 600 帧验证需排查错误或失控，主观节奏仍交由试玩。
- 概念图是完整合成图，不能直接拆成独立运行时资产；背景、窗口和效果层仍需在正式制作阶段重建。
- Godot 脚本运行期错误不一定导致进程返回非零；验证命令必须同时扫描输出中的 `SCRIPT ERROR` / `ERROR:`。

### 视觉风险

- 概念图中的 Light Version/Footer 原色低于 4.5:1；实现 Token 已加深，但仍需在实际字体、字号和合成背景下复测。
- Light 与 Dark 图中的窗口框位置和尺寸存在少量像素差异，不能把两个合成图直接当作严格布局模板；应使用统一设计网格。
- Dark 图缺少拖尾只代表单帧状态，错误地按主题禁用拖尾会破坏 Theme/Motion 分离。
- Start、Pause、Game Over 的极简方向已确认，但具体字号、透明度和间距仍需在完整 UI 中视觉校准。

### 后续开发风险

- Timer 已实现为最近一次 Wake/Active 到进入 Rest 的正计时；它不参与失败或难度，仍应保持可独立移除。
- Ball 初始参数已集中，但补能感、衰减节奏、Rest 窗口、Wake Impulse 与接球动机仍需人工试玩，不得仅凭机器测试定稿。
- 字体家族方向已批准，但具体字体文件、版本和许可证尚未归档，标题、Timer 和 Footer 的最终宽度仍需实测。
- 随机或低强度动态变化若没有概率上限、冷却或可读性约束，仍可能意外形成不可处理阶段；玩法规格需建立约束与验证指标。

## 10. Phase 0 工作日志

| 日期 | 任务 | 结果 |
| --- | --- | --- |
| 2026-09-08 | 读取治理与计划 | 完成 |
| 2026-09-08 | 检查工作区和 Git | 完成；非 Git 仓库，未初始化 |
| 2026-09-08 | 核验 Godot 与辅助环境 | 完成；Godot 4.7 stable、Python 3.14.5、Node 24.15.0 |
| 2026-09-08 | 归档 Light/Dark 概念图 | 完成；大小与 SHA-256 一致 |
| 2026-09-08 | 视觉规则与像素分析 | 完成；结果写入 `visual_spec.md` |
| 2026-09-08 | 资产登记 | 完成；结果写入 `asset_registry.md` |
| 2026-09-08 | 最终验收 | 完成；文件、目录、哈希、资产表、文档结构和禁止产物检查通过 |
| 2026-09-08 | 用户通过 Phase 0 人工确认门 | 完成；Q002、Q003、Q007 及相关主题/可读性/Git 决策已确认 |
| 2026-09-08 | V0.1 项目初始化 | 完成；创建最小工程、空目录、Git 规则与本地 `main` 仓库 |
| 2026-09-08 | Godot 配置加载验证 | 完成；Godot 4.7 headless editor 退出码 `0` |
| 2026-09-08 | V0.1 书面规格与 TDD 计划 | 完成；用户确认技术设计后执行 |
| 2026-09-08 | 确定性规则实现 | 完成；Energy、Speed Mapping、State、Rules、Wake、Ball 碰撞测试通过 |
| 2026-09-08 | Endless 主场景整合 | 完成；Ball、Paddle、边界、HUD 与程序化视觉已连接 |
| 2026-09-08 | V0.1 机器验收 | 完成；86 checks；主场景 180 帧无错误；等待人工试玩 |
| 2026-09-08 | 用户确认 V0.1.1 调整设计 | 完成；固定重力、Ground 损耗、碰撞反馈与宽光迹 |
| 2026-09-08 | V0.1.1 TDD 与变异检查 | 完成；去重力、0.75 Ground、Trail 忽略速度均被测试捕获 |
| 2026-09-08 | V0.1.1 离线视觉 QA | 完成；120 帧两轮复核；分段 Trail 修正为连续双层渐变光迹 |
| 2026-09-08 | V0.1.1 重构前现场快照 | 完成；`18c1931 chore: snapshot v0.1.1 endless prototype baseline` |
| 2026-09-08 | V0.1.2 技术设计与 TDD 计划 | 完成；设计 `58dcf50`，计划 `35db446`，均经用户确认 |
| 2026-09-08 | V0.1.2 纯模型与 Controller 迁移 | 完成；Vitality、Surface Response、Velocity 结算与 Wake 分离 |
| 2026-09-08 | V0.1.2 Visual/Rules 迁移 | 完成；Trail/Glow 数据源分离，旧 BallEnergyModel 运行时引用清零 |
| 2026-09-08 | V0.1.2 最终机器验证 | 完成；fresh import、173 checks、600 帧及四项变异检查通过 |
| 2026-09-08 | V0.1.2 运行时调参面板 | 完成；F1 切换、共享 PrototypeTuning、205 checks 与 600 帧验证 |
| 2026-09-08 | V0.1.3 Wake Impulse TDD | 完成；Rest 窗口、邻近判定、弱/强冲量、连续输入防叠加与正常碰撞隔离 |
| 2026-09-08 | V0.1.3 场景级验证 | 完成；fresh import、235 checks 与主场景 1200 帧运行通过 |
| 2026-09-08 | 视觉独立审计（实机截帧） | 完成；Godot 4.7 同构建离线渲染，量化 Glow 剖面、Trail 采样、遮挡比例与主题对比度 |
| 2026-09-08 | 视觉语言 v1 冻结 | 完成；三通道原则与 Ball / Paddle / Trail 参数确认 |
| 2026-09-08 | 视觉规格同步 | 完成；`visual_spec.md`、`asset_registry.md`、`AGENTS.md` 已按 v1 更新 |

## 11. Phase 0 启动判断

Phase 0 规格与文档工作：`完成`。

是否具备进入 Bounce Lite V0.1 项目初始化的条件：`是`，且用户已明确批准。

Phase 0 结束时的结果（历史快照）：

- `Q002`、`Q003`、`Q007` 已由用户确认并写入规格；
- `Q001`、`Q004`、`Q006` 已确认；
- `Q005` 的决策时点已确认，技术路线延后到获批的开发任务；
- 已建立 Godot 4.7 / Compatibility / Windows / 960×720 / 4:3 基线；
- 已建立本地 `main` Git 仓库，远端为空；
- 当时没有 main scene、玩法脚本、正式素材或可玩 Demo。

是否具备进入 V0.1 玩法实现准备的条件：`是`。该确认门已经通过，V0.1 Endless 原型现已完成机器实现验证。

## 12. V0.1 初始化证据（历史快照）

| 项目 | 结果 |
| --- | --- |
| `project.godot` | 已创建；无 `run/main_scene` |
| Design Resolution | `960×720` |
| Resize / Stretch | Resizable；`canvas_items`；Aspect `keep` |
| Renderer | `gl_compatibility` |
| 项目元数据 | Project Name `Bounce Lite`；UI Title 规格 `Bouncing Ball` |
| Godot 验证 | `4.7.stable.official.5b4e0cb0f` headless editor 加载成功，退出码 `0` |
| Git | 本地 `main` 仓库；无远端 |
| 禁止产物检查 | 无 `*.gd`、`*.tscn`、`*.tres`、音频或新制正式素材 |

说明：表中“无 main scene / 无脚本”仅描述初始化完成当时。当前工程保持 Project Name 为 `Bounce Lite`，并由 `scripts/main.gd` 将实际窗口标题显式设置为 `Bouncing Ball`。

## 13. V0.1.2 核心模型设计状态（历史）

- 技术方案：已由用户确认；
- 书面规格：`docs/superpowers/specs/2026-09-08-v0.1.2-vitality-physics-separation-design.md`；
- 实施计划：`docs/superpowers/plans/2026-09-08-v0.1.2-vitality-physics-separation.md`；
- 代码状态：核心 TDD 迁移、fresh import、600 帧与变异验证完成；
- 后续状态：用户已批准 V0.1.3 Wake Impulse 改动，当前人工试玩门见第 16 节；
- 当前没有正式素材、正式音频、主题切换、Game Over 或后续玩法规则。

## 14. V0.1.1 Endless 原型实现证据（历史快照）

本节记录提交 `18c1931` 对应的 V0.1.1 历史状态。当前实现已由第 15 节的 V0.1.2 架构替代。

### 组件与职责

| 组件 | 文件 | 当前职责 |
| --- | --- | --- |
| PrototypeTuning | `scripts/config/prototype_tuning.gd` | 集中保存速度、能量损耗、Wake、Paddle 与 Trail 参数 |
| BallEnergyModel | `scripts/ball/ball_energy_model.gd` | Energy 约束、平方速度映射、环境耗散、Paddle 恢复、状态导出 |
| BallController | `scripts/ball/ball_controller.gd` | CharacterBody2D 移动、固定重力积分、碰撞分类与 Energy 驱动反弹 |
| PaddleController | `scripts/paddle/paddle_controller.gd` | 鼠标 X、平滑与边界、Wake 手势检测 |
| EndlessRules | `scripts/rules/endless_rules.gd` | Combo、Ground 清零、当前活跃时间、Rest/Wake 规则事件 |
| BallVisuals | `scripts/ball/ball_visuals.gd` | 程序化 Core/Glow、连续双层光迹、碰撞形变与 Wake 亮度反馈 |
| PrototypeHUD | `scripts/ui/prototype_hud.gd` | 纯文字 Combo 与 `TIME MM:SS` |
| Main | `scenes/main.tscn`、`scripts/main.gd` | 组装边界与组件、连接信号、设置 UI Title |

### 初始调参基线

| 参数 | 当前值 |
| --- | ---: |
| Active Speed | `360 px/s` |
| Max Speed 安全上限 | `520 px/s` |
| Gravity Acceleration | `520 px/s²` |
| Wall / Top Energy Retention | `0.985` |
| Ground Energy Retention | `0.65` |
| Active Threshold | `300 px/s` |
| Rest Threshold | `35 px/s` |
| Wake Speed | `330 px/s` |
| Wake Paddle Velocity | `450 px/s` |
| Wake Hold | `0.08 s` |
| Paddle Smoothing | `18` |
| Paddle Size | `150×18 px` |
| Ball Radius | `16 px` |
| Trail Samples | `16` |

上述数值仅是试玩起点，不是最终设计。

### 机器验证

| 检查 | 结果 |
| --- | --- |
| Godot headless editor 导入 / 加载 | 退出 `0`，无错误日志 |
| 确定性测试 | `TEST PASS: 112 checks`，退出 `0` |
| Main Scene | headless 运行 600 帧，退出 `0`，无 `SCRIPT ERROR` / `ERROR:` |
| 离线视觉 QA | Compatibility Renderer 输出 120 帧；确认 Ground squash/darken 与连续宽光迹；临时帧已清理 |
| Git Remote | 空 |
| 正式资产 / 音频 | 未新增；概念目录以 `.gdignore` 排除运行时导入 |
| `git diff --check` | 退出 `0` |

### 人工试玩待确认

1. 不接球时，球是否自然从运动 → 衰弱 → 休眠；
2. 接球是否有恢复活力的感觉；
3. Ground 是否像损耗而非普通碰撞；
4. 速度变化是否自然；
5. 是否会主动想接球维持运动。

以上五项均为 `待确认`，机器验证与离线帧检查不代替体验判断。

## 15. V0.1.2 Vitality–Physics 实现证据

本节记录 V0.1.2 机器验证时的实现快照；当前 Wake 行为已由第 16 节的 V0.1.3 实现替代。

### 当时组件与职责

| 组件 | 文件 | 当前职责 |
| --- | --- | --- |
| PrototypeTuning | `scripts/config/prototype_tuning.gd` | 分组保存 Vitality、Physics、Surface Response、Paddle 与 Visual 参数 |
| BallVitalityModel | `scripts/ball/ball_vitality_model.gd` | Vitality clamp/delta、ACTIVE/DECAYING、联合 RESTING 与 Wake 状态 |
| SurfaceCollisionResult | `scripts/physics/surface_collision_result.gd` | 单次碰撞的 Velocity/Vitality 只读快照 |
| SurfaceResponseModel | `scripts/physics/surface_response_model.gd` | 纯计算 Wall/Top/Ground/Paddle 的 restitution、friction、impulse 与 delta |
| BallController | `scripts/ball/ball_controller.gd` | CharacterBody2D、重力、碰撞检测和“Velocity → Vitality → State”结算编排 |
| PaddleController | `scripts/paddle/paddle_controller.gd` | 鼠标 X、平滑与边界、Wake 手势检测 |
| EndlessRules | `scripts/rules/endless_rules.gd` | Combo、Ground 清零、当前活跃时间、Rest/Wake 语义事件 |
| BallVisuals | `scripts/ball/ball_visuals.gd` | Velocity-only Trail 长度/宽度、Vitality-only Glow 亮度/范围、碰撞形变与 Wake pulse |

### 当时调试起点

| 参数 | 值 |
| --- | ---: |
| Initial / Max / Wake Speed | `360 / 520 / 330 px/s` |
| Gravity Acceleration | `520 px/s²` |
| Max / Active / Rest / Wake Vitality Ratio | `1.00 / 0.70 / 0.08 / 0.85` |
| Rest Settle Speed | `45 px/s` |
| Wall/Top Restitution | `0.96 → 0.995` |
| Wall/Top Tangent / Vitality Retention | `0.995 / 0.985` |
| Ground Restitution | `0.12 → 0.78` |
| Ground Tangent / Vitality Retention | `0.80 / 0.65` |
| Paddle Restitution / Impulse | `0.72 → 0.92 / 160 px/s` |

上述数值只作为 V0.1.2 人工试玩起点。

### 当时机器证据

| 检查 | 当前结果 |
| --- | --- |
| Godot headless editor import | 退出 `0`；注册 BallVitalityModel、SurfaceResponseModel 等 14 个脚本类，无解析错误 |
| 确定性测试 | `TEST PASS: 173 checks`，退出 `0` |
| Main Scene | headless 运行 600 帧，退出 `0`，无脚本或运行期错误 |
| 旧模型引用 | `scripts/tests/scenes/project.godot` 中 BallEnergyModel、旧映射与同步方法引用为零 |
| Vitality 领域边界 | BallVitalityModel 中 SurfaceKind、Wall/Ground/Paddle、restitution、impulse 引用为零 |
| 变异检查 | 错用损耗后 Vitality、遗漏 Paddle impulse、Vitality 重建 Velocity、Trail 乘 Vitality 均产生预期失败并恢复 GREEN |

### V0.1.2 人工试玩观察（历史）

1. Ground 是否形成自然的小跳、滚动和休眠；
2. Paddle 是否同时带来运动注入与 Vitality 恢复感；
3. Trail 与 Glow 是否清楚表达 Motion 与 Vitality；
4. Wake 是否仍然有意图明确且可靠；
5. 是否存在空中冻结、接球减速、突然停止或速度失控。

以上项目均为 `待确认`；最终机器验证完成后仍不得描述为体验验收通过。

## 15A. 视觉语言 v1 冻结记录（`2026-09-08`）

### 冻结内容

三通道原则与 Ball / Paddle / Trail 完整参数已冻结，写入 `docs/visual_spec.md` §1.1、§8.5、§11.4、§11.5，资产登记同步至 `docs/asset_registry.md`。

### 验证方式

| 项 | 事实 |
| --- | --- |
| 引擎 | Godot `4.7.stable.official.5b4e0cb0f`，与本项目同一构建哈希 |
| 方式 | 独立沙箱工程离线渲染，未修改本仓库任何文件 |
| 尺度 | 1:1 设计尺度，底色 `dark.panel #171C26` |
| 结论 | 全部数值可由运行时径向渐变贴图实现，不需要 Shader 或位图素材 |

### 审计期间的关键实测

以下为像素测量结果，不是估计值：

| 观察 | 数值 |
| --- | --- |
| 当前 Ball Glow 剖面 | 四段全平台阶，边界 `16 / 19.4 / 26.5 / 36.6`，段内单一 RGB，段间突变；包络 73 px（登记为 55–60） |
| 当前 Trail 峰值时机 | 采样数在落地损耗前 5 帧达到最大（14），刚接到球时最小（5） |
| 休眠 Vitality 衰减 | 2 秒内从 `0.0743` 衰减到 `0.0002`；地面亚像素微跳持续吃 Ground 损耗 |
| Paddle 遮挡静止 Ball | V0.1.2 稳定遮挡 24.7%；V0.1.3 Wake Impulse 后降至 5.8% |
| Wake 后落地穿透 | 稳定停在 `y = 571.3`，比正常静止位置低 `6.3 px` |
| 概念图 Light 主题实测 | 白球对近白面板 `1.03:1`，最强光晕 `1.76:1`，Paddle `1.35:1`；均低于非文字 UI 的 `3:1` 参考下限 |

最后一项的含义：Light Theme 的可读性问题**不是实现没跟上，而是概念图本身没有解决**。因此 Light 需要单独设计而不是换色，用户已确认降级为非当前优先项。

### 机器验证的边界

上述全部为渲染与几何测量，只证明数值可实现且可测量。Glow 是否好看、Trail 是否舒服、Paddle 反馈手感是否成立，仍需人工试玩。

## 16. V0.1.3 Resting Wake Impulse 实现证据

### 当前行为

- `DECAYING` 继续运行既有 Physics Loop，并可通过正常 Paddle Collision 恢复；
- 进入 `RESTING` 时清零速度并开始 `rest_elapsed_time`；
- 默认前 `0.12 s` 不接受 Wake Impulse；
- 休息窗口结束后，仅横向落入 Paddle 作用窗口的实际运动输入会产生一次冲量；
- 冲量使用 Paddle 水平速度，默认水平系数 `0.18`、向上系数 `0.45`；
- 冲量低于 `180 px/s` 时保持 `RESTING`，允许短暂小跳或滚动；
- 达到阈值时恢复最大 Vitality 的 `0.15`，进入 `DECAYING`；
- Wake Impulse 不经过 SurfaceResponseModel，正常 Paddle Collision 行为保持不变。

### 当前人工试玩待确认

1. `0.12 s` Rest 窗口是否自然；
2. 弱输入是否呈现轻推而非异常弹飞；
3. 强输入是否具有明确救活感；
4. Paddle 横向作用窗口是否易于理解；
5. Wake 后进入 `DECAYING` 是否能自然衔接下一次有效接球。

以上项目均为 `待确认`；F1 调参面板中的 `RESTING WAKE` 分组仅用于运行时校准，不代表参数已经定稿。

## 17. V0.1.3 Bug Fixes & Frozen Visual Presentation（2026-09-09）

用户当前指令明确版本分工：V0.1.3 修复 + 冻结视觉实现；V0.1.4 基础音频；V0.1.5 最终调查 / 最终体验复核。旧文档缺少版本路线是同步缺口，不是规划未确认。

本次从 main / dbf369a 的干净工作区开始，无子 Agent、worktree、依赖安装、Git 远端或正式素材。实现文件与可复现命令见 [实施记录](superpowers/plans/2026-09-09-v0.1.3-bugfix-visual-implementation.md)。

- 几何：Paddle Y=537；Main 从场景实际碰撞面推导边界；Ball z_index=1。
- 物理修复：弱 Wake 落地收敛到 y=564.92；异常越界恢复最近安全位置、移除外向速度，低 Vitality 地面逃逸回到稳定 RESTING。正常运动不依赖兜底。
- 视觉：统一 token、青色 Core、连续径向 Glow、离散时间采样 Trail、Paddle 瞬时反馈、Dark panel 校准。
- 通道：移除 Ball 独立亮暗事件脉冲，保留几何装饰；未迁移 Rules 职责。
- 验证：235 基线 → bug fixes 274 / 场景738 → 最终确定性289 / 场景749；headless import、主场景1200帧退出0；Compatibility 三态基准及640×480至1440×1080四档渲染截图保存并检查。
- 环境：默认用户日志路径曾触发 Godot 崩溃，改用仓库 .godot 日志恢复；根证书存储警告及 editor settings 无法保存提示仍存在，无网络任务，不修改系统；import 注册与解析完成。
- 待确认：Rest/Wake 手感、底角压力下感受、离散 Trail 舒适度、零 Vitality 可见性、Paddle 反馈短促性；确认人用户。
- 未解决：高速 Paddle sweep 仍未实施；configure() 开局副作用保持原状。它们不自动触发本轮范围扩展。

当前停止点为 V0.1.3 人工试玩。未启动 V0.1.4 音频或 V0.1.5 最终体验复核。

## 18. 用户试玩反馈后的 Wake 修复（2026-09-09）

已确认：球视觉表现与边缘稳定度通过；重力260为用户实际试玩决定，改善整体纵向活动范围。Rest/Wake旧体验未通过：范围过近、弱输入抢先消费、球撞挡板下沿。

本轮采用200 px中心范围、50 ms弱样本峰值采样、强输入立即提交、竖直系数0.70，保留0.12 s Rest、连续强度与0.15 Vitality恢复。所有Paddle碰撞保留，下沿阻挡属于物理结果；无collision exception、随机变化或必达顶板验收。独立DebugOverlay解决Ball覆盖调参面板；修正面板将速度上限520显示为521的步进取整问题。

确定性325 / 真实场景803通过，含30/60/120 Hz左右划动、让开/未让开、落稳再唤醒；import、1200帧退出0，覆盖层截图检查通过。详见当前实施记录。Rest/Wake手感待用户复测，既有Paddle sweep与configure开局副作用未扩展修复；V0.1.4未启动。

## 19. V0.1.4 Basic Audio Feedback（2026-09-09）

用户已验收V0.1.3并授权最小音频反馈。调查Kenney Audio官方分类、Impact/Digital/Interface素材页；仅下载Impact Sounds原包并提取6个候选（每事件2个），CC0原许可及来源/哈希归档，无后期处理。

BasicAudio节点通过surface_resolved和wake_impulse_applied接入，Paddle仅有效碰撞、Ground过滤微小法向运动、Wake仅提交时发声。三个单voice播放器、事件间隔与40 ms跨事件抑制避免密集堆叠；F2–F4切换、F5静音，4秒显示文件名，全部临时。

确定性358、物理场景803、音频场景24通过，import/1200帧与6候选非headless播放正常。快速测试给予100 ms音频线程退出清理时间，避免测试过快退出的资源警告；生产不等待。既有环境根证书/用户编辑器配置提示未变。详情[V0.1.4记录](v0.1.4-basic-audio.md)。

无已知阻塞接入问题；音量、尾音、重复舒适度与玩具感待用户实机判断。未启动V0.1.5或V0.2。

## 20. 首次远端 checkpoint / V0.1.4 baseline（2026-09-09）

本段替代§18–19的当前状态判断，保留其当时执行记录。用户已验收V0.1.3。V0.1.4已确认以最小音频验证电子玩具感：Paddle pepSound3弹起、Strong Wake同类更有能量、Weak Wake无专门音效、Ground forceField短片下沉，Wall/Top已接入。Paddle/Strong Wake/Wall通过，Ground A可用；最新固定音高1.5待单独试听。确定性381、物理场景803、音频场景38 checks通过。Paddle Resting Support仅为pending设计问题，未实现；V0.1.5未启动。

同步README、治理入口、项目概览、音频记录、资产登记、V0.1.3规格/实施记录。新增LICENSE（代码及技术文档MIT）、ASSET_LICENSE.md（媒体排除与权利边界）、THIRD_PARTY_ASSETS.md（3个Kenney包、17原始OGG及4试听裁片、原许可与来源）。概念PNG上游权利尚未建立，不授予再使用权；原文件和归档副本保持不变。

首次远端目标为https://github.com/Kandecho/Bounce-Lite.git；保留main原25个提交，不squash或重写，仅将本轮已授权工作追加为baseline提交。审查当前文件及待推送历史，未发现常见凭据模式或明显不应公开的大文件；最大历史资源约1.2 MB。只推main，不推本地Codex快照引用。新增忽略规则覆盖IDE私有配置、环境文件、本地路径配置、日志和临时输出；Godot导入配置及UID保留，.godot缓存和ZIP不提交。

启动器移除硬编码机器路径，支持GODOT_CONSOLE、忽略的godot.local.txt及PATH；日志显式落到.gitignore覆盖的.godot。共享运行说明已改为可移植方式，历史环境证据中的旧绝对路径保留。

本次基线验证：test_runner 381、physics_scenarios 803、audio_scenarios 38全部通过；headless import与主场景1200帧退出0，启动器--check通过。存在既有根证书存储及编辑器用户配置保存提示，无脚本/场景错误。没有新增玩法/音频行为修改；完整视觉截图未重跑。

未解决：Paddle Resting Support、既有高速Paddle sweep和configure开局副作用；Ground最新音高及重复舒适度待听感确认；概念参考图权利来源待核实。未启动V0.1.5/V0.2。实际push结果与commit以Git历史和远端refs为准。

补充退出证据：首次使用--fixed-fps 60加速1200帧运行虽退出0，但报告8个ObjectDB实例/3个资源退出时仍占用；随后按普通headless 1200帧并启用verbose复查，退出0且未复现该提示。音频场景测试自身包含线程清理等待；生产代码未加等待。快速进程退出时的资源清理时序保留为investigation，不能据一次复跑断言已修复。
