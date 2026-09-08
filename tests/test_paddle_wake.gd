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

	suite.expect_false(paddle.advance_wake_detector(500.0, 0.04),
		"one short fast movement does not wake")
	suite.expect_true(paddle.advance_wake_detector(500.0, 0.04),
		"sustained fast movement reaches eighty milliseconds and wakes")
	suite.expect_false(paddle.advance_wake_detector(500.0, 0.04),
		"a latched gesture does not fire every frame")
	suite.expect_false(paddle.advance_wake_detector(0.0, 0.016),
		"dropping below threshold resets the detector")
	suite.expect_false(paddle.advance_wake_detector(500.0, 0.04),
		"a reset detector requires a new full hold")
	suite.expect_true(paddle.advance_wake_detector(500.0, 0.04),
		"a second sustained gesture can wake again")
	suite.expect_false(paddle.advance_wake_detector(100.0, 0.2),
		"low-speed movement never triggers wake")

	paddle.position = Vector2(480.0, 529.0)
	paddle.set_target_x(1000.0)
	paddle.advance_motion(1.0)
	suite.expect_true(paddle.position.x <= 715.001,
		"Paddle center stays inside the right boundary")
	suite.expect_float(paddle.position.y, 529.0, 0.001,
		"Paddle does not move vertically")
	suite.expect_true(paddle.velocity.x > 0.0,
		"Paddle velocity reflects actual horizontal movement")
	paddle.free()
