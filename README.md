# Bounce Lite

> A video game with the tactile feel of a real toy.

一个用鼠标就能玩的物理电子玩具。移动挡板接住球，看它被弹簧抛起、穿过传送门，或把碎片撞成一块完整的砖。

没有分数、关卡或胜负。球会逐渐停下，也能被你再次拨动；想玩多久、想让它碰什么，由你决定。

**当前版本：0.2.1** · [版本说明与已知问题](docs/releases/v0.2.1.md)

## 里面有什么

- **会变化的场地**：弹跳器、斜面、平台、弹簧和跷跷板等机关随机出现、停留和离场，每次都有不同的球路。
- **意外的相遇**：转子改变运动，能量块补充活力，成对传送门把球送到另一处。
- **三种砖块**：普通砖逐次破裂，脆砖一碰即碎，反向砖先拼合、再摔碎。
- **碰得到的反馈**：球的形变、光晕、拖影和碰撞声音回应每次接触。

## 开始玩

目前提供源码版本，需要 **Godot 4.7 stable**，使用 Compatibility 渲染器；已在 Windows 上验证。

1. 下载本仓库，或克隆：

   ```sh
   git clone https://github.com/Kandecho/Bounce-Lite.git
   ```

2. 在 Godot 项目管理器中导入根目录的 `project.godot`。
3. 打开工程，等待资源导入完成，按 **F5** 运行。

### Windows 快速启动

也可以双击 [run-playtest.bat](run-playtest.bat)。首次运行前，任选一种方式指定 Godot：

- 将环境变量 `GODOT_CONSOLE` 设为 Godot 可执行文件的完整路径。
- 创建 `.local/godot.local.txt`，第一行填写可执行文件的完整路径，不加引号。
- 将名为 `godot_console.exe` 或 `godot.exe` 的程序加入 `PATH`。

例如，路径配置文件可以填写 `C:\Tools\Godot\Godot_v4.7-stable_win64_console.exe`，请替换为实际安装位置。本地配置不会提交到 Git。

## 操作

| 操作 | 效果 |
| --- | --- |
| 左右移动鼠标 | 移动挡板接球；球休息时，在附近拨动挡板尝试唤醒 |
| R | 按当前种子重新开始 |
| N | 换一个随机种子重新开始 |
| F5（游戏内） | 静音／恢复声音 |
| H | 显示开发快捷键 |

默认窗口为 640×480，缩放时保持 4:3。

## 开发状态

项目仍在持续试玩与打磨。实体出现概率、整体美术，尤其反向砖的外观，尚待改善；部分重新参与体验与挡板碰撞边界问题仍在跟踪。

- [版本说明](docs/releases/v0.2.1.md)：本版变化、已知问题与对照启动方式。
- [项目概览](docs/project_overview.md)：产品定位与持续约束。
- [文档导航](docs/README.md)：开发、验证和产物维护规则。

使用 Godot / GDScript 开发，画面主要由程序绘制，声音包含 Kenney 素材和原创合成音。

## 许可

代码及技术文档采用 [MIT License](LICENSE)。媒体资产的许可见 [ASSET_LICENSE.md](ASSET_LICENSE.md)；Kenney 音频采用 CC0，来源及使用记录见 [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md)。
