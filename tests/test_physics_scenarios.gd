extends SceneTree

const Support = preload("res://tests/test_support.gd")
const MainScene = preload("res://scenes/main.tscn")
var suite = Support.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	var ball = main.get_node("GameArea/Ball")
	var paddle = main.get_node("GameArea/Paddle")
	var contacts: Array[bool] = []
	ball.paddle_contact.connect(func(valid: bool, _point: Vector2) -> void: contacts.append(valid))
	ball.set_physics_process(false)
	paddle.set_physics_process(false)
	await physics_frame
	await physics_frame
	# Geometry comes from the real scene (whole client area is the world).
	var ground_y: float = ball.safe_center_bounds().end.y
	var paddle_y: float = paddle.position.y
	var support_y: float = paddle_y - main.tuning.paddle_size.y * 0.5 - main.tuning.ball_radius - ball.safe_margin
	var underside_y: float = paddle_y + main.tuning.paddle_size.y * 0.5 + main.tuning.ball_radius
	var corner_left: float = ball.arena_bounds.position.x + main.tuning.ball_radius + 1.0
	var corner_right: float = ball.arena_bounds.end.x - main.tuning.ball_radius - 1.0
	var paddle_min_x: float = ball.arena_bounds.position.x + main.tuning.paddle_size.x * 0.5
	var paddle_max_x: float = ball.arena_bounds.end.x - main.tuning.paddle_size.x * 0.5
	# Developer time is independent of Rest, collisions and Wake; only delta advances it.
	var panel = main.get_node("DebugOverlay/RuntimeTuningPanel")
	panel.set_process(false)
	panel.observation_seconds = 10.0
	ball.position = Vector2(480, ground_y)
	ball.vitality_model.set_vitality(0.04)
	load("res://tests/test_support.gd").prepare_resting(ball)
	panel.advance_observation_time(1.0)
	suite.expect_float(panel.observation_seconds, 11.0, 0.0001, "RESTING does not pause developer time")
	ball.advance_resting_time(0.12)
	ball.apply_resting_interaction(25, paddle.position)
	suite.expect_float(panel.observation_seconds, 11.0, 0.0001, "Wake never resets developer time")
	var motion_before_clock: Vector2 = ball.velocity
	var vitality_before_clock: float = ball.vitality_model.current_vitality
	panel.advance_observation_time(1.0)
	suite.expect_equal(ball.velocity, motion_before_clock, "developer time cannot change Physics")
	suite.expect_float(ball.vitality_model.current_vitality, vitality_before_clock, 0.0001, "developer time cannot change Vitality")
	# Real scene geometry, real move_and_collide, fixed time steps.
	for start_x in [corner_left, 480.0, corner_right]:
		ball.position = Vector2(start_x, ground_y)
		ball.vitality_model.set_vitality(0.04)
		load("res://tests/test_support.gd").prepare_resting(ball)
		ball.advance_resting_time(0.12)
		paddle.position.x = clampf(start_x, paddle_min_x + 1.0, paddle_max_x - 1.0)
		await physics_frame
		paddle.advance_feedback(1.0)
		ball.apply_resting_interaction(5.0, paddle.position)
		ball.advance_resting_time(0.05)
		suite.expect_float(paddle.dim_strength(), 0.0, 0.0001,
			"weak interaction transfers nothing through Paddle")
		for frame in range(120):
			await physics_frame
			ball._physics_process(1.0 / 60.0)
			suite.expect_true(ball.safe_center_bounds().grow(0.13).has_point(ball.position),
				"weak Wake stays inside real scene at x=%s frame=%s" % [start_x, frame])
		suite.expect_true(ball.is_resting(), "weak Wake settles without activation")
		suite.expect_float(ball.position.y, ground_y, 0.1, "weak Wake returns to legal ground tangent")
		suite.expect_equal(ball.velocity, Vector2.ZERO, "weak Wake fully settles")
		suite.expect_false(ball.wake_consumed, "scene settle rearms Wake")
		suite.expect_true(ball.apply_resting_interaction(25.0, Vector2(ball.position.x, paddle_y)),
			"strong Wake remains available after scene settle")
		suite.expect_true(paddle.dim_strength() > 0.0,
			"strong Wake hands its Vitality through the Paddle")
	# Actual smoothed swipes: tiny onset, then a fast motion away from the launch path.
	for hz in [30, 60, 120]:
		for direction in [-1.0, 1.0]:
			ball.start_active(Vector2.UP)
			ball.position = Vector2(480, ground_y)
			ball.vitality_model.set_vitality(0.04)
			load("res://tests/test_support.gd").prepare_resting(ball)
			ball.advance_resting_time(0.12)
			paddle.position.x = 480 + direction * 130
			paddle.configure(main.tuning, ball.arena_bounds.position.x, ball.arena_bounds.end.x, paddle_y)
			paddle.set_target_x(paddle.position.x + direction)
			await physics_frame
			paddle.advance_motion(1.0 / hz)
			suite.expect_false(ball.wake_consumed, "small swipe onset remains available")
			ball._physics_process(1.0 / hz)
			paddle.set_target_x(paddle.position.x + direction * 50)
			# Physical travel, rather than the target jump, crosses the Wake threshold.
			for sample in range(3):
				paddle.advance_motion(1.0 / hz)
				if not ball.is_resting():
					break
				ball.advance_resting_time(1.0 / hz)
			suite.expect_false(ball.is_resting(), "actual left/right swipe activates Wake")
			suite.expect_true(ball.velocity.y < -300, "swipe produces clear upward movement")
			contacts.clear()
			for frame in range(hz * 2 / 3):
				await physics_frame
				ball._physics_process(1.0 / hz)
			suite.expect_true(ball.position.y < paddle_y - 25.0, "clear path allows Ball to rise above Paddle height")
			suite.expect_true(contacts.is_empty(), "departed Paddle does not obstruct launch")
			suite.expect_equal(ball.get_collision_exceptions().size(), 0, "clear launch has no collision exception")
	# A Paddle left overhead must really block the Wake, then allow stable rearming.
	for hz in [30, 60, 120]:
		ball.start_active(Vector2.UP)
		ball.position = Vector2(480, ground_y)
		paddle.position.x = 480
		ball.vitality_model.set_vitality(0.04)
		load("res://tests/test_support.gd").prepare_resting(ball)
		ball.advance_resting_time(0.12)
		contacts.clear()
		await physics_frame
		ball.apply_resting_interaction(25.0, paddle.position)
		for frame in range(hz * 8):
			await physics_frame
			ball._physics_process(1.0 / hz)
		suite.expect_true(contacts.has(false), "overhead Paddle retains real underside collision")
		suite.expect_true(ball.is_resting(), "blocked launch eventually settles back to Resting")
		suite.expect_equal(ball.velocity, Vector2.ZERO, "blocked launch does not chatter indefinitely")
		suite.expect_false(ball.wake_consumed, "blocked launch rearms after settling")
		suite.expect_equal(ball.get_collision_exceptions().size(), 0, "blocked launch has no collision exception")
		suite.expect_true(ball.apply_resting_interaction(25.0, Vector2(310, paddle_y)), "next Wake remains available after blocked launch")
	# Paddle is real support: low-energy top arrival settles without repeat events.
	for hz in [30, 60, 120]:
		ball.start_active(Vector2.UP)
		paddle.position.x = 480
		ball.position = Vector2(480, support_y - 1.0)
		ball.vitality_model.set_vitality(0.04)
		ball.velocity = Vector2(0, 20)
		contacts.clear()
		for frame in range(hz):
			await physics_frame
			ball._physics_process(1.0 / hz)
		suite.expect_equal(ball.support_kind, ball.SupportKind.PADDLE, "low-energy arrival rests on Paddle")
		suite.expect_true(ball.is_resting(), "Paddle support has independent resting activity")
		suite.expect_equal(ball.velocity, Vector2.ZERO, "Paddle rest does not micro-bounce")
		suite.expect_true(contacts.is_empty(), "support does not emit repeated collision feedback")
		suite.expect_float(ball.vitality_model.current_vitality, 0.04, 0.0001, "support does not reward or wear vitality")
		var x_before: float = ball.position.x
		paddle.position.x += 20
		await physics_frame
		ball._physics_process(1.0 / hz)
		suite.expect_float(ball.position.x, x_before, 0.0001, "Paddle translation does not carry Ball")
		suite.expect_equal(ball.support_kind, ball.SupportKind.PADDLE, "overlapping support persists")
		paddle.position.x += 120
		await physics_frame
		ball._physics_process(1.0 / hz)
		suite.expect_equal(ball.support_kind, ball.SupportKind.NONE, "departed Paddle releases support")
		suite.expect_true(ball.velocity.y > 0, "zero-velocity resting Ball falls when unsupported")
		suite.expect_float(ball.vitality_model.current_vitality, 0.04, 0.0001, "support loss is physics, not vitality recovery")
		# Settle again, then weak response and one strong restart from Paddle.
		paddle.position.x = 480
		ball.position = Vector2(480, support_y - 1.0)
		ball.velocity = Vector2(0, 20)
		for frame in range(hz):
			await physics_frame
			ball._physics_process(1.0 / hz)
		ball.apply_resting_interaction(3, paddle.position)
		suite.expect_equal(ball.velocity, Vector2.ZERO, "Paddle weak feedback is non-launching")
		suite.expect_true(ball.apply_resting_interaction(30, paddle.position), "Paddle supports a fresh strong Wake")
		suite.expect_equal(ball.velocity, Vector2(0, -350), "Paddle restart equals Ground restart")
		for frame in range(hz / 5):
			await physics_frame
			ball._physics_process(1.0 / hz)
		suite.expect_true(ball.position.y < support_y - 11.0, "Paddle-supported strong Wake leaves support normally")
	# Bottom corners with repeatedly driven Paddle. Recovery must not become the normal path.
	for start_x in [corner_left, corner_right]:
		ball.position = Vector2(start_x, ground_y)
		ball.vitality_model.set_vitality(0.02)
		load("res://tests/test_support.gd").prepare_resting(ball)
		for frame in range(180):
			await physics_frame
			paddle.set_target_x(start_x if frame % 60 < 30 else 480.0)
			paddle.advance_motion(1.0 / 60.0)
			ball._physics_process(1.0 / 60.0)
			suite.expect_true(ball.safe_center_bounds().grow(0.13).has_point(ball.position),
				"corner Paddle input cannot eject Ball")
	# Verify regular flight still runs entirely through collisions, without fallback clamps.
	ball.position = Vector2(480, 300)
	ball.start_active(Vector2(0.62, 1.0))
	var recovery_before: int = ball.bounds_recovery_count
	for frame in range(600):
		await physics_frame
		ball._physics_process(1.0 / 60.0)
	suite.expect_equal(ball.bounds_recovery_count, recovery_before,
		"normal flight never uses exceptional bounds recovery")
	# Descending top contact restores Vitality; an underside contact must not.
	paddle.position.x = 480.0
	contacts.clear()
	ball.position = Vector2(480, paddle_y - 57.0)
	ball.vitality_model.set_vitality(0.20)
	ball.velocity = Vector2(0, 200)
	for frame in range(20):
		await physics_frame
		ball._physics_process(1.0 / 60.0)
	suite.expect_true(contacts.has(true), "real top collision emits valid Paddle feedback")
	suite.expect_float(ball.vitality_model.current_vitality, 0.20 + 0.80 * main.tuning.paddle_vitality_restore, 0.001,
		"normal top collision restores the configured share of missing Vitality")
	contacts.clear()
	# The Ball's own region below the Paddle: rising into the underside from just below it.
	ball.position = Vector2(480, underside_y + 20.0)
	ball.vitality_model.set_vitality(0.20)
	ball.velocity = Vector2(0, -225)
	for frame in range(6):
		await physics_frame
		ball._physics_process(1.0 / 60.0)
	suite.expect_true(contacts.has(false), "real underside collision emits invalid Paddle feedback")
	suite.expect_false(contacts.has(true), "underside contact is never an effective Paddle hit")
	suite.expect_true(ball.vitality_model.current_vitality <= 0.20,
		"underside contact cannot restore Vitality")
	# A real valid Paddle hit resolves before input; no second launch/reward.
	ball.start_active(Vector2.DOWN)
	paddle.position.x = 480
	ball.position = Vector2(480, paddle_y - 27.0)
	ball.vitality_model.set_vitality(0.2)
	ball.velocity = Vector2(0, 200)
	await physics_frame
	ball._physics_process(1.0 / 60)
	var after_contact: Vector2 = ball.velocity
	suite.expect_false(ball.apply_resting_interaction(100, paddle.position), "normal contact cannot also commit Wake")
	suite.expect_equal(ball.velocity, after_contact, "normal rebound is never doubled by same-tick input")
	# A stopped escaped Ball must also be recovered before the RESTING early return.
	ball.vitality_model.set_vitality(0.02)
	load("res://tests/test_support.gd").prepare_resting(ball)
	ball.position = Vector2(900, 800)
	ball._physics_process(1.0 / 60.0)
	suite.expect_float(ball.position.y, ground_y, 0.01, "stationary escaped Ball is recovered")
	suite.expect_true(ball.is_resting(), "escape recovery preserves stable rest")
	suite.print_summary()
	main.free()
	OS.delay_msec(100)
	await process_frame
	quit(0 if suite.failures == 0 else 1)
