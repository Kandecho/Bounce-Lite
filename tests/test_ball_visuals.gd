extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const VITALITY_PATH := "res://scripts/ball/ball_vitality_model.gd"
const RESPONSE_PATH := "res://scripts/physics/surface_response_model.gd"
const VISUALS_PATH := "res://scripts/ball/ball_visuals.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var vitality_script: Script = load(VITALITY_PATH)
	var response_script: Script = load(RESPONSE_PATH)
	var visuals_script: Script = load(VISUALS_PATH)
	suite.expect_not_null(visuals_script, "BallVisuals exists")
	if (
		tuning_script == null
		or vitality_script == null
		or response_script == null
		or visuals_script == null
	):
		return
	suite.expect_true(visuals_script.can_instantiate(), "BallVisuals parses")
	if not visuals_script.can_instantiate():
		return

	var visuals: Node2D = visuals_script.new()
	visuals.configure(tuning_script.new())
	suite.expect_true(visuals.has_method("set_motion"),
		"BallVisuals accepts a Velocity snapshot for Trail")
	suite.expect_true(visuals.has_method("set_vitality"),
		"BallVisuals accepts a Vitality snapshot for Glow")
	suite.expect_true(visuals.has_method("play_collision_feedback"),
		"BallVisuals accepts collision feedback events")
	suite.expect_true(visuals.has_method("play_wake_feedback"),
		"BallVisuals accepts Wake feedback events")
	suite.expect_true(visuals.has_method("advance_feedback"),
		"BallVisuals exposes deterministic feedback progression")
	if (
		not visuals.has_method("set_motion")
		or not visuals.has_method("set_vitality")
		or not visuals.has_method("play_collision_feedback")
		or not visuals.has_method("play_wake_feedback")
		or not visuals.has_method("advance_feedback")
	):
		visuals.free()
		return

	visuals.set_vitality(1.0, vitality_script.ActivityState.ACTIVE)
	visuals.set_motion(Vector2(520.0, 0.0))
	for index in range(30):
		visuals.record_ball_position(Vector2(index * 10.0, 0.0))
	var fast_trail_size: int = visuals.trail_points.size()
	var fast_trail_capacity: int = visuals._trail_capacity()
	suite.expect_equal(fast_trail_size, 16,
		"fast motion keeps the full light-trail history")

	visuals.set_vitality(0.20, vitality_script.ActivityState.DECAYING)
	suite.expect_equal(visuals.trail_points.size(), fast_trail_size,
		"changing Vitality at equal Velocity does not alter Trail")
	suite.expect_equal(visuals._trail_capacity(), fast_trail_capacity,
		"Trail capacity is mathematically independent of Vitality")
	suite.expect_float(visuals.vitality_ratio, 0.20, 0.0001,
		"Glow state receives low Vitality independently")

	visuals.set_motion(Vector2(130.0, 0.0))
	suite.expect_true(visuals.trail_points.size() < fast_trail_size,
		"slower Velocity shortens Trail at equal Vitality")
	var slow_trail_size: int = visuals.trail_points.size()
	visuals.set_vitality(1.0, vitality_script.ActivityState.ACTIVE)
	suite.expect_equal(visuals.trail_points.size(), slow_trail_size,
		"raising Vitality still does not extend a slow Trail")

	visuals.set_motion(Vector2.ZERO)
	suite.expect_equal(visuals.trail_points.size(), 0,
		"zero Velocity clears the motion trail")
	visuals.record_ball_position(Vector2(999.0, 0.0))
	suite.expect_equal(visuals.trail_points.size(), 0,
		"zero Velocity cannot record new Trail samples")

	visuals.play_collision_feedback(response_script.SurfaceKind.PADDLE, Vector2.UP)
	var paddle_glow: float = visuals.glow_pulse
	suite.expect_true(visuals.deformation.y < 1.0 and visuals.deformation.x > 1.0,
		"Paddle hit squashes vertically before release")
	suite.expect_true(paddle_glow > 0.0, "Paddle hit boosts Glow")

	visuals.play_collision_feedback(response_script.SurfaceKind.WALL, Vector2.LEFT)
	suite.expect_true(visuals.deformation.x < 1.0,
		"Wall hit gives weak compression along the collision normal")
	suite.expect_true(visuals.glow_pulse < paddle_glow,
		"Wall feedback is weaker than Paddle feedback")

	visuals.play_collision_feedback(response_script.SurfaceKind.GROUND, Vector2.UP)
	suite.expect_true(visuals.darken_pulse > 0.0,
		"Ground hit briefly darkens the Ball")
	visuals.play_wake_feedback()
	suite.expect_true(visuals.glow_pulse > paddle_glow,
		"Wake produces the strongest light pulse")
	visuals.advance_feedback(1.0)
	suite.expect_float(visuals.deformation.x, 1.0, 0.001,
		"collision deformation releases back to the round Core")
	suite.expect_true(visuals.glow_pulse < 0.001 and visuals.darken_pulse < 0.001,
		"temporary light feedback decays")
	visuals.free()
