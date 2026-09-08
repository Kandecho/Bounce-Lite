extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const ENERGY_PATH := "res://scripts/ball/ball_energy_model.gd"
const VISUALS_PATH := "res://scripts/ball/ball_visuals.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var energy_script: Script = load(ENERGY_PATH)
	var visuals_script: Script = load(VISUALS_PATH)
	suite.expect_not_null(visuals_script, "BallVisuals exists")
	if tuning_script == null or energy_script == null or visuals_script == null:
		return
	suite.expect_true(visuals_script.can_instantiate(), "BallVisuals parses")
	if not visuals_script.can_instantiate():
		return

	var visuals: Node2D = visuals_script.new()
	visuals.configure(tuning_script.new())
	suite.expect_true(visuals.has_method("set_motion_speed_ratio"),
		"BallVisuals accepts actual motion speed")
	suite.expect_true(visuals.has_method("play_collision_feedback"),
		"BallVisuals accepts collision feedback events")
	suite.expect_true(visuals.has_method("play_wake_feedback"),
		"BallVisuals accepts Wake feedback events")
	suite.expect_true(visuals.has_method("advance_feedback"),
		"BallVisuals exposes deterministic feedback progression")
	if (
		not visuals.has_method("set_motion_speed_ratio")
		or not visuals.has_method("play_collision_feedback")
		or not visuals.has_method("play_wake_feedback")
		or not visuals.has_method("advance_feedback")
	):
		visuals.free()
		return

	visuals.set_activity(1.0, energy_script.ActivityState.ACTIVE)
	visuals.set_motion_speed_ratio(1.0)
	for index in range(30):
		visuals.record_ball_position(Vector2(index * 10.0, 0.0))
	var active_trail_size: int = visuals.trail_points.size()
	suite.expect_equal(active_trail_size, 16,
		"high-Energy fast motion keeps the full light-trail history")
	visuals.set_motion_speed_ratio(0.25)
	suite.expect_true(visuals.trail_points.size() < active_trail_size,
		"slower actual motion shortens Trail even when Energy stays high")
	visuals.set_motion_speed_ratio(1.0)
	for index in range(30, 60):
		visuals.record_ball_position(Vector2(index * 10.0, 0.0))

	visuals.set_activity(0.25, energy_script.ActivityState.DECAYING)
	visuals.set_motion_speed_ratio(0.25)
	suite.expect_true(visuals.trail_points.size() < active_trail_size,
		"low-Energy slow motion shortens the light trail")
	visuals.set_activity(0.0, energy_script.ActivityState.RESTING)
	suite.expect_equal(visuals.trail_points.size(), 0,
		"RESTING clears the light trail")

	visuals.play_collision_feedback(energy_script.SurfaceKind.PADDLE, Vector2.UP)
	var paddle_glow: float = visuals.glow_pulse
	suite.expect_true(visuals.deformation.y < 1.0 and visuals.deformation.x > 1.0,
		"Paddle hit squashes vertically before release")
	suite.expect_true(paddle_glow > 0.0, "Paddle hit boosts Glow")

	visuals.play_collision_feedback(energy_script.SurfaceKind.WALL, Vector2.LEFT)
	suite.expect_true(visuals.deformation.x < 1.0,
		"Wall hit gives weak compression along the collision normal")
	suite.expect_true(visuals.glow_pulse < paddle_glow,
		"Wall feedback is weaker than Paddle feedback")

	visuals.play_collision_feedback(energy_script.SurfaceKind.GROUND, Vector2.UP)
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
