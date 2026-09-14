extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(8):
		await physics_frame
	if OS.get_cmdline_user_args().has("--geometry-baseline"):
		suite.expect_true(main.geometry_playground == null and main.play_world != null, "baseline entry creates only the original world")
	else:
		var game = main.geometry_playground
		suite.expect_equal(game.world_seed, 184, "CLI snapshot restores the recorded seed")
		suite.expect_true(main.ball.visible and game.spawn_point_clear(main.ball.position), "CLI restores with a safe single-ball start")
		var key := InputEventKey.new()
		key.keycode = KEY_N
		key.pressed = true
		root.push_input(key)
		suite.expect_true(game.world_seed != 184, "N selects a fresh world seed")
		key = InputEventKey.new()
		key.keycode = KEY_F9
		key.pressed = true
		root.push_input(key)
		suite.expect_equal(game.world_seed, 184, "F9 reaches the saved geometry combination")
		key = InputEventKey.new()
		key.keycode = KEY_R
		key.pressed = true
		root.push_input(key)
		suite.expect_equal(game.world_seed, 184, "R retains the current seed")
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline:
		await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
