# Bounce Lite Agent Governance

## 适用范围与当前状态

适用于本仓库全部子目录。当前阶段为 **V0.1.6 — Design Boundary Consolidation**。用户已授权 C1 修复、Combo 完整移除、Timer 转开发计数器、低风险健康度清理与文档归档；不新增玩法。当前设计依据为 [V0.1.6 Design Baseline](docs/design/design-baseline-v0.1.6.md)，实现和验证见 [收口报告](docs/reviews/v0.1.6-consolidation.md)。

用户已验收 V0.1.3（包括 Rest/Wake 修复），明确授权 V0.1.4：从 Kenney CC0 Audio 素材选择少量候选并接入当前事件，验证触发与叠音后交由用户实机试听。当前授权优先于历史禁止音频的阶段说明。

已确认版本记录与当前范围：

- V0.1.3：bug fixes + frozen visual presentation implementation。
- V0.1.4：basic audio feedback；已形成远端基线，方向已确认，Ground 最新音高待试听。
- V0.1.5：final investigation / final experience review；Paddle支撑与连续弱交互/离散强Wake已授权，总体体验已获用户验收，非碰撞Paddle闪动修复后关键回归通过。

- V0.1.6：Activity 通知不改物理；物理停稳后提交 RESTING。Combo 已移除；计时器仅为 F1 默认隐藏的开发观察工具。V0.2.0 未授权。

## 指令、授权与资料

在平台 system / developer 指令之下，项目判断采用：

current user instruction > current active repository documentation > historical / proposal material

- 用户当前直接请求优先于旧阶段文件、审查建议和技能工作流。
- 当前用户设计基线已正式归档至 docs/design/；新版本决定优先于历史审计建议。
- 当前有效文档见下方导航；Phase 0 和 V0.1/V0.1.2 计划仅保留历史基线。
- 参考图片、附件、审查意见和候选方案不自动构成执行授权。
- 在已授权范围内自主完成常规实现选择、相关修复、必要验证和文档同步，不逐项请求确认。
- 若需要扩大范围、改变已冻结设计契约、产品方向、技术路线、平台、分辨率、名称、验收标准或版本规划，暂停该项并说明冲突及依据；其他不受影响的工作继续。
- 机器测试与渲染证据不能替代用户体验验收。

## 开始与结束工作

开始前确认工作区路径、相关文件和 Git 状态；识别并保护用户已有修改，明确本次文件范围。编辑前读取文件当前内容。搜索及命令优先使用明确的仓库路径，避免依赖不可靠的默认目录。

结束前检查实际差异，确认没有越权修改或覆盖用户工作。报告实际修改、验证结果、未解决问题、人工试玩项及下一阶段启动判断。仅检查过历史记录时，不声称本轮测试通过。

## 当前产品与技术契约

- Project Name：Bounce Lite；UI Title：Bouncing Ball。
- Windows / Godot 4.7 / GDScript / Compatibility / 960×720 / 4:3 等比缩放。
- 放松型 Endless 数字玩具；鼠标控制 Paddle 水平运动；无固定局时、必败曲线或竞技压力。
- CharacterBody2D Ball、固定重力 260 px/s²、局部 signals；不引入 RigidBody2D、全局 Event Bus 或替代碰撞系统。
- Physics 与 Vitality 通过显式事件和响应交互；SurfaceResponseModel 使用碰撞前 Velocity/Vitality 计算普通响应，BallController 按 Velocity → Vitality delta → State 应用。Paddle 低能支撑与异常恢复为保留的明确物理入口。
- Activity 转换只更新状态并通知，不直接修改 Velocity、Position 或 Physics 状态。Ground/Paddle 物理停稳先应用运动与支撑结果，再提交 RESTING；Wake 可显式同时恢复活力与按需启动。
- configure() 只配置依赖，start_active() 显式开局；不得恢复隐式开局。Paddle 是 Surface + Interaction Medium，不是 Ball Controller。
- BallVitalityModel 只维护 Vitality 边界和状态，不持有 Surface 或速度公式。
- Vitality 保持在 [0, max]；正常玩法由碰撞改变，初始化及显式强 Wake 恢复为已确认的独立入口。
- 保留 ACTIVE / DECAYING / RESTING。Support独立于Activity；当前连续弱几何响应、离散Strong Wake与支撑契约见docs/v0.1.5-paddle-interaction.md，替代V0.1.3的速度映射。
- Paddle 固定高度、直接位置驱动；轻量 sweep 仅登记，未纳入本轮。
- safe bounds 仅用于异常恢复，不能代替正常 Surface Response；settle 不额外施加 Vitality 损耗或生成反弹。
- 不保留 Combo UI、计数、清零、成绩或对应规则测试。Timer 仅在默认隐藏的 F1 开发面板累计过程时间，不绑定 Activity/Vitality/Interaction，不因 RESTING 暂停或 Wake 归零；不持久化参数或观察时间。
- ball_radius 为物理圆与未形变 Core 的共享半径，paddle_size 为物理矩形与外观共享尺寸；场景形状与 tuning 必须一致，几何回归锁定此约束。

## 冻结视觉与范围

- Ball Core / Glow 表达 Vitality，保留 RESTING 固定底光与状态色的已验收特例；Trail 只表达 Velocity；Paddle Feedback 只来自真实碰撞。禁止合并为统一 activity 值。
- 荧光青 Ball、连续径向 Glow、离散时间采样 Trail、Paddle 瞬时反馈、Dark token 校准属于 V0.1.3 已授权范围。
- Ball 不使用独立事件亮暗脉冲；可保留瞬时几何 squash/stretch。
- Paddle 不使用常驻 Glow、edge line 或装饰层；约 140 ms 回到接近基础色，有限尾段完全清零。曲线口径见当前 spec。
- 视觉仍为运行时程序生成 GradientTexture2D，不生产正式位图或字体。V0.1.4使用少量Kenney CC0音效及已授权最小裁片，不建立正式素材生产流程。
- 不实现 Game Over、Classic、Recover、主题切换、Light 对象重设计、Paddle 分区、障碍物、排行榜、最高分、Vitality 数值条、复杂 Shader 或粒子。
- V0.1.4仅Paddle/Ground/Wake最小音频反馈，Wall低优先级。每事件最多2–3候选，保留原始来源与许可；不代替用户作听感决定。V0.1.5已授权上述交互修正；V0.2音频流程、正式混音、风格体系、动态音高、随机变体、材质音色和配乐不在当前范围。

## 文件、Git 与技能安全

- 不覆盖或撤销用户修改，不擅自删除、移动或重命名文件。本轮已明确授权 Combo 代码移除及文档归档；保留历史审计与探索素材。
- docs/design 为正式设计基线；docs/reviews 为项目审计资产；Claude outputs 为 AI 过程档案，保留视觉探索和生成记录。归档复制校验字节与 SHA-256，不重写历史报告。
- 保留 Reviewer、AI 来源及 Co-authored-by；不将临时会话 URL 写入新增文件或提交。已有 commit 的 Session 信息需单独授权历史处理，不以工作区清理冒充移除历史。
- 原始概念图仅可按授权复制；不覆盖、转码或移动；归档复制核对字节数与 SHA-256。
- 本地 Git 已批准；用户已授权首次推送到 https://github.com/Kandecho/Bounce-Lite.git。后续远端写操作仍以具体任务授权为准，不推送本地工具快照 refs。未经用户明确请求，不创建子 Agent、并行 Agent 或 worktree。
- 不为方便安装依赖或改变系统配置。
- 技能仅作为方法，不扩大授权；不默认启动完整 Superpowers 工作流。
- 文档与素材任务按需使用对应技能；代码实现不因技能存在而生成新视觉方向。
- 状态用“已确认、待确认、阻塞”等明确表述；区分已实现、机器已验证和人工待验收。
- 历史记录保留并加替代说明，不把旧方案改写成当时已执行的新决定。

## 当前有效文档与验证入口

- docs/README.md：文档生命周期与归档导航。
- docs/design/design-baseline-v0.1.6.md：当前设计判断依据；v0.1.x 原稿字节保留。
- docs/reviews/v0.1.6-consolidation.md：本轮实施、验证及已知限制；历史审计不回写。

- README.md：GitHub项目介绍、简短状态及运行入口。
- docs/v0.1.5-paddle-interaction.md：当前Paddle支撑、弱交互/Strong Wake契约、实施与验证。
- docs/v0.1.4-basic-audio.md：当前音频范围、候选、触发、验证与试听门。
- docs/project_overview.md：产品与已确认版本路线。
- docs/superpowers/specs/2026-09-09-v0.1.3-bugfix-visual-design.md：当前契约、几何、反馈通道及实施解释。
- docs/superpowers/plans/2026-09-09-v0.1.3-bugfix-visual-implementation.md：本阶段执行记录与验证命令。
- docs/visual_spec.md：冻结视觉目标；docs/asset_registry.md：对应实现登记。
- docs/development_notes.md：环境证据、变更与验证历史。
- docs/reviews/：历史审查及冻结问题证据；顶部状态与处置记录优先于旧建议。

改动确定性行为时先添加可复现回归，再实现修复；运行 tests/test_runner.gd。几何、Wake 或场景接线改动另跑 tests/test_physics_scenarios.gd；音频事件接线另跑 tests/test_audio_scenarios.gd。视觉改动执行 tests/capture_visual_baseline.gd 并检查截图。阶段结束运行 headless import 与主场景 1200 帧。纯文档修改检查差异、链接和状态一致性即可，不机械重跑全部测试。

Godot console 路径由本机 GODOT_CONSOLE 或忽略的 .local/godot.local.txt 提供，启动器也支持 PATH。自动化验证显式将 --log-file 指向仓库 .godot 下。

## 人工试听门

V0.1.3及V0.1.4历史验收保留；重力260保持。当前V0.1.5采用Support NONE/GROUND/PADDLE，低速低活力顶面停稳、不承载横移、失去支撑恢复重力。输入为新目标位移，200 px范围/0.12 s休息/50 ms窗口，初始阈值12.5 px。弱交互连续几何响应、不改速度/活力、不发Wake声；Strong一次恢复0.15活力，必要时固定向上350，不继承水平速度。原0.18/0.70冲量映射已由用户新指令取代。Paddle碰撞始终有效。用户已验收总体体验；Paddle只在真实碰撞时闪动，弱交互/Strong Wake均不触发Paddle闪动。V0.1.5 Paddle interaction model已收口；V0.1.6改动的机器验证与人工待复核项见收口报告。V0.2未授权。
