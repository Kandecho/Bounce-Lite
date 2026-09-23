# Bounce Lite Project Overview

> 当前协作方式：主代理Astra的思考强度由用户手动控制，普通实现Sol medium，明确小活Luna medium。实现／集成代理负责完整验证闭环及可审计证据，主代理审查约束、遗漏风险和需求偏差，默认不复跑测试或重读完整实现。分派、升级、检查触发与交付格式统一见[治理规则](../AGENTS.md#agent-execution-policy)。

> 2026-09-23 当前入口：第一运动A/B已保存为 `60e3516`；用户随后选择速度1.5×／重力2.25×并继续弹簧refinement，实际范围与证据见[最新停点](exploration/geometry-harvest-batch1.md#spring-refinement-15x)。挡板保持y570，独立接触反馈未进入本轮，main仍为 `f792d3b`。下方历史参数、实施时点与验收不覆盖当前记录。

> 2026-09-13 当前状态：V0.2.0 随机对象、有效挡板动作资格、Wake/Continue 收尾已实现并完成本轮机器与渲染检查，按用户授权合入 main 后连续进入广泛物理玩具探索。当前入口为[新方向](exploration/physical-toy-exploration.md)、[实现基线](design/design-baseline-v0.2.0.md)、[收口记录](reviews/v0.2.0-consolidation.md)。以下2026-09-11及更早状态为历史，不能覆盖本轮授权或作为新玩法的提前筛选门槛。

> 2026-09-11 当前状态：`codex/exp-v02-shared-world` 已在完整原型上实现中心色 UI 与全客户区场地，文档同步起点为 `793c361`。当前依据为 [V0.2.0 Design Note](design/v0.2.0-design-note.md)，后续顺序和验证见[实施计划](exploration/v0.2.0-follow-up-plan.md)，实际改动和证据见[共享小世界记录](exploration/v0.2-shared-world.md)。随机出现、Continue 资格及 Wake／Continue 表现调整尚未实施；最新组合待实机体验。main 游戏代码仍为 V0.1.6。下文保留历史时点，不覆盖当前设计。

## V0.1.6 基线与早期 V0.2 规划记录（历史）

main 的现有实现以 [V0.1.6 设计基线](design/design-baseline-v0.1.6.md)为依据。Activity 状态通知不改 Physics；Ground/Paddle 停稳由明确物理条件触发，先提交运动结果再进入 RESTING。Paddle 为 Surface + Interaction Medium，不是 Ball Controller。Vitality 影响运动维持能力，不规定方向，仍只经既有碰撞／Wake 事件变化。

Combo 与其成绩逻辑已删除；Timer 只在 F1 开发面板显示累计过程时间，与游戏状态无绑定。默认画面无成绩或时间 HUD。configure 与 start_active 分离；本轮规划不改普通反弹、恢复模型、方向、视觉和音频。实现、验证和人工待复核项见 [收口报告](reviews/v0.1.6-consolidation.md)。

用户已确认 [V0.2 探索原则](design/v0.2-exploration-principles.md)，并要求建立[第一阶段探索计划](exploration/v0.2-exploration-plan.md)，停在具体实施之前。探索问题是“什么样的事件，会让玩家产生我和它在玩的感觉”；以接触语言、共同改变第三对象、停顿连续感及世界介入等不同假设展开搜索。允许玩家自发目标与奖励，不引入系统强制任务；不提前固化 wake／rebounce 状态或正式架构。

当前规划已建立，实验分支、代码和试玩均未启动。后续实验全部在分支进行，经实际体验作保留／变形／搁置判断，再挑选符合核心关系的部分进入 main；不预先承诺 V0.2.0 功能清单。下文产品描述、机制限制及版本记录以其阶段为准，不将旧版机制冻结自动施加给新探索。

下文阶段记录保留历史原意；曾批准的 Combo、活跃时间、旧 Wake 和概念状态 UI 不再构成当前实现要求。


## 1. 项目定位

Bounce Lite 是一个轻量、单屏、低认知负担的桌面休息游戏，目标用户为轻量休闲桌面小游戏用户。概念图中的标语为：

> A SMALL GAME FOR BIGGER BREAKS

已确认的核心体验是：提供一个可随时开始、随时结束，用于放松的数字玩具。体验保持简单、平静并有清楚反馈，不以固定时长或竞技压力驱动玩家。

## 2. 名称体系

| 语境 | 名称 | 状态 |
| --- | --- | --- |
| 项目、目录、工程与文档 | `Bounce Lite` | 已确认 |
| 游戏窗口标题 | `Bouncing Ball` | 已确认 |
| 概念图版本文字 | `v0.1` | 待确认其是否直接绑定正式构建版本 |

## 3. 核心体验方向

- 单一主要对象：Ball；
- 单一直接控制对象：Paddle；
- 视觉重点：克制的背景、青色 Ball、Vitality Glow、离散 Velocity Trail、瞬时 Paddle 真实碰撞反馈；开发 Timer 仅在 F1 中观察；
- 情绪目标：轻松、安静、柔和、短时可进入；
- 反馈原则：运动反馈应明确，但不以大量粒子或强烈闪烁制造负担；
- 主题原则：Light 与 Dark 是视觉主题，Idle 与 Moving 是运动状态，两个维度独立。
- 输入原则：鼠标控制 Paddle 水平移动；键盘不是 V0.1 必需输入。

本节只描述产品和视觉方向，不授权实现玩法。

## 4. 目标用户与使用场景

已确认用户与场景：

- 桌面工作或学习间隙；
- 可随时开始或结束的休息片段，不规定单局目标时长；
- 希望快速进入、无需学习复杂规则的用户；
- 对强刺激、密集 UI 或长局游戏没有需求的场景。

目标用户是轻量休闲桌面小游戏用户。核心操作为鼠标水平移动 Paddle；键盘操作可在后续版本评估，但不属于 V0.1 必需输入。

## 5. 单局与难度原则

- 不设定固定单局时长目标；
- 不采用单调递增的难度曲线；
- 避免“越玩越快直到必然失败”的强制终局模式；
- 难度可通过低强度、非单调的速度波动、轨迹变化、偶发事件或不确定性变化形成；
- 接触与落地只呈现物理回应，不定义成功／失败结果；
- V0.1 不设计排行榜、最高分压力或连续生存挑战等竞技目标，除非后续版本重新评估。

## 6. 阶段路线（历史记录按当时决定保留，当前以 V0.1.6 为准）

### Phase 0 - Project Setup & Visual Specification

产出：

- 技术环境事实基线；
- Godot 项目规划；
- 概念图归档与可追溯记录；
- `visual_spec.md`；
- `asset_registry.md`；
- 项目说明与开发记录；
- V0.1 启动判断。

Phase 0 不创建 Godot 工程，不实现游戏内容。

### V0.1A - Project Initialization

用户已于 `2026-09-08` 批准该子阶段。范围仅包括：

- Godot 工程初始化；
- Compatibility / Windows / 960×720 / 4:3 缩放基线；
- 基础目录与本地 Git；
- 不设置 Git 远端；
- 不创建场景、脚本、玩法逻辑或正式素材。

### V0.1B - Gameplay Implementation

用户已确认并完成本子阶段的 Endless 初始实现及 V0.1.1 重力调整。V0.1/V0.1.1 历史范围为：

- CharacterBody2D Ball 与确定性反弹；
- 初始 BallEnergyModel；
- 鼠标 Paddle 输入与 Wake 手势；
- EndlessRules、Combo 和当前活跃时间；
- ACTIVE / DECAYING / RESTING；
- 程序化基础 Core / Glow / Trail；
- 自动化规则测试与可运行验证。

该 Energy-driven Motion 架构已由 V0.1.2 替代，但文档保留为历史基线。

### V0.1.2 - Vitality–Physics Separation

用户已于 `2026-09-08` 批准本重构。当时实现范围为：

- Velocity、Position、Gravity 与 Collision 属于 Physics；
- Inflation/Elasticity、Bounce capability、ActivityState 与基础视觉强度属于 Vitality；
- BallVitalityModel 不持有 Surface 或速度映射规则；
- SurfaceResponseModel 以碰撞前 Velocity/Vitality 计算纯 CollisionResult；
- BallController 依次应用 Velocity、Vitality delta 与状态；
- Paddle 使用统一响应、固定 impulse、速度上限与 Vitality 恢复；
- Ground 通过恢复系数、切向损耗和 Rest 联合门槛形成自然安定；
- Trail 只表达 Velocity，Glow 只表达 Vitality。

不存在 Game Over，不实现其他模式、正式素材、正式音频、主题系统或精修视觉。当前技术边界见 `docs/superpowers/specs/2026-09-08-v0.1.2-vitality-physics-separation-design.md`。

### V0.1.3 - Bug Fixes & Frozen Visual Presentation

用户已于 `2026-09-08` 批准本轮改动。V0.1.3 保留既有状态体系：低 Vitality、低速度但尚未停稳的球继续使用 `DECAYING` 和正常 Physics Loop；只有低 Vitality 且 Ground 响应允许稳定时才进入 `RESTING`。

以下为V0.1.3历史Wake规则，已由文末V0.1.5契约替代：进入 `RESTING` 后先经过可调的短暂休息窗口。窗口结束后，只有横向接近球的 Paddle 运动才产生 Wake Impulse。冲量强度连续映射 Paddle 水平速度，方向以向上为主并少量继承 Paddle 水平移动方向：弱冲量允许滚动或小幅移动但保持 `RESTING`；强冲量恢复少量 Vitality 并进入 `DECAYING`。Wake Impulse 与正常 Paddle Surface Response 是两个独立入口。

V0.1.3 的关键 Wake 参数已集中到 `PrototypeTuning`，并接入 F1 运行时调参面板；不保存调参结果。

2026-09-09 用户已明确批准 V0.1.3 包含 bug fixes 与冻结视觉实现。当前已修复 Paddle/Resting Ball 重叠、Ground settle、越界恢复及绘制层级，并实现青色 Core、连续 Glow、离散 Trail、Paddle 瞬时反馈及 Dark token 校准。机器验证完成，V0.1.3已通过用户整体验收，包括Rest/Wake修复。重力已确认改为 260 px/s²，Wake 中心范围 200 px，弱输入采样 50 ms、强输入立即响应，竖直系数 0.70。Paddle 始终参与真实碰撞，无随机冲量，不要求 Wake 到达顶板。当前完整契约见 [V0.1.3 spec](superpowers/specs/2026-09-09-v0.1.3-bugfix-visual-design.md)。

### V0.1.4 - Basic Audio Feedback

版本范围已确认：基础音频反馈。已接入并形成 V0.1.4 baseline，当前候选与人工确认边界见文末状态及音频记录。

### V0.1.5 - Final Investigation / Final Experience Review

版本范围为最终调查与整体体验复核。2026-09-10用户已授权实现Paddle支撑与Wake模型修正，见文末当前状态。

其他模式、主题切换、更多平台和发布流程仍需另行授权。

## 7. 技术路线摘要

| 项目 | 基线 |
| --- | --- |
| Engine | Godot 4.7 stable，已核验并用于项目初始化 |
| Language | GDScript 已确认并用于当前原型 |
| Renderer | Compatibility 已确认 |
| Primary Target | Windows 已确认 |
| Design Resolution | 960×720 |
| Aspect Ratio | 4:3 |
| Resize Strategy | 等比缩放，非 4:3 使用 letterbox / pillarbox |

Renderer、平台、分辨率和缩放方式已写入工程基线。变更这些设置属于技术路线变化，必须请求确认。

## 8. 角色与决策权

### 用户

- 决定产品方向、体验节奏和视觉选择；
- 确认功能范围、技术路线重大变更和验收标准；
- 决定主题策略、状态界面、字体与可读性要求；
- 决定是否从项目初始化进入玩法实现。

### Agent

- 在授权范围内收集事实、整理文档和维护规格；
- 区分事实、候选与已确认决定；
- 标记风险和阻塞项；
- 不覆盖用户文件、不自行扩大范围；
- 在人工确认门前停止。

详细治理规则见根目录 `AGENTS.md`。

## 9. Phase 0 视觉与主题策略（历史，不作为当前功能契约）

- Start、Pause、Game Over 采用极简文字 UI；
- 不使用按钮边框、卡片或复杂面板；
- 通过字号、字重、透明度和间距区分信息层级；
- 开源字体优先 `Inter`、`Noto Sans`，正式发布前复核授权；
- V0.1 不实现 Light/Dark 主题切换，只保留两套设计规格；
- Light 版本文字与 Footer 的颜色按可读性目标加深；
- V0.1.3 Glow / Trail 已采用运行时径向渐变贴图；不需要 Shader 或正式位图。

## 10. Phase 0 成功条件

- 所有概念图中可见元素已完成登记；
- 可见元素具有可追溯的尺寸、颜色 Token 和实现候选；
- Theme 与 Motion State 已分离；
- 环境、路径、版本和 Git 状态有证据；
- Start/Pause/Game Over 等概念图未展示的界面已登记为明确的人工确认项；
- 没有 Godot 文件、玩法代码、正式素材或可玩 Demo；
- 阶段报告明确回答是否具备进入 V0.1 的条件。

## 11. 人工确认门

Phase 0 完成不等于 V0.1 自动开始。最终流程为：

> 概念图 → 生产规格 → Phase 0 报告 → 用户确认 → 正式制作

该确认门已于 `2026-09-08` 通过；V0.1、V0.1.1、V0.1.2 与获批的 V0.1.3 核心实现均已进入机器验证流程。每次机器验证只证明确定性规则和工程可运行，不能替代人工体验验收。

2026-09-09基线记录（后续状态见文末V0.1.5）：用户已验收V0.1.3。V0.1.4已确认以最小音频验证电子玩具感：Paddle pepSound3弹起、Strong Wake同类更有能量、Weak Wake无专门音效、Ground forceField短片下沉，Wall/Top已接入。Paddle/Strong Wake/Wall通过，Ground A可用；最新固定音高1.5待单独试听。确定性381、物理场景803、音频场景38 checks通过。Paddle Resting Support仅为pending设计问题，未实现；V0.1.5未启动。见 [音频基线](v0.1.4-basic-audio.md)。

## V0.1.4 历史基线（2026-09-09）

用户已验收V0.1.3。V0.1.4已确认以最小音频验证电子玩具感：Paddle pepSound3弹起、Strong Wake同类更有能量、Weak Wake无专门音效、Ground forceField短片下沉，Wall/Top已接入。Paddle/Strong Wake/Wall通过，Ground A可用；最新固定音高1.5待单独试听。确定性381、物理场景803、音频场景38 checks通过。Paddle Resting Support仅为pending设计问题，未实现；V0.1.5未启动。

## V0.1.5 收口记录（历史，2026-09-10）

Paddle作为合法支撑面，Activity/Support/Physics分离；低活力低速顶面可停稳，横移不自动承载，支撑丢失恢复重力。连续弱输入产生可见轻微几何响应，保持RESTING且不改变Velocity/Vitality；Strong阈值达标后恢复活力，必要时一次固定上跳，不继承Paddle水平速度。方案与实现见[V0.1.5实施记录](v0.1.5-paddle-interaction.md)。用户已验收总体体验；非碰撞Paddle闪动已按反馈移除，Paddle仅真实碰撞闪动。关键回归完成，V0.1.5 Paddle interaction model收口；不开展V0.2。
