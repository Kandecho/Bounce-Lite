# 实现与兼容边界

本页说明当前模块如何承担产品契约；产品目的见[概览](project_overview.md)，候选和暂定选择见[计划](exploration/harvest-refinement-plan.md)。精确参数以源码为权威，不在文档复制完整常数表。

## 代码入口

| 模块 | 维护职责 |
| --- | --- |
| [Main](../scripts/main.gd) | 默认模式、命令行对照、场景实例及显式接线 |
| [Ball](../scripts/ball/ball_controller.gd)、[表面响应](../scripts/physics/surface_response_model.gd) | 运动、碰撞、支撑、请求提交和安全恢复 |
| [Paddle](../scripts/paddle/paddle_controller.gd)、[节奏资格](../scripts/ball/play_rhythm.gd) | 实际挡板动作采样、Wake及Continue资格 |
| [共享tuning](../scripts/config/prototype_tuning.gd) | 运动尺度及基础物理／交互阈值；限速与反馈标尺分别表达 |
| [原世界](../scripts/world/play_world.gd) | 转子、能量块、随机生命周期和可用包络 |
| [几何族](../scripts/world/geometry_toys.gd) | 六类几何／机械接触、持球与支撑、完整运动包络 |
| [门户](../scripts/world/portal_toys.gd)、[砖族](../scripts/world/brick_toys.gd) | 各自稳定动作、有限生命周期、生成和快照校验 |
| [共享占用](../scripts/world/spawn_occupancy.gd) | 查询注册对象的本体包络，不维护机制类型枚举 |
| [试玩控制](../scripts/world/geometry_playground.gd) | 种子、模式、重开和组合保存／恢复 |

## 维护时应保护的行为

Wake由附近真实挡板动作触发；Continue由有效接触或附近定向动作授予一次机会，球停稳后消费。Wake消费旧Continue机会，启动先提交运动再通知状态；挡板底面仍有真实碰撞。相关阈值和运动档位应同时核对，不能把底座1×速度当成默认fast模式的实际速度。

几何普通表面、主动弹射与移动表面分别响应，机械动作时长不随运动倍数机械缩放。弹簧释放沿共享发射与限速规则，保留有上限的部分横速；平台支撑或弹簧持球期间保持关系连续，结束后再离场。

门户仅在完整active阶段沿球实际走过的无阻挡路径触发；入口前的实体优先阻挡，传送后不结算被跳过的碰撞。出口不安全就拒绝，不改球位置、速度或冷却。传送保持世界坐标中的速度方向，清除不连续拖影和旧支撑；休息与弹簧持球期间不传送，同对冷却还要求离开双口后才解锁。

普通砖两次不同有效接触裂／碎；反向砖首次拼合、再次强碎，拼合期间碰撞可靠但不消费第二次；脆砖一次即碎。持续压住、同帧或未离开范围的重复接触不重复计数。拼合不重置寿命，碎片只是有界视觉反馈。

![普通碎片、反向砖与脆砖的形态对照](exploration/images/brick-refinement-fragment-language-comparison.png)

受控实际运动画面：左为普通砖碎片，右为带柔光的反向初始碎片，下方为脆砖。此图用于解释形态，不证明随机频率或声音体验。

## 生成与恢复

跨族本体占用默认互相避让，外围场力可重叠；几何运动包络、门户双口、转子核心和能量块均参与。生成、激活复查、组合恢复使用一致边界，无合法位置就有限重试后延迟，不强制重叠。

默认组合为外层v4／`coexistence-bricks`，砖子格式v2；旧砖v1接受时保留其原生成规则，R／N重新开始才回到当前规则。旧门户v3、几何／共存v2需在对应模式使用，跨模式或无效数据在修改世界前拒绝。F9恢复对象及随机进度后安全发球，球接触锁与瞬时反馈重置；快照不等于完整输入重播。

## 验证证据的边界

回归保护当前契约，场景专项保护实际接线，受控捕获检查具体事件，自然片段观察可达性和节奏；各自不能替代另一个，也不能替代人的长期体验。开放缺陷及其状态只见[问题登记](exploration/toybox-playtest.md#feedback-register)，运行入口见[开发说明](development.md)。
