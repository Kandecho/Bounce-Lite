# Bounce Lite

> A video game with the tactile feel of a real toy.

Bounce Lite 是一个轻量的桌面数字玩具。移动鼠标控制挡板，接触一颗不断弹跳的球，观察它的运动、衰减与回应。

这里没有 Game Over，也没有必须坚持多久的压力。你可以连续接球，也可以看着它慢慢停下来，再拨弄一下，让它重新动起来。

## 核心体验

Bounce Lite 希望让屏幕中的互动拥有真实玩具的触感：操作简单，反馈清楚；玩家决定何时介入，球的后续运动由物理世界决定。

- **接住与弹起**：用挡板与球互动，观察真实接触后的反弹。挡板移动方向不直接传给球。
- **停下与唤醒**：球会逐渐失去活力、进入休息；在附近移动挡板，可以让它重新活动。
- **看见与听见反馈**：荧光青球体、光晕与残影呈现活力和运动，简短的电子音效回应弹起与落地。

它追求的是随手玩一会儿的轻松感，以及“再拨一下会怎样”的好奇心。

## 当前状态

当前分支为 **V0.2「共享小世界」可玩原型**。玩家通过挡板接触球，球可以拨动转子、改变局部气流、触碰补能对象；最近有互动时，短暂停顿后还可能继续一段。优先探索一个愿意停留几分钟的片段，没有加入设置界面或全量 UI。

分支 `codex/exp-v02-shared-world` 从已获用户实测认可的 E01 有限接触影响展开；main 仍为 V0.1.6。完整组合尚待用户体验，不自动合入 main。运行和检验细节见[原型记录](docs/exploration/v0.2-shared-world.md)。

F1 打开开发调参与 `DEV ELAPSED` 观察计数器；计数器持续累计，不因休息暂停或 Wake 归零，默认不显示在游戏画面。

详细进度与版本路线见[项目概览](docs/project_overview.md)。

## 运行试玩

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

使用 **Godot 4.7 / GDScript / Compatibility 渲染器**。画面以 960×720、4:3 为设计基准，窗口缩放时保持比例。画面由程序绘制；基础音效使用 Kenney 素材，世界事件使用原创合成音。

## 文档

- [main 设计基线](docs/design/design-baseline-v0.1.6.md)：V0.1.6 当前实现职责与边界。
- [V0.2 当前设计](docs/design/v0.2-full-prototype.md)与[原型记录](docs/exploration/v0.2-shared-world.md)：实施口径、实际机制、验证和待体验项。
- [V0.1.6 收口报告](docs/reviews/v0.1.6-consolidation.md)：改动、验证与保留限制。
- [文档导航](docs/README.md)：正式文档、审计与历史过程档案。
- [项目概览](docs/project_overview.md)：产品方向、版本路线与当前状态。
- [Paddle 与 Wake](docs/v0.1.5-paddle-interaction.md)：当前交互方案与试玩重点。
- [视觉规格](docs/visual_spec.md)：视觉语言与反馈设计。
- [基础音频](docs/v0.1.4-basic-audio.md)：声音方向、试玩操作与验证入口。
- [开发记录](docs/development_notes.md)：实现及验证历史。

## License / Third-party assets

代码及技术文档采用 [MIT License](LICENSE)。媒体资产的许可独立说明，见 [ASSET_LICENSE.md](ASSET_LICENSE.md)。

Kenney 音频素材采用 **CC0**；素材包、原始来源及裁片记录见 [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md)。概念参考图不包含在 MIT 授权中。
