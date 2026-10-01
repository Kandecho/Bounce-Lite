# 开发与验证

运行环境和路径配置见[项目README](../README.md)。无需项目外的测试框架；使用现有Godot console，在仓库根目录执行。角色、授权及验证选择见[AGENTS](../AGENTS.md)，测试长期维护规则见[产物治理](README.md#artifact-governance)。

## 试玩对照

| 入口／游戏参数 | 用途 |
| --- | --- |
| `run-playtest.bat` | 默认完整单球世界 |
| `--no-bricks` | 保留门户，无砖 |
| `--no-portals` | 几何与原世界，无门户或砖 |
| `--geometry-only`／`run-geometry.bat` | 纯几何 |
| `--geometry-baseline` | 原世界底座 |
| `--v02-baseline` | 关闭共享世界及Continue的底座对照 |
| `--geometry-seed=184` | 指定随机种子 |
| `--geometry-fixed` | 固定几何对照 |
| `run-motion-current.bat`／`run-motion-fast.bat` | 同种子的1×／1.5×纯几何运动尺度对照，均用现有弹簧动作 |

启动器把游戏参数传入Godot的 `--` 之后。R按种子重开、N换种子；F8/F9保存／恢复本模式组合。模式和兼容规则见[实现说明](implementation.md#生成与恢复)。命令行对照不等于恢复整个旧版本。

## 自动检查

双击式入口为 `run-playtest.bat --test`。自动化可用PowerShell直接运行；下面假设 `GODOT_CONSOLE` 已指向可执行文件，其他路径来源仍按README配置。

```powershell
$godotExecutable = $env:GODOT_CONSOLE
New-Item -ItemType Directory -Path '.godot' -Force | Out-Null
& $godotExecutable --headless --editor --import --path . --log-file .godot/import.log --quit
& $godotExecutable --headless --path . --log-file .godot/tests.log --script res://tests/test_runner.gd
```

核心runner只包含其 `TEST_PATHS` 列出的确定性套件，不代表全部场景专项。按改动选择额外入口，日志检查脚本错误和资源失败，不能只看进程退出码。

| 改动／问题 | 额外检查 |
| --- | --- |
| 基础物理、Wake、支撑 | `test_physics_scenarios.gd`；其中旧尺度断言用 `-- --motion-profile=current --no-bricks` 对照 |
| 几何与原世界接线 | `test_geometry_coexistence.gd -- --no-portals`；相应几何机械专项 |
| 门户及生成边界 | `test_portal_harvest.gd -- --no-bricks`、`test_spawn_clearance.gd` |
| 砖状态、薄碰撞与快照兼容 | `test_brick_harvest.gd`、`test_brick_refinement.gd`、`test_brick_entry.gd` |
| 声音接线 | `test_audio_scenarios.gd -- --motion-profile=current --no-bricks`及改动机制的音频专项 |
| 运行时阶段交付 | headless导入、默认主场景1200帧，及受影响实际事件／渲染 |

音频场景中的弱Wake接触采用固定旧速度初态，需用current尺度；默认fast尺度会让该初态落入支撑阈值，提前结束而不发接触音，不能将这个模式下的失败当作素材加载失败。默认模式的实际接线另由核心runner、默认启动及相关机制专项覆盖。

表内脚本均在 `tests/`，用 `--script res://tests/<文件>` 运行；表中的 `--` 之后是游戏参数。例如：

```powershell
& $godotExecutable --headless --path . --log-file .godot/physics.log --script res://tests/test_physics_scenarios.gd -- --motion-profile=current --no-bricks
& $godotExecutable --headless --path . --log-file .godot/main-1200.log --quit-after 1200
```

导入可能访问编辑器设置；隔离检验时只为该进程设置APPDATA，勿修改用户全局配置。完整日志、录音和快照留在忽略目录，正式结论记录对应版本与证据范围。

## 诊断与捕获

`observe_geometry.gd`用于多种子运动观察；砖族受控演化由 `capture_brick_refinement.gd`，完整世界自然采样由 `capture_brick_refinement_natural.gd` 提供。无砖避让和门户长窗口仍有独立捕获，不因新版事件更多而直接替代。

`capture_geometry_audio.gd`从现用参数生成试听，支持 `-- --audio-output=res://.godot/audio-review` 隔离新WAV。它不录制真实游戏声音。所有捕获都应注明受控初态或自然输入；截图、通过次数和运行时长不构成人工体验结论。

## 本地资料

`.local/` 保存机器配置和私有档案，`.godot/` 保存生成结果；原始反馈 `docs/user-feedback.md` 不提交。公开仓库不依赖这些资料运行，亦不把它们视为可随意删除的缓存。新增公开资源时，更新相应来源和许可证说明。
