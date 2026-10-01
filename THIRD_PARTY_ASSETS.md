# 第三方素材来源

当前分发的第三方媒体均来自Kenney；随包许可为CC0。原始音源与派生裁片分开保留，程序合成音没有额外第三方媒体依赖。资产许可边界见[ASSET_LICENSE](ASSET_LICENSE.md)。

| 素材包 | 官方来源 | 随包许可 |
| --- | --- | --- |
| Digital Audio | [Kenney Digital Audio](https://kenney.nl/assets/digital-audio) | [License.txt](assets/audio/kenney-digital/License.txt) |
| Sci-fi Sounds 1.0 | [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) | [License.txt](assets/audio/kenney-scifi/License.txt) |

## 当前文件与用途

| 目录 | 文件 | 用途 |
| --- | --- | --- |
| `assets/audio/kenney-digital/` | `pepSound3.ogg` | Paddle A、Strong Wake、Wall A |
| 同上 | `pepSound5.ogg` | Paddle B对照 |
| 同上 | `pepSound1.ogg` | Wall B对照 |
| `assets/audio/kenney-scifi/` | `forceField_000.ogg`、`forceField_001.ogg` | Ground A/B裁片的原始来源 |
| 同上 | `forceField_000-pu-160ms.wav`、`forceField_001-pu-180ms.wav` | Ground A/B |

共5个原始OGG和2个派生WAV，原始文件未覆盖或转码。`.import` 是对应的Godot导入配置；缓存与下载包不提交。

## 派生裁片

两个WAV为16-bit PCM，仅裁剪和短淡入／淡出，保留CC0；起点相对原音源，淡出起点相对裁片。

| 输出 | 原文件 | 提取起点／长度 | 淡入／淡出起点／淡出长度 |
| --- | --- | --- | --- |
| `forceField_000-pu-160ms.wav` | `forceField_000.ogg` | 120／160ms | 3／120／40ms |
| `forceField_001-pu-180ms.wav` | `forceField_001.ogg` | 120／180ms | 3／135／45ms |

运行时播放起点、音高、增益和候选映射由[音频代码](scripts/audio/basic_audio_feedback.gd)维护。已退出的试听候选和概念参考不再随当前源码树分发；保留在私有来源档案，不改变其原始许可或作者归属。
