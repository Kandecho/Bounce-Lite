# Bounce Lite

> A video game with the tactile feel of a real toy.

Bounce Lite 是一个物理电子玩具。移动鼠标控制挡板，让球与机关碰撞、停下、再次活动。一个玩的动作，不需要积分、奖励、任务或长期收益来证明它值得发生。

main已集成第一批几何／机械，后续在 `codex/harvest-geometry` 开发：单球、圆形弹跳器、三角侧踢、斜面、平台、弹簧、摆板。机关随机出现、停留和离场，允许同类并存，由实际物理产生组合。

**当前按 [harvest + refinement](docs/exploration/harvest-refinement-plan.md) 逐批集成**：每批完成后更新文档、停止并等待人工检查。第一批记录见[几何／机械集成](docs/exploration/geometry-harvest-batch1.md)。第二批传送门已按10月1日用户授权在实验分支启动，第三批普通砖／反向砖尚未启动；结构由长期试玩后决定，场力、多球与抓球保留原实验成果。

**当前进度**：2026-10-01 当前状态：第一批几何与原有转子／能量块共存已在 `fa099e4` 实现并本地快进合入main；旧main `f792d3b` 和纯几何停点 `287ac0c` 保留可返回。默认单球六类几何与转子／能量块共同运行，纯几何及底座对照仍可用。1.5×速度／2.25×重力与弹簧0.20秒／50%有上限横速此前已获用户试玩通过；独立亮边已撤下，其余球形变、声音层次及Vitality变暗保留。2026-10-01用户已反馈共存版“集成后体验良好”；现按原计划在 `codex/harvest-geometry` 启动第二批传送门，main保持 `79b9de0`，砖块未启动。 [集成范围与证据边界](docs/exploration/harvest-refinement-plan.md#portal-harvest-20261001)。

## 核心体验

Bounce Lite 希望让屏幕中的互动拥有真实玩具的触感：操作简单，反馈清楚；玩家决定何时介入，球的后续运动由物理世界决定。

- **接球与改变球路**：鼠标移动挡板，真实接触保留E01的有限影响；静态表面自然反射，主动机关与机械运动提供不同的碰撞回应。
- **停下与唤醒**：球会逐渐失去活力、进入休息；在附近移动挡板，可以让它重新活动。
- **看见与听见反馈**：明亮球核心、青色光晕与残影呈现活力和运动；挡板在实际传递活力后变暗，简短音效回应碰撞与世界事件。

它追求的是随手玩一会儿的轻松感，以及“再拨一下会怎样”的好奇心。

## 当前状态

协作规则见[代理模型与执行纪律](AGENTS.md#agent-execution-policy)：用户指定子代理统一6.1 Sol（`gpt-6.1-sol`），主代理保持当前方案；子代理medium为本轮执行选择。实现代理负责验证闭环，主代理审查约束、风险与需求。

**可返回的 V0.2.0 原main基线**：代码提交 `e905580`，合入记录 `f792d3b`。球、挡板、Vitality、随机转子和能量块、Wake/Continue 已完成收尾。

**第一批 `codex/harvest-geometry` 已以 `fa099e4` 集成main**，从原main选择性迁入几何／机械、随机生命周期、专用碰撞声音及种子／快照入口。原游乐场留在 `codex/exp-physical-toybox`：固定代码 `6f31ea7`、随机代码 `4947b67`。它仍可用于多球、抓球和场力实验，操作与旧验证见[游乐场试玩记录](docs/exploration/toybox-playtest.md)。

从已获用户实测认可的 E01 展开，中心色 UI、全客户区场地、随机对象、真实动作资格及 Wake／Continue 强弱与表现均已实现。默认窗口640×480。底座行为见[V0.2.0 基线](docs/design/design-baseline-v0.2.0.md)，其验证见[收口记录](docs/reviews/v0.2.0-consolidation.md)。已发生的用户试玩结论见[试玩记录](docs/exploration/toybox-playtest.md)，当前refinement安全停点与待体验项见第一批记录。

上一轮已主动借鉴弹球和物理游戏机制，制作可玩组合；来源与交付见[物理玩具探索](docs/exploration/physical-toy-exploration.md)。接下来按[分批集成与打磨方案](docs/exploration/harvest-refinement-plan.md)收获这些成果，玩法本身无需依赖积分、奖励、任务或长期收益。

F1 打开开发调参与 `DEV ELAPSED` 观察计数器；计数器持续累计，不因休息暂停或 Wake 归零，默认不显示在游戏画面。

详细进度与版本路线见[项目概览](docs/project_overview.md)。

## 纯几何运动A/B对照

- [1×运动对照](run-motion-current.bat)
- [1.5×运动对照（重力×2.25）](run-motion-fast.bat)

两个入口均为纯几何对照，默认同一随机种子184；窗口标题与日志标明profile。两档都使用本轮弹簧动作，1.5×也是无参数启动的默认尺度，挡板均保持y570。寿命、生成与机械时间不机械倍乘。2×强对照保留在 `60e3516`；本轮生效参数、快照兼容和证据见[弹簧停点记录](docs/exploration/geometry-harvest-batch1.md#spring-refinement-15x)。

## 运行第一批试玩

配置下述Godot路径后，双击 [run-playtest.bat](run-playtest.bat) 或在编辑器按F5，进入单球几何／机械与原有转子、能量块的默认共存场景。[run-geometry.bat](run-geometry.bat) 显式使用 `--geometry-only`，保留原单球纯几何对照。

- 鼠标移动挡板，接球或在休息球附近拨动挡板。
- R按当前种子重开场景，N换种子。
- F8保存机关组合，F9恢复组合后安全重新发单球。
- H显示开发快捷键；F1调参、F5静音、F7切换E01沿用。

启动参数 `--geometry-only` 选择纯几何，`--geometry-baseline` 返回V0.2.0底座，`--geometry-fixed` 使用六类机关的固定开发对照，`--geometry-seed=184` 使用指定种子。直接调用 Godot 时，把这些参数放在 `--` 之后。同种子仍受输入与合法生成重试影响，快照更适合保存已经出现的组合；新的几何快照与旧游乐场快照区分类型。

指定几何种子开始试玩：

```powershell
.\run-geometry.bat --geometry-seed=184
```

仓库附带[初版自然演化30秒的几何快照](docs/exploration/snapshots/geometry-batch1-184-30s.json)，仅适用于 `ee6b25b` 的version1对照。refinement更改机械与生成规则，旧快照不能静默作为新版组合加载；当前version2组合还必须包含匹配的motion_profile和 `rules=spring-200ms-lateral50-motion150`；旧规则或另一档记录会被拒绝，需回原版本打开。共存快照另含 `world_mode=coexistence` 及原世界对象、随机源和计时状态；纯几何为 `geometry-only`，缺少模式的旧version2按纯几何处理，仅纯几何入口接受。共存最近快照保存在 `.godot/geometry-snapshots/latest-coexistence.json`，纯几何仍为 `latest.json`，两个入口不覆盖彼此。R／N在共存模式同步重开两族对象；F9恢复组合后安全发球，快照不是球轨迹、输入或F1设置的完整重播。

### 使用 Godot 编辑器

1. 准备 Godot **4.7 stable**。
2. 下载或克隆本仓库，在 Godot 中导入根目录的 `project.godot`。
3. 打开工程，按 **F5** 启动游戏。

游戏中左右移动鼠标控制挡板；球停下后，在附近拨动挡板尝试唤醒它。游戏内 **F5** 切换全部音效静音，**F7** 切换有限接触影响；F7 只改变之后的接触，不重置世界。

### 使用 Windows 启动器

配置好 Godot 路径后，可直接双击 [run-playtest.bat](run-playtest.bat)：

- 设置 `GODOT_CONSOLE` 环境变量为 Godot 可执行文件的完整路径；或
- 创建 `.local/godot.local.txt`，在第一行填写该完整路径（不加引号）；或
- 将名为 `godot_console.exe` 或 `godot.exe` 的程序加入 PATH。

本地路径配置不会提交到 Git。开发调参与音效对比操作见[音频试玩说明](docs/v0.1.4-basic-audio.md)。

## 技术栈

使用 **Godot 4.7 / GDScript / Compatibility 渲染器**。逻辑视口为 960×720，默认窗口为 640×480，窗口缩放时保持 4:3。画面由程序绘制；基础音效使用 Kenney 素材，世界事件使用原创合成音。

## 文档

- [V0.2.0 实现基线](docs/design/design-baseline-v0.2.0.md)：当前底座；[V0.1.6 基线](docs/design/design-baseline-v0.1.6.md)保留为历史对照。
- [V0.2.0 当前设计](docs/design/v0.2.0-design-note.md)、[后续计划](docs/exploration/v0.2.0-follow-up-plan.md)与[原型记录](docs/exploration/v0.2-shared-world.md)：分别说明判断依据、待实施任务和实际验证。
- [V0.1.6 收口报告](docs/reviews/v0.1.6-consolidation.md)：改动、验证与保留限制。
- [文档导航](docs/README.md)：正式文档、审计与历史过程档案。
- [项目概览](docs/project_overview.md)：产品方向、版本路线与当前状态。
- [V0.1.5 Paddle 与 Wake](docs/v0.1.5-paddle-interaction.md)：历史交互基准，当前差异见原型记录。
- [视觉规格](docs/visual_spec.md)：视觉语言与反馈设计。
- [基础音频](docs/v0.1.4-basic-audio.md)：声音方向、试玩操作与验证入口。
- [开发记录](docs/development_notes.md)：实现及验证历史。

## License / Third-party assets

代码及技术文档采用 [MIT License](LICENSE)。媒体资产的许可独立说明，见 [ASSET_LICENSE.md](ASSET_LICENSE.md)。

Kenney 音频素材采用 **CC0**；素材包、原始来源及裁片记录见 [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md)。概念参考图不包含在 MIT 授权中。
