extends SceneTree
## Seeded natural evolution: input targets only, no repositioning or fabricated contacts.
var viewport: SubViewport
func _init() -> void: call_deferred("_run")
func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").muted = true
	var game = main.geometry_playground
	var world = main.play_world
	game.restart_world(184)
	var ball = main.ball
	var paddle = main.paddle
	paddle.set_physics_process(false)
	var world_events: Array[Dictionary] = []
	world.event_emitted.connect(func(kind, point, intensity): world_events.append({"time": game.elapsed, "kind": kind, "position": [point.x, point.y], "intensity": intensity}))
	var samples: Array[Dictionary] = []
	var max_speed := 0.0
	var max_toys := 0
	var illegal_pairs := 0
	var rests := 0
	var speed_cap: float = main.tuning.max_speed
	var states: Dictionary = {}
	for frame in range(7201):
		var seconds := frame / 60.0
		var aim: float = ball.position.x + sin(seconds * 0.6) * 45
		if fmod(seconds, 24) > 18: aim = 250
		if ball.position.y > paddle.position.y: aim = ball.position.x + (135 if ball.position.x < 480 else -135)
		paddle.set_target_x(aim)
		paddle.advance_motion(1.0 / 60)
		await physics_frame
		max_speed = maxf(max_speed, ball.velocity.length())
		max_toys = maxi(max_toys, game.toys.get_child_count())
		if ball.is_resting(): rests += 1
		states[str(ball.vitality_model.state)] = true
		for core in world.entity_envelopes():
			for envelope in game.toys.entity_envelopes():
				if core.intersects(envelope): illegal_pairs += 1
		if frame % 60 == 0:
			samples.append({"frame": frame, "time": game.elapsed, "ball": [ball.position.x, ball.position.y], "velocity": [ball.velocity.x, ball.velocity.y], "vitality": ball.vitality_model.current_vitality, "activity": ball.vitality_model.state, "rotor": world.rotor_state, "charge": world.charge_state, "spin": world.angular_velocity, "geometry": game.toys.get_child_count(), "held": is_instance_valid(ball.spring_hold)})
		if frame in [600, 1800, 3600]:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://.godot/geometry-coexistence-20260930/natural-%04d.png" % frame)
	var file := FileAccess.open("res://.godot/geometry-coexistence-20260930/natural.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed":184,"frames":7200,"input_only":true,"samples":samples,"world_events":world_events,"geometry_events":game.events,"world_lifecycle":world.export_snapshot().journal,"geometry_lifecycle":game.toys.lifecycle_events,"max_speed":max_speed,"max_toys":max_toys,"illegal_entity_pairs":illegal_pairs,"rest_frames":rests,"states":states,"bounds_recoveries":ball.bounds_recovery_count,"collision_budget_exhaustions":ball.collision_budget_exhaustions}, "\t"))
	file.close()
	print("NATURAL max_speed=", max_speed, " toys=", max_toys, " illegal_pairs=",illegal_pairs," world_events=",world_events.size()," geometry_events=",game.events.size())
	viewport.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	quit(0 if illegal_pairs == 0 and max_toys <= 6 and max_speed <= speed_cap + 0.01 else 1)
