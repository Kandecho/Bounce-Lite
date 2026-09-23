extends SceneTree
## Fixed-layout initial drop; each later pose is the real Ball and spring physics.
var viewport: SubViewport
var main
var ball
var spring
var evidence: Array[Dictionary] = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").muted = true
	main.paddle.set_physics_process(false)
	var toys = main.geometry_playground.toys
	toys.set_layout(1)
	for frame in range(2): await physics_frame
	for body in toys.get_children():
		if body is StaticBody2D and body.get_meta("toy_kind", "") == "spring": spring = body
	ball = main.ball
	ball.start_active(Vector2.DOWN)
	ball.position = spring.position + Vector2(7, -65)
	ball.velocity = Vector2(120, 180)
	for frame in range(60):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	assert(ball.spring_hold == spring, "real spring contact must capture")
	await save("seat")
	for frame in range(7): await physics_frame
	await save("compress")
	for frame in range(30):
		await physics_frame
		if ball.spring_hold == null: break
	assert(ball.spring_hold == null and ball.velocity.y < 0, "spring must release")
	await save("release")
	var path := "res://.godot/spring-refinement-15x/capture-%s.json" % main.tuning.motion_profile
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": main.tuning.motion_profile, "initial_offset": [7, -65], "initial_velocity": [120, 180], "frames": evidence, "events": main.geometry_playground.events}, "\t"))
	file.close()
	viewport.queue_free()
	await process_frame
	quit(0)

func save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	var path := "res://.godot/spring-refinement-15x/spring-%s-%s.png" % [main.tuning.motion_profile, label]
	assert(picture.save_png(path) == OK)
	evidence.append({"label": label, "time": main.geometry_playground.elapsed, "image": path, "position": [ball.position.x, ball.position.y], "velocity": [ball.velocity.x, ball.velocity.y], "holding": is_instance_valid(ball.spring_hold), "compression": spring.get_meta("compression")})
	print("SPRING CAPTURE ", label, " path=", path)
