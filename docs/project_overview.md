# Bounce Lite Project Overview

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
- 视觉重点：柔和背景、克制的窗口层级、清晰的球体、发光挡板和简洁 Timer；
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
- 失败体验应表达“这一次没有接住”，而不是“系统进入无法处理阶段”；
- V0.1 不设计排行榜、最高分压力或连续生存挑战等竞技目标，除非后续版本重新评估。

## 6. 阶段路线

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

用户已于 `2026-09-08` 批准本重构。当前实现范围为：

- Velocity、Position、Gravity 与 Collision 属于 Physics；
- Inflation/Elasticity、Bounce capability、ActivityState 与基础视觉强度属于 Vitality；
- BallVitalityModel 不持有 Surface 或速度映射规则；
- SurfaceResponseModel 以碰撞前 Velocity/Vitality 计算纯 CollisionResult；
- BallController 依次应用 Velocity、Vitality delta 与状态；
- Paddle 使用统一响应、固定 impulse、速度上限与 Vitality 恢复；
- Ground 通过恢复系数、切向损耗和 Rest 联合门槛形成自然安定；
- Trail 只表达 Velocity，Glow 只表达 Vitality。

不存在 Game Over，不实现其他模式、正式素材、正式音频、主题系统或精修视觉。当前技术边界见 `docs/superpowers/specs/2026-09-08-v0.1.2-vitality-physics-separation-design.md`。

### 后续阶段

音频、完善动效、主题切换、更多平台与发布流程均需在 V0.1 之后单独规划。不得从当前概念图自动推导这些功能已经获批。

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

## 9. 已确认视觉与主题策略

- Start、Pause、Game Over 采用极简文字 UI；
- 不使用按钮边框、卡片或复杂面板；
- 通过字号、字重、透明度和间距区分信息层级；
- 开源字体优先 `Inter`、`Noto Sans`，正式发布前复核授权；
- V0.1 不实现 Light/Dark 主题切换，只保留两套设计规格；
- Light 版本文字与 Footer 的颜色按可读性目标加深；
- Glow / Trail 等效果的实现路线在开发阶段通过技术验证确定。

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

该确认门已于 `2026-09-08` 通过；V0.1、V0.1.1 与获批的 V0.1.2 核心实现均已进入机器验证流程。每次机器验证只证明确定性规则和工程可运行，不能替代人工体验验收。
