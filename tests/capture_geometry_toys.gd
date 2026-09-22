extends SceneTree
## Controlled initial drops, then real Main/Ball Physics. No prescribed flight animation.
var viewport: SubViewport
var main
var toys
var ball
var evidence: Array[Dictionary] = []

func _init() -> void: call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count): await physics_frame

func find_body(kind: String):
	for child in toys.get_children():
		if child is StaticBody2D and child.get_meta("toy_kind", "") == kind: return child
	return null

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").muted = true
	main.paddle.set_physics_process(false)
	toys = main.geometry_playground.toys
	ball = main.ball
	toys.set_layout(1)
	await frames(2)
	var spring = find_body("spring")
	ball.start_active(Vector2.DOWN)
	ball.position = spring.position + Vector2(7, -65)
	ball.velocity = Vector2(0, 180)
	for frame in range(60):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	assert(is_instance_valid(ball.spring_hold), "real spring contact must capture")
	await save("spring-seat")
	await frames(8)
	await save("spring-compress")
	for frame in range(80):
		await physics_frame
		if not is_instance_valid(ball.spring_hold): break
	assert(ball.spring_hold == null and ball.velocity.y < 0, "actual release must occur")
	await save("spring-release")
	var seesaw = find_body("seesaw")
	ball.start_active(Vector2.DOWN)
	ball.position = seesaw.position + Vector2(60, -65)
	ball.velocity = Vector2(0, 350)
	await save("seesaw-before")
	for frame in range(45):
		await physics_frame
		if absf(float(seesaw.get_meta("angular_velocity"))) > 0.01: break
	assert(absf(float(seesaw.get_meta("angular_velocity"))) > 0.01, "actual collision must drive seesaw")
	await frames(6)
	await save("seesaw-impact")
	var file := FileAccess.open("res://.godot/checkpoint-mechanics-evidence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"controlled_initial_conditions": "Fixed layout; spring drop offset (7,-65), initial velocity (0,180); seesaw drop offset (60,-65), initial velocity (0,350). All later motion is Main/Ball Physics.", "frames": evidence, "events": main.geometry_playground.events}, "\t"))
	file.close()
	viewport.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	quit()

func save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	picture.resize(640, 480, Image.INTERPOLATE_LANCZOS)
	var path := "res://.godot/checkpoint-geometry-" + label + ".png"
	var spring = find_body("spring")
	var seesaw = find_body("seesaw")
	evidence.append({"label": label, "time": main.geometry_playground.elapsed, "image": path,
		"ball_position": [ball.position.x, ball.position.y], "ball_velocity": [ball.velocity.x, ball.velocity.y],
		"holding": is_instance_valid(ball.spring_hold), "compression": spring.get_meta("compression"),
		"seesaw_angle": seesaw.rotation, "seesaw_omega": seesaw.get_meta("angular_velocity")})
	print("GEOMETRY CAPTURE ", label, " result=", picture.save_png(path))
