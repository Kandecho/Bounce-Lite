extends RefCounted

func run(suite: RefCounted) -> void:
	var ball = load("res://scripts/ball/ball_controller.gd").new()
	ball.configure(load("res://scripts/config/prototype_tuning.gd").new())
	ball.configure_arena(Rect2(173, 133, 615, 448))
	for hz in [30, 60, 120]:
		for direction in [-1, 1]:
			ball.start_active(Vector2.UP)
			ball.position = Vector2(480, 564.92)
			ball.vitality_model.set_vitality(0.04)
			load("res://tests/test_support.gd").prepare_resting(ball)
			ball.advance_resting_time(0.12)
			for index in range(12):
				ball.apply_resting_interaction(50.0 / hz, Vector2(480 + direction * 150, 537))
				ball.advance_resting_time(1.0 / hz)
			suite.expect_true(ball.is_resting(), "slow input responds without accumulating forever")
			suite.expect_equal(ball.velocity, Vector2.ZERO, "weak input never launches at any tick rate")
			suite.expect_true(ball.apply_resting_interaction(30, Vector2(480 + direction * 150, 537)), "departing gesture can wake")
			suite.expect_equal(ball.velocity, Vector2(0, -350), "same launch for either direction and input size")
			suite.expect_equal(ball.get_collision_exceptions().size(), 0, "all surfaces remain real")
	ball.start_active(Vector2.UP)
	ball.position = Vector2(480, 564.92)
	ball.vitality_model.set_vitality(0.04)
	load("res://tests/test_support.gd").prepare_resting(ball)
	ball.advance_resting_time(0.12)
	ball.apply_resting_interaction(10, Vector2(480, 537))
	ball.apply_resting_interaction(0, Vector2(681, 537))
	suite.expect_false(ball.apply_resting_interaction(3, Vector2(480, 537)), "leaving range discards previous weak accumulation")
	ball.advance_resting_time(0.1)
	suite.expect_true(ball.is_resting(), "deadline does not launch a stale gesture")
	ball.free()
