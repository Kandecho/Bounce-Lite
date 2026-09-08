extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const PANEL_PATH := "res://scripts/dev/runtime_tuning_panel.gd"
const BALL_PATH := "res://scripts/ball/ball_controller.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var panel_script: Script = load(PANEL_PATH)
	var ball_script: Script = load(BALL_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning exists for runtime tuning tests")
	suite.expect_not_null(panel_script, "RuntimeTuningPanel exists")
	suite.expect_not_null(ball_script, "BallController exists for live tuning tests")
	if tuning_script == null or panel_script == null or ball_script == null:
		return
	suite.expect_true(panel_script.can_instantiate(), "RuntimeTuningPanel parses")
	if not panel_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var panel: Control = panel_script.new()
	panel.configure(tuning)

	suite.expect_false(panel.visible, "runtime tuning panel starts hidden")
	suite.expect_true(panel.has_parameter("gravity_acceleration"),
		"panel exposes Gravity")
	suite.expect_true(panel.has_parameter("max_speed"),
		"panel exposes Max velocity")
	suite.expect_true(panel.has_parameter("paddle_impulse"),
		"panel exposes Paddle impulse")
	suite.expect_false(panel.has_parameter("initial_speed"),
		"panel omits launch-only Initial speed")

	suite.expect_true(panel.set_parameter_value("gravity_acceleration", 700.0),
		"panel accepts a Gravity edit")
	suite.expect_float(tuning.gravity_acceleration, 700.0, 0.001,
		"Gravity edit updates the shared tuning resource")
	suite.expect_true(panel.set_parameter_value("max_speed", 640.0),
		"panel accepts a Max velocity edit")
	suite.expect_float(tuning.max_speed, 640.0, 0.001,
		"Max velocity edit updates the shared tuning resource")
	var ball: CharacterBody2D = ball_script.new()
	ball.configure(tuning)
	ball.velocity = Vector2.ZERO
	ball.advance_air_motion(0.10)
	suite.expect_float(ball.velocity.y, 70.0, 0.001,
		"a running Ball reads the edited Gravity from shared tuning")
	ball.velocity = Vector2(1000.0, 0.0)
	ball.advance_air_motion(0.01)
	suite.expect_float(ball.velocity.length(), 640.0, 0.001,
		"a running Ball reads the edited Max velocity from shared tuning")
	ball.free()

	suite.expect_true(panel.set_parameter_value("wall_vitality_loss", 0.03),
		"panel accepts Wall Vitality loss")
	suite.expect_float(tuning.wall_vitality_retention, 0.97, 0.0001,
		"Wall loss is converted to the existing retention source")
	suite.expect_true(panel.set_parameter_value("ground_vitality_loss", 0.45),
		"panel accepts Ground Vitality loss")
	suite.expect_float(tuning.ground_vitality_retention, 0.55, 0.0001,
		"Ground loss is converted to the existing retention source")
	suite.expect_true(panel.set_parameter_value("paddle_vitality_restore", 0.50),
		"panel accepts Paddle Vitality restore")
	suite.expect_float(float(tuning.get("paddle_vitality_restore")), 0.50, 0.0001,
		"Paddle restore edit updates the shared tuning resource")

	var f1 := InputEventKey.new()
	f1.keycode = KEY_F1
	f1.pressed = true
	suite.expect_true(panel.handle_toggle_event(f1), "F1 is handled by the panel")
	suite.expect_true(panel.visible, "F1 opens the runtime tuning panel")
	suite.expect_true(panel.handle_toggle_event(f1), "a second F1 press is handled")
	suite.expect_false(panel.visible, "a second F1 press closes the panel")

	var f2 := InputEventKey.new()
	f2.keycode = KEY_F2
	f2.pressed = true
	suite.expect_false(panel.handle_toggle_event(f2), "unrelated keys are ignored")
	panel.free()
