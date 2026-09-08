# Bounce Lite V0.1.3 Wake Impulse 待处理记录

## 记录状态

- 状态：`冻结 / 待统一处理`
- 记录日期：2026-09-08
- 适用基线：当前 V0.1.3 Wake Impulse 工作现场
- 实施状态：未实施
- 范围约束：暂停继续扩展 Wake Impulse；不修改 Surface Response、Vitality 核心模型或 Paddle 的产品定位

本记录用于固化当前已发现的问题、已确认根因和候选解决方向。它不构成实现授权，也不代表相关参数已经最终确认。

## 一、Paddle 与 Resting 球的默认空间关系

### 当前问题

当前运行时几何为：

- Paddle 中心：`Y = 550`
- Paddle 尺寸：`150 × 18`
- Ground 顶面：约 `Y = 581`
- Ball 半径：`16 px`
- Ball 静止落地中心：约 `Y = 565`
- Ball 顶部：约 `Y = 549`
- Paddle 底部：约 `Y = 559`

因此，Paddle 与静止落地的 Ball 存在约 `10 px` 的垂直重叠。

这不是单纯的视觉遮挡。Paddle 水平移动时会持续压入 Ball，在底部边缘形成 Paddle、Ground 和 Wall 的多重约束冲突，使碰撞恢复结果不稳定。

### 已确认根因

运行时 Paddle 高度没有为地面 Resting Ball 留出独立空间。当前构图位置同时承担了正常接球位置和地面静止位置，两者在物理几何上发生重叠。

### 推荐方案

- 保持 Paddle 的固定高度语义，不通过动态移动 Paddle 回避该问题。
- 将运行时 Paddle 中心高度调整至约 `Y = 537`，或经几何核算后的等价安全位置。
- 以“Paddle 与稳定落地 Ball 之间保留明确间隙”为验收条件，而不是只依据视觉观感确定高度。
- 同步统一主场景、运行时常量和相关测试夹具中的 Paddle 高度，避免测试与实际场景使用不同几何。

几何参考：Paddle 中心不高于约 `Y = 540` 才能避免与静止 Ball 重叠；`Y = 537` 可留下约 `3 px` 的基础间隙。

## 二、Ball 越界缺少最终兜底

### 当前问题

在以下条件叠加时，Ball 可能绕过底部有限碰撞边界并掉出 Game Area：

- Paddle 与 Ball 已发生几何重叠；
- Wall 与 Ground 同时形成角落约束；
- Wake Impulse 或碰撞结果包含朝容器外侧的水平分量；
- Ball 已被碰撞恢复推到边界形状端点之外。

Ball 离开碰撞围栏后，当前没有越界检测或恢复路径，固定重力会使其继续下坠直至不可见。

### 已确认根因

- 现有碰撞边界只负责正常接触，没有建立 Ball 必须始终位于有效 Game Area 内的最终不变量。
- Wall 和 Ground 是有限碰撞形状；当多重穿透恢复把 Ball 推过角落端点后，外部不再有碰撞体阻止其继续运动。
- 当前 BallController 没有 safe bounds、越界检测或不可恢复状态修复。

### 推荐方案

增加独立的容器安全兜底，但不取代正常碰撞系统：

1. 根据 Game Area 与 Ball 半径定义 `Ball safe bounds`；安全范围应为容器范围向内收缩 Ball 半径及少量容差后的矩形。
2. 在正常运动与碰撞结算完成后检测 Ball 是否越出 safe bounds。
3. 越界时将 Ball 恢复到最近的安全位置，并清除仍指向容器外侧的速度分量；切向速度按当时状态决定是否保留。
4. 如果 Ball 已处于低 Vitality 且从 Ground 一侧越界，恢复后进入稳定贴地的 RESTING 姿态，不制造新的反弹能量。
5. 将该路径视为异常保护，可增加开发期诊断事件或日志，但不得让它成为正常反弹逻辑。

目标是：物理碰撞负责正常行为，安全边界只防止不可恢复状态。

## 三、Resting 后落地穿透

### 当前问题

V0.1.3 允许 RESTING 状态下继续执行有限运动，这一方向保留。但轻微 Wake Impulse 使 Ball 产生小幅运动后再次落地时，可能形成约 `6 px` 的稳定 Ground 穿透。

该现象会使休眠位置不稳定，也会放大 Paddle、Ground 与 Wall 的多重约束问题。

### 已确认根因

- RESTING 状态允许轻微物理响应，但当前没有统一的最终 settle 收敛步骤。
- 低速、低反弹接触结束后，Ball 的垂直速度虽然接近零，位置却不一定恢复到 Ground 表面的合法切点。
- 状态转换与位置稳定目前是分开的：进入或保持 RESTING 并不自动保证几何姿态有效。

### 推荐方案

- 保留现有 `DECAYING / RESTING` 状态体系，不新增 `SETTLING` 状态。
- 增加轻量的 Resting settle 逻辑：当 Ball 满足低 Vitality、低速度并确认由 Ground 支撑时，将其收敛到稳定贴地位置。
- 稳定位置以 `ground_top - ball_radius` 为基准，并保留极小分离容差，避免持续处于穿透接触。
- settle 时清零向下的垂直速度；小幅水平运动可以按当前 RESTING 规则保留或衰减。
- 轻微 Wake 后未达到唤醒阈值的 Ball 仍可滚动或小幅移动，但再次停止时必须回到同一稳定落地约束。

目标是：RESTING 仍可被轻微推动，但最终必然收敛到合法、稳定、可重复的贴地姿态。

## 四、Paddle 直接位置移动缺少 sweep 检测

### 当前问题

Paddle 当前通过直接更新位置实现水平移动，没有检查 previous position 到 current position 之间的移动路径。

潜在影响：

- 高速移动时 Paddle 可能穿过 Ball，而没有形成预期碰撞；
- 玩家输入路径、视觉运动与实际碰撞采样可能不完全一致；
- 直接位移进入 Ball 时可能产生几何穿透，而不是从首次接触点开始结算。

### 已确认根因

Paddle 采用非物理、直接位置驱动设计；当前交互只依赖离散帧位置和场景碰撞，没有移动路径上的轻量 sweep。

### 推荐方案（后续候选）

保持 Paddle 为玩家输入驱动的非完整物理对象。未来若实际试玩仍出现高速漏碰或输入轨迹不一致，再增加轻量 sweep：

- 记录 `previous_position` 与 `current_position`；
- 仅对本帧移动路径上的 Ball 交互做检测；
- 不将 Paddle 改造为完整 PhysicsBody；
- 不把 sweep 扩展为通用力场或新的碰撞系统。

### 当前处置

本项只登记，不纳入当前优先修复范围。

## 五、暂不调整项

以下设计继续冻结，不在本轮问题处理记录中重构：

- Wake Impulse 核心设计；
- Surface Response 结构及结算时序；
- Vitality 模型；
- Paddle 作为玩家输入接口的定位；
- `ACTIVE / DECAYING / RESTING` 状态体系；
- 正常运动阶段的 Paddle Collision 语义。

Wake Impulse 当前口径保持：

- 进入 RESTING 后存在短暂不可响应窗口；
- 窗口结束后的新 Paddle 输入可以产生 Wake Impulse；
- 输入强度连续，但是否唤醒保持二元判断；
- 不足以唤醒时只允许轻微物理响应，并保持 RESTING；
- 达到阈值时退出 RESTING，恢复少量 Vitality，进入 DECAYING；
- Wake Impulse 只负责重新启动运动，不负责完整恢复 Vitality；
- 方向以向上为主，只继承少量 Paddle 水平运动方向。

## 六、推荐的后续统一处理顺序

以下仅为候选执行顺序，需取得后续实现授权后再进行：

1. 统一并上调 Paddle 的运行时固定高度，先消除静止几何重叠。
2. 补充 Resting settle，使低速落地最终收敛到稳定位置。
3. 增加 Ball safe bounds 与异常恢复，建立容器最终不变量。
4. 增加覆盖底部左右角、多重接触、轻微 Wake 后再落地的确定性测试。
5. 人工复测 Wake Impulse；不在上述修复中顺带调整其核心手感。
6. Paddle sweep 继续保留为后续独立问题，只有在几何和边界问题修复后仍能复现漏碰时再评估。

## 七、后续验收观察点

- Resting Ball 与 Paddle 默认无碰撞、无重叠。
- 在左右底角持续将 Paddle 抵向 Ball，Ball 不会离开 Game Area。
- 轻微 Wake 后 Ball 可以小幅移动，但重新落地时不存在稳定穿透。
- 强 Wake 的休息窗口、二元唤醒判断和少量 Vitality 恢复语义不变。
- 正常运动阶段的 Paddle Collision 与 Surface Response 行为不受影响。
- safe bounds 只在异常路径触发，不参与正常物理手感。

## 八、冻结结论

当前 V0.1.3 Wake Impulse 不继续扩展。优先问题是恢复合理的默认空间关系、稳定 RESTING 落地姿态，并为 Ball 建立不可恢复越界的最终保护。Paddle sweep 作为已知后续风险登记，暂不实施。

