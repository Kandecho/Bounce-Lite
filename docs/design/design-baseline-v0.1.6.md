# Bounce Lite Design Baseline — V0.1.6

> V0.1.6历史基线；只用于该版本对照。当前持续约束见[产品概览](../project_overview.md)。

日期：2026-09-10。状态：用户已确认的 Design Boundary Consolidation 决定；实现与验证见 [收口报告](../reviews/v0.1.6-consolidation.md)。本文是当前设计判断入口，V0.2.0 未授权。

来源：[用户原始 V0.1.x 基线](design-baseline-v0.1.x.md)及本轮用户实施指令。原稿原曾以 `docs/design-baseline-v0.1.6.md` 暂存，与桌面提供的 V0.1.x 原稿 SHA-256 相同；现按内容版本归档，字节未改。原稿不覆盖，本文记录本轮明确决定。

> 玩家决定是否继续互动，世界决定接下来会发生什么。

## 两层职责与接口

- Physics 决定位置、速度、重力、碰撞及 Surface Response；Velocity 与运动历史驱动 Trail。
- Interaction 影响活力与 Wake；Vitality 影响碰撞中的运动维持能力，不直接规定运动方向。当前没有独立时间衰减。
- Activity 保留 ACTIVE / DECAYING / RESTING，只维护状态并通知。Activity 转换不能直接改 Velocity、Position、Support 或停稳运动。
- Physics 可以经 Collision / Vitality 引起 Activity 转换。停稳需先满足物理条件，应用速度与支撑位置结果，再提交 RESTING。
- Wake 是同时作用两层的显式事件：先恢复活力、退出 RESTING；必要时固定向上启动。不是 Paddle 水平速度向 Ball 的传递。

## Paddle 的两种身份

Paddle 是真实 Surface，也是 Interaction Medium；它不是 Ball Controller。真实接触改变运动并可恢复活力；接触之外，玩家通过新目标位移提供交互。弱输入仅连续几何回应；Strong Wake 达阈值才恢复活力并按需启动。

保留 V0.1.5 的 200 px 范围、0.12 s 休息、50 ms 采样、12.5 px 阈值、0.15 最大活力恢复、350 px/s 向上启动。Paddle 可提供休息支撑，不横移承载；支撑丢失恢复重力。普通碰撞和阻挡始终有效。

## 无目标化呈现

删除 Combo 显示、计数、清零、规则和测试，不保留隐藏成绩。产品不以连续成功、玩家表现、分数或失败压力组织体验。

Timer 仅为默认隐藏的 F1 开发观察计数器 `DEV ELAPSED`，累计本次运行的过程时间。开发者可以读取两个时刻的差值观察区间；没有自动运动段计时或状态区间日志。它不监听 Activity、Vitality、Interaction，不因 RESTING 暂停，不因 Wake 归零，不属于玩家 HUD。重新运行才新建计数器。

提供行为证据，不提供人格、情绪标签或解释球意图的文本。

## 保留的实现边界

- 不调整 Vitality 恢复模型、衰减参数、方向影响、Surface 模型或音效。
- Core / Glow 保留已验收的 V0.1.3 视觉：RESTING 固定底光／状态色是现有可读性特例，本轮不做美术调整；Trail 不因此关掉高速运动证据。
- `ball_radius` 是共享的物理圆半径与未形变 Core 半径；形变仅视觉。场景形状与参数需一致，以测试锁定，当前不引入动态几何系统。
- 不新增 Paddle sweep、方向传递、新 Surface、玩法、时间衰减或架构层。

历史审计的意见是审查记录；本轮采用或暂缓的决定见收口报告，不能将历史建议自动视作未来执行授权。
