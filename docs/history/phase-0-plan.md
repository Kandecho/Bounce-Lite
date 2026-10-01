# Bounce Lite Phase 0 - Project Setup & Visual Specification

本历史文件于2026-09-09从根目录迁入 docs/history/。下文目录树及路径保留当时记录；当前参考图统一位于 assets/concept/，当前状态见[README](../../README.md)。

## 0. 文档定位

本文件是 Bounce Lite 的 Phase 0 执行基线，用于把概念图转化为可追踪、可验收、可供后续 Agent 使用的生产规格。

本文件保存 Phase 0 的历史执行基线，不单独授权启动游戏开发。用户已在 Phase 0 完成后另行批准 V0.1 项目初始化；该批准不追溯改变本阶段原有边界。

项目名称：`Bounce Lite`

界面标题：`Bouncing Ball`

当前阶段：`Phase 0 - Project Setup & Visual Specification`

阶段状态：Phase 0 已于 2026-09-08 完成执行与验收；用户同日已通过人工确认门，批准进入 `V0.1 项目初始化`。

---

## 1. Phase 0 目标与边界

### 1.1 目标

Phase 0 完成以下工作：

1. 确认项目技术基线；
2. 完成 Godot 项目规划；
3. 归档并登记概念图；
4. 将概念视觉拆解为可测量的设计规格；
5. 建立完整素材规格登记体系；
6. 建立项目文档体系；
7. 判断是否具备进入 Bounce Lite V0.1 开发阶段的条件。

### 1.2 禁止事项

Phase 0 不得进入以下工作：

- Ball 实现；
- Paddle 实现；
- 碰撞系统；
- 游戏循环；
- 计时逻辑；
- 计分系统；
- 音效实现；
- 动画实现；
- 可玩 Demo；
- 正式素材生产；
- 未经确认的产品、技术或视觉范围扩展。

不得创建 `project.godot`、`*.gd`、`*.tscn`、`*.tres` 或其他 Godot 工程文件，除非用户在 Phase 0 结束后明确授权进入 V0.1。

### 1.3 人工确认门

Phase 0 完成后必须输出阶段报告并停止。只有用户明确确认可以进入 V0.1 后，才允许初始化 Godot 工程或制作游戏内容。

流程固定为：

> 概念图 → 生产规格 → 人工确认 → 正式制作

---

## 2. 已知输入与事实基线

### 2.1 当前输入

| 输入 | 当前路径 | 用途 |
| --- | --- | --- |
| Light 概念图 | `day-raw.png` | Light Theme 视觉参考 |
| Dark 概念图 | `night-raw.png` | Dark Theme 视觉参考 |
| Phase 0 计划 | `phase-0-plan.md` | 阶段范围与执行基线 |
| Agent 治理规则 | `AGENTS.md` | 工作边界与协作规则 |

两张概念图由用户提供。Phase 0 归档时必须复制，不能移动、覆盖或修改根目录中的原文件。

### 2.2 概念图尺寸

Concept Reference Resolution：

```text
1448 × 1086
```

比例：`4:3`

该尺寸只用于概念图测量与比例换算，不是实际运行分辨率。

---

## 3. 技术基线

### 3.1 Engine

候选安装位置：

```text
C:\Tools\Godot
```

Phase 0 只能对该位置进行只读核验，不得启动项目初始化。需要记录：

| 项目 | 要求 |
| --- | --- |
| Godot 可执行文件 | 记录实际完整路径 |
| 实际安装版本 | 以可执行文件报告的版本为准，不根据目录名推断 |
| Renderer | 推荐 `Compatibility`；若不采用，记录理由并请求确认 |
| Target Platform | 推荐 `Windows`；若增加其他平台，视为范围变更 |
| 操作系统 | 记录名称、版本与架构 |
| 辅助环境 | 记录 Python、Node 等已存在工具；不得为 Phase 0 擅自安装依赖 |
| 项目路径 | 记录规范化绝对路径 |
| Git 状态 | 记录是否为仓库、当前分支与工作区状态；不得擅自初始化 Git |

任何实际环境与推荐默认值不一致时，Agent 必须记录差异、影响和建议，不得静默更换技术路线。

### 3.2 画布与窗口规格

Game Design Resolution：

```text
960 × 720
```

设计与后续实现必须满足：

- 保持 `4:3` 设计比例；
- 支持窗口缩放；
- 采用等比缩放，禁止非等比拉伸；
- 非 4:3 窗口使用 letterbox 或 pillarbox 保留内容比例；
- 记录缩放策略、最小窗口尺寸、最大测试尺寸和高 DPI 处理原则；
- 概念图中的测量值同时记录源图像素、归一化比例和 960×720 设计像素。

建议的规格换算格式：

| 元素 | 源图边界框 | X/Y 归一化位置 | W/H 归一化尺寸 | 960×720 设计值 |
| --- | --- | --- | --- | --- |
| 示例元素 | `(x, y, w, h)` | `x/1448, y/1086` | `w/1448, h/1086` | `(x, y, w, h)` |

表中“示例元素”仅说明记录格式，不是资产条目。

---

## 4. 目标文件与目录责任

下列结构是 Phase 0 执行完成后的目标；本次计划修订不得提前创建其中的 `assets/`、`docs/`、`scenes/` 或 `scripts/`。

```text
Bounce Lite/
├── AGENTS.md
├── README.md
├── phase-0-plan.md
├── assets/
│   └── concept/
│       ├── light_mode/
│       │   └── day-raw.png
│       └── dark_mode/
│           └── night-raw.png
├── docs/
│   ├── project_overview.md
│   ├── visual_spec.md
│   ├── asset_registry.md
│   └── development_notes.md
├── scenes/                 # Phase 0 仅规划；V0.1 初始化后可为空目录
└── scripts/                # Phase 0 仅规划；V0.1 初始化后可为空目录
```

文件职责：

| 文件 | 单一职责 |
| --- | --- |
| `AGENTS.md` | 规定 Agent 的长期工作边界与治理原则 |
| `README.md` | 提供项目入口、当前阶段、技术基线摘要和文档导航 |
| `docs/project_overview.md` | 说明产品定位、阶段路线、角色分工与范围边界 |
| `docs/visual_spec.md` | 保存从概念图提取的布局、主题、UI、动效和可访问性规格 |
| `docs/asset_registry.md` | 为每个可独立实现的视觉元素建立唯一、可追踪的资产记录 |
| `docs/development_notes.md` | 保存环境证据、决策记录、偏差、风险和待确认事项 |

---

## 5. 概念图归档规则

### 5.1 归档映射

| 原文件 | 归档目标 | Theme | Motion State 证据 | 视觉基准 |
| --- | --- | --- | --- | --- |
| `day-raw.png` | `assets/concept/light_mode/day-raw.png` | Light | 图中 Ball 为 Moving | 是 |
| `night-raw.png` | `assets/concept/dark_mode/night-raw.png` | Dark | 单帧不足以确定 Idle 或 Moving | 是 |

Phase 0 执行归档时必须：

1. 保留原始文件名与文件内容；
2. 使用复制，不使用移动；
3. 记录来源为“用户提供”；
4. 记录用途、对应 Phase/版本、归档日期和是否作为视觉基准；
5. 记录原文件与副本的字节数及 SHA-256，确认二者一致；
6. 不进行裁切、压缩、调色、放大或格式转换。

### 5.2 Theme 与 Motion State 分离

主题和运动状态是两个独立维度：

```text
Theme
├── Light
└── Dark

Motion State
├── Idle
└── Moving
```

禁止把“日间概念图有拖尾”解释为“只有 Light Theme 才有拖尾”，也禁止把“夜间概念图未显示拖尾”解释为“Dark Theme 不允许拖尾”。

以下效果必须作为独立条目登记，并分别描述 Theme 与 Motion State：

- Ball Glow；
- Ball Trail；
- Particles。

概念图没有提供的组合只能标为待人工确认，Agent 不得从单帧自行推导产品规则。

---

## 6. 视觉规格要求

`docs/visual_spec.md` 必须把图像描述转化为可以测量和复核的规格，而不是只写主观风格词。

### 6.1 视觉拆解范围

至少拆解：

1. 外部环境背景；
2. Window Frame 与阴影；
3. Header；
4. Game Area 与边界；
5. Ball Core、Glow、Trail、Particles；
6. Paddle 本体与 Glow；
7. HUD Timer；
8. Start、Pause、Game Over 状态界面；
9. Footer、分隔线和标语；
10. Light/Dark 主题差异。

每项至少记录：

- 概念图定位；
- 源图边界框；
- 归一化位置和尺寸；
- 960×720 设计尺寸；
- 层级关系；
- 色彩 Token；
- 圆角、边框、阴影、模糊或发光参数方向；
- Theme 适用范围；
- Motion State 适用范围；
- 实现候选与选择依据；
- 当前状态和待确认事项。

### 6.2 色彩系统

分别建立 `Light Theme Token` 和 `Dark Theme Token`。至少覆盖：

- `background`：外部环境背景；
- `window`：主窗口与边框；
- `panel`：Game Area 与 HUD 容器；
- `text-primary`：标题和主要数值；
- `text-secondary`：版本号、页脚等次级文本；
- `ball-core`；
- `ball-glow`；
- `ball-trail`；
- `paddle-core`；
- `paddle-glow`；
- `hud-surface`；
- `hud-icon`；
- `focus-ring`；
- `overlay`：Start、Pause、Game Over 状态遮罩。

每个 Token 记录色值、透明度、使用场景和与相邻背景的对比度。正常文字以不低于 `4.5:1` 为目标；若艺术性次级文字未达到目标，必须标记风险并请求人工判断，不能静默接受。

### 6.3 UI 与排版

必须登记：

- 字体方向、候选字体、授权来源和回退字体；
- 标题字号、字重、字距和行高；
- Timer 容器、图标和数字规格；
- Timer 数字是否使用等宽或 tabular numerals；
- 如未来采用真实按钮，登记默认、悬停、按下、聚焦和禁用状态；状态界面采用纯文字时不得强行套用按钮外观；
- Start、Pause、Game Over 的信息层级；
- Footer 标语、分隔线和版本文本；
- Light/Dark 模式下的可读性差异。

命名关系固定为：

```text
Project Name: Bounce Lite
UI Title: Bouncing Ball
```

项目名与界面标题不是同一文案，文档不得混用。

### 6.4 交互元素

Header 中红、黄、绿三个 Traffic Light 默认定义为：

> 视觉装饰元素，不是真实窗口控制按钮。

因此它们不提供点击行为、不占用键盘焦点，也不应被辅助技术识别为按钮。若未来改为真实控制，属于交互范围变更，必须重新确认。

### 6.5 动效、可访问性与性能规格

Phase 0 只定义方向，不实现动效。`visual_spec.md` 必须登记：

- Ball Glow、Trail、Particles 的视觉职责和叠加顺序；
- 动效触发状态、持续时间方向和停止条件；
- Reduced Motion 模式下的替代方案；
- Reduced Transparency 模式下的清晰边框或不透明回退；
- 键盘焦点的可见性要求；
- 模糊、Glow、Trail 和 Particles 的性能风险与预算验证方法；
- 主题切换触发方式作为人工确认项，不由 Agent 自行决定。

---

## 7. 素材规格登记体系

`docs/asset_registry.md` 中的 A001-A005 只能作为编号示例，不能代表完整清单。

### 7.1 最小完整资产树

```text
Window
├── Environment Background
├── Window Frame
├── Header
│   ├── Traffic Light Decoration
│   ├── Title
│   └── Version Text
├── Game Area
│   ├── Surface
│   └── Border
├── Ball
│   ├── Core
│   ├── Glow
│   ├── Trail
│   └── Particles
├── Paddle
│   ├── Core
│   └── Glow
├── HUD
│   └── Timer
│       ├── Container
│       ├── Clock Icon
│       └── Digits
├── Start State
│   ├── Overlay
│   ├── Message
│   └── Action Control
├── Pause State
│   ├── Overlay
│   ├── Message
│   └── Action Control
├── Game Over State
│   ├── Overlay
│   ├── Message
│   └── Action Control
└── Footer
    ├── Divider
    └── Tagline
```

一个元素如果拥有独立的来源、实现方式、状态或主题差异，就必须单独登记，不能只依附在父级说明中。

### 7.2 登记字段

| 字段 | 规则 |
| --- | --- |
| Asset ID | 唯一且稳定的编号；废弃条目不复用编号 |
| 名称 | 与资产树名称一致 |
| 用途 | 说明视觉职责及交互职责 |
| 来源 | 概念图、用户提供、后续生成或程序化候选 |
| 来源版本 | 记录文件名、版本或生成批次；尚未生产时写 `Not Produced` |
| 视觉基准 | `Yes` 或 `No` |
| Theme | `Light`、`Dark` 或 `Shared` |
| Motion State | `Idle`、`Moving`、`Both` 或 `Not Applicable` |
| 尺寸比例 | 源图像素、归一化比例和 960×720 设计尺寸 |
| 颜色 | 引用 `visual_spec.md` 中的语义 Token |
| 实现候选 | `Sprite`、`UI`、`Shader`、`Particle`、`Procedural` 等；候选不等于已批准方案 |
| 状态 | `待拆解`、`待设计`、`待确认`、`已确认` 或 `阻塞` |
| 备注 | 依赖、风险、授权、可访问性或性能说明 |

Phase 0 验收时，概念图中已出现的元素不得保留为 `待拆解`；所有 `待确认` 和 `阻塞` 条目必须写明问题、影响和确认人。

---

## 8. 项目文档要求

### 8.1 `README.md`

必须包含：

- Bounce Lite 项目简介；
- Project Name 与 UI Title 的区别；
- 当前阶段与状态；
- Phase 0 目标及禁止事项；
- 技术基线摘要；
- 设计分辨率；
- 文档导航；
- 当前不存在可运行 Godot 项目的明确说明。

在 `project.godot` 实际存在前，不得编写虚假的运行或构建说明。

### 8.2 `docs/project_overview.md`

必须包含：

- 产品定位与核心体验；
- 目标用户和使用场景；
- Phase 0、V0.1 及后续阶段的边界；
- 用户与 Agent 的职责；
- 已确认产品文案；
- 技术路线摘要；
- 人工确认门。

### 8.3 `docs/visual_spec.md`

必须覆盖本计划第 5、6 节的归档解释、测量体系、布局、色彩、UI、主题、动效、可访问性和性能规格。

### 8.4 `docs/asset_registry.md`

必须覆盖本计划第 7 节的完整资产树、字段定义和逐项登记结果。

### 8.5 `docs/development_notes.md`

必须包含：

- Phase 0 环境核验记录及证据；
- 决策日志：日期、决策、依据、确认人和影响；
- 与推荐默认值的偏差；
- 技术风险、视觉风险和后续开发风险；
- 待确认事项及阻塞级别；
- Phase 0 工作日志。

该文件不得包含尚未获批的游戏实现方案或把建议写成既定决定。

---

## 9. Phase 0 执行顺序

### Task 1：工作区与治理检查

- [x] 阅读根目录 `AGENTS.md` 和本计划；
- [x] 列出已有文件并记录用户修改；
- [x] 检查 Git 状态；若不是仓库，只记录事实，不初始化；
- [x] 确认本次执行获准创建的文件范围。

产出：清晰的工作区基线，无文件被覆盖或移动。

### Task 2：技术环境只读核验

- [x] 核验候选 Godot 路径与实际版本；
- [x] 记录 Renderer 和 Target Platform 的建议值；
- [x] 记录操作系统、辅助环境和项目路径；
- [x] 将证据与差异写入 `docs/development_notes.md`。

产出：技术基线明确，但没有 Godot 工程文件。

### Task 3：概念图归档

- [x] 建立规定的 Light/Dark 归档目录；
- [x] 复制两张原图；
- [x] 核对字节数和 SHA-256；
- [x] 登记来源、用途、版本和视觉基准状态。

产出：可追溯、未修改的概念图副本。

### Task 4：视觉规格拆解

- [x] 以 1448×1086 为测量基线；
- [x] 换算 960×720 设计尺寸和归一化比例；
- [x] 建立 Light/Dark Token；
- [x] 分离 Theme 与 Motion State；
- [x] 登记 UI、动效、可访问性和性能要求；
- [x] 将不能从概念图确定的产品决定列为人工确认项。

产出：`docs/visual_spec.md`。

### Task 5：素材规格登记

- [x] 按最小完整资产树逐项建档；
- [x] 为每项分配稳定 Asset ID；
- [x] 填写尺寸、颜色、主题、状态和实现候选；
- [x] 检查所有概念元素均有对应记录；
- [x] 对待确认或阻塞项写明影响与确认人。

产出：`docs/asset_registry.md`。

### Task 6：文档体系完成

- [x] 完成 `README.md`；
- [x] 完成 `docs/project_overview.md`；
- [x] 补全 `docs/development_notes.md`；
- [x] 检查四份项目文档互相引用且术语一致。

产出：完整、可导航的 Phase 0 文档体系。

### Task 7：验收与人工确认

- [x] 按第 10 节执行验收；
- [x] 输出第 11 节规定的阶段报告；
- [x] 明确给出 V0.1 启动判断；
- [x] 停止并等待用户确认。

产出：Phase 0 完成报告，不包含任何开发实现。

---

## 10. Phase 0 验收标准

### 10.1 工程规划

- [x] Godot 实际安装版本已通过只读方式核验；
- [x] Renderer、Target Platform 和设计分辨率已明确；
- [x] 窗口缩放与 4:3 保持策略已记录；
- [x] 目录结构及各文件职责已确定；
- [x] Git 状态已记录，未因本阶段被擅自初始化；
- [x] 不存在 `project.godot` 或其他新建 Godot 工程文件。

### 10.2 文档

- [x] `README.md` 完成；
- [x] `docs/project_overview.md` 完成；
- [x] `docs/visual_spec.md` 完成；
- [x] `docs/asset_registry.md` 完成；
- [x] `docs/development_notes.md` 完成；
- [x] `AGENTS.md` 与本计划不存在范围冲突；
- [x] 文档中的路径、命名、版本和状态一致。

### 10.3 视觉

- [x] 两张概念图已复制归档并验证内容一致；
- [x] 所有概念元素均已登记；
- [x] 所有概念元素均有尺寸比例；
- [x] 所有概念元素均引用颜色 Token；
- [x] 所有概念元素均有实现候选；
- [x] Theme 与 Motion State 已独立登记；
- [x] Light/Dark 对比度风险已记录；
- [x] Reduced Motion 与 Reduced Transparency 方向已记录；
- [x] 未生产正式素材。

### 10.4 边界

- [x] 无 Ball、Paddle 或碰撞实现；
- [x] 无游戏循环、计时或计分逻辑；
- [x] 无音效或动画实现；
- [x] 无可玩 Demo；
- [x] 无未经确认的范围扩展；
- [x] 所有未决事项均写明影响、责任人与是否阻塞 V0.1。

任一必需项未满足时，Phase 0 可以报告当前进度，但不得宣称已具备进入 V0.1 的条件。

---

## 11. Phase 0 完成汇报格式

```markdown
## 已完成

- 文件：
- 文档：
- 规格：

## 未完成

- 缺失信息：
- 待确认事项：

## 风险

- 技术风险：
- 视觉风险：
- 后续开发风险：

## 启动判断

是否具备进入 Bounce Lite V0.1 开发阶段的条件：是 / 否

依据：

阻塞原因（如不具备）：
```

报告输出后必须停止，等待人工确认。

---

## 12. 已确认决定与人工确认项

### 已确认决定

- 项目名为 `Bounce Lite`；
- 界面标题为 `Bouncing Ball`；
- Traffic Light 是视觉装饰，不是窗口控制；
- Concept Reference Resolution 为 1448×1086；
- Game Design Resolution 为 960×720；
- 设计比例为 4:3；
- Renderer 默认建议为 Compatibility；
- Target Platform 默认建议为 Windows；
- Phase 0 只产出基线、归档、规格和文档，不产出游戏实现。

### 必须由 Phase 0 记录或请求人工确认

- Godot 可执行文件的实际路径和版本；
- 主题切换由系统、手动选择还是其他条件触发；
- Start、Pause、Game Over 状态的最终视觉；
- 字体选择及授权来源；
- 未达到目标对比度的艺术性文字是否保留；
- Glow、Trail、Particles 的最终实现路线；
- 是否以及何时初始化 Git；
- 是否批准进入 Bounce Lite V0.1。

---

## 最终原则

Phase 0 的任务不是制作游戏，而是：

> 将一个视觉概念转化为可执行、可追踪、可验收的游戏开发规格。

优先保证边界明确、事实有证据、视觉有规格、未决事项有负责人，并在进入正式制作前取得人工确认。
