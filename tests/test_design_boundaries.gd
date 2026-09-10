extends RefCounted

const Ball = preload("res://scripts/ball/ball_controller.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Surface = preload("res://scripts/physics/surface_response_model.gd")


func run(suite: RefCounted) -> void:
	var ball = Ball.new()
	ball.velocity = Vector2(73, -91)
	ball.configure(Tuning.new())
	suite.expect_equal(ball.velocity, Vector2(73, -91), "configure must not launch or rewrite motion")
	ball.vitality_model.set_vitality(0.04)
	ball.velocity = Vector2(120, -210)
	ball.position = Vector2(400, 300)
	ball.rest_elapsed_time = 0.7
	ball.wake_consumed = true
	ball.vitality_model.resolve_activity(true)
	suite.expect_equal(ball.velocity, Vector2(120, -210), "Activity transition preserves Velocity")
	suite.expect_equal(ball.position, Vector2(400, 300), "Activity transition preserves Position")
	suite.expect_float(ball.rest_elapsed_time, 0.7, 0.0001, "Activity notification does not reset rest lifecycle")
	suite.expect_true(ball.wake_consumed, "Activity notification does not rearm Interaction")
	var original_model = ball.vitality_model
	ball.configure(Tuning.new())
	suite.expect_equal(ball.vitality_model, original_model, "configure preserves the current model lifecycle")
	suite.expect_float(ball.vitality_model.current_vitality, 0.04, 0.0001, "configure does not restore Vitality")
	suite.expect_true(ball.is_resting(), "configure does not start a new activity cycle")
	ball.start_active(Vector2.RIGHT)
	suite.expect_equal(ball.velocity, Vector2(360, 0), "explicit start controls launch direction")
	# State observers must see already-applied physical settle, on either surface.
	var observed: Array = []
	ball.vitality_model.activity_state_changed.connect(func(_before: int, after: int):
		if after == 2:
			observed.append([ball.velocity, ball.position.y, ball.support_kind])
	)
	ball.configure_arena(Rect2(173, 133, 615, 448))
	ball.position = Vector2(480, 564.92)
	ball.velocity = Vector2(0, 20)
	ball.vitality_model.set_vitality(0.04)
	ball.resolve_surface_collision(Surface.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_equal(observed.size(), 1, "Ground commits one resting transition")
	if observed.size() == 1:
		suite.expect_equal(observed[0][0], Vector2.ZERO, "Ground velocity settled before Activity notification")
		suite.expect_equal(observed[0][2], ball.SupportKind.GROUND, "Ground support committed before Activity notification")
	var paddle := Node2D.new()
	paddle.position = Vector2(480, 537)
	ball.configure_support(paddle)
	ball.start_active(Vector2.DOWN)
	ball.position = Vector2(480, 511.95)
	ball.velocity = Vector2(0, 20)
	ball.vitality_model.set_vitality(0.04)
	ball.resolve_surface_collision(Surface.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_equal(observed.size(), 2, "Paddle commits one resting transition")
	if observed.size() == 2:
		suite.expect_equal(observed[1][0], Vector2.ZERO, "Paddle velocity settled before Activity notification")
		suite.expect_equal(observed[1][2], ball.SupportKind.PADDLE, "Paddle support committed before Activity notification")
		suite.expect_float(observed[1][1], 511.92, 0.001, "Paddle position settled before Activity notification")
	ball.free()
	paddle.free()
	ball = Ball.new()
	ball.start_active(Vector2.LEFT)
	suite.expect_equal(ball.velocity, Vector2(-360, 0), "unconfigured explicit start respects requested direction")
	ball.free()
