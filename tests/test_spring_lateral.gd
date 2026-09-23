extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var game = main.geometry_playground
	var ball = main.ball
	main.paddle.set_physics_process(false)
	for incoming_x in [-200.0, 0.0, 200.0, 600.0]:
		ball.set_physics_process(false)
		game.toys.set_layout(1)
		await physics_frame
		var spring: StaticBody2D
		for body in game.toys.get_children():
			if body is StaticBody2D and body.get_meta("toy_kind", "") == "spring": spring = body
		ball.start_active(Vector2.DOWN)
		ball.position = spring.position + Vector2(0, -35)
		ball.velocity = Vector2(incoming_x, 180)
		ball.set_physics_process(true)
		for frame in range(15):
			await physics_frame
			if is_instance_valid(ball.spring_hold): break
		suite.expect_equal(ball.spring_hold, spring, "descending real contact captures incoming lateral motion")
		if ball.spring_hold != spring: continue
		suite.expect_true(ball.velocity.is_zero_approx(), "held Ball pauses motion")
		ball.set_physics_process(false)
		game.toys.set_physics_process(false)
		game.toys._physics_process(0.10)
		ball._advance_spring_hold(0.10)
		suite.expect_equal(ball.spring_hold, spring, "spring stays seated halfway through 0.20 seconds")
		game.toys._physics_process(0.11)
		ball._advance_spring_hold(0.11)
		suite.expect_true(ball.spring_hold == null and ball.velocity.y < 0.0, "spring releases after 0.20 seconds")
		var lateral_cap := sqrt(main.tuning.max_speed * main.tuning.max_speed - main.tuning.spring_release_speed * main.tuning.spring_release_speed)
		var expected_x := clampf(incoming_x * 0.5, -lateral_cap, lateral_cap)
		suite.expect_float(ball.velocity.x, expected_x, 1.5, "release keeps half incoming lateral speed within physical cap")
		suite.expect_float(ball.velocity.y, -main.tuning.spring_release_speed, 1.5, "lateral release preserves vertical spring force")
		game.toys.set_physics_process(true)
		ball.set_physics_process(true)
	for mode in ["invalid", "timeout"]:
		ball.set_physics_process(false)
		game.toys.set_layout(1)
		await physics_frame
		var spring: StaticBody2D
		for body in game.toys.get_children():
			if body is StaticBody2D and body.get_meta("toy_kind", "") == "spring": spring = body
		ball.start_active(Vector2.DOWN)
		ball.position = spring.position + Vector2(0, -35)
		ball.velocity = Vector2(-200 if mode == "invalid" else 200, 180)
		ball.set_physics_process(true)
		for frame in range(15):
			await physics_frame
			if is_instance_valid(ball.spring_hold): break
		suite.expect_equal(ball.spring_hold, spring, mode + " starts from real lateral capture")
		ball.set_physics_process(false)
		game.toys.set_physics_process(false)
		if mode == "invalid":
			game.toys.set_layout(0)
			await process_frame
			ball._advance_spring_hold(0.02)
		else:
			ball._advance_spring_hold(1.21)
		suite.expect_true(ball.spring_hold == null, mode + " fallback releases")
		suite.expect_float(ball.velocity.x, -100 if mode == "invalid" else 100, 1.5, mode + " fallback keeps captured lateral motion")
		suite.expect_float(ball.velocity.y, -main.tuning.spring_release_speed, 1.5, mode + " fallback shares normal spring launch")
		game.toys.set_physics_process(true)
		ball.set_physics_process(true)
	ball.clear_geometry_relationships()
	suite.expect_float(ball._spring_incoming_x, 0.0, 0.001, "new cycle clears prior spring incidence")
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
