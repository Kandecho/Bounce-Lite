# Bounce Lite Visual Specification

## 1. 规格状态与用途

本文件把 `day-raw.png` 与 `night-raw.png` 中的可见信息转化为生产规格，并记录用户在 V0.1 初始化前确认的视觉决策。它不授权生产正式素材或实现玩法。

规格日期：`2026-09-08`

Project Name：`Bounce Lite`

UI Title：`Bouncing Ball`

## 2. 视觉方向

### 2.1 采用方向

> 克制的 Soft UI Evolution + 有限透明/玻璃感

主要特征：

- 居中的桌面窗口构图；
- Light/Dark 对称主题；
- 细边框和柔和多层阴影；
- 大面积留白或深色负空间；
- 单一高亮交互色用于 Paddle；
- 白色 Ball 作为视觉焦点；
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

| Motion State | Ball Core | Glow | Trail | Particles |
| --- | --- | --- | --- | --- |
| Idle | 显示 | 可保留静态低强度 | 不显示 | 不显示 |
| Moving | 显示 | 随速度或碰撞反馈变化的候选 | 显示候选 | 可选；尚未批准 |

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
| `light.ball-core` | `#FEFEFE` | Sampled | Ball 主体 |
| `light.ball-glow` | `#7CB8FF @ 20–45%` | Candidate | 合成边缘采样 `#D3E6FD` |
| `light.ball-trail` | `#8EC2FF @ 10–30%` | Candidate | 合成节点从 `#EDF5FD` 过渡到 `#CAE3FD` |
| `light.paddle-core` | `#60F1BF` | Sampled | Paddle 核心 |
| `light.paddle-glow` | `#60F1BF @ 18–35%` | Candidate | Paddle 外发光 |
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
| `dark.ball-core` | `#FDFDFD` | Sampled | Ball 主体 |
| `dark.ball-glow` | `#FFFFFF @ 14–28%` | Candidate | Dark 概念图为低强度中性 Glow |
| `dark.ball-trail` | `#CFE3FF @ 12–28%` | Candidate | Moving 状态候选；图中未显示 |
| `dark.paddle-core` | `#A5EBB4` | Sampled | Paddle 核心 |
| `dark.paddle-glow` | `#A5EBB4 @ 15–30%` | Candidate | Paddle 外发光 |
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

- Core 目标直径约 32 design px；
- 白色实心圆，边缘抗锯齿；
- Glow 独立于 Core；
- Trail 独立于 Theme，只由 Moving 候选状态触发；
- Light 图拖尾约四段，透明度向历史位置递减；
- Particles 在概念图中未形成可确认图层，保持待设计；
- 候选实现：程序化圆形/Texture + Shader；Trail 可用历史位置节点或轻量粒子评估。

### 11.5 Paddle

- 目标核心尺寸取 Light/Dark 中位方向：约 `150×18 design px`；
- 胶囊形，圆角约为高度一半；
- Light 与 Dark 使用不同核心 Token，但几何统一；
- Glow 置于 Core 后方，不改变碰撞或输入尺寸；
- 候选实现：`Control/StyleBox`、程序化矩形或简洁 Sprite；不要求位图素材。

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

具体字号、间距和透明度在首个整体 UI 实现中校准，但不得改变上述极简文字方向。

## 13. 动效与性能方向

- Phase 0 不实现动画；
- Ball 移动是核心运动，其他持续动画应保持最少；
- Trail 节点数量、采样间隔、生命周期和透明曲线必须在 V0.1 用实际速度验证；
- Particles 不是必需项，只有当 Trail/Glow 无法表达反馈时再启用；
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
| V007 | Glow/Trail/Particles 技术路线 | 在开发阶段进行技术验证后选择 | 用户 + V0.1 技术验证 | 决策时点已确认；不阻塞初始化 |

## 15. Phase 0 结论

概念图中的现有元素已经转化为布局、主题、Token、状态和实现候选。状态界面、字体方向、V0.1 主题策略和 Light 可读性已经获得用户确认；具体字体文件、Glow/Trail 技术路线及未授权的玩法交互继续保留到对应开发任务处理。
