extends RefCounted

const Ball = preload("res://scripts/ball/ball_controller.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Response = preload("res://scripts/physics/surface_response_model.gd")
const TestSupport = preload("res://tests/test_support.gd")


# The Paddle dims only for Vitality it actually hands over: valid hits and Wake.
func run(suite: RefCounted) -> void:
	var tuning: Resource = Tuning.new()
	tuning.shared_world_enabled = true
	tuning.paddle_vitality_restore = 0.30
	var ball: CharacterBody2D = Ball.new()
	ball.configure(tuning)
	var transfers: Array[float] = []
	ball.paddle_energy_transferred.connect(func(amount: float): transfers.append(amount))

	ball.vitality_model.set_vitality(0.4)
	ball.velocity = Vector2(0, 300)
	ball.resolve_surface_collision(Response.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_equal(transfers.size(), 1, "valid Paddle hit reports its transfer")
	if transfers.size() == 1:
		suite.expect_float(transfers[0], 0.18, 0.0001, "transfer equals Vitality actually restored")

	ball.vitality_model.set_vitality(0.4)
	ball.velocity = Vector2(300, 0)
	ball.resolve_surface_collision(Response.SurfaceKind.PADDLE, Vector2.LEFT, false)
	suite.expect_equal(transfers.size(), 1, "invalid Paddle contact transfers nothing")
	ball.velocity = Vector2(0, -300)
	ball.resolve_surface_collision(Response.SurfaceKind.WALL, Vector2.DOWN, false)
	suite.expect_equal(transfers.size(), 1, "other surfaces never dim the Paddle")

	ball.vitality_model.set_vitality(0.04)
	TestSupport.prepare_resting(ball)
	ball.advance_resting_time(0.12)
	suite.expect_true(ball.apply_resting_interaction(25.0, ball.global_position), "Wake activates")
	suite.expect_equal(transfers.size(), 2, "Wake through the Paddle reports its transfer")
	if transfers.size() == 2:
		suite.expect_float(transfers[1], 0.15, 0.0001, "Wake transfer equals its Vitality restore")

	ball.vitality_model.set_vitality(0.04)
	TestSupport.prepare_resting(ball)
	ball.support_kind = ball.SupportKind.GROUND
	ball.note_player_input(20.0)
	var resumed := false
	for frame in range(70):
		ball.advance_play_rhythm(1.0 / 60.0)
		if not ball.is_resting():
			resumed = true
			break
	suite.expect_true(resumed, "Continue fires in the fixture")
	suite.expect_equal(transfers.size(), 2, "Continue is the Ball's own and never dims the Paddle")
	ball.free()
