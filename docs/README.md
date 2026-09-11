# 文档导航与生命周期

## 正式项目文档

- [main 实现基线 V0.1.6](design/design-baseline-v0.1.6.md)：当前可玩实现的设计职责；原文保留，不作为 V0.2 探索机制的冻结清单。
- [用户原始 V0.1.x 基线](design/design-baseline-v0.1.x.md)：保留原始字节和版本，不随实施改写。
- [项目概览](project_overview.md)、[Paddle 交互](v0.1.5-paddle-interaction.md)、[基础音频](v0.1.4-basic-audio.md)：顶部当前说明优先，历史段落保留。
- [视觉规格](visual_spec.md)、[素材登记](asset_registry.md)：冻结视觉与来源；历史 HUD 概念不代表当前实现授权。

## V0.2 完整可玩片段原型

- [当前设计与实施口径](design/v0.2-full-prototype.md)：充分展开原型的授权、两项设计硬边界，以及高推理主代理检验／低推理子代理实现的协作方式。
- [共享小世界实施记录](exploration/v0.2-shared-world.md)：当前分支的接触、转子余波、补能、停顿与继续，以及验证和试玩入口。
- [原创世界反馈](exploration/world-feedback-notes.md)：合成声音与视觉反馈的实现、来源和检验。
- [E01 接触语言](exploration/e01-contact-language.md)：有限影响经用户实测可以保留，作为本原型起点。
- [早期探索原则](design/v0.2-exploration-principles.md)与[逐项实验计划](exploration/v0.2-exploration-plan.md)：保留早期判断和候选，不再要求本轮逐项实施或逐项验收。

当前分支为 `codex/exp-v02-shared-world`。用户已授权自主修改机制和视听，优先完整可玩片段，不追求设置和全量 UI。整体体验尚待用户试玩；main 仍为 V0.1.6 可玩基线。历史文档中的未授权、冻结和独立实验要求按当时时点理解，以当前设计口径为准。

## 项目审计资产

[审计索引](reviews/README.md)记录 Reviewer、日期、范围和结论。历史报告只作不可回写的审查时点记录；最新实施结果见 [V0.1.6 Consolidation](reviews/v0.1.6-consolidation.md)。

## AI 协作过程与历史记录

`docs/superpowers/specs/`、`docs/superpowers/plans/` 保存阶段规格和执行过程；[development_notes.md](development_notes.md)保存环境与验证历史；`docs/history/` 保存早期计划。以版本和顶部替代说明判断生命周期，不把历史草案当成当前授权。

仓库实际目录名为 `Claude outputs/`，保持其作为忽略的本地 AI 协作过程档案；视觉探索图片、生成记录与原审查副本保留，无大规模移动。正式 Cross Review 已按原字节复制到 `docs/reviews/`，不会仅留在 AI 输出目录。原始概念与来源素材保持原位置与许可。

## 来源与公开信息

保留 Reviewer、AI 参与说明、Co-authored-by。新文件及未来提交不记录临时会话 URL。用户已单独授权清理历史提交 `dbf369a` 的临时 Session trailer；对应新提交 `a172cc2`，代码树和 AI 署名保留。可达历史检查无 Session trailer；范围与新旧提交映射见收口报告和审计索引。
