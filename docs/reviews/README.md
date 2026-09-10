# 审计与评审索引

历史报告反映审查时点，保留原文、结论和证据限制；不因后续修复重写。当前处置见实施报告。

V0.1.6 历史审计中的代码行号和源码链接对应审计基准 `0046ccc`；本轮已删除的 Rules / HUD 源码需在该提交中查阅，原报告不为适配当前工作区改写链接或结论。

| 文件 | Reviewer / 来源 | 日期 | 范围 | 当时结论 |
| --- | --- | --- | --- | --- |
| [V0.1.6 Codex Audit](v0.1.6-audit.md) | Codex | 2026-09-10 | V0.1.5 `0046ccc` 的 Physics / Interaction 与设计一致性 | 回归通过；C1 边界、Combo / Timer 等待处置 |
| [V0.1.6 Claude Cross Review](v0.1.6-cross-review.md) | Claude AI 协作输出；原稿 Reviewer 为“独立审查（非开发者）” | 2026-09-10 | V0.1.5 静态交叉审查；原稿明确未运行测试 | 提出职责、调度、几何、目标 UI 和长期体验风险；不是实施授权 |
| [V0.1.6 Consolidation](v0.1.6-consolidation.md) | Codex 实施与验证 | 2026-09-10 | 用户授权的边界收口、目标元素移除与文档归档 | 实际验证和保留限制见报告 |
| [V0.1.3 视觉同步审查](2026-09-08-v0.1.3-visual-sync-review.md) | 原稿署名保留 | 见原稿 | 历史视觉审查 | 以原稿及后续替代记录为准 |
| [V0.1.3 Wake 冻结问题](bounce-lite-v0.1.3-wake-impulse-frozen-issues.md) | 原稿署名保留 | 见原稿 | 历史 Wake 问题 | 已由后续版本处理的项目不再作为当前缺陷 |

## 归档校验

- Codex Audit：原文件已在正式目录，本轮保持原字节；SHA-256 `168277720A97B4115E692E52BEB751204164015194C08E9881625729D8EFC33B`。
- Claude Cross Review：从 `Claude outputs/v0.1.6-cross-review.md` 复制，原文件与其他过程档案保留；23697 bytes；SHA-256 `FB0868BD6A4B216BD9EE45179CBC2F7ADDDFBBFAC54B76510562B63CFC5496EC`。
- 用户原始基线：从已有 `docs/design-baseline-v0.1.6.md` 按原稿内容版本归档为 `docs/design/design-baseline-v0.1.x.md`；3987 bytes；SHA-256 `CDFB58B8A53D0BD72FE39725561D12F5C3F77F54315698761B9D554C62960D59`，与用户桌面原稿一致。

归档不改变原审查意见，也不抹除 AI 贡献。用户后续单独授权清理提交说明中的临时 Session trailer；只重写该说明及受影响父链，全部提交 tree、作者和 AI 署名保持。历史报告原字节不改。

## 发布时提交映射（2026-09-10）

| 原审查记录引用 | 清理后的可达提交 | 说明 |
| --- | --- | --- |
| `dbf369a` | `a172cc22fdee8c62f93277df724ca0fe45701263` | 仅删除 Session trailer，保留 Co-authored-by |
| `0046ccc` | `d524a441ad7c419ba27f9bce7a2db05d3bc0028c` | V0.1.5 同一代码树；父链更新 |

原审计中的源码行号仍按 V0.1.5 内容解读；查阅代码可使用清理后的对应提交。其余 4 个受影响提交仅因父链变化而变更哈希。
