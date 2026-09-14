extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var game = main.geometry_playground
	var ball = main.ball
	main.paddle.set_physics_process(false)
	suite.expect_true(game != null and main.play_world == null, "default has geometry and no old world objects")
	suite.expect_equal(main.get_node("GameArea").find_children("Ball", "CharacterBody2D", false).size(), 1, "one Ball is the only attention center")
	game.toys.set_layout(1)
	game.toys.set_process(false)
	await physics_frame
	var platform: StaticBody2D
	for body in game.toys.get_children():
		if body is StaticBody2D and body.get_meta("toy_kind", "") == "platform":
			platform = body
	ball.start_active(Vector2.DOWN)
	ball.position = platform.position + Vector2(0, -26)
	ball.velocity = Vector2(0, 20)
	ball.vitality_model.set_vitality(0.04)
	for frame in range(120):
		await physics_frame
	suite.expect_true(ball.is_resting() and ball.velocity.is_zero_approx(), "low-energy platform contact settles without chatter")
	suite.expect_equal(ball.support_kind, ball.SupportKind.GEOMETRY, "flat geometry is explicit Physics support")
	suite.expect_true(ball.vitality_model.current_vitality <= 0.04, "passive support supplies no energy")
	var still: Vector2 = ball.position
	for frame in range(120):
		await physics_frame
	suite.expect_equal(ball.position, still, "supported platform remains physically still")
	suite.expect_true(ball.apply_resting_interaction(20, Vector2(ball.position.x, 570)), "baseline Wake works from geometry support")
	suite.expect_float(ball.velocity.y, -350, 0.001, "geometry Wake retains original upward speed")
	# Separate high-speed real platform contact verifies dedicated audio routing.
	ball.start_active(Vector2.DOWN)
	ball.position = platform.position + Vector2(0, -55)
	ball.velocity = Vector2(0, 160)
	var basic_before = main.get_node("BasicAudio").play_counts.duplicate()
	var geometry_before: int = game.feedback.play_count
	for frame in range(20):
		await physics_frame
	suite.expect_equal(main.get_node("BasicAudio").play_counts, basic_before, "geometry contact does not double-trigger generic audio")
	suite.expect_true(game.feedback.play_count > geometry_before, "geometry contact uses its own sound")
	ball.position = platform.position + Vector2(0, -26)
	ball.velocity = Vector2(0, 20)
	ball.vitality_model.set_vitality(0.04)
	for frame in range(40):
		await physics_frame
	platform.collision_layer = 0
	await physics_frame
	await physics_frame
	suite.expect_true(ball.support_kind == ball.SupportKind.NONE and ball.velocity.y > 0, "removed platform releases support to gravity")
	game.toys.set_process(true)
	game.restart_world(184)
	for frame in range(150):
		await physics_frame
	suite.expect_true(game.save_combination(), "F8 records this batch's combination")
	var saved: Dictionary = game.toys.export_snapshot()
	game.restart_world(7)
	suite.expect_true(game.restore_combination(), "F9 restores geometry combination")
	suite.expect_equal(game.toys.export_snapshot().rng_state, saved.rng_state, "snapshot restores RNG progress")
	for frame in range(8):
		await physics_frame
	suite.expect_true(ball.visible and game.spawn_point_clear(ball.position), "snapshot safely serves single Ball")
	main.get_node("BasicAudio").muted = true
	game._physics_process(0)
	suite.expect_true(game.feedback.muted, "geometry follows the baseline F5 mute")
	# A distinct profile refuses older exploration snapshots before mutating toys.
	var bad := FileAccess.open("res://.godot/geometry-wrong-profile.json", FileAccess.WRITE)
	bad.store_string('{"profile":"toybox","version":1,"geometry":{}}')
	bad.close()
	suite.expect_false(game.restore_combination("res://.godot/geometry-wrong-profile.json"), "old Toybox profiles cannot silently restore here")
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline:
		await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
