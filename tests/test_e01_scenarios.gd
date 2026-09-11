extends SceneTree

const Support = preload("res://tests/test_support.gd")
const MainScene = preload("res://scenes/main.tscn")
var suite = Support.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	# Audio wiring has its own scenario suite; avoid asynchronous playback at teardown.
	main.get_node("BasicAudio").set_muted(true)
	var ball = main.get_node("GameArea/Ball")
	var paddle = main.get_node("GameArea/Paddle")
	ball.set_physics_process(false)
	paddle.set_physics_process(false)
	var results: Array = []
	ball.surface_resolved.connect(func(result):
		if result.valid_paddle_hit:
			results.append(result))
	await physics_frame
	var paddle_y: float = paddle.position.y
	var velocities: Array[Vector2] = []
	for enabled in [false, true]:
		main._set_e01_enabled(enabled)
		for offset in [-45.0, 0.0, 45.0]:
			paddle.position = Vector2(480, paddle_y)
			ball.start_active(Vector2.DOWN)
			ball.position = Vector2(480 + offset, paddle_y - 57.0)
			ball.velocity = Vector2(0, 220)
			ball.vitality_model.set_vitality(0.4)
			results.clear()
			paddle.advance_feedback(1.0)
			await physics_frame
			for frame in range(20):
				ball._physics_process(1.0 / 60.0)
				if not results.is_empty():
					break
				await physics_frame
			suite.expect_equal(results.size(), 1, "real top collision commits exactly one effective response")
			if results.is_empty():
				continue
			var outgoing: Vector2 = results[0].velocity_after
			velocities.append(outgoing)
			if enabled and offset != 0:
				suite.expect_true(outgoing.x * signf(offset) > 40, "actual contact position reaches the physics response")
			else:
				suite.expect_float(outgoing.x, 0.0, 0.001, "baseline and center remain vertical for vertical arrival")
			suite.expect_true(outgoing.y < 0, "real contact escapes upward")
			suite.expect_float(ball.vitality_model.current_vitality, 1, 0.001, "real contact retains baseline recovery")
			suite.expect_true(paddle.dim_strength() > 0, "true-contact energy transfer reaches the Paddle")
	if velocities.size() == 6:
		suite.expect_float(velocities[3].length(), velocities[0].length(), 0.001, "experiment does not add contact energy")
		suite.expect_float(velocities[3].x, -velocities[5].x, 0.001, "mirrored contacts have mirrored bias")
	# F7 switches only future responses; no restart, impulse, reward or false flash.
	var before_velocity: Vector2 = ball.velocity
	var before_position: Vector2 = ball.position
	var before_vitality: float = ball.vitality_model.current_vitality
	paddle.advance_feedback(1.0)
	var key := InputEventKey.new()
	key.keycode = KEY_F7
	key.pressed = true
	main._unhandled_key_input(key)
	suite.expect_false(main.tuning.e01_contact_enabled, "F7 selects baseline")
	suite.expect_equal(ball.velocity, before_velocity, "comparison switch cannot change current motion")
	suite.expect_equal(ball.position, before_position, "comparison switch cannot reposition Ball")
	suite.expect_float(ball.vitality_model.current_vitality, before_vitality, 0.0001, "comparison switch cannot reward")
	suite.expect_float(paddle.dim_strength(), 0, 0.0001, "comparison switch cannot dim Paddle")
	key.echo = true
	main._unhandled_key_input(key)
	suite.expect_false(main.tuning.e01_contact_enabled, "key repeat does not toggle repeatedly")
	main.free()
	await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
