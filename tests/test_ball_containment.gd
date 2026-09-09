extends RefCounted

const Ball = preload("res://scripts/ball/ball_controller.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Response = preload("res://scripts/physics/surface_response_model.gd")


func run(suite: RefCounted) -> void:
	var ball := Ball.new()
	ball.configure(Tuning.new())
	suite.expect_true(ball.has_method("configure_arena"), "Ball accepts physical arena bounds")
	if not ball.has_method("configure_arena"):
		ball.free()
		return
	ball.configure_arena(Rect2(173, 133, 615, 448))
	ball.position = Vector2(400, 300)
	ball.velocity = Vector2(120, -90)
	suite.expect_false(ball.recover_out_of_bounds(), "valid flight never invokes recovery")
	suite.expect_equal(ball.velocity, Vector2(120, -90), "containment preserves normal velocity")
	for sample in [
		[Vector2(150, 300), Vector2(-50, 70), Vector2(0, 70)],
		[Vector2(800, 300), Vector2(50, 70), Vector2(0, 70)],
		[Vector2(400, 100), Vector2(50, -70), Vector2(50, 0)],
		[Vector2(400, 700), Vector2(50, 70), Vector2(50, 0)],
		[Vector2(150, 700), Vector2(-50, 70), Vector2.ZERO],
		[Vector2(800, 700), Vector2(50, 70), Vector2.ZERO],
	]:
		ball.vitality_model.reset_active()
		ball.position = sample[0]
		ball.velocity = sample[1]
		suite.expect_true(ball.recover_out_of_bounds(), "outside position is recovered")
		suite.expect_true(ball.position.x >= 189.0 and ball.position.x <= 772.0
			and ball.position.y >= 149.0 and ball.position.y <= 565.0,
			"recovered circle fits inside collision faces")
		suite.expect_equal(ball.velocity, sample[2], "recovery removes only outward velocity")
		suite.expect_float(ball.vitality_model.current_vitality, 1.0, 0.00001,
			"recovery creates no vitality change")
	ball.position = Vector2(150, 300)
	ball.velocity = Vector2(50, -20)
	ball.recover_out_of_bounds()
	suite.expect_equal(ball.velocity, Vector2(50, -20), "inward velocity survives recovery")
	ball.vitality_model.set_vitality(0.04)
	ball.position = Vector2(800, 700)
	ball.velocity = Vector2(150, 300)
	ball.recover_out_of_bounds()
	suite.expect_true(ball.is_resting(), "low vitality ground escape recovers to RESTING")
	suite.expect_equal(ball.velocity, Vector2.ZERO, "ground recovery adds no bounce")
	suite.expect_float(ball.position.y, 564.92, 0.01, "recovery uses stable ground tangent")
	suite.expect_float(ball.vitality_model.current_vitality, 0.04, 0.00001,
		"low vitality recovery does not refill vitality")
	ball.position = Vector2(480, 571.3)
	ball.velocity = Vector2(18, 40)
	ball.resolve_surface_collision(Response.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_float(ball.position.y, 564.92, 0.01, "weak Wake landing repairs penetration")
	suite.expect_false(ball.resting_wake_impulse_consumed, "settle rearms one-shot Wake")
	ball.advance_resting_time(0.12)
	suite.expect_true(ball.apply_resting_wake_impulse(Vector2(500, 0), Vector2(480, 537)),
		"repaired resting ball can be strongly woken again")
	ball.free()
