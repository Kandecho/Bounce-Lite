extends Node2D
## First harvest batch: one Ball, six contact shapes, reproducible local combinations.
const PROFILE := "bounce-lite-geometry-harvest-v1"
var main: Node2D
var toys: Node2D
var feedback: Node
var world_seed := 1
var fixed_layout := false
var elapsed := 0.0
var events: Array[Dictionary] = []
var latest_path := "res://.godot/geometry-snapshots/latest.json"
var last_saved_path := ""
var _restart_pending := false
var _restart_wait := 0
var _hint: Label
var _help: Label
var _notice := ""
var _notice_remaining := 0.0

func configure(host: Node2D) -> void:
	main = host
	toys = load("res://scripts/world/geometry_toys.gd").new()
	add_child(toys)
	toys.configure(main.ball.arena_bounds)
	toys.set_ball_context(main.ball.global_position, main.tuning.ball_radius)
	toys.set_paddle_context(main.paddle.global_position, main.tuning.paddle_size)
	main.ball.configure_geometry(toys)
	feedback = load("res://scripts/world/geometry_feedback.gd").new()
	add_child(feedback)
	toys.event_emitted.connect(feedback.on_geometry_event)
	toys.event_emitted.connect(_on_event)
	_create_hint()
	world_seed = maxi(1, randi() & 0x7fffffff)
	fixed_layout = OS.get_cmdline_user_args().has("--geometry-fixed")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--geometry-seed="):
			world_seed = clampi(int(argument.trim_prefix("--geometry-seed=")), 1, 0x7fffffff)
	if fixed_layout:
		toys.set_layout(1)
		_queue_restart()
	else:
		toys.set_random_mode(true, world_seed)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--geometry-snapshot="):
			restore_combination(argument.trim_prefix("--geometry-snapshot="))
	print("GEOMETRY seed=", world_seed, " fixed=", fixed_layout)

func restart_world(seed_value: int) -> void:
	world_seed = clampi(seed_value, 1, 0x7fffffff)
	elapsed = 0.0
	events.clear()
	if fixed_layout:
		toys.set_layout(1)
	else:
		toys.set_random_mode(true, world_seed)
	_queue_restart()

func _queue_restart() -> void:
	_restart_pending = true
	_restart_wait = 2
	main.ball.visible = false
	main.ball.collision_layer = 0
	main.ball.set_physics_process(false)

func _physics_process(delta: float) -> void:
	elapsed += delta
	feedback.set_muted(main.get_node("BasicAudio").muted)
	toys.set_ball_context(main.ball.global_position, main.tuning.ball_radius)
	toys.set_paddle_context(main.paddle.global_position, main.tuning.paddle_size)
	if not _restart_pending:
		return
	if _restart_wait > 0:
		_restart_wait -= 1
		return
	for y in [260.0, 220.0, 490.0, 640.0]:
		for x in [480.0, 390.0, 570.0, 300.0, 660.0, 210.0, 750.0, 120.0, 840.0]:
			var point := Vector2(x, y)
			if not spawn_point_clear(point):
				continue
			main.ball.global_position = point
			main.ball.start_active(Vector2(0.62, 1.0))
			main.ball.visible = true
			main.ball.collision_layer = 2
			main.ball.set_physics_process(true)
			_restart_pending = false
			return

func spawn_point_clear(point: Vector2) -> bool:
	if not point.is_finite() or not main.ball.safe_center_bounds().has_point(point):
		return false
	var circle := CircleShape2D.new()
	circle.radius = main.tuning.ball_radius + main.ball.safe_margin
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0, point)
	query.collision_mask = 5
	query.exclude = [main.ball.get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func save_combination() -> bool:
	var directory := "res://.godot/geometry-snapshots"
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		show_notice("记录失败：无法创建目录")
		return false
	var data := {"profile": PROFILE, "version": 1, "seed": world_seed, "time": elapsed,
		"fixed": fixed_layout, "geometry": toys.export_snapshot(), "journal": toys.lifecycle_events,
		"ball_observation": {"position": [main.ball.position.x, main.ball.position.y], "velocity": [main.ball.velocity.x, main.ball.velocity.y]}}
	last_saved_path = directory + "/geometry-%d-%d.json" % [world_seed, Time.get_ticks_msec()]
	for path in [last_saved_path, latest_path]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			show_notice("记录失败：无法写入文件")
			return false
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	show_notice("组合已记录 · F9 重新访问")
	return true

func restore_combination(source_path: String = "") -> bool:
	var path := latest_path if source_path.is_empty() else source_path
	if not FileAccess.file_exists(path):
		show_notice("先按 F8 记录本批组合")
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("profile") != PROFILE or data.get("version") != 1 or not data.get("geometry") is Dictionary:
		show_notice("不是本批几何组合记录")
		return false
	if not toys.restore_snapshot(data.geometry):
		show_notice("组合恢复失败")
		return false
	world_seed = int(data.seed)
	elapsed = float(data.time)
	fixed_layout = bool(data.get("fixed", false))
	toys.lifecycle_events.assign(data.get("journal", []))
	_queue_restart()
	show_notice("组合已恢复，安全重新发球")
	return true

func _on_event(kind: String, position: Vector2, intensity: float) -> void:
	events.append({"kind": kind, "time": elapsed, "position": [position.x, position.y], "intensity": intensity})
	if events.size() > 512:
		events.pop_front()

func _create_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_hint = Label.new()
	_hint.position = Vector2(22, 680)
	_hint.add_theme_font_size_override("font_size", 21)
	_hint.modulate = Color(0.68, 0.80, 0.83)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hint)
	_help = Label.new()
	_help.position = Vector2(22, 22)
	_help.add_theme_font_size_override("font_size", 21)
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help.visible = false
	layer.add_child(_help)

func _process(delta: float) -> void:
	_notice_remaining = maxf(0, _notice_remaining - delta)
	_hint.text = _notice if _notice_remaining > 0 else "移动鼠标接球 · H 快捷键"
	_help.text = "几何与机械 · 种子 %d\nR 同种子重开 · N 新组合\nF8 记录 · F9 恢复并重新发球（不重放输入）\nF1 参数 · F5 静音 · F7 接触角度\nH 收起 · \\ 隐藏提示" % world_seed

func show_notice(message: String) -> void:
	_notice = message
	_notice_remaining = 3.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R: restart_world(world_seed)
		KEY_N:
			fixed_layout = false
			restart_world(maxi(1, randi() & 0x7fffffff))
		KEY_F8: save_combination()
		KEY_F9: restore_combination()
		KEY_H: _help.visible = not _help.visible
		KEY_BACKSLASH: _hint.visible = not _hint.visible
		_: return
	get_viewport().set_input_as_handled()
