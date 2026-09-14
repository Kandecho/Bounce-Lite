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
	var paddle = main.paddle
	paddle.set_physics_process(false)
	var reports: Array[Dictionary] = []
	for seed_value in [184, 20260914]:
		game.restart_world(seed_value)
		var peak := 0.0
		var rests := 0
		var max_toys := 0
		var recoveries_before: int = ball.bounds_recovery_count
		for frame in range(7200):
			# Mouse target only: follow, occasionally give room, and allow quiet.
			var seconds := frame / 60.0
			var aim: float = ball.position.x + sin(seconds * 0.6) * 45
			if fmod(seconds, 24) > 18:
				aim = 250
			if ball.position.y > paddle.position.y:
				aim = ball.position.x + (135 if ball.position.x < 480 else -135)
			paddle.set_target_x(aim)
			paddle.advance_motion(1.0 / 60)
			await physics_frame
			if not ball.visible:
				continue
			peak = maxf(peak, ball.velocity.length())
			if ball.is_resting() and ball.velocity.is_zero_approx():
				rests += 1
			suite.expect_true(ball.safe_center_bounds().grow(0.13).has_point(ball.position), "single Ball stays inside arena")
			if frame % 60 == 0:
				max_toys = maxi(max_toys, game.toys.export_snapshot().toys.size())
		var kinds: Dictionary = {}
		for event in game.events:
			kinds[event.kind] = int(kinds.get(event.kind, 0)) + 1
		var recoveries: int = ball.bounds_recovery_count - recoveries_before
		suite.expect_true(peak <= 520.01, "geometry keeps global speed bound")
		suite.expect_equal(recoveries, 0, "ordinary geometry needs no exceptional recovery")
		var report := {"seed": seed_value, "seconds": 120, "peak": peak, "rest_frames": rests, "recoveries": recoveries, "max_toys": max_toys,
			"events": kinds, "journal": game.toys.lifecycle_events.duplicate(true)}
		reports.append(report)
		print("GEOMETRY OBSERVE seed=", seed_value, " peak=", peak, " rest=", rests, " recovery=", recoveries, " max_toys=", max_toys, " events=", kinds)
	var file := FileAccess.open("res://.godot/geometry-observation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(reports, "\t"))
	file.close()
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline:
		await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
