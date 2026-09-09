# Bounce Lite

轻量休闲桌面数字玩具。**V0.1.3 已获用户验收；V0.1.4 Basic Audio Feedback 已形成首次远端基线。** 无 Game Over 或主题切换。

- Project Name：Bounce Lite；窗口标题：Bouncing Ball。
- Godot 4.7.stable.official.5b4e0cb0f / GDScript / Compatibility。
- Windows，960×720，4:3；非 4:3 窗口等比缩放并留边。

## 已确认版本路线

| 版本 | 范围 | 状态 |
| --- | --- | --- |
| V0.1.3 | bug fixes + frozen visual presentation implementation | 已获用户验收 |
| V0.1.4 | basic audio feedback | 基础方向已确认；回归通过；Ground 最新音高待试听 |
| V0.1.5 | final investigation / final experience review | 路线已确认；未启动 |

当前用户指令优先于当前有效仓库文档；历史计划与审查建议不覆盖当前决定。

## 当前实现

- CharacterBody2D Ball、独立 Physics / Vitality、统一 Surface Response。
- ACTIVE / DECAYING / RESTING；Ground 清零 Combo 并耗损 Vitality，不终止游戏。
- 重力已按用户试玩结论设为 260 px/s²，改善整体纵向活动范围。
- RESTING 后等待约 0.12 s；中心距离 200 px 内的实际 Paddle 运动触发 Wake。弱输入最多采样 50 ms，强输入立即响应；连续冲量为 (vx×0.18, −abs(vx)×0.70)。
- Paddle 始终参与真实碰撞：让开可顺利跃起，挡住起跳路径会正常碰撞；无碰撞例外、随机冲量或必达顶板要求。
- 弱输入只轻推并保持 RESTING；强输入增加 0.15 最大 Vitality，默认进入 DECAYING；再次在 Ground 停稳后重新开放输入；Paddle 支撑适配尚未实现。
- Paddle Y=537，与稳定落地 Ball 保留约 3 px 间隙；Ground settle、越界异常恢复及 Ball 绘制层级已修复。
- 荧光青 Core、连续 Vitality Glow、固定时间采样离散 Velocity Trail。
- Paddle 有效/无效接触和强弱 Wake 的瞬时反馈，无常驻 Glow。
- Dark panel 校准为 #171C26；仅 Combo / Timer HUD；F1 临时调参，不保存；调试面板位于独立 CanvasLayer 10，统一覆盖游戏对象。

音频采用 Kenney CC0 Digital Audio / Sci-fi Sounds：Paddle pepSound3 弹起、Strong Wake 同类更强弹起、Ground 短促下沉；Weak Wake 无专门音效，Wall/Top 已接入低音量反馈。详见[当前音频基线](docs/v0.1.4-basic-audio.md)。

不包含其他模式、排行榜、Paddle 分区、障碍物、正式图片/字体、正式音频系统、复杂 Shader 或粒子。

## 运行与验证

双击 [run-playtest.bat](run-playtest.bat) 试玩；鼠标水平控制 Paddle，F1 打开开发调参面板。弱/强 Wake 按输入冲量区分，不再使用旧的“持续快速移动 80 ms”手势。

F2/F3 分别切换 Paddle/Ground A/B，F4 显示唯一 Strong Wake 候选，F5 静音比较，F6 切换 Wall A/B。新选择在下一次真实事件播放，不保存。

Godot 编辑器可直接打开 project.godot。命令行/双击启动器依次读取 `GODOT_CONSOLE` 环境变量、被忽略的 `godot.local.txt` 中的完整可执行路径，或 PATH 中的 godot_console.exe / godot.exe。机器路径不写入共享脚本。

在仓库根目录运行（先设置本机 `GODOT_CONSOLE`）：

~~~powershell
$repo = (Get-Location).Path
$godot = $env:GODOT_CONSOLE
New-Item -ItemType Directory -Force "$repo/.godot" | Out-Null
& $godot --headless --log-file "$repo/.godot/tests.log" --path $repo --script res://tests/test_runner.gd
& $godot --headless --fixed-fps 60 --log-file "$repo/.godot/physics.log" --path $repo --script res://tests/test_physics_scenarios.gd
& $godot --headless --fixed-fps 60 --log-file "$repo/.godot/audio.log" --path $repo --script res://tests/test_audio_scenarios.gd
~~~

本次基线回归：确定性381、物理场景803、音频场景38 checks 通过；headless import 与主场景1200帧退出0。环境仍报告根证书存储/编辑器用户配置保存错误，未出现脚本或场景错误。V0.1.3 视觉截图属于前轮证据，本轮未改视觉。

## 已确认与待判断

用户已验收 V0.1.3；音频加入后的改善、Paddle / Strong Wake / Wall 当前方案通过，Ground A 可用。最新 Ground 固定音高1.5尚无单独试听确认；需判断整体音区和重复播放舒适度。

Paddle Resting Support 保持 pending / investigation：当前没有统一支撑 Surface 状态，Ground settle 才会复位 Wake 消费；Paddle 支撑时的静止、移开与唤醒尚未适配。现有高速 Paddle sweep、configure 开局副作用也未扩展修复。加速 headless 退出曾报告资源仍占用，普通1200帧复查未复现，清理时序保持 investigation。没有把这些问题标记为已完成功能。

V0.1.5 与 V0.2 未启动。

## License 与资产

代码、测试、场景配置、启动器及技术文档采用 [MIT License](LICENSE)，允许第三方商业使用，也保留作者商业发行的选择。媒体资产不默认随代码采用 MIT，边界见 [ASSET_LICENSE.md](ASSET_LICENSE.md)。

Kenney 音频保留各自 CC0；三个包、全部已入库候选、原文件与裁片来源见 [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md)。概念 PNG 是用户提供的参考，未授予再使用权，其上游权利状态待核实。

## 文档导航

- [AGENTS.md](AGENTS.md)：治理与授权边界。
- [项目概览](docs/project_overview.md)：产品及已确认版本路线。
- [当前 V0.1.3 设计](docs/superpowers/specs/2026-09-09-v0.1.3-bugfix-visual-design.md)。
- [当前 V0.1.3 实施与验证](docs/superpowers/plans/2026-09-09-v0.1.3-bugfix-visual-implementation.md)。
- [视觉规格](docs/visual_spec.md)、[资产登记](docs/asset_registry.md)、[开发记录](docs/development_notes.md)。
- [冻结问题及处置](docs/reviews/bounce-lite-v0.1.3-wake-impulse-frozen-issues.md)、[历史视觉审查](docs/reviews/2026-09-08-v0.1.3-visual-sync-review.md)。
- [Phase 0](phase-0-plan.md) 与 docs/superpowers 中 V0.1/V0.1.2 文件仅作为历史基线。

原始 day-raw.png / night-raw.png 及 assets/concept 中归档副本保持不变；它们是参考证据，不是运行时素材。
