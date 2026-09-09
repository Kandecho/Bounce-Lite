# Third-party assets / 第三方资产记录

本记录覆盖当前仓库全部第三方音频，包括已退出事件表的试听候选。作者/发布者：**Kenney**（部分原包署名 Kenney Vleugels），https://kenney.nl 。各包官方素材页及随包 License.txt 均标明 **Creative Commons CC0 1.0 Universal**，允许商业使用；CC0 不要求署名，本记录用于来源追溯。许可文本：https://creativecommons.org/publicdomain/zero/1.0/ 。

## 官方来源

| 本地目录（assets/audio/ 下） | 素材包 | 官方页 | 原包许可 |
| --- | --- | --- | --- |
| kenney-impact | Impact Sounds 1.0 | [Impact Sounds](https://kenney.nl/assets/impact-sounds) | [License.txt](assets/audio/kenney-impact/License.txt) |
| kenney-digital | Digital Audio | [Digital Audio](https://kenney.nl/assets/digital-audio) | [License.txt](assets/audio/kenney-digital/License.txt) |
| kenney-scifi | Sci-fi Sounds 1.0 | [Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) | [License.txt](assets/audio/kenney-scifi/License.txt) |

原 ZIP 下载地址（2026-09-09 核对）：
- [Impact Sounds ZIP](https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip)
- [Digital Audio ZIP](https://kenney.nl/media/pages/assets/digital-audio/216eac4753-1677590265/kenney_digital-audio.zip)
- [Sci-fi Sounds ZIP](https://kenney.nl/media/pages/assets/sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip)

## 原始文件清单

原始 OGG 未覆盖、未转码，文件名保持原包名称。

| 包 | 文件 | 当前用途 |
| --- | --- | --- |
| Digital Audio | pepSound3.ogg | Paddle A / Strong Wake / Wall A |
| Digital Audio | pepSound5.ogg | Paddle B |
| Digital Audio | pepSound1.ogg | Wall B；历史裁片源 |
| Digital Audio | highUp.ogg, pepSound2.ogg, pepSound4.ogg, phaseJump1.ogg, phaseJump2.ogg, phaserDown1.ogg | 历史试听候选，当前不接入 |
| Sci-fi Sounds | forceField_000.ogg, forceField_001.ogg | Ground A/B 裁片原始来源 |
| Impact Sounds | impactGeneric_light_000.ogg, impactGeneric_light_001.ogg, impactSoft_heavy_000.ogg, impactSoft_medium_000.ogg, impactSoft_medium_001.ogg, impactWood_light_000.ogg | 初轮试听候选，当前不接入 |

Impact 原文件另有 [逐文件大小及 SHA-256 记录](assets/audio/kenney-impact/SOURCES.md)。

## 最小试听裁片

四个 WAV 均由本项目从同目录对应 Kenney OGG 提取，16-bit PCM；仅裁剪与短淡入淡出，未加入合成声源。保留 CC0，不纳入项目代码 MIT 的资产授权范围。时间相对原文件；淡出起点相对裁片。

| 输出文件 | 原文件 | 提取起点 / 长度 | 淡入 / 淡出起点 / 淡出长度 | 用途 |
| --- | --- | --- | --- | --- |
| kenney-scifi/forceField_000-pu-160ms.wav | forceField_000.ogg | 120 /160 ms | 3 /120 /40 ms | Ground A |
| kenney-scifi/forceField_001-pu-180ms.wav | forceField_001.ogg | 120 /180 ms | 3 /135 /45 ms | Ground B |
| kenney-digital/pepSound1-puh-160ms.wav | pepSound1.ogg | 108 /160 ms | 3 /135 /25 ms | 已停用试听候选 |
| kenney-digital/phaserDown1-puh-180ms.wav | phaserDown1.ogg | 200 /180 ms | 3 /155 /25 ms | 已停用试听候选 |

共17个原始 OGG、4个派生 WAV；Godot .import 文件仅为导入配置，缓存与下载 ZIP 不提交。当前播放器起点、固定音高和音量见 [音频基线](docs/v0.1.4-basic-audio.md)。

## 其他资源边界

概念 PNG 为用户提供的设计参考，非 Kenney 资源，不能从本表推断其许可；来源权利尚未建立，见 [ASSET_LICENSE.md](ASSET_LICENSE.md)。仓库未捆绑第三方字体、配乐或 Godot 引擎二进制。
