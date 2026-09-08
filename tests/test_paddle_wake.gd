extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const PADDLE_PATH := "res://scripts/paddle/paddle_controller.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var paddle_script: Script = load(PADDLE_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning is available to Paddle tests")
	suite.expect_not_null(paddle_script, "PaddleController exists")
	if tuning_script == null or paddle_script == null:
		return
	suite.expect_true(paddle_script.can_instantiate(), "PaddleController parses")
	if not paddle_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var paddle: CharacterBody2D = paddle_script.new()
	paddle.configure(tuning, 171.0, 790.0, 529.0)
	var motion_samples: Array = []
	var has_motion_signal := paddle.has_signal("motion_sampled")
	suite.expect_true(has_motion_signal,
		"Paddle exposes actual motion samples instead of a binary Wake gesture")
	if has_motion_signal:
		paddle.connect("motion_sampled", func(sample_velocity: Vector2, sample_position: Vector2) -> void:
			motion_samples.append([sample_velocity, sample_position])
		)

	paddle.position = Vector2(480.0, 529.0)
	paddle.set_target_x(1000.0)
	paddle.advance_motion(1.0)
	suite.expect_true(paddle.position.x <= 715.001,
		"Paddle center stays inside the right boundary")
	suite.expect_float(paddle.position.y, 529.0, 0.001,
		"Paddle does not move vertically")
	suite.expect_true(paddle.velocity.x > 0.0,
		"Paddle velocity reflects actual horizontal movement")
	if has_motion_signal:
		suite.expect_equal(motion_samples.size(), 1,
			"one Paddle update publishes one non-zero motion sample")
		if motion_samples.size() == 1:
			suite.expect_float(motion_samples[0][0].x, paddle.velocity.x, 0.001,
				"motion sample carries actual Paddle velocity")
			suite.expect_float(motion_samples[0][0].y, 0.0, 0.001,
				"motion sample remains horizontal")
		paddle.set_target_x(paddle.position.x)
		paddle.advance_motion(0.1)
		suite.expect_equal(motion_samples.size(), 1,
			"stationary Paddle updates do not publish Wake input")
	paddle.free()
