extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()
var main
var ball
var game

func _init() -> void:
	call_deferred("_run")

func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func body_of(kind: String):
	for child in game.toys.get_children():
		if child is StaticBody2D and child.get_meta("toy_kind", "") == kind:
			return child
	return null

func drop_on(body, speed: float = 180.0) -> void:
	ball.start_active(Vector2.DOWN)
	ball.position = body.position + Vector2(7, -55)
	ball.velocity = Vector2(0, speed)

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game = main.geometry_playground
	ball = main.ball
	main.paddle.set_physics_process(false)
	game.toys.set_layout(1)
	await frames(2)
	var spring = body_of("spring")
	drop_on(spring)
	for frame in range(40):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	suite.expect_equal(ball.spring_hold, spring, "real descending top collision captures spring")
	var seat_y: float = ball.position.y
	var seated_energy: float = ball.vitality_model.current_vitality
	spring.set_meta("remaining", 0.0)
	game.toys.random_mode = true
	game.toys._spawn_timer = 1000.0
	await frames(8)
	suite.expect_true(is_instance_valid(ball.spring_hold) and ball.velocity.is_zero_approx(), "spring holds Ball during compression")
	suite.expect_true(ball.position.y > seat_y + 1.0 and spring.get_meta("compression") > 0.2, "physical Ball follows visible compression")
	suite.expect_true(spring.collision_layer != 0 and spring.get_meta("phase") == "active", "expired held spring retains contact until release")
	for frame in range(75):
		await physics_frame
		if not is_instance_valid(ball.spring_hold): break
	suite.expect_true(ball.spring_hold == null and ball.velocity.y < -450, "automatic bounded release commits strong upward motion")
	var release_shape := CircleShape2D.new()
	release_shape.radius = main.tuning.ball_radius - 0.5
	var release_query := PhysicsShapeQueryParameters2D.new()
	release_query.shape = release_shape
	release_query.transform = ball.global_transform
	release_query.collision_mask = 1
	release_query.exclude = [ball.get_rid()]
	suite.expect_true(main.get_world_2d().direct_space_state.intersect_shape(release_query, 1).is_empty(), "release clears spring before its head rebounds")
	suite.expect_true(ball.vitality_model.current_vitality <= seated_energy, "spring does not replenish Vitality")
	var stages: Array = []
	for event in game.events:
		if event.kind.begins_with("toy_spring_"): stages.append(event.kind)
	suite.expect_equal(stages, ["toy_spring_seat", "toy_spring_compress", "toy_spring_release"], "actual spring stages publish once in order")
	await frames(2)
	suite.expect_true(spring.get_meta("phase") == "fading", "expired spring fades after hold ends")
	# Reset cancels relationships, then a fresh real contact verifies cooldown and invalidation.
	game.toys.set_layout(1)
	await frames(2)
	spring = body_of("spring")
	drop_on(spring)
	for frame in range(60):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	for frame in range(75):
		await physics_frame
		if not is_instance_valid(ball.spring_hold): break
	release_query.transform = ball.global_transform
	suite.expect_true(main.get_world_2d().direct_space_state.intersect_shape(release_query, 1).is_empty(), "live spring head cannot rebound into released Ball")
	drop_on(spring)
	await frames(20)
	suite.expect_true(ball.spring_hold == null, "same spring cooldown prevents immediate recapture")
	ball.set_physics_process(false)
	ball.position = Vector2(800, 100)
	await frames(70)
	ball.set_physics_process(true)
	drop_on(spring)
	for frame in range(40):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	suite.expect_true(is_instance_valid(ball.spring_hold), "spring becomes reusable after cooldown")
	game.toys.set_layout(0)
	await frames(3)
	suite.expect_true(ball.spring_hold == null and ball.velocity.is_finite(), "removed spring cannot permanently hold Ball")
	# A stalled module must not keep its Ball forever, and restart/restore must not inherit holds.
	for scenario in ["timeout", "restart", "snapshot"]:
		game.toys.set_layout(1)
		await frames(2)
		spring = body_of("spring")
		drop_on(spring)
		for frame in range(40):
			await physics_frame
			if is_instance_valid(ball.spring_hold): break
		suite.expect_true(is_instance_valid(ball.spring_hold), scenario + " starts with actual captured Ball")
		if scenario == "timeout":
			game.toys.set_physics_process(false)
			await frames(74)
			suite.expect_true(ball.spring_hold == null and ball.velocity.is_finite(), "Core bounds hold when module clock stalls")
			game.toys.set_physics_process(true)
		elif scenario == "restart":
			game.restart_world(184)
			await frames(6)
			suite.expect_true(ball.spring_hold == null and ball.visible, "restart cancels held Ball before replacing world")
		else:
			suite.expect_true(game.save_combination(), "held mechanical combination saves")
			suite.expect_true(game.restore_combination(), "held mechanical combination restores")
			await frames(6)
			var orphan := false
			for toy in game.toys.export_snapshot().toys:
				if toy.holding: orphan = true
			suite.expect_true(ball.spring_hold == null and not orphan and ball.visible, "snapshot clears orphaned mechanical holds before safe serve")
	game.toys.set_layout(1)
	await frames(2)
	var platform = body_of("platform")
	drop_on(platform, 20.0)
	ball.position = platform.position + Vector2(0, -26)
	ball.vitality_model.set_vitality(0.04)
	await frames(60)
	suite.expect_equal(ball.support_kind, ball.SupportKind.GEOMETRY, "platform real contact establishes support")
	platform.set_meta("remaining", 0.0)
	game.toys.random_mode = true
	game.toys._spawn_timer = 1000.0
	await frames(70)
	suite.expect_true(platform.get_meta("phase") == "active" and platform.collision_layer != 0, "expired platform keeps true resting support")
	ball.apply_resting_interaction(20, Vector2(ball.position.x, 570))
	await frames(2)
	suite.expect_true(platform.get_meta("phase") == "fading", "platform leaves after Wake releases support")
	game.restart_world(184)
	await frames(120)
	suite.expect_true(game.save_combination(), "v2 snapshot saves")
	var data = JSON.parse_string(FileAccess.get_file_as_string(game.last_saved_path))
	suite.expect_equal(data.version, 2.0, "snapshot records refinement version")
	suite.expect_true(game.restore_combination(), "v2 snapshot restores")
	await frames(5)
	suite.expect_true(ball.spring_hold == null and game.spawn_point_clear(ball.position), "snapshot serves safe unheld Ball")
	var old = FileAccess.open("res://.godot/geometry-v1-reject.json", FileAccess.WRITE)
	data.version = 1
	old.store_string(JSON.stringify(data)); old.close()
	suite.expect_false(game.restore_combination("res://.godot/geometry-v1-reject.json"), "older geometry snapshot is explicitly rejected")
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
