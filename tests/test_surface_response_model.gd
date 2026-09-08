extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const RESULT_PATH := "res://scripts/physics/surface_collision_result.gd"
const RESPONSE_PATH := "res://scripts/physics/surface_response_model.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var result_script: Script = load(RESULT_PATH)
	var response_script: Script = load(RESPONSE_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning exists for Surface tests")
	suite.expect_not_null(result_script, "SurfaceCollisionResult exists")
	suite.expect_not_null(response_script, "SurfaceResponseModel exists")
	if tuning_script == null or result_script == null or response_script == null:
		return
	suite.expect_true(result_script.can_instantiate(), "SurfaceCollisionResult parses")
	suite.expect_true(response_script.can_instantiate(), "SurfaceResponseModel parses")
	if not result_script.can_instantiate() or not response_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var response: RefCounted = response_script.new(tuning)

	var wall: RefCounted = response.resolve(
		Vector2(100.0, 20.0), Vector2.LEFT,
		response_script.SurfaceKind.WALL, 1.0, 1.0, 1.0, false)
	suite.expect_float(wall.velocity_after.x, -99.5, 0.001,
		"Wall reflects the normal component with light loss")
	suite.expect_float(wall.velocity_after.y, 19.9, 0.001,
		"Wall lightly retains the tangent component")
	suite.expect_float(wall.vitality_delta, -0.015, 0.0001,
		"Wall applies light Vitality wear")
	suite.expect_false(wall.settle_allowed,
		"Wall never grants physical settling")

	var top: RefCounted = response.resolve(
		Vector2(20.0, -100.0), Vector2.DOWN,
		response_script.SurfaceKind.TOP, 1.0, 1.0, 1.0, false)
	suite.expect_true(top.velocity_after.y > 0.0,
		"Top reflects downward with light loss")
	suite.expect_float(top.vitality_delta, wall.vitality_delta, 0.0001,
		"Top and Wall use the same initial Vitality wear")

	var ground: RefCounted = response.resolve(
		Vector2(80.0, 300.0), Vector2.UP,
		response_script.SurfaceKind.GROUND, 1.0, 1.0, 1.0, false)
	suite.expect_float(ground.velocity_after.x, 64.0, 0.001,
		"Ground friction reduces tangent speed")
	suite.expect_float(ground.velocity_after.y, -234.0, 0.001,
		"full-Vitality Ground response uses the current 0.78 restitution")
	suite.expect_float(ground.vitality_delta, -0.35, 0.0001,
		"Ground keeps sixty-five percent Vitality")
	suite.expect_true(ground.vitality_delta < wall.vitality_delta,
		"Ground loses more Vitality than Wall")
	suite.expect_false(ground.settle_allowed,
		"a fast Ground response cannot settle")

	var ground_at_sixty_five: RefCounted = response.resolve(
		Vector2(0.0, 300.0), Vector2.UP,
		response_script.SurfaceKind.GROUND, 0.65, 0.65, 1.0, false)
	suite.expect_float(ground_at_sixty_five.velocity_after.y, -164.7, 0.001,
		"Ground uses Vitality from before the current collision")
	suite.expect_float(ground_at_sixty_five.vitality_after, 0.4225, 0.0001,
		"Ground reports post-collision Vitality without using it for current response")

	var paddle: RefCounted = response.resolve(
		Vector2(0.0, 100.0), Vector2.UP,
		response_script.SurfaceKind.PADDLE, 0.20, 0.20, 1.0, true)
	suite.expect_float(paddle.velocity_after.y, -236.0, 0.001,
		"Paddle adds fixed impulse after its ordinary response")
	suite.expect_float(paddle.vitality_delta, 0.80, 0.0001,
		"Paddle returns the delta needed to restore max Vitality")
	suite.expect_float(paddle.vitality_after, 1.0, 0.0001,
		"Paddle result reports restored Vitality")
	suite.expect_true(paddle.valid_paddle_hit,
		"valid Paddle result preserves semantic contact status")
	suite.expect_false(paddle.settle_allowed,
		"Paddle never grants physical settling")

	var capped_paddle: RefCounted = response.resolve(
		Vector2(0.0, 500.0), Vector2.UP,
		response_script.SurfaceKind.PADDLE, 1.0, 1.0, 1.0, true)
	suite.expect_float(capped_paddle.velocity_after.length(), 520.0, 0.001,
		"Paddle impulse remains below the global speed cap")

	var invalid_paddle: RefCounted = response.resolve(
		Vector2(100.0, 20.0), Vector2.LEFT,
		response_script.SurfaceKind.PADDLE, 1.0, 1.0, 1.0, false)
	suite.expect_equal(invalid_paddle.effective_surface_kind,
		response_script.SurfaceKind.WALL,
		"invalid Paddle contact uses Wall-like response")
	suite.expect_float(invalid_paddle.velocity_after.x, wall.velocity_after.x, 0.001,
		"invalid Paddle contact has Wall-like velocity")
	suite.expect_float(invalid_paddle.vitality_delta, wall.vitality_delta, 0.0001,
		"invalid Paddle contact does not restore Vitality")

	var zero_normal: RefCounted = response.resolve(
		Vector2(12.0, -34.0), Vector2.ZERO,
		response_script.SurfaceKind.GROUND, 0.5, 0.5, 1.0, false)
	suite.expect_float(zero_normal.velocity_after.x, 12.0, 0.0001,
		"zero normal preserves horizontal Velocity")
	suite.expect_float(zero_normal.velocity_after.y, -34.0, 0.0001,
		"zero normal preserves vertical Velocity")
	suite.expect_float(zero_normal.vitality_delta, 0.0, 0.0001,
		"zero normal cannot change Vitality")

	var slow_ground: RefCounted = response.resolve(
		Vector2(10.0, 20.0), Vector2.UP,
		response_script.SurfaceKind.GROUND, 1.0, 1.0, 1.0, false)
	suite.expect_true(slow_ground.velocity_after.length() < tuning.rest_settle_speed,
		"slow Ground response is below the settle threshold")
	suite.expect_true(slow_ground.settle_allowed,
		"only a slow Ground response grants settling")

	var repeated_wall: RefCounted = response.resolve(
		Vector2(100.0, 20.0), Vector2.LEFT,
		response_script.SurfaceKind.WALL, 1.0, 1.0, 1.0, false)
	suite.expect_float(repeated_wall.velocity_after.x, wall.velocity_after.x, 0.0001,
		"Surface response is deterministic for equal inputs")
	suite.expect_float(repeated_wall.vitality_after, wall.vitality_after, 0.0001,
		"Surface Vitality result is deterministic for equal inputs")
