# Bounce Lite Visual Specification

> 2026-09-23 当前说明：F09球—挡板碰撞反馈偏弱已纳入[正式问题登记](exploration/toybox-playtest.md)，F03速度调参还涉及上限兼作拖影标尺的耦合，证据见[第一批调查](exploration/geometry-harvest-batch1.md#motion-investigation-20260923)。这些是准备处理的问题；尚未选择新形变、挡板反馈或拖影方案，本轮没有视觉代码变更。下方历史冻结／验收不等于当前反馈问题已解决。

> 2026-09-11 当前分支说明：本文件保留 V0.1 规格及历史验收。当前依据为 [V0.2.0 Design Note](design/v0.2.0-design-note.md)，实际已实现方案 B、挡板传能变暗和全客户区场地，见[共享小世界记录](exploration/v0.2-shared-world.md)。Wake／Continue 表现交换仍在[后续计划](exploration/v0.2.0-follow-up-plan.md)中；下文冻结规格不覆盖当前决定。

## V0.1.6 生命周期说明（2026-09-10）

当前默认画面无 Combo 或时间 HUD；旧 Combo／HUD Timer／结果 UI 的规格和素材登记仅保留历史参考，不再作为当前生产要求。时间累计只在默认隐藏的 F1 开发面板显示 `DEV ELAPSED`，没有 Wake reset 或 RESTING pause。Ball / Glow / Trail / Paddle 的已验收外观不改。当前语义见 [V0.1.6 基线](design/design-baseline-v0.1.6.md)，变更见 [收口报告](reviews/v0.1.6-consolidation.md)。


## 1. 规格状态与用途

本文件把 `day-raw.png` 与 `night-raw.png` 中的可见信息转化为生产规格，并记录用户在 V0.1 初始化前确认的视觉决策。它不授权生产正式素材或实现玩法。

规格冻结日期：`2026-09-08`；实现同步：`2026-09-09`。V0.1.3 已授权并实现冻结玩法对象视觉，人工体验待确认。

Project Name：`Bounce Lite`

UI Title：`Bouncing Ball`

### 1.1 核心视觉原则：反馈通道分离（已冻结）

冻结日期：`2026-09-08`

Bounce Lite 使用三个互相独立的视觉反馈通道。每个通道只表达一个变量，**不得重新组合为任何单一合并值**：

| 通道 | 表达 | 驱动变量 |
| --- | --- | --- |
| Ball Glow | 球自身状态 | Vitality |
| Trail | 球当前运动 | Velocity |
| Paddle Feedback | 玩家刚刚输入 | Interaction 事件 |

附加约束：

- **Paddle Feedback 不得留下长期视觉状态。** Paddle 是玩家介入系统的位置接口，不是第二个生命体；它表达“刚刚发生了一次输入”，不表达自身处于什么状态。因此不使用独立 Glow 层、不使用常驻 edge line 或任何常驻装饰层；反馈必须在约 `140 ms` 内退回基础色。Paddle 的可见性问题优先通过调整基础色解决，不通过增加图层解决。
- **明度分级规则。** 任何叠加在另一层之上的效果层，必须在明度上高于它所叠加对象在该时刻的状态值，否则会在峰值帧消失。当前两处分级：Ball Glow `S 0.95` 高于 Core `S 0.58`；Paddle 边缘扰动 `16.30:1` 高于本体闪光 `10.75:1`。

该原则具有**否决效力**，直接排除以下改动：

- 低 Vitality 时削弱或缩短 Trail —— 禁止，Trail 不感知 Vitality；
- 残影颜色跟随球体当前颜色 —— 禁止，会使 Physics 通道间接携带 Vitality；
- 给 Paddle 任何随状态缓变的光 —— 禁止。

本原则同时记录于 `AGENTS.md` 已确认基线。文档中与本节冲突的历史描述一律以本节为准。

## 2. 视觉方向

### 2.1 采用方向

> 克制的 Soft UI Evolution + 有限透明/玻璃感

主要特征：

- 居中的桌面窗口构图；
- Light/Dark 对称主题；
- 细边框和柔和多层阴影；
- 大面积留白或深色负空间；
- Paddle 常态为低明度基础色，仅在接触瞬间短暂亮起；
- 荧光青系 Ball 作为视觉焦点（V0.1.3 起；概念图中的白球已由 §8.5 的色彩模型取代）；
- Timer 是唯一持续可见的 HUD；
- 背景有景深模糊，内容层保持清晰。

### 2.2 不采用方向

- 不使用 Claymorphism 的 3–4 px 厚边框、强烈双阴影或玩具化体积；
- 不要求 Liquid Glass 的实时折射、透镜畸变或复杂流体变形；
- 不使用霓虹赛博风、强闪烁或大量同时运动的装饰；
- 不把概念图的合成背景直接当作可发布运行时资产。

本地 UI/UX 规则库的页面结构推荐与桌面游戏无关，未采用；风格邻近项和可访问性规则仅作为校验依据。最终色板以概念图采样为主。

## 3. 参考资料与可追溯性

| Theme | 原始参考 | 归档副本 | Resolution | SHA-256 | 视觉基准 |
| --- | --- | --- | --- | --- | --- |
| Light | `day-raw.png` | `assets/concept/light_mode/day-raw.png` | 1448×1086 | `52E4759BA7D8A47AD74E76567263340319522EBE0C1B83EA6C0F0B66762821B3` | Yes |
| Dark | `night-raw.png` | `assets/concept/dark_mode/night-raw.png` | 1448×1086 | `A68E6CF40E567B83FD73BDBDF0C23C31AEC85EDC40091D6045B4FB6D1C01D406` | Yes |

参考图是完整合成图。背景、窗口、UI 和效果没有独立图层，因此透明度、Blur 半径和阴影参数无法从最终像素唯一反解；本文件把可直接测量值与后续候选值明确分开。

## 4. 坐标、画布与缩放

### 4.1 坐标基线

- Concept Reference Resolution：`1448×1086`
- Game Design Resolution：`960×720`
- 两者比例：`4:3`
- 等比换算系数：`960 / 1448 = 720 / 1086 ≈ 0.662983`
- 原点：左上角 `(0, 0)`
- 边界框格式：`(x, y, width, height)`

### 4.2 缩放策略

- 设计布局以 960×720 为唯一基准；
- 窗口缩放使用统一比例，不改变 X/Y 相对比例；
- 非 4:3 窗口使用 letterbox 或 pillarbox；
- 不裁切 Window Frame、Timer 或 Footer；
- 建议最小内容尺寸为 `640×480`；低于该尺寸时不保证概念视觉的文字清晰度；
- 建议验收尺寸：`640×480`、`960×720`、`1280×960`、`1440×1080`；
- 高 DPI 下按逻辑设计尺寸布局，渲染分辨率随系统缩放；
- 背景可以覆盖安全区，但核心窗口内容必须始终完整可见。

最小尺寸和验收尺寸属于 Phase 0 建议；V0.1 创建工程时需要用户确认并映射为实际 Godot 设置。

## 5. 布局测量

以下数值由合成图人工观察与像素检测得到，误差容限为 `±4 source px`。Light/Dark 图之间存在少量构图差异，后续使用统一网格，不为每个主题建立不同布局。

| 元素 | Source BBox，约 | 归一化位置/尺寸，约 | 960×720 Design BBox，约 | 说明 |
| --- | --- | --- | --- | --- |
| Full Canvas / Environment | `(0,0,1448,1086)` | `(0%,0%,100%,100%)` | `(0,0,960,720)` | 主题背景覆盖全画布 |
| Window Frame | `(238,123,973,828)` | `(16.4%,11.3%,67.2%,76.2%)` | `(158,82,645,549)` | Light/Dark 共用统一网格 |
| Header | `(238,123,973,74)` | `(16.4%,11.3%,67.2%,6.8%)` | `(158,82,645,49)` | 包含装饰点、标题、版本 |
| Game Area | `(258,197,933,682)` | `(17.8%,18.1%,64.4%,62.8%)` | `(171,131,619,452)` | 核心玩法内容安全区 |
| Timer Container | `(990,220,180,62)` | `(68.4%,20.3%,12.4%,5.7%)` | `(656,146,119,41)` | Game Area 右上内缩 |
| Clock Icon | `(1017,236,28,28)` | `(70.2%,21.7%,1.9%,2.6%)` | `(674,156,19,19)` | Outline icon |
| Timer Digits | `(1069,236,74,28)` | `(73.8%,21.7%,5.1%,2.6%)` | `(709,156,49,19)` | 示例文案 `00:12` |
| Ball Core - Light | `(733,451,50,50)` | `(50.6%,41.5%,3.5%,4.6%)` | `(486,299,33,33)` | Moving 帧证据 |
| Ball Core - Dark | `(735,451,46,46)` | `(50.8%,41.5%,3.2%,4.2%)` | `(487,299,31,31)` | 单帧运动状态不确定 |
| Trail Envelope - Light | `(602,359,134,111)` | `(41.6%,33.1%,9.3%,10.2%)` | `(399,238,89,74)` | 约四段 Ghost + 与 Ball 相接 |
| Paddle Core - Light | `(608,798,232,28)` | `(42.0%,73.5%,16.0%,2.6%)` | `(403,529,154,19)` | 像素阈值检测值 |
| Paddle Core - Dark | `(614,794,220,26)` | `(42.4%,73.1%,15.2%,2.4%)` | `(407,526,146,17)` | 像素阈值检测值 |
| Footer Region | `(238,879,973,71)` | `(16.4%,80.9%,67.2%,6.5%)` | `(158,583,645,47)` | 与 Window Frame 一体 |
| Footer Tagline | `(516,908,416,18)` | `(35.6%,83.6%,28.7%,1.7%)` | `(342,602,276,12)` | 大写、宽字距、居中 |

### 5.1 统一布局建议

- Window Frame：目标圆角 `14–16 design px`；
- Game Area：目标圆角 `8–10 design px`；
- Timer：胶囊圆角约为高度的 50%；
- Paddle：胶囊圆角约为高度的 50%；
- Window Frame 到 Game Area 的水平内边距约 `13 design px`；
- Header 与 Footer 使用同一左右网格；
- Ball 和 Paddle 的图中位置只是状态快照，不是固定生成点或固定 Paddle 位置规则。

## 6. 层级与材质

从后到前的建议层级：

1. Environment Background；
2. 主题调色或暗化层；
3. Window Shadow；
4. Window Surface / Frame；
5. Game Area Surface 与 Border；
6. Ball Trail / Paddle Glow 等后置效果；
7. Ball Core 与 Paddle Core；
8. HUD Timer；
9. Start/Pause/Game Over 文字状态层；
10. Header 与 Footer 内容。

材质原则：

- Window 和 HUD 可以使用半透明感，但文本必须在稳定表面上渲染；
- 背景 Blur 是视觉方向，不要求 V0.1 首版实时计算；优先考虑预处理背景或低成本模糊方案；
- Border 保持细而清晰，用于在 Reduced Transparency 下维持层级；
- Shader、Particle 和 Sprite 只作为候选，实现路线见 `asset_registry.md`。

## 7. Theme 与 Motion State

### 7.1 独立维度

| Theme | 描述 |
| --- | --- |
| Light | 明亮天空/湖面、近白窗口、蓝灰文字、薄蓝 Ball 效果、薄荷 Paddle |
| Dark | 深蓝灰环境、深色窗口和 Game Area、白色文字、白色 Ball、浅绿 Paddle |

| 通道 | 表达变量 | Idle / RESTING | Moving |
| --- | --- | --- | --- |
| Ball Core | Vitality（色彩） | 低饱和、低明度 | 随 Vitality 连续变化 |
| Ball Glow | Vitality（强度） | 状态地板，不为零 | 随 Vitality 连续变化 |
| Trail | Velocity | 不显示（速度为零） | 残影数量 / 间距 / 透明度随速度 |
| Paddle Feedback | Interaction | 不显示 | 仅接触瞬间出现，约 `140 ms` 内消失 |
| Particles | 不适用 | 不使用 | 不使用；三通道模型中没有它的位置 |

Motion State 不再作为 Glow 的驱动来源。Glow 只由 Vitality 驱动，Trail 只由 Velocity 驱动，两者不共享任何合并的“活跃比例”。

### 7.2 证据矩阵

| Reference | Theme | 可确认 Motion State | 不能推导的规则 |
| --- | --- | --- | --- |
| `day-raw.png` | Light | Moving | 不能证明 Idle 时 Glow 强度；不能证明 Trail 只属于 Light |
| `night-raw.png` | Dark | 未确认 | 不能证明 Dark 禁用 Trail；不能证明截图一定是 Idle |

四种组合都必须可表达：`Light+Idle`、`Light+Moving`、`Dark+Idle`、`Dark+Moving`。没有视觉证据的组合由用户在 V0.1 前确认。

### 7.3 主题切换

V0.1 不实现 Light/Dark 主题切换。两套 Theme Token 和四种 Theme × Motion State 组合继续作为设计规格保留，不因此删减。首个可视版本采用哪套主题，以及后续是否增加手动或系统主题切换，需要在对应实现任务中确认。

## 8. 色彩系统

### 8.1 取值规则

- `Sampled`：直接来自概念图指定像素或文字区域极值；
- `Derived`：根据相邻采样和视觉关系整理的目标色；
- `Candidate`：概念图未提供独立源色，仅供 V0.1 评估；
- 合成图无法证明原始图层透明度，因此带透明度的值是候选范围。

### 8.2 Light Theme Tokens

| Token | 值 / 范围 | 类型 | 用途与说明 |
| --- | --- | --- | --- |
| `light.background-top` | `#B2DDFE` | Sampled | 天空/上方环境 |
| `light.background-bottom` | `#C1E3FD` | Sampled | 湖面/下方环境 |
| `light.window` | `#F5F9FE` | Sampled | Window 输出目标；允许轻微半透明感 |
| `light.panel` | `#F6FAFE` | Sampled | Game Area 输出目标 |
| `light.panel-border` | `#D9E5F2` | Derived | 细边框，需在白色表面保持可见 |
| `light.text-primary` | `#1E2E46` | Sampled | Title；对 Window 约 12.95:1 |
| `light.text-secondary` | `#5E7190` | Derived | Version；按可读性要求从概念色加深，对 `#F5F9FE` 约 4.68:1 |
| `light.text-hud` | `#536A93` | Sampled | Timer；约 5.19:1 |
| `light.text-footer` | `#5E7190` | Derived | Footer；按可读性要求加深，对 `#FEFEFF` 约 4.91:1 |
| `light.ball-core` | `#FEFEFE` | Sampled | 概念采样证据；玩法对象实现色见 §8.5 |
| `light.ball-glow` | `#7CB8FF @ 20–45%` | Candidate | 概念采样证据；实现见 §8.5 |
| `light.ball-trail` | `#8EC2FF @ 10–30%` | Candidate | 概念采样证据；实现见 §8.5 |
| `light.paddle-core` | `#60F1BF` | Sampled | 概念采样证据；已不作为实现目标，见 §8.5 |
| `light.paddle-glow` | `#60F1BF @ 18–35%` | Candidate | **已废止**：Paddle 不使用常驻 Glow，见 §1.1 |
| `light.hud-surface` | `#F5FAFE` | Sampled | Timer Container |
| `light.hud-icon` | `#536A93` | Derived | Clock Icon 与 Timer 同色族 |
| `light.focus-ring` | `#2E75C7` | Candidate | 键盘焦点；必须与相邻表面有清晰差异 |
| `light.overlay` | `#EAF3FC @ 84%` | Candidate | 状态遮罩；需保留背景情境 |

### 8.3 Dark Theme Tokens

| Token | 值 / 范围 | 类型 | 用途与说明 |
| --- | --- | --- | --- |
| `dark.background-top` | `#373F4D` | Sampled | 上方环境 |
| `dark.background-bottom` | `#252C3B` | Sampled | 下方环境 |
| `dark.window` | `#242B37` | Sampled | Window 输出目标 |
| `dark.panel` | `#171C26` | Sampled | Game Area 输出目标 |
| `dark.panel-border` | `#3A4350` | Derived | 细边框 |
| `dark.text-primary` | `#FFFFFF` | Sampled | Title；对 Window 约 14.23:1 |
| `dark.text-secondary` | `#AAAFBB` | Sampled | Version；约 6.48:1 |
| `dark.text-hud` | `#FFFFFF` | Sampled | Timer；对 HUD 约 14.23:1 |
| `dark.text-footer` | `#A4A9B2` | Sampled | Footer；约 5.85:1 |
| `dark.ball-core` | `#FDFDFD` | Sampled | 概念采样证据；玩法对象实现色见 §8.5 |
| `dark.ball-glow` | `#FFFFFF @ 14–28%` | Candidate | 概念采样证据；实现见 §8.5 |
| `dark.ball-trail` | `#CFE3FF @ 12–28%` | Candidate | 概念采样证据；实现见 §8.5 |
| `dark.paddle-core` | `#A5EBB4` | Sampled | 概念采样证据；已不作为实现目标，见 §8.5 |
| `dark.paddle-glow` | `#A5EBB4 @ 15–30%` | Candidate | **已废止**：Paddle 不使用常驻 Glow，见 §1.1 |
| `dark.hud-surface` | `#252B35` | Sampled | Timer Container |
| `dark.hud-icon` | `#FFFFFF` | Derived | Clock Icon |
| `dark.focus-ring` | `#A5EBB4` | Candidate | 键盘焦点 |
| `dark.overlay` | `#0B1018 @ 82%` | Candidate | 状态遮罩 |

### 8.4 固定装饰色

| Token | Light Sample | Dark Sample | 规则 |
| --- | --- | --- | --- |
| `traffic.red` | `#FB6058` | `#FC5C5F` | 统一为单一品牌无关装饰色即可 |
| `traffic.yellow` | `#FDC749` | `#FCC451` | 无状态语义 |
| `traffic.green` | `#4BC856` | `#58BE52` | 无状态语义 |

Traffic Light 不能用颜色表达应用状态，因为它们已经被定义为纯装饰。

### 8.5 V0.1.3 玩法对象色彩模型（已冻结）

`2026-09-08` 起，Ball 与 Paddle 的实现色不再取自概念图采样。§8.2 与 §8.3 中的 `*.ball-*` 与 `*.paddle-*` 条目继续作为**概念图采样证据**保留，但不再是玩法对象的实现目标。

Ball —— 色相恒定 `H = 189°`，只有饱和度与明度随 Vitality 变化：

```text
Core   S = lerp(0.42, 0.58, v)    V = lerp(0.42, 1.00, v)
Glow   S = lerp(0.60, 0.95, v)    V = lerp(0.55, 1.00, v)
```

| Vitality | Core | 对 `dark.panel` 实测 |
| --- | --- | ---: |
| 1.00 | `#6BE9FF` | 11.97 : 1 |
| 0.40 | `#569AA6` | 5.34 : 1 |
| RESTING | `#3E646B` | 2.63 : 1 |

Paddle：

| 用途 | 值 | 对 `dark.panel` 实测 |
| --- | --- | ---: |
| `paddle.idle` | `#45786E` | 3.38 : 1 |
| `paddle.flash` | `#6FE0BE` | 10.75 : 1 |
| `paddle.disturbance` | `#E6FFF6` | 16.30 : 1 |

Trail：固定使用满 Vitality 的 Ball Glow 色，不随当前 Vitality 变化。

**校准底色必须为 `dark.panel #171C26`。** V0.1.3 已由旧 `#090B0F` / `#11151C` 校准为目标 panel token；外围使用 `dark.window #242B37`。状态：`已实现，人工待确认`。

Light Theme 的玩法对象色彩不在本次冻结范围内。用户已确认 Light 不作为当前优先项，且它需要单独设计而不是换色——实测概念图 `day-raw.png` 中白球对近白面板仅 `1.03:1`，最强光晕处 `1.76:1`，Paddle `1.35:1`，均低于非文字 UI 的 `3:1` 参考下限。状态：`待设计`。

## 9. 对比度与可访问性

### 9.1 概念图对比度

| 元素 | Foreground | Background | Contrast | 判断 |
| --- | --- | --- | ---: | --- |
| Light Title | `#1E2E46` | `#F5F9FE` | 12.95:1 | 通过 4.5:1 目标 |
| Light Version（概念采样） | `#7689A5` | `#F5F9FE` | 3.37:1 | 未通过；实现 Token 已调整 |
| Light Timer | `#536A93` | `#F5FAFE` | 5.19:1 | 通过 |
| Light Footer（概念采样） | `#667A9F` | `#FEFEFF` | 4.30:1 | 略低于目标；实现 Token 已调整 |
| Light Version（实现 Token） | `#5E7190` | `#F5F9FE` | 4.68:1 | 通过 |
| Light Footer（实现 Token） | `#5E7190` | `#FEFEFF` | 4.91:1 | 通过 |
| Dark Title | `#FFFFFF` | `#242B37` | 14.23:1 | 通过 |
| Dark Version | `#AAAFBB` | `#242B37` | 6.48:1 | 通过 |
| Dark Timer | `#FFFFFF` | `#252B35` | 14.23:1 | 通过 |
| Dark Footer | `#A4A9B2` | `#282D37` | 5.85:1 | 通过 |

用户已确认可读性优先于像素级复刻，V0.1 使用加深后的 Light Version 与 Footer Token。

### 9.2 行为规范

- 未来若引入真实、可聚焦按钮，必须有可见键盘焦点；
- 最小交互目标建议 `44×44 design px`，桌面鼠标与未来触控均可用；
- Traffic Light 为装饰，不进入焦点顺序，也不暴露按钮语义；
- Clock Icon 与可见 Timer 文本重复含义时视为装饰；若单独使用则必须有文本替代；
- Reduced Motion：关闭 Trail 和 Particles，Glow 改为静态低强度，不影响玩法信息；
- Reduced Transparency：Window、HUD 和 Overlay 使用更不透明表面与清晰边框；
- 不依赖颜色单独表达 Pause、Game Over 或可点击状态；状态文字本身必须可辨识；
- 不移除焦点环，也不只依赖 Hover 显示可用性。

## 10. UI 与排版

### 10.1 字体方向

- 风格：圆润、现代、安静、清晰的 sans-serif；
- 首选：`Inter`；
- 回退与多语言候选：`Noto Sans`；
- Timer：优先同一字体的 tabular numerals；若不支持，再评估等宽字体；
- 两者均按开源字体方案管理；引入字体文件时登记来源、版本、许可证文件与子集策略；
- 正式发布前必须再次确认所使用字体文件和许可证允许随游戏分发。

当前初始化不下载或打包字体文件。字体家族已确认，不等于具体字体文件已经完成授权归档。

### 10.2 960×720 排版建议

| 元素 | Size | Weight | 其他 |
| --- | ---: | ---: | --- |
| Header Title | 16 px | 600 | 普通大小写，单行 |
| Version | 13 px | 400 | 右对齐，单行 |
| Timer Digits | 20 px | 500 | Tabular/mono 数字，格式候选 `MM:SS` |
| Footer Tagline | 11 px | 500 | Uppercase，字距约 4 px，居中 |
| State Title | 28 px 候选 | 600 | 纯文字；最终值随整体 UI 校准 |
| State Result | 18 px 候选 | 500 | 示例 `TIME 01:23`；使用稳定数字宽度 |
| State Prompt | 16 px 候选 | 600 | 纯文字；不绘制按钮边框或卡片 |

Timer 当前只显示 `00:12`，不能据此决定正计时、倒计时或格式上限。

## 11. 组件规格

### 11.1 Window Frame

- 居中，统一 Light/Dark 几何；
- 薄边框、柔和阴影、14–16 px 设计圆角；
- Light 依赖明度差和蓝灰阴影；Dark 依赖细亮边与深色层级；
- 推荐 `Control/Panel + StyleBox` 或程序化 UI；完整窗口 Sprite 只作为低灵活性候选。

### 11.2 Header

- Traffic Light：三个约 13×13 design px 圆形，间距约 9 px；
- Title：`Bouncing Ball`；
- Version：概念显示 `v0.1`，版本绑定规则待确认；
- 所有元素垂直居中；
- Traffic Light 无交互、无焦点、无状态语义。

### 11.3 Game Area

- 约 619×452 design px；
- 核心对象、HUD 和状态遮罩的共同容器；
- 薄边框定义范围；
- Light 使用近白低对比表面；Dark 使用 #171C26 附近深色表面；
- 不允许对象视觉效果溢出到 Header/Footer，除非 V0.1 明确设计。

### 11.4 Ball

已冻结（`2026-09-08`）。Core 与 Glow 共同表达 Vitality；Trail 属于 Velocity 通道，规格见本节末尾。

**Core 与 Glow（Vitality 通道）**

- Core 直径 `32 design px`，实心圆，**必须开启抗锯齿**（V0.1.3 已显式开启）；
- 色相恒定 `H = 189°`。改变色相会读作“变成了另一个东西”，只降饱和与明度才读作“同一个东西没力气了”；
- 色彩模型见 §8.5。**Glow 必须比 Core 更饱和**，否则球缘没有轮廓，光晕消失在核心里（§1.1 明度分级规则）；
- Glow 峰值位于 `d = 1.0 r`，即球体轮廓线上；峰值 alpha：`RESTING = 0.25`（状态地板），否则 `lerp(0.25, 0.85, v)`；
- Glow 衰减 `alpha(d) = peak × (1 − t)^1.6`，`t = (d − 1) / 0.75`，`d = 1.75 r` 归零；包络直径 `56 px`，落在 A014 登记的 `55–60 px` 区间内；
- **RESTING 的 Glow 地板必须实现为状态常量，不得由 Vitality 推导。** 旧实现曾因地面亚像素微跳持续损耗，2 秒内从 `0.074` 衰减到 `0.0002`；V0.1.3 已修复 settle，但状态地板契约保留，不依赖剩余 Vitality；
- 不绘制高光点。高光暗示球体感，与平面语言冲突，且在浅色核心上几乎不可见；
- 实现路径：运行时生成径向渐变贴图（`Gradient` + `GradientTexture2D`，`FILL_RADIAL`）配 `draw_texture_rect`，**不需要 Shader**；Ball Glow 与 Trail 残影共用同一张贴图。

实测径向剖面（对 `dark.panel #171C26`）：

| Vitality | r=0 | r=17 | r=20 | r=24 | r=28 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1.00 | 11.97 | 5.38 | 2.64 | 1.25 | 1.00 |
| 0.40 | 5.34 | 1.98 | 1.44 | 1.09 | 1.00 |
| RESTING | 2.63 | 1.25 | 1.12 | 1.03 | 1.00 |

> RESTING 时真正承担“仍然存在”的是 Core 的 `2.63:1`，Glow 地板贡献有限（`0.25` 与 `0.30` 之间边缘对比仅 `1.25` 对 `1.32`）。若试玩认为感觉不足，有效杠杆依次为：提高 RESTING Core 明度、把地板提到 `0.45` 以上、呼吸式调制。见 `VL001`。

**Trail（Velocity 通道）**

离散残影，不是连续能量尾迹。目标是让玩家看到“球正在运动”，而不是高速飞行特效。

- 采样：**固定时间间隔 `0.085 s`**，不是固定距离。距离采样会让残影间距恒定、速度只能通过数量表达；时间采样使间距天然正比于速度，这是频闪照片编码速度的方式；
- 残影数 `n = clamp(round(lerp(0, 4, speed / max_speed)), 0, 4)`；
- 间距 `spacing = max(speed × 0.085, 18 px)`；
- alpha：最新 `0.34` → 最旧 `0.05`，整组再乘 `lerp(0.30, 1.0, speed / max_speed)`；
- 直径：`1.00 → 0.82 ×` 球直径；
- **颜色固定为满 Vitality 的 Glow 色**；取当前球色会使 Physics 通道间接携带 Vitality；
- Trail 不因低 Vitality 而削弱。高速运动即使发生在球即将耗尽 Vitality 之前，也应产生明显 Trail。

| 速度 | n | 间距 | 间距 / 球直径 |
| ---: | ---: | ---: | ---: |
| 160 px/s | 1 | 18.0 px | 0.56 |
| 330 px/s | 3 | 28.1 px | 0.88 |
| 490 px/s | 4 | 41.7 px | 1.30 |

**Particles**

不使用。三通道模型中没有它的位置。

### 11.5 Paddle

已冻结（`2026-09-08`）。Paddle 表达玩家输入事件，**不表达自身状态**，不留下长期视觉状态。

- 几何：`150 × 18 design px`，胶囊形，圆角 `9`（高度一半）；
- 固定高度是空间语义的一部分，Paddle 只负责水平移动；
- **无 Glow 层、无常驻 edge line、无任何常驻装饰层。**

组成：

| 层 | 必需性 | 作用 |
| --- | --- | --- |
| `idle` 基础色 | 必需 | 形态，不表达状态 |
| `interaction` 本体亮度变化 | 必需 | 主要信息：发生了输入 |
| `contact` 局部边缘扰动 | 必需 | 定位：打在哪里 |
| `squash` 轻微形变 | 可选 | 手感补充，不作为必要表达 |

三级明度见 §8.5。基础色取去饱和方向，理由是需要与 Ball 的青色区分：Paddle 是输入工具，不是第二个生命体。参照 Ball Core `11.97:1`、Glow 边缘 `5.38:1`，Paddle `idle` 必须明显低于此，否则与焦点对象争夺注意力。

时间曲线：攻击 1 帧（瞬时），衰减 `τ = 55 ms`，即 `1.00 / 0.34 / 0.08 / 0.02` 对应 `0 / 60 / 140 / 220 ms`。本曲线表达感知上短于 Ball 状态维持的输入反馈；逻辑上 Vitality 仍在同次碰撞同步结算，不引入视觉延迟。140 ms 时剩余约 7.84%，接近基础色；下表是完全截止时间。局部扰动也乘指数包络，截止时全部清零。

事件强度按两个来源分组，不在视觉层固定事件枚举，避免未来增加 Surface 时 Paddle 视觉规则膨胀：

| 来源 | 子类 | 强度 | 衰减 |
| --- | --- | ---: | ---: |
| Collision Feedback | 有效接球 | 1.00 | 220 ms |
| Collision Feedback | 无效接触 | 0.28（本体色去饱和） | 120 ms |
| Wake Feedback | 弱输入 | 0.15–0.45 连续 | 150 ms |
| Wake Feedback | 强输入 | 0.85 | 260 ms |

- Wake 强度应连续映射冲量大小，并在激活阈值处保留可见跳变。该跳变是教学装置：玩家能在几次尝试内自行学会“多快才算够”，不需要任何 UI 提示；
- 区分有效 / 无效接触不可省略。当前已经保留“下侧接触不恢复 Vitality”的规则，若两种接触亮得一样，光就在说谎；
- 边缘扰动几何：两段长 `22 px` 亮段从接触点向两侧移动 `14 px → 60 px`，`alpha = k × (1 − progress)^1.3 × 0.95`；另加接触点上方 `7 px` 冲击刻度，`alpha = k × (1 − progress)^2.6 × 0.85`；
- `squash` 为可选层：全局 transform `(1.09 x, 0.80 y)`，在 18 px 高的条上仅约 `3.6 px`，实测几乎不可见。真正承担表达的是亮度跃迁与边缘扰动。真正的**局部**凹陷需要把 Paddle 从 `StyleBoxFlat` 改为多边形绘制，见 `VL006`；
- 实现：本体 `StyleBoxFlat`，边缘扰动 `draw_line` 覆盖绘制，`squash` 用 `draw_set_transform`。

### 11.6 HUD Timer

- 目标容器约 `119×41 design px`；
- 右上定位，包含 Outline Clock Icon 与数字；
- Timer 是只读状态显示，不是按钮；
- 数字必须使用稳定宽度，避免更新时间导致跳动；
- 具体计时语义属于 V0.1 玩法决定。

### 11.7 Footer

- 文案候选沿用概念图：`A SMALL GAME FOR BIGGER BREAKS`；
- 两侧短 Divider 提供平衡，不表达进度；
- Light Footer 对比度需要加深或由用户接受艺术性例外；
- Footer 文案是否最终采用仍需用户确认。

## 12. 状态界面

Start、Pause、Game Over 采用极简文字 UI。状态层保持透明，不新增可见卡片、复杂面板或按钮式外框；主要通过字号、字重、透明度、行距和组间距区分层级。

| State | 可见文案基线 | 层级 | 视觉规则 | 状态 |
| --- | --- | --- | --- | --- |
| Start | `Bouncing Ball` + `START` | 标题在上，开始提示在下 | 居中纯文字；不绘制按钮边框或卡片 | 已确认 |
| Pause | `PAUSED` | 单一状态标题 | 居中纯文字；保持当前局上下文可辨识 | 已确认 |
| Game Over | `TIME 01:23` + `CLICK TO RESTART` | 结果在上，重开提示在下 | 居中纯文字；不绘制按钮边框或卡片 | 已确认 |

`01:23` 是版式示例，不决定 Timer 的计时语义或上限。Start 与 Restart 的实际点击区域、Pause 的触发/恢复操作仍属于玩法交互规格；可见层不得因此变成传统按钮。键盘不是 V0.1 必需输入，但未来若增加键盘或辅助技术支持，必须提供可辨识的焦点与操作语义。

当前 V0.1 Endless 原型不存在 Game Over，因此不实例化 Game Over 状态层；本节的 Game Over 文案继续作为 Classic/Recover 等后续规则的视觉规格保留。

具体字号、间距和透明度在首个整体 UI 实现中校准，但不得改变上述极简文字方向。

## 13. 动效与性能方向

- Phase 0 不实现动画；
- Ball 移动是核心运动，其他持续动画应保持最少；
- Trail 采样间隔、残影数量与透明曲线已在 §11.4 冻结；实现后需用实际速度复测；
- Particles 不使用；V0.1 未授权，且三通道模型中没有它的位置；
- Paddle 反馈必须在约 `140 ms` 内完全退回基础色，不得留下任何残余；
- 不统一套用单一动画时长；时长应由距离、状态和反馈目的决定；
- 窗口阴影、背景 Blur、Ball Glow、Paddle Glow 和 Trail 是主要 overdraw 风险；
- Compatibility Renderer 下至少测试 640×480、960×720、1280×960、1440×1080；
- 记录 CPU/GPU 帧时间、稳定帧率和效果关闭后的差值；
- Reduced Motion 与 Reduced Transparency 必须作为同等有效的视觉状态，而不是缺陷模式。

## 14. 待确认事项

| ID | 事项 | 当前结论 | 确认人 | 状态 / 影响 |
| --- | --- | --- | --- | --- |
| V001 | 主题切换触发 | V0.1 不实现切换；保留双主题规格 | 用户 | 已确认；不阻塞 |
| V002 | Light 次级文字对比度 | 使用加深后的 `#5E7190` Token | 用户 | 已确认；不阻塞 |
| V003 | 字体与许可证 | 优先 Inter / Noto Sans；发布前复核授权 | 用户 | 字体方向已确认；授权归档待制作阶段完成 |
| V004 | Start/Pause/Game Over | 极简文字 UI，无边框/卡片/复杂面板 | 用户 | 已确认；不阻塞 |
| V005 | Footer 最终文案 | 保留概念文案 | 用户 | 否 |
| V006 | `v0.1` 版本绑定规则 | 与正式构建版本同步 | 用户 | 否 |
| V007 | Glow/Trail/Particles 技术路线 | 已确认：程序化径向渐变贴图，无 Shader；Particles 不使用 | 用户 | 已确认；见 §11.4 |
| VL001 | RESTING Glow 地板值 | 首选 `0.25`；建议实测 `0.25 / 0.40 / 0.55` 三档 | 用户 | 待确认；不阻塞实现 |
| VL002 | `squash` 是否保留 | 可选层；18 px 上仅 `3.6 px`，实测几乎不可见 | 用户 + Codex | 待确认 |
| VL003 | Ball `z_index` 高于 Paddle | V0.1.3 已设 Ball=1、Paddle=0 | 用户 | 已实现；人工效果待确认 |
| VL004 | 运行时校准底色改为 `#171C26` | V0.1.3 已完成，来自统一 token | Codex | 已实现并渲染验证 |
| VL005 | RESTING 呼吸式调制 | 后续可选，非 V0.1.3 必需 | 用户 | 待设计 |
| VL006 | 局部凹陷是否值得多边形改造 | 影响 §11.5 的 `squash` 层 | Codex | 待确认 |
| VL007 | Light Theme 玩法对象色彩 | 需单独设计，不是换色；实测概念图本身低于 `3:1` | 用户 | 待设计；已降级为非当前优先项 |

## 15. Phase 0 结论

概念图中的现有元素已经转化为布局、主题、Token、状态和实现候选。状态界面、字体方向、V0.1 主题策略和 Light 可读性已经获得用户确认；具体字体文件及未授权的玩法交互继续保留到对应开发任务处理。

## 16. 概念图的适用范围（`2026-09-08` 更新）

截至本次更新，玩法对象已有三处刻意偏离概念图，且均由用户逐项确认：

| 项 | 概念图 | 当前规格 |
| --- | --- | --- |
| Ball Core | 白色 `#FEFEFE` / `#FDFDFD` | 荧光青系，随 Vitality 变化（§8.5） |
| Paddle Glow | 常驻发光 | 不使用常驻 Glow，仅接触瞬间反馈（§1.1、§11.5） |
| Paddle Core | `#60F1BF` 高亮薄荷 | `#45786E` 低明度基础色（§8.5） |

因此：**`day-raw.png` 与 `night-raw.png` 对玩法对象的视觉基准地位已经结束。** 它们现在的适用范围是布局、窗口框架、Header / Footer、HUD 版式与排版方向。

后续视觉审查不得再以概念图作为 Ball、Paddle、Trail、Glow 的比对基准；这三类对象一律以 §1.1、§8.5、§11.4、§11.5 为准。

## 17. 视觉语言 v1 冻结记录

| 项 | 值 |
| --- | --- |
| 冻结日期 | `2026-09-08` |
| 冻结范围 | 三通道原则、Ball 色彩与 Glow 分布、Trail 离散残影参数、Paddle 反馈三层 |
| 验证方式 | Godot `4.7.stable.official.5b4e0cb0f` 独立沙箱工程实机渲染，1:1 设计尺度，底色 `dark.panel #171C26` |
| 验证结论 | 所有数值均可由程序化径向渐变贴图实现，不需要 Shader 或位图素材 |
| 不在冻结范围 | Light Theme 玩法对象色彩；`VL001`–`VL007` 各项 |

机器渲染只证明数值可实现且可测量，不代表主观体验已经通过。所有手感相关判断仍需人工试玩。

## 18. V0.1.3 实现同步（2026-09-09）

用户已确认冻结视觉属于 V0.1.3；V0.1.4 为基础音频，V0.1.5 为最终调查/体验复核。代码以 scripts/config/visual_tokens.gd 集中映射本规格，未制作正式图片或 Shader。

Glow 不受事件亮暗脉冲或速度影响；Ball 仅保留几何形变。Trail 使用固定时间采样历史，按路径插值落实最低 18 px 间距，最多四个可见残影；无足够历史时不虚构轨迹。Paddle 可选 squash 未实施。RESTING Core 与 Glow 使用状态常量，避免零 Vitality 消失。

实际运行时 ACTIVE / DECAYING / RESTING 截图已检查，语义、手感与舒适度仍待用户试玩。详细实现与测试见 [当前 V0.1.3 spec](superpowers/specs/2026-09-09-v0.1.3-bugfix-visual-design.md)。

## V0.1.5 弱交互几何反馈（2026-09-10）

用户批准连续weak interaction→连续轻微响应→离散Strong Wake。弱响应仅Core最多6%竖向压缩、横向最多3%展开，随输入强度变化并按既有恢复曲线回弹；不移动Ball物理位置或碰撞形状，不改变Core颜色/Glow强度，不产生静止Trail。Paddle仅真实碰撞沿用短瞬时反馈，弱交互和Strong Wake均不触发Paddle闪动；Strong保持球的既有几何反馈。该几何装饰不改变Vitality/Velocity/Interaction三通道归属。总体体验已获用户验收；碰撞专属Paddle闪动按后续反馈收口。
