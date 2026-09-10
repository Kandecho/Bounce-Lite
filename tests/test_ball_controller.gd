extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const VITALITY_PATH := "res://scripts/ball/ball_vitality_model.gd"
const RESPONSE_PATH := "res://scripts/physics/surface_response_model.gd"
const CONTROLLER_PATH := "res://scripts/ball/ball_controller.gd"
const VISUALS_PATH := "res://scripts/ball/ball_visuals.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var vitality_script: Script = load(VITALITY_PATH)
	var response_script: Script = load(RESPONSE_PATH)
	var controller_script: Script = load(CONTROLLER_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning is available to Ball tests")
	suite.expect_not_null(vitality_script, "BallVitalityModel is available to Ball tests")
	suite.expect_not_null(response_script, "SurfaceResponseModel is available to Ball tests")
	suite.expect_not_null(controller_script, "BallController exists")
	if (
		tuning_script == null
		or vitality_script == null
		or response_script == null
		or controller_script == null
	):
		return
	suite.expect_true(controller_script.can_instantiate(), "BallController parses")
	if not controller_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var ball: CharacterBody2D = controller_script.new()
	ball.configure(tuning)
	var vitality_model: Variant = ball.get("vitality_model")
	suite.expect_not_null(vitality_model,
		"BallController exposes its independent Vitality collaborator")
	if vitality_model == null:
		ball.free()
		return
	suite.expect_not_null(ball.get("surface_response_model"),
		"BallController exposes its pure Surface response collaborator")

	ball.start_active(Vector2(1.0, -1.0))
	suite.expect_float(ball.velocity.length(), 360.0, 0.01,
		"active Ball starts from explicit launch speed")
	suite.expect_true(ball.has_method("advance_air_motion"),
		"Ball exposes deterministic air motion integration")

	ball.velocity = Vector2(123.0, -45.0)
	var velocity_before_vitality_change := ball.velocity
	ball.vitality_model.set_vitality(0.25)
	suite.expect_float(ball.velocity.x, velocity_before_vitality_change.x, 0.0001,
		"changing Vitality does not rebuild horizontal Velocity")
	suite.expect_float(ball.velocity.y, velocity_before_vitality_change.y, 0.0001,
		"changing Vitality does not rebuild vertical Velocity")

	ball.vitality_model.set_vitality(1.0)
	ball.velocity = Vector2.RIGHT * 360.0
	ball.advance_air_motion(0.1)
	var full_vitality_gravity_delta := ball.velocity.y
	suite.expect_float(full_vitality_gravity_delta, 26.0, 0.01,
		"fixed gravity adds vertical speed in the air")
	ball.vitality_model.set_vitality(0.25)
	ball.velocity = Vector2.RIGHT * 360.0
	ball.advance_air_motion(0.1)
	suite.expect_float(ball.velocity.y, full_vitality_gravity_delta, 0.01,
		"gravity acceleration is independent of Vitality")
	ball.velocity = Vector2.ZERO
	ball.advance_air_motion(10.0)
	suite.expect_float(ball.velocity.length(), 520.0, 0.01,
		"gravity-driven fall remains below the safety speed cap")

	var settled_results: Array = []
	ball.surface_resolved.connect(func(result: RefCounted) -> void:
		settled_results.append([
			result.vitality_after,
			ball.vitality_model.current_vitality,
			ball.velocity,
			ball.vitality_model.state,
		])
	)
	ball.vitality_model.reset_active()
	ball.velocity = Vector2(80.0, 300.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_float(ball.velocity.x, 64.0, 0.01,
		"Ground applies tangential friction to current Velocity")
	suite.expect_float(ball.velocity.y, -234.0, 0.01,
		"Ground current response uses pre-collision full Vitality")
	suite.expect_float(ball.vitality_model.current_vitality, 0.65, 0.0001,
		"Ground updates Vitality after applying Velocity")
	suite.expect_equal(settled_results.size(), 1,
		"Ball emits one settled result per collision")
	if settled_results.size() == 1:
		suite.expect_float(settled_results[0][0], settled_results[0][1], 0.0001,
			"settled event observes applied Vitality")
		suite.expect_float(settled_results[0][2].y, ball.velocity.y, 0.0001,
			"settled event observes applied Velocity")

	ball.vitality_model.reset_active()
	ball.velocity = Vector2(100.0, 20.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.WALL, Vector2.LEFT, false)
	suite.expect_true(ball.velocity.x < 0.0,
		"Wall collision reflects current Velocity horizontally")
	suite.expect_float(ball.vitality_model.current_vitality, 0.985, 0.0001,
		"Wall applies light Vitality wear")

	ball.vitality_model.set_vitality(0.20)
	ball.velocity = Vector2(0.0, 100.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_float(ball.vitality_model.current_vitality, 1.0, 0.0001,
		"valid Paddle hit restores max Vitality")
	suite.expect_float(ball.velocity.y, -236.0, 0.01,
		"Paddle adds fixed impulse without rebuilding mapped speed")
	suite.expect_true(not is_equal_approx(ball.velocity.length(), 360.0),
		"Paddle recovery is not forced to the old active speed")

	ball.vitality_model.reset_active()
	ball.velocity = Vector2(0.0, 500.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_float(ball.velocity.length(), 520.0, 0.01,
		"Paddle impulse cannot exceed max speed")
	ball.velocity = Vector2(0.0, 500.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_float(ball.velocity.length(), 520.0, 0.01,
		"repeated Paddle success cannot create infinite speed")

	ball.vitality_model.reset_active()
	ball.velocity = Vector2(100.0, 20.0)
	ball.resolve_surface_collision(response_script.SurfaceKind.PADDLE, Vector2.LEFT, false)
	suite.expect_float(ball.vitality_model.current_vitality, 0.985, 0.0001,
		"invalid Paddle contact has Wall-like Vitality wear")
	suite.expect_true(ball.velocity.x < 0.0,
		"invalid Paddle contact has Wall-like reflection")

	ball.vitality_model.reset_active()
	ball.velocity = Vector2(80.0, 300.0)
	for index in range(16):
		if ball.is_resting():
			break
		ball.velocity.y = absf(ball.velocity.y)
		ball.resolve_surface_collision(response_script.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_true(ball.is_resting(),
		"repeated Ground arrivals eventually rest the Ball")
	suite.expect_float(ball.velocity.length(), 0.0, 0.0001,
		"RESTING zeroes physical Velocity only after settlement")
	ball.free()

	var visuals_script: Script = load(VISUALS_PATH)
	if visuals_script == null or not visuals_script.can_instantiate():
		return
	var integrated_ball: CharacterBody2D = controller_script.new()
	var integrated_visuals: Node2D = visuals_script.new()
	integrated_visuals.name = "Visuals"
	integrated_ball.add_child(integrated_visuals)
	integrated_ball.configure(tuning)
	if integrated_visuals.has_method("play_collision_feedback"):
		integrated_ball.vitality_model.reset_active()
		integrated_ball.velocity = Vector2(0.0, 300.0)
		integrated_ball.resolve_surface_collision(
			response_script.SurfaceKind.GROUND, Vector2.UP, false)
		suite.expect_true(integrated_visuals.deformation.y < 1.0,
			"BallController forwards Ground feedback to BallVisuals")
		integrated_ball.vitality_model.set_vitality(0.0)
		load("res://tests/test_support.gd").prepare_resting(integrated_ball)
		integrated_ball.global_position = Vector2(480.0, 565.0)
		if integrated_ball.has_method("advance_resting_time"):
			integrated_ball.advance_resting_time(0.12)
		if integrated_ball.has_method("apply_resting_interaction"):
			integrated_ball.apply_resting_interaction(
				25.0, Vector2(480.0, 537.0))
		suite.expect_true(integrated_visuals.deformation.x < 1.0,
			"BallController forwards Wake feedback to BallVisuals")
	integrated_ball.free()
