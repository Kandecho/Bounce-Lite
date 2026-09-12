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
	paddle.position.x = 480.0
	paddle.configure(tuning, 171.0, 790.0, 537.0)
	var motion_samples: Array = []
	var has_motion_signal := paddle.has_signal("interaction_sampled")
	suite.expect_true(has_motion_signal,
		"Paddle exposes scalar actual movement alongside physical velocity")
	if has_motion_signal:
		paddle.connect("interaction_sampled", func(sample_distance: float, sample_position: Vector2) -> void:
			if sample_distance > 0.0:
				motion_samples.append([sample_distance, sample_position])
		)

	paddle.position = Vector2(480.0, 537.0)
	paddle.set_target_x(1000.0)
	paddle.advance_motion(1.0)
	suite.expect_true(paddle.position.x <= 715.001,
		"Paddle center stays inside the right boundary")
	suite.expect_float(paddle.position.y, 537.0, 0.001,
		"Paddle does not move vertically")
	suite.expect_true(paddle.velocity.x > 0.0,
		"Paddle velocity reflects actual horizontal movement")
	if has_motion_signal:
		suite.expect_equal(motion_samples.size(), 1,
			"one motion step publishes one non-zero interaction sample")
		if motion_samples.size() == 1:
			suite.expect_float(motion_samples[0][0], 235.0, 0.001,
				"motion sample carries actual clamped movement")

		paddle.advance_motion(0.1)
		suite.expect_equal(motion_samples.size(), 1,
			"settled paddle does not publish movement")
	paddle.set_target_x(500.0)
	paddle.advance_motion(1.0 / 60.0)
	var sample_count := motion_samples.size()
	paddle.advance_motion(1.0 / 60.0)
	suite.expect_true(absf(paddle.velocity.x) > 0.0, "Paddle smoothing is still physically moving")
	suite.expect_equal(motion_samples.size(), sample_count + 1, "smoothing tail reports real motion")
	paddle.set_target_x(2000.0)
	paddle.advance_motion(1.0 / 60.0)
	sample_count = motion_samples.size()
	paddle.set_target_x(3000.0)
	paddle.advance_motion(1.0 / 60.0)
	suite.expect_equal(motion_samples.size(), sample_count + 1, "clamped target still reports actual smoothing motion")
	paddle.free()
