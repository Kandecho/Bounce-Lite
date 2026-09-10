# Bounce Lite Asset Registry

## V0.1.6 生命周期说明（2026-09-10）

当前默认画面无 Combo 或时间 HUD；旧 Combo／HUD Timer／结果 UI 的规格和素材登记仅保留历史参考，不再作为当前生产要求。时间累计只在默认隐藏的 F1 开发面板显示 `DEV ELAPSED`，没有 Wake reset 或 RESTING pause。Ball / Glow / Trail / Paddle 的已验收外观不改。当前语义见 [V0.1.6 基线](design/design-baseline-v0.1.6.md)，变更见 [收口报告](reviews/v0.1.6-consolidation.md)。


## 1. 登记规则

本登记表记录视觉元素的生产规格，不代表对应文件已经生产。Phase 0 不制作正式素材。

- Asset ID 永久唯一，删除或废弃的编号不复用；
- 一个元素只要具有独立来源、Theme、Motion State、实现方式或状态，就单独登记；
- `状态` 表示规格决策状态，不表示运行时素材已经存在；
- `来源版本 = Not Produced` 表示尚无正式运行时资产；
- 实现候选不是技术路线批准；
- 所有 `待确认` 或 `阻塞` 条目在备注中写明问题、影响和确认人。

状态词：

| 状态 | 含义 |
| --- | --- |
| `待拆解` | 尚未从参考资料中识别或测量 |
| `待设计` | 已知需要该元素，但概念资料未提供足够视觉信息 |
| `待确认` | 已有建议，等待用户或指定负责人确认 |
| `已确认` | Phase 0 规格事实或用户明确决定已经记录 |
| `原型实现` | 已有程序化验证实现，但不是正式素材或最终视觉 |
| `阻塞` | 未决事项会阻止完整 V0.1 状态或资产工作 |
| `已废止` | 该元素已被设计决定移除；编号保留不复用 |

尺寸格式：`Source BBox → 960×720 Design BBox`。`≈` 表示合成图测量，容限为 ±4 source px。

## 2. 概念参考登记

| Reference ID | Theme | 原始文件 | 归档副本 | 来源 | 对应版本 | 视觉基准 | SHA-256 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| REF001 | Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` | 用户提供 | Phase 0 / 2026-09-08 | Yes | `52E4759BA7D8A47AD74E76567263340319522EBE0C1B83EA6C0F0B66762821B3` |
| REF002 | Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` | 用户提供 | Phase 0 / 2026-09-08 | Yes | `A68E6CF40E567B83FD73BDBDF0C23C31AEC85EDC40091D6045B4FB6D1C01D406` |

## 3. 完整资产树

```text
Window
├── Environment Background
├── Window Shadow
├── Window Surface
├── Window Frame Border
├── Header
│   ├── Traffic Light Decoration
│   │   ├── Red
│   │   ├── Yellow
│   │   └── Green
│   ├── Title
│   └── Version Text
├── Game Area
│   ├── Surface
│   └── Border
├── Ball                          (Vitality 通道 + Velocity 通道)
│   ├── Core
│   ├── Glow
│   ├── Resting State
│   ├── Trail
│   ├── Squash / Stretch
│   └── Particles                 (不使用)
├── Paddle                        (Interaction 通道)
│   ├── Core
│   ├── Interaction Flash
│   ├── Contact Disturbance
│   └── Glow                      (已废止)
├── HUD
│   ├── Combo Text
│   └── Timer
│       ├── Container
│       ├── Clock Icon
│       └── Digits
├── Start State
│   ├── Transparent Layout Layer
│   ├── Title
│   └── Start Prompt
├── Pause State
│   ├── Transparent Layout Layer
│   ├── Status Text
│   └── No Visible Secondary Action
├── Game Over State
│   ├── Transparent Layout Layer
│   ├── Result Text
│   └── Restart Prompt
└── Footer
    ├── Region
    ├── Divider
    └── Tagline
```

## 4. 逐项登记

### 4.1 Window 与 Header

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A001 | Environment Background | 提供环境、景深和主题氛围 | REF001/REF002 合成图 | Not Produced | Yes | Light/Dark | Not Applicable | `(0,0,1448,1086) → (0,0,960,720)` | `light.background-*` / `dark.background-*` | Theme-specific TextureRect；预处理 Blur；简化渐变 | 待设计 | 问题：无独立背景图层；影响：不能直接作为运行时资产；确认人：用户 |
| A002 | Window Shadow | 从环境中分离主窗口 | REF001/REF002 合成效果 | Not Produced | Yes | Light/Dark | Not Applicable | 约包围 Window 外 20–35 design px | 主题阴影，不作为不透明色 | StyleBox Shadow 或低成本 9-slice | 待确认 | 问题：Blur/扩散值无法反解；影响：性能与层级；确认人：用户 + V0.1 技术验证 |
| A003 | Window Surface | 主窗口表面 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(238,123,973,828) → (158,82,645,549)` | `light.window` / `dark.window` | Control/Panel + StyleBox | 已确认 | 统一 Light/Dark 几何；不使用主题独立布局 |
| A004 | Window Frame Border | 主窗口细边界 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | 同 A003；目标 1–2 design px | `light.panel-border` / `dark.panel-border` | StyleBox border 或 9-slice | 已确认 | 14–16 design px 外圆角；Reduced Transparency 时保持清晰 |
| A005 | Header Region | 承载装饰、标题和版本 | REF001/REF002 | Not Produced | Yes | Shared geometry | Not Applicable | `≈(238,123,973,74) → (158,82,645,49)` | 继承 Window Token | Control 容器 | 已确认 | 内容垂直居中；无独立 Header 纹理要求 |
| A006 | Traffic Light Red | 纯视觉装饰 | REF001/REF002 | Not Produced | Yes | Shared | Not Applicable | `≈(266,151,20,20) → (176,100,13,13)` | `traffic.red` | 程序化圆形 / UI | 已确认 | 无点击、焦点或状态语义 |
| A007 | Traffic Light Yellow | 纯视觉装饰 | REF001/REF002 | Not Produced | Yes | Shared | Not Applicable | `≈(300,151,20,20) → (199,100,13,13)` | `traffic.yellow` | 程序化圆形 / UI | 已确认 | 无点击、焦点或状态语义 |
| A008 | Traffic Light Green | 纯视觉装饰 | REF001/REF002 | Not Produced | Yes | Shared | Not Applicable | `≈(333,150,20,21) → (221,99,13,14)` | `traffic.green` | 程序化圆形 / UI | 已确认 | 无点击、焦点或状态语义 |
| A009 | Header Title | 显示游戏窗口标题 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(383,150,143,24) → (254,99,95,16)` | `*.text-primary` | Label + Inter / Noto Sans | 已确认 | 文案固定为 `Bouncing Ball`；字体文件在制作阶段引入并登记许可证 |
| A010 | Version Text | 显示版本 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(1146,151,40,21) → (760,100,27,14)` | `*.text-secondary` | Label | 待确认 | 问题：`v0.1` 是否绑定正式构建版本；影响：版本展示规则；确认人：用户 |

### 4.2 Game Area、Ball 与 Paddle

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A011 | Game Area Surface | 承载玩法对象和 HUD | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(258,197,933,682) → (171,131,619,452)` | `light.panel` / `dark.panel` | Control/Panel + StyleBox | 已确认 | 统一几何；8–10 design px 圆角 |
| A012 | Game Area Border | 标记玩法内容安全区 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | 同 A011；目标 1–2 design px | `light.panel-border` / `dark.panel-border` | StyleBox border | 已确认 | 对象效果默认不溢出到 Header/Footer |
| A013 | Ball Core | 核心运动对象视觉 | REF001/REF002 | Not Produced | Yes | Shared core | Both | Light `≈50×50 → 33×33`；Dark `≈46×46 → 31×31`；目标直径约 32 | 见 `visual_spec.md` §8.5 | 程序化抗锯齿圆形 | 已确认 | 荧光青系，H 189 恒定，S/V 随 Vitality；概念图白球已被取代。图中位置是快照，不是固定出生位置 |
| A014 | Ball Glow | 将 Ball 与背景分离并提供反馈 | REF001/REF002 合成效果 | Not Produced | Yes | Light/Dark | Both | Light 视觉包络约 55–60 design px；Dark 更低强度 | 见 `visual_spec.md` §8.5 | 运行时径向渐变贴图 + `draw_texture_rect`，无 Shader | 已确认 | **只表达 Vitality**。峰值在 `d=1.0r`，`(1-t)^1.6` 衰减至 `1.75r`，包络 56 px。V0.1.3 已实现连续径向贴图，见 §8.2 |
| A015 | Ball Trail | 表达移动方向和速度 | REF001 明确；REF002 未显示 | Not Produced | Yes | Light/Dark | Moving | Light Envelope `≈(602,359,134,111) → (399,238,89,74)`；约四段 | 固定为满 Vitality 的 Glow 色 | 离散残影，与 Glow 共用同一张径向渐变贴图 | 已确认 | **只表达 Velocity**。固定时间采样 `0.085 s`，`n ≤ 4`，间距 `max(speed × 0.085, 18)`。V0.1.3 已实现离散残影，见 §8.2 |
| A016 | Ball Particles | 可选碰撞/运动强调 | 概念图没有可确认独立层 | Not Produced | No | Light/Dark | Moving candidate | 未出现；尺寸由未来事件规格决定 | 引用 Ball Effect Token | 不使用 | 已确认 | 三通道模型中没有 Particles 的位置；不实现 |
| A017 | Paddle Core | 玩家控制对象视觉 | REF001/REF002 | Not Produced | Yes | Light/Dark | Both | Light `232×28 → 154×19`；Dark `220×26 → 146×17`；统一目标约 `150×18` | `paddle.idle` 见 `visual_spec.md` §8.5 | `Control/StyleBox` 或程序化矩形 | 已确认 | 胶囊形，圆角 9。常态为低明度基础色 `#45786E`，**不表达任何状态**；概念图 `#60F1BF` 已被取代 |
| A018 | Paddle Glow | ~~强调 Paddle 和可控性~~ | REF001/REF002 合成效果 | Not Produced | No | 不适用 | 不适用 | 不生产 | 不适用 | 不实现 | 已废止 | `2026-09-08` 用户决定：Paddle 不使用常驻 Glow。Paddle 表达输入事件而非自身状态，常驻发光层会把它从轻交互接口推成独立 UI。替代项见 A035 / A036；编号保留不复用 |
| A035 | Paddle Interaction Flash | 表达“刚刚发生了一次输入” | 用户 V0.1.3 决定 | Not Produced | No | Neutral | 仅事件瞬间 | 覆盖 Paddle 本体 `150×18` | `paddle.flash` 见 `visual_spec.md` §8.5 | 本体色 lerp，`τ = 55 ms` 衰减 | 待设计 | 有效接球 1.00 / 无效接触 0.28 / Wake 弱 0.15–0.45 / Wake 强 0.85。必须在约 140 ms 内完全退回基础色 |
| A036 | Paddle Contact Disturbance | 定位“打在哪里” | 用户 V0.1.3 决定 | Not Produced | No | Neutral | 仅事件瞬间 | 两段 `22 px` 亮段，行程 `14 → 60 px`；冲击刻度 `7 px` | `paddle.disturbance` 见 `visual_spec.md` §8.5 | `draw_line` 覆盖绘制 | 待设计 | 明度必须高于 A035 的本体闪光，否则峰值帧不可见 |

| A037 | Ball Resting State | 表达“仍然存在，但进入等待状态” | 用户 V0.1.3 决定 | Not Produced | No | Neutral | RESTING | 同 A013 / A014 几何 | 见 `visual_spec.md` §8.5 RESTING 行 | Core 低饱和低明度 + Glow 状态地板 | 待设计 | Glow 地板 `0.25` **必须是状态常量，不得由 Vitality 推导**；休眠期 Vitality 会衰减趋近于零。呼吸式调制为后续可选项，非 V0.1.3 必需。见 `VL001` |
| A038 | Ball / Paddle Squash Stretch | 碰撞瞬间的形变手感 | V0.1.1 起已存在于实现，本次补登记 | Not Produced | No | Neutral | 仅事件瞬间 | Ball 按法线方向压缩；Paddle 全局 `(1.09 x, 0.80 y)` | 不引用颜色 Token | `draw_set_transform` | 待确认 | 自 V0.1.1 起实现但一直未登记。Paddle 的形变在 18 px 高的条上仅约 `3.6 px`，实测几乎不可见；是否保留见 `VL002` |

### 4.3 HUD Timer

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A019 | Timer Container | 提供 Timer 稳定背景 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(990,220,180,62) → (656,146,119,41)` | `light.hud-surface` / `dark.hud-surface` | Control/Panel + StyleBox | 已确认 | 正式视觉规格保留；V0.1 极简 HUD 不绘制容器 |
| A020 | Clock Icon | 说明 Timer 语义 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(1017,236,28,28) → (674,156,19,19)` | `light.hud-icon` / `dark.hud-icon` | 矢量 Path、程序化 Line2D 或统一图标资产 | 已确认 | 正式视觉规格保留；V0.1 极简 HUD 不绘制图标 |
| A021 | Timer Digits | 显示当前活跃时间 | REF001/REF002 + 用户规则 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(1069,236,74,28) → (709,156,49,19)` | `light.text-hud` / `dark.text-hud` | V0.1：纯文字 Label，`TIME MM:SS` | 原型实现 | 从最近一次 Wake/Active 到 Rest 正计时；不参与失败、难度或成绩目标 |
| A034 | Combo Text | 提供轻量连续接球反馈 | 用户 V0.1 规则 | Not Produced | No | Neutral prototype | Not Applicable | 左上纯文字；当前字号 17 design px | V0.1.3 使用 `dark.text-secondary` | V0.1：纯文字 Label，`COMBO N` | 原型实现 | Paddle 命中 +1；Ground 清零；无排行榜或奖励系统 |

### 4.4 Start State

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A022 | Start Transparent Layout Layer | 承载开始状态文字而不新增可见面板 | 用户确认 | Not Produced | No | Light/Dark | Idle | 覆盖 Game Area `(171,131,619,452)`；仅作为布局区域 | 无独立表面 | 透明 Control 容器 | 已确认 | 不绘制 Overlay、卡片或复杂面板 |
| A023 | Start Title | 显示游戏标题 | 用户确认 | Not Produced | No | Light/Dark | Idle | 居中组上方；具体字号随整体 UI 校准 | `*.text-primary` | Label + Inter / Noto Sans | 已确认 | 文案固定为 `Bouncing Ball` |
| A024 | Start Prompt | 表达开始入口 | 用户确认 | Not Produced | No | Light/Dark | Idle | 位于 A023 下方；以间距和字重分层 | `*.text-primary` 或次级文字 Token | Label；点击区域由玩法规格定义 | 已确认 | 文案 `START`；不显示按钮边框或卡片；实际输入映射待玩法任务 |

### 4.5 Pause State

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A025 | Pause Transparent Layout Layer | 承载暂停文字并保留当前局上下文 | 用户确认 | Not Produced | No | Light/Dark | Idle | 覆盖 Game Area `(171,131,619,452)`；仅作为布局区域 | 无独立表面 | 透明 Control 容器 | 已确认 | 不绘制 Overlay、卡片或复杂面板 |
| A026 | Pause Status Text | 明确暂停状态 | 用户确认 | Not Produced | No | Light/Dark | Idle | Game Area 居中；最终字号随整体 UI 校准 | `*.text-primary` | Label + Inter / Noto Sans | 已确认 | 文案固定为 `PAUSED` |
| A027 | Pause Visible Action Slot | 保留既有 Asset ID 并记录无可见次级操作 | 用户确认 | Not Produced | No | Light/Dark | Idle | 不适用 | 不适用 | 不生产可见资产 | 已确认 | V0.1 视觉基线只有 `PAUSED`；恢复/退出操作属于后续交互规格 |

### 4.6 Game Over State

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A028 | Game Over Transparent Layout Layer | 承载结束状态文字而不新增可见面板 | 用户确认 | Not Produced | No | Light/Dark | Idle | 覆盖 Game Area `(171,131,619,452)`；仅作为布局区域 | 无独立表面 | 透明 Control 容器 | 已确认 | 不绘制 Overlay、卡片或复杂面板 |
| A029 | Game Over Result Text | 显示本局时长结果 | 用户确认 | Not Produced | No | Light/Dark | Idle | 居中组上方；稳定数字宽度 | `*.text-primary` / `*.text-hud` | Label + tabular numerals | 已确认 | 文案格式基线 `TIME 01:23`；数值为排版示例，不决定计时语义 |
| A030 | Game Over Restart Prompt | 表达重新开始入口 | 用户确认 | Not Produced | No | Light/Dark | Idle | 位于 A029 下方；以间距、透明度和字重分层 | `*.text-primary` 或次级文字 Token | Label；点击区域由玩法规格定义 | 已确认 | 文案固定为 `CLICK TO RESTART`；不显示按钮边框或卡片 |

### 4.7 Footer

| Asset ID | 名称 | 用途 | 来源 | 来源版本 | 视觉基准 | Theme | Motion State | 尺寸比例 | 颜色 | 实现候选 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A031 | Footer Region | 承载标语与分隔线 | REF001/REF002 | Not Produced | Yes | Shared geometry | Not Applicable | `≈(238,879,973,71) → (158,583,645,47)` | 继承 Window Token | Control 容器 | 已确认 | 与 Header 使用同一左右网格 |
| A032 | Footer Divider | 平衡 Footer 构图 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | 每侧约 `17×1 design px` | `*.text-secondary` 的低强度变体 | Line2D、ColorRect 或程序化线 | 已确认 | 不表达进度或状态；左右可复用同一规格 |
| A033 | Footer Tagline | 表达产品语气 | REF001/REF002 | Not Produced | Yes | Light/Dark | Not Applicable | `≈(516,908,416,18) → (342,602,276,12)` | `light.text-footer` / `dark.text-footer` | Label | 待确认 | 问题：最终文案和 Light 对比度；影响：品牌语气/可读性；确认人：用户；候选文案 `A SMALL GAME FOR BIGGER BREAKS` |

## 5. Token 依赖

所有颜色必须引用 `docs/visual_spec.md` 中的语义 Token，不能在组件实现中各自复制裸色值。

| 资产组 | 必需 Token |
| --- | --- |
| Window | `background-*`、`window`、`panel-border` |
| Text | `text-primary`、`text-secondary`、`text-hud`、`text-footer` |
| Ball | `visual_spec.md` §8.5 Ball 色彩模型（H 189 恒定，S/V 随 Vitality） |
| Trail | 固定使用满 Vitality 的 Ball Glow 色；**不得引用当前 Vitality 派生色** |
| Paddle | `paddle.idle`、`paddle.flash`、`paddle.disturbance`（§8.5） |
| HUD | `hud-surface`、`hud-icon`、`text-hud` |
| States | 主题文字 Token；当前极简状态层不使用可见 Overlay、卡片或按钮表面 |

## 6. 实现候选评估规则

V0.1 选择实现路线时，按以下顺序评估：

1. 是否能在 Light/Dark 间复用几何；
2. 是否能在 640×480 到 1440×1080 之间清晰缩放；
3. 是否支持 Reduced Motion / Reduced Transparency；
4. 是否满足 Compatibility Renderer 的性能目标；
5. 是否需要正式位图素材；
6. 是否具有可追溯来源和可再分发授权。

优先程序化或 UI/StyleBox 的元素：Window、Game Area、Traffic Light、Paddle、Timer Container、Divider。

历史候选中的 Environment Background、Clock Icon 尚未制作；Ball Glow / Trail 已确认使用运行时径向贴图，无独立位图或 Shader。

Particles 已由冻结视觉语言排除，不实现。

## 7. Phase 0 登记结论（历史基线）

- 概念图中可见元素：均已登记，无 `待拆解` 条目；
- Theme 与 Motion State：已分别登记；
- 尺寸：可见元素均有源图或目标设计尺寸；
- 颜色：可见元素均引用 `visual_spec.md` Token；
- 实现：均有候选或明确说明为何尚不能选择；
- 正式素材：均未生产；
- 状态视觉与字体方向：已由用户确认；具体字体文件授权归档和玩法交互映射在对应开发任务处理。

## 8. V0.1.3 资产边界（`2026-09-09` 更新）

- 当前视觉全部由 Godot 节点和程序绘制生成，没有新增 Sprite、Texture、字体或音频资产；
- Ball Glow 与 Trail 残影使用**运行时生成**的径向渐变贴图（`GradientTexture2D`，`FILL_RADIAL`），属于程序化资产，不是位图素材，不需要 Shader；
- `assets/concept/` 包含 `.gdignore`，两张参考图不参与运行时导入；
- A019 Timer Container 与 A020 Clock Icon 未进入当前极简 HUD；
- A016 Particles 已确认不使用；A018 Paddle Glow 已废止。

### 8.1 三通道归属

每个视觉资产只属于一个反馈通道，**不得跨通道取值**（原则见 `visual_spec.md` §1.1）：

| 通道 | 驱动变量 | 资产 |
| --- | --- | --- |
| Vitality | 球自身状态 | A013 Core、A014 Glow、A037 Resting State |
| Velocity | 球当前运动 | A015 Trail |
| Interaction | 玩家刚刚输入 | A035 Interaction Flash、A036 Contact Disturbance |
| 不属于通道 | 事件瞬时装饰 | A038 Squash / Stretch |

A017 Paddle Core 不属于任何通道：它是形态，不表达状态。

### 8.2 当前实现登记

冻结视觉已于 2026-09-09 获用户授权并实现，后续V0.1.3整体已通过用户验收。“Not Produced”仍指未生产正式素材文件，不否定程序化实现。

| Asset ID | 当前实现 | 文件 |
| --- | --- | --- |
| A013 | H=189°、Vitality 色彩模型、抗锯齿、无高光点 | scripts/ball/ball_visuals.gd |
| A014 | 连续径向 Glow，56 px 包络，单一 Vitality 驱动 | scripts/config/visual_tokens.gd、scripts/ball/ball_visuals.gd |
| A015 | 0.085 s 时间采样、最多四个离散残影、固定满 Vitality Glow 色 | scripts/ball/ball_visuals.gd |
| A017 | #45786E 基础色，150×18，中心 Y=537 | scripts/paddle/paddle_controller.gd、scenes/main.tscn |
| A018 | 常驻外扩 Glow 已移除，不产生文件 | scripts/paddle/paddle_controller.gd |
| A035 / A036 | 有效/无效接触、弱/强 Wake 的亮度闪现与局部扰动 | scripts/paddle/paddle_controller.gd、scripts/main.gd |
| A037 | RESTING Glow=0.25、Core 固定状态色，零 Vitality 仍可见 | scripts/ball/ball_visuals.gd |
| A038 | 保留 Ball 几何反馈；不加可选 Paddle squash | scripts/ball/ball_visuals.gd |
| A011 / A012 | Dark panel=#171C26、边框=#3A4350 | scripts/config/visual_tokens.gd、scripts/main.gd |

测试截图仅写入忽略目录 .godot/v013-{active,decaying,resting}-{width}x{height}.png，属于验证证据，不是运行时资产。该条为V0.1.3资产记录；后续V0.1.4导入音效见§9。

## 9. V0.1.4 音频基线（2026-09-09）

| 事件 | 默认A | 备选B |
| --- | --- | --- |
| Paddle Hit | Digital Audio / pepSound3.ogg | pepSound5.ogg |
| Ground Hit | Sci-fi Sounds / forceField_000-pu-160ms.wav | forceField_001-pu-180ms.wav |
| Strong Wake | Digital Audio / pepSound3.ogg | 无 |
| Wall / Top | Digital Audio / pepSound3.ogg | pepSound1.ogg |

Weak Wake无专门音效。全部音频来自Kenney CC0；17个原始OGG、4个最小裁片WAV已入库，其中历史试听素材保留但未接入。当前素材与参数见[V0.1.4基线](v0.1.4-basic-audio.md)；全部来源、包名、原文件和裁片映射见[第三方记录](../THIRD_PARTY_ASSETS.md)，许可边界见[资产许可](../ASSET_LICENSE.md)。没有建立正式资产生产流程。

### 参考文件位置整理（2026-09-09）

REF001 / REF002统一使用assets/concept/内归档路径。根目录重复PNG经SHA-256再次核对一致后移除，其未被游戏引用的.import配置同时移除。表中的原文件名保留来源含义，不表示根目录仍有副本。素材内容与许可未变。

### V0.1.5 反馈增量（2026-09-10）

A038增加连续弱交互的轻微Core几何变形，仍由scripts/ball/ball_visuals.gd程序绘制；无新增媒体资产。音频素材、来源、许可及音量参数均保持V0.1.4基线，Weak不播放专门Wake音效。
