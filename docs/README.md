# 文档导航与生命周期

## 当前入口（2026-10-01）

- [代理模型与执行纪律](../AGENTS.md#agent-execution-policy)：子代理统一6.1 Sol（`gpt-6.1-sol`），medium为执行选择，主代理保持当前配置；职责、审查触发、集成责任与可审计交付规则继续适用，历史配置保留真实归属。
- [第一批几何／机械集成记录](exploration/geometry-harvest-batch1.md#coexistence-result-20260930)：`fa099e4`已集成main，共存机器验证及动态证据通过，10月1日用户反馈体验良好。
- [分批集成与打磨方案](exploration/harvest-refinement-plan.md#portal-harvest-20261001)：第一批已通过用户试玩，第二批传送门已在实验分支实现并通过必要机器验证，待试玩；main保持79b9de0，砖块未启动。
- [物理电子玩具探索](exploration/physical-toy-exploration.md)：广度探索收获、实际试玩后的筛选决定及历史来源。
- [游乐场试玩记录](exploration/toybox-playtest.md)：正式反馈登记F01–F09及T01，区分准备解决、持续跟踪、已实施待验收与候选方案；原始反馈文件保持原文且未跟踪。
- [V0.2.0 实现基线](design/design-baseline-v0.2.0.md)：随机对象、真实动作资格、Wake/Continue 与现有底座。
- [V0.2.0 收口记录](reviews/v0.2.0-consolidation.md)：本轮验证、Git 状态和体验边界。

- [第二批传送门记录](exploration/portal-harvest-batch2.md)：已实现的成对门户、临时参数、模式／快照、机器验证及自然传送画面；待用户试玩。

下方保留旧版文档导航的历史状态描述；是否已实现以对应提交与实现记录为准，当前工作范围以最新方案和用户请求为准，历史停止要求不覆盖最新明确授权；新组合体验仍待人工判断。

## 正式项目文档

- [main 实现基线 V0.1.6](design/design-baseline-v0.1.6.md)：当前可玩实现的设计职责；原文保留，不作为 V0.2 探索机制的冻结清单。
- [用户原始 V0.1.x 基线](design/design-baseline-v0.1.x.md)：保留原始字节和版本，不随实施改写。
- [项目概览](project_overview.md)、[Paddle 交互](v0.1.5-paddle-interaction.md)、[基础音频](v0.1.4-basic-audio.md)：顶部当前说明优先，历史段落保留。
- [视觉规格](visual_spec.md)、[素材登记](asset_registry.md)：历史视觉基线与来源，顶部说明指向最新 UI 记录；历史 HUD 概念不代表当前实现授权。

## V0.2.0 原型阶段的设计、计划与现场（历史导航）

- [V0.2.0 Design Note](design/v0.2.0-design-note.md)：当前设计依据，包含不检测观看、固定 lifecycle、有效挡板动作、世界对象规则及后续顺序；其中建议和待探索项保留其状态。
- [后续实施计划](exploration/v0.2.0-follow-up-plan.md)：从 `793c361` 现场继续的任务、分工、参数决策方法与验证；本轮只落盘计划，不启动代码。
- [共享小世界实施记录](exploration/v0.2-shared-world.md)：按版本记录初版、中心色 UI、全客户区场地和检验证据；顶部当前快照优先于早期数值。
- [原创世界反馈](exploration/world-feedback-notes.md)：合成声音与视觉反馈的实现、来源和检验。
- [E01 接触语言](exploration/e01-contact-language.md)：有限影响经用户实测可以保留，作为本原型起点。
- [原始 V0.2 设计思路](design/design-idea-v0.2.0.md)：`793c361` 归档的历史来源，保留原始字节；与最新设计笔记冲突时不作为当前指令。
- [完整原型阶段口径](design/v0.2-full-prototype.md)：`3d9d402` 原型形成时的历史决定；后续新增约定以当前 Design Note 为准。
- [早期探索原则](design/v0.2-exploration-principles.md)与[逐项实验计划](exploration/v0.2-exploration-plan.md)：保留早期判断和候选，不再要求本轮逐项实施或逐项验收。

当前分支为 `codex/exp-v02-shared-world`，现场核对起点为 `793c361`。中心色 UI 与全客户区几何已实现；随机出现、Continue 动作资格和 Wake／Continue 表现交换尚未实现。最新组合仍待实机体验，main 游戏代码仍是 V0.1.6。历史文件保留路径并注明效力，不移动原稿或改写历史审计。

## 项目审计资产

[审计索引](reviews/README.md)记录 Reviewer、日期、范围和结论。历史报告只作不可回写的审查时点记录；最新实施结果见 [V0.1.6 Consolidation](reviews/v0.1.6-consolidation.md)。

## AI 协作过程与历史记录

`docs/superpowers/specs/`、`docs/superpowers/plans/` 保存阶段规格和执行过程；[development_notes.md](development_notes.md)保存环境与验证历史；`docs/history/` 保存早期计划。以版本和顶部替代说明判断生命周期，不把历史草案当成当前授权。

仓库实际目录名为 `Claude outputs/`，保持其作为忽略的本地 AI 协作过程档案；视觉探索图片、生成记录与原审查副本保留，无大规模移动。正式 Cross Review 已按原字节复制到 `docs/reviews/`，不会仅留在 AI 输出目录。原始概念与来源素材保持原位置与许可。

## 来源与公开信息

保留 Reviewer、AI 参与说明、Co-authored-by。新文件及未来提交不记录临时会话 URL。用户已单独授权清理历史提交 `dbf369a` 的临时 Session trailer；对应新提交 `a172cc2`，代码树和 AI 署名保留。可达历史检查无 Session trailer；范围与新旧提交映射见收口报告和审计索引。
