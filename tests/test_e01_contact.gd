extends RefCounted

const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Response = preload("res://scripts/physics/surface_response_model.gd")


func run(suite: RefCounted) -> void:
	var tuning = Tuning.new()
	var response = Response.new(tuning)
	var incoming := Vector2(80, 280)
	var baseline = response.resolve(incoming, Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true)
	var off = response.resolve(incoming, Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true, 0.8)
	suite.expect_equal(off.velocity_after, baseline.velocity_after, "E01 disabled preserves original response")
	tuning.e01_contact_enabled = true
	var center = response.resolve(incoming, Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true)
	var left = response.resolve(incoming, Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true, -0.8)
	var right = response.resolve(incoming, Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true, 0.8)
	suite.expect_equal(center.velocity_after, baseline.velocity_after, "center contact retains the incoming trajectory")
	suite.expect_true(left.velocity_after.x < center.velocity_after.x - 30, "left contact has a perceptible left tendency")
	suite.expect_true(right.velocity_after.x > center.velocity_after.x + 30, "right contact has a perceptible right tendency")
	for result in [left, right]:
		suite.expect_float(result.velocity_after.length(), baseline.velocity_after.length(), 0.001, "contact bias adds no energy")
		suite.expect_float(result.vitality_after, baseline.vitality_after, 0.0001, "contact bias does not change Vitality")
		suite.expect_true(result.velocity_after.y < 0, "top contact continues away from Paddle")
	var other_incoming = response.resolve(Vector2(-240, 280), Vector2.UP, Response.SurfaceKind.PADDLE, 0.4, 0.4, 1.0, true, 0.8)
	suite.expect_true(other_incoming.velocity_after.x < 0, "same right-side input cannot erase strong leftward incoming motion")
	suite.expect_true(other_incoming.velocity_after.distance_to(right.velocity_after) > 100, "contact location does not prescribe the outgoing trajectory")
	for kind in [Response.SurfaceKind.WALL, Response.SurfaceKind.GROUND, Response.SurfaceKind.PADDLE]:
		var plain = response.resolve(incoming, Vector2.UP, kind, 0.4, 0.4, 1.0, false)
		var biased = response.resolve(incoming, Vector2.UP, kind, 0.4, 0.4, 1.0, false, 1.0)
		suite.expect_equal(biased.velocity_after, plain.velocity_after, "non-effective contact ignores contact offset")
	for offset in [-5.0, -1.0, 1.0, 5.0]:
		var capped = response.resolve(Vector2(500, 500), Vector2.UP, Response.SurfaceKind.PADDLE, 1, 1, 1, true, offset)
		suite.expect_true(capped.velocity_after.length() <= tuning.max_speed + 0.001, "E01 respects speed cap")
		suite.expect_true(capped.velocity_after.y < 0, "extreme offset cannot turn top contact downward")
		var bounded = response.resolve(Vector2(500, 500), Vector2.UP, Response.SurfaceKind.PADDLE, 1, 1, 1, true, clampf(offset, -1, 1))
		suite.expect_equal(capped.velocity_after, bounded.velocity_after, "offset remains bounded outside Paddle width")
