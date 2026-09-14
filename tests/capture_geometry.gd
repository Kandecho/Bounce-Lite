extends SceneTree
## Full real Main, one ball, mouse-target-only evolution after the seeded start.
var viewport: SubViewport

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").muted = true
	var game = main.geometry_playground
	game.restart_world(184)
	var ball = main.ball
	var paddle = main.paddle
	paddle.set_physics_process(false)
	var observations: Array[Dictionary] = []
	var snapshot_path := ""
	for frame in range(3601):
		var seconds := frame / 60.0
		var aim: float = ball.position.x + sin(seconds * 0.6) * 45
		if fmod(seconds, 24) > 18:
			aim = 250
		if ball.position.y > paddle.position.y:
			aim = ball.position.x + (135 if ball.position.x < 480 else -135)
		paddle.set_target_x(aim)
		paddle.advance_motion(1.0 / 60)
		await physics_frame
		if frame in [600, 1800, 3000, 3600]:
			if frame == 1800:
				var key := InputEventKey.new()
				key.keycode = KEY_F8
				key.pressed = true
				viewport.push_input(key)
				snapshot_path = game.last_saved_path
			var snapshot: Dictionary = game.toys.export_snapshot()
			var active := 0
			var kinds: Array[String] = []
			for toy in snapshot.toys:
				if toy.phase == "active":
					active += 1
				kinds.append(toy.kind)
			observations.append({"time": game.elapsed, "active": active, "kinds": kinds, "event_count": game.events.size()})
			await RenderingServer.frame_post_draw
			var picture := viewport.get_texture().get_image()
			picture.resize(640, 480, Image.INTERPOLATE_LANCZOS)
			picture.save_png("res://.godot/geometry-seed184-%02ds.png" % (frame / 60))
	var file := FileAccess.open("res://.godot/geometry-capture-evidence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 184, "input_only": true, "snapshot": snapshot_path, "observations": observations,
		"events": game.events, "lifecycle": game.toys.lifecycle_events}, "\t"))
	file.close()
	print("GEOMETRY CAPTURE snapshot=", snapshot_path, " observations=", observations)
	viewport.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline:
		await process_frame
	quit()
