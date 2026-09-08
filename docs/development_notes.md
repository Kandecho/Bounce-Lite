# Bounce Lite Development Notes

## 1. 记录范围

本文件记录 Phase 0 与 V0.1 项目初始化的环境证据、决策、偏差、风险和待确认事项。它不包含游戏实现，也不把未来候选方案视为已经授权。

记录日期：`2026-09-08`

时区：`Asia/Shanghai`

## 2. 工作区基线

| 项目 | 事实 |
| --- | --- |
| 项目路径 | `D:\hangk\Documents\Bounce Lite` |
| 初始文件 | `AGENTS.md`、`phase-0-plan.md`、`day-raw.png`、`night-raw.png` |
| Git | 本地仓库；`main` 分支；不设置远端 |
| Git 操作 | 用户已批准 `git init`；不创建 worktree、不推送 |
| 项目状态 | 存在最小 `project.godot`；没有 main scene、脚本或可玩内容 |

## 3. Engine 与辅助环境证据

### Godot

候选目录存在：

```text
D:\Apps\Godot_v4.7-stable_win64
```

发现的可执行文件：

```text
D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64.exe
D:\Apps\Godot_v4.7-stable_win64\Godot_v4.7-stable_win64_console.exe
```

只读版本查询结果：

```text
4.7.stable.official.5b4e0cb0f
```

两个可执行文件均以退出码 `0` 完成版本查询。未启动 Godot 编辑器，未创建工程。

### 系统

| 项目 | 检测值 |
| --- | --- |
| OS | Microsoft Windows 10.0.26200 |
| OS Architecture | X64 |
| Process Architecture | X64 |
| PowerShell | 7.6.5 |
| Native Argument Passing | Windows |
| Python | 3.14.5 |
| Python Launcher | `C:\Users\hangk\AppData\Local\Programs\Python\Launcher\py.exe` |
| Node | v24.15.0 |
| Node Executable | `C:\Program Files\nodejs\node.exe` |

Python 的当前环境未安装 Pillow；Phase 0 没有安装依赖，而是使用系统图像 API 完成只读采样。

## 4. 概念图归档证据

| Theme | 原文件 | 归档副本 | Bytes | SHA-256 | 结果 |
| --- | --- | --- | ---: | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` | 1,174,596 | `52E4759BA7D8A47AD74E76567263340319522EBE0C1B83EA6C0F0B66762821B3` | 一致 |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` | 995,996 | `A68E6CF40E567B83FD73BDBDF0C23C31AEC85EDC40091D6045B4FB6D1C01D406` | 一致 |

原文件未移动、覆盖、裁切、压缩、调色或转码。

## 5. 已确认决策

| 日期 | 决策 | 依据 / 确认人 | 影响 |
| --- | --- | --- | --- |
| 2026-09-08 | Project Name 为 `Bounce Lite` | 用户直接要求 | 用于目录、工程和文档 |
| 2026-09-08 | UI Title 为 `Bouncing Ball` | 用户直接要求 | 用于窗口标题，两种名称不得混用 |
| 2026-09-08 | Traffic Light 为装饰 | 用户直接要求 | 无点击、焦点或窗口控制语义 |
| 2026-09-08 | Concept Reference 为 1448×1086 | 源图测量与用户要求 | 只用于分析和换算 |
| 2026-09-08 | Game Design Resolution 为 960×720 | 用户确认的计划 | 4:3、等比缩放 |
| 2026-09-08 | Renderer 默认 Compatibility | 用户确认的计划 | V0.1 初始化时复述并写入 |
| 2026-09-08 | Target Platform 默认 Windows | 用户确认的计划 | 其他平台属于范围变化 |
| 2026-09-08 | Phase 0 不创建 Godot 工程 | 用户确认的边界 | 停止在规格和文档阶段 |
| 2026-09-08 | Start/Pause/Game Over 使用极简文字 UI | 用户直接确认 | 无按钮边框、卡片或复杂面板；层级由排版与透明度表达 |
| 2026-09-08 | 字体优先 Inter / Noto Sans | 用户直接确认 | 使用开源方案；正式发布前复核实际字体文件授权 |
| 2026-09-08 | 目标用户为轻量休闲桌面小游戏用户 | 用户直接确认 | 产品定位不以竞技或长局压力驱动 |
| 2026-09-08 | 核心体验为可随时开始/结束的放松数字玩具 | 用户直接确认 | 不设置固定单局时长目标 |
| 2026-09-08 | 鼠标水平控制 Paddle；键盘非 V0.1 必需输入 | 用户直接确认 | 输入设计以桌面鼠标为基线 |
| 2026-09-08 | 难度不单调递增，也不制造必然失败阶段 | 用户直接确认 | 允许低强度随机速度、轨迹、事件或不确定性变化 |
| 2026-09-08 | V0.1 不包含排行榜、最高分压力或连续生存挑战 | 用户直接确认 | 竞技目标排除在当前版本范围外 |
| 2026-09-08 | V0.1 不实现主题切换，只保留 Light/Dark 规格 | 用户直接确认 | 不建立主题切换状态或设置入口 |
| 2026-09-08 | Light 次级文字按可读性调整 | 用户直接确认 | Version/Footer Token 加深为 `#5E7190` |
| 2026-09-08 | Glow / Trail 路线在开发阶段确定 | 用户直接确认 | 初始化阶段不选择 Shader、Sprite 或 Particle 路线 |
| 2026-09-08 | 进入 V0.1 项目初始化；建立本地 Git 且无远端 | 用户直接确认 | 允许创建最小工程和目录骨架，不授权玩法实现 |

## 6. 视觉分析记录

### 已验证事实

- 两张图均为 1448×1086、4:3；
- Light 图明确显示四段淡蓝拖尾，属于 `Light + Moving` 证据；
- Dark 图没有可见拖尾，但单帧不能证明 Dark Theme 禁用拖尾；
- Light Paddle 的高饱和核心区域约为 `232×28 px`；
- Dark Paddle 的高饱和核心区域约为 `220×26 px`；
- Light 标题代表色 `#1E2E46` 对 `#F5F9FE` 约 `12.95:1`；
- Light 版本文字代表色 `#7689A5` 对 `#F5F9FE` 约 `3.37:1`；
- Light Timer 数字代表色 `#536A93` 对 `#F5FAFE` 约 `5.19:1`；
- Light Footer 代表色 `#667A9F` 对 `#FEFEFF` 约 `4.30:1`；
- Dark 标题 `#FFFFFF` 对 `#242B37` 约 `14.23:1`；
- Dark 版本文字 `#AAAFBB` 对 `#242B37` 约 `6.48:1`；
- Dark Timer `#FFFFFF` 对 `#252B35` 约 `14.23:1`；
- Dark Footer `#A4A9B2` 对 `#282D37` 约 `5.85:1`。

色值来自概念图指定像素或区域极值，只作为概念参考。透明、模糊和背景混合会改变最终显示，V0.1 必须在实际渲染中重新测量。

### 风格决策

本地 UI/UX 规则检索将 Claymorphism、Liquid Glass 和 Soft UI Evolution 列为近邻方向。概念图并没有 Claymorphism 常见的 3–4 px 厚边框和强烈双阴影，因此视觉规格采用：

> 克制的 Soft UI Evolution + 有限透明/玻璃感

Liquid Glass 只作为材质语言参考，不要求实现折射或复杂动态玻璃。该选择减少性能风险，并更贴近概念图的细边框、柔和阴影和留白。

## 7. 与推荐默认值的偏差

| 项目 | 推荐 | 当前事实 | 偏差 |
| --- | --- | --- | --- |
| Godot | 4.x / 指定安装目录 | 4.7 stable 已核验 | 无 |
| Renderer | Compatibility | 尚无工程，未写入配置 | 无事实偏差；待 V0.1 落地 |
| Platform | Windows | 当前系统为 Windows x64 | 无 |
| Design Resolution | 960×720 | 已写入规格 | 无 |
| Git | 建立本地版本基线 | 本地 `main` 仓库、无远端 | 无 |
| 图像分析 | 可使用 Pillow | 当前 Python 无 Pillow | 无阻塞；未安装依赖，使用系统 API |

## 8. 待确认事项

| ID | 事项 | 当前结论 | 确认人 | 对 V0.1 的影响 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Q001 | 主题切换触发方式 | V0.1 不实现主题切换；保留双主题设计规格 | 用户 | 无切换状态或设置入口 | 已确认 |
| Q002 | Start/Pause/Game Over 最终视觉 | 极简文字 UI，无按钮边框、卡片或复杂面板 | 用户 | 视觉方向已解除阻塞；交互映射另行规划 | 已确认 |
| Q003 | 字体家族与授权 | 优先 Inter / Noto Sans；发布前复核实际文件授权 | 用户 | 字体方向已解除阻塞；字体资产尚未引入 | 已确认 |
| Q004 | Light 次级文字对比度 | Version/Footer 使用 `#5E7190` | 用户 | 代表对比度达到 4.5:1 目标 | 已确认 |
| Q005 | Glow/Trail/Particles 实现路线 | 在玩法开发阶段通过视觉/性能验证确定 | 用户 + V0.1 技术评估 | 不阻塞项目初始化 | 延后到开发阶段 |
| Q006 | Git 初始化时间 | V0.1 项目初始化时建立本地仓库，不设置远端 | 用户 | 建立本地版本基线 | 已确认 |
| Q007 | 目标用户、单局节奏、输入方式 | 休闲桌面用户；无固定时长；鼠标水平控制 Paddle；键盘非必需 | 用户 | 已建立玩法规划约束 | 已确认 |
| Q008 | 概念图 `v0.1` 文案规则 | 与正式构建版本绑定 | 用户 | 影响版本显示和发布流程 | 待确认 |

## 9. 风险登记

### 技术风险

- Glow、模糊和透明层过多可能增加 Compatibility Renderer 下的填充率成本；V0.1 需用目标硬件测量帧时间。
- 概念图是完整合成图，不能直接拆成独立运行时资产；背景、窗口和效果层仍需在正式制作阶段重建。
- 项目当前没有 main scene；初始化验证只能证明配置可加载，不能证明玩法或导出可用。

### 视觉风险

- 概念图中的 Light Version/Footer 原色低于 4.5:1；实现 Token 已加深，但仍需在实际字体、字号和合成背景下复测。
- Light 与 Dark 图中的窗口框位置和尺寸存在少量像素差异，不能把两个合成图直接当作严格布局模板；应使用统一设计网格。
- Dark 图缺少拖尾只代表单帧状态，错误地按主题禁用拖尾会破坏 Theme/Motion 分离。
- Start、Pause、Game Over 的极简方向已确认，但具体字号、透明度和间距仍需在完整 UI 中视觉校准。

### 后续开发风险

- Timer 当前只显示 `00:12`，尚未确认它表示倒计时、正计时还是局内时长。
- Paddle 输入已确认为鼠标水平移动；Ball 速度范围、失误条件和单局结束条件仍未定义，后续不得用单调递增制造必然失败。
- 字体家族方向已批准，但具体字体文件、版本和许可证尚未归档，标题、Timer 和 Footer 的最终宽度仍需实测。
- 随机或低强度动态变化若没有概率上限、冷却或可读性约束，仍可能意外形成不可处理阶段；玩法规格需建立约束与验证指标。

## 10. Phase 0 工作日志

| 日期 | 任务 | 结果 |
| --- | --- | --- |
| 2026-09-08 | 读取治理与计划 | 完成 |
| 2026-09-08 | 检查工作区和 Git | 完成；非 Git 仓库，未初始化 |
| 2026-09-08 | 核验 Godot 与辅助环境 | 完成；Godot 4.7 stable、Python 3.14.5、Node 24.15.0 |
| 2026-09-08 | 归档 Light/Dark 概念图 | 完成；大小与 SHA-256 一致 |
| 2026-09-08 | 视觉规则与像素分析 | 完成；结果写入 `visual_spec.md` |
| 2026-09-08 | 资产登记 | 完成；结果写入 `asset_registry.md` |
| 2026-09-08 | 最终验收 | 完成；文件、目录、哈希、资产表、文档结构和禁止产物检查通过 |
| 2026-09-08 | 用户通过 Phase 0 人工确认门 | 完成；Q002、Q003、Q007 及相关主题/可读性/Git 决策已确认 |
| 2026-09-08 | V0.1 项目初始化 | 完成；创建最小工程、空目录、Git 规则与本地 `main` 仓库 |
| 2026-09-08 | Godot 配置加载验证 | 完成；Godot 4.7 headless editor 退出码 `0` |

## 11. Phase 0 启动判断

Phase 0 规格与文档工作：`完成`。

是否具备进入 Bounce Lite V0.1 项目初始化的条件：`是`，且用户已明确批准。

当前结果：

- `Q002`、`Q003`、`Q007` 已由用户确认并写入规格；
- `Q001`、`Q004`、`Q006` 已确认；
- `Q005` 的决策时点已确认，技术路线延后到获批的开发任务；
- 已建立 Godot 4.7 / Compatibility / Windows / 960×720 / 4:3 基线；
- 已建立本地 `main` Git 仓库，远端为空；
- 没有 main scene、玩法脚本、正式素材或可玩 Demo。

是否具备直接进入 V0.1 玩法实现的条件：`尚未判定`。项目初始化授权不包含玩法实现；需要下一任务明确范围、状态流、Timer 语义和验收标准。

## 12. V0.1 初始化证据

| 项目 | 结果 |
| --- | --- |
| `project.godot` | 已创建；无 `run/main_scene` |
| Design Resolution | `960×720` |
| Resize / Stretch | Resizable；`canvas_items`；Aspect `keep` |
| Renderer | `gl_compatibility` |
| 项目元数据 | Project Name `Bounce Lite`；UI Title 规格 `Bouncing Ball` |
| Godot 验证 | `4.7.stable.official.5b4e0cb0f` headless editor 加载成功，退出码 `0` |
| Git | 本地 `main` 仓库；无远端 |
| 禁止产物检查 | 无 `*.gd`、`*.tscn`、`*.tres`、音频或新制正式素材 |

说明：Godot 的 `application/config/name` 同时用于项目名并默认影响原生窗口标题。当前工程保持 Project Name 为 `Bounce Lite`，另以项目元数据登记 UI Title `Bouncing Ball`；实际窗口标题将在获批的主窗口实现中显式设置，初始化阶段不为此创建脚本。
