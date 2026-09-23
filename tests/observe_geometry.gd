extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()
class PhysicsClock extends Node:
	signal tick
	func _physics_process(_delta: float) -> void:
		tick.emit()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var game = main.geometry_playground
	var ball = main.ball
	var paddle = main.paddle
	paddle.set_physics_process(false)
	var clock := PhysicsClock.new()
	clock.process_physics_priority = 100
	root.add_child(clock)
	var reports: Array[Dictionary] = []
	var seeds := [184, 20260914, 7]
	var frame_count := 7200
	var output_path := "res://.godot/motion-ab/geometry-observation-%s.json" % main.tuning.motion_profile
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--observe-seed="): seeds = [int(argument.trim_prefix("--observe-seed="))]
		if argument.begins_with("--observe-seeds="):
			seeds.clear()
			for value in argument.trim_prefix("--observe-seeds=").split(","):
				seeds.append(int(value))
		if argument.begins_with("--observe-frames="): frame_count = int(argument.trim_prefix("--observe-frames="))
		if argument.begins_with("--observe-output="): output_path = argument.trim_prefix("--observe-output=")
	for seed_value in seeds:
		game.restart_world(seed_value)
		ball.collision_budget_samples.clear()
		var penetration_frames := 0
		var paddle_overlap_frames := 0
		var hold_frames := 0
		var max_hold_frames := 0
		var counts := {"paddle": 0, "wake": 0, "surface": 0}
		var hit_counter = func(valid, _position):
			if valid: counts.paddle += 1
		var wake_counter = func(_strength, _activated, _position): counts.wake += 1
		var surface_counter = func(_result): counts.surface += 1
		ball.paddle_contact.connect(hit_counter)
		ball.wake_committed.connect(wake_counter)
		ball.surface_resolved.connect(surface_counter)
		var shape := CircleShape2D.new()
		shape.radius = main.tuning.ball_radius - 0.5
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.collision_mask = 5
		query.exclude = [ball.get_rid()]
		var peak := 0.0
		var rests := 0
		var max_toys := 0
		var overlap_examples: Array[Dictionary] = []
		var budget_frame_examples: Array[Dictionary] = []
		var recoveries_before: int = ball.bounds_recovery_count
		var budget_before: int = ball.collision_budget_exhaustions
		var previous_budget: int = budget_before
		var budget_streak := 0
		var max_budget_streak := 0
		var last_tick: int = Engine.get_physics_frames()
		var max_tick_gap := 0
		for frame in range(frame_count):
			# Mouse target only: follow, occasionally give room, and allow quiet.
			var seconds := frame / 60.0
			var aim: float = ball.position.x + sin(seconds * 0.6) * 45
			if fmod(seconds, 24) > 18:
				aim = 250
			if ball.position.y > paddle.position.y:
				aim = ball.position.x + (135 if ball.position.x < 480 else -135)
			paddle.set_target_x(aim)
			paddle.advance_motion(1.0 / 60)
			await clock.tick
			var tick: int = Engine.get_physics_frames()
			max_tick_gap = maxi(max_tick_gap, tick - last_tick)
			last_tick = tick
			if not budget_frame_examples.is_empty() and not budget_frame_examples[-1].has("next_ball") and frame > int(budget_frame_examples[-1].frame):
				budget_frame_examples[-1].next_ball = [ball.position.x, ball.position.y]
				budget_frame_examples[-1].next_velocity = [ball.velocity.x, ball.velocity.y]
			var current_budget: int = ball.collision_budget_exhaustions
			if current_budget > previous_budget:
				budget_streak += 1
				if budget_frame_examples.size() < 8:
					budget_frame_examples.append({"frame": frame, "ball": [ball.position.x, ball.position.y], "velocity": [ball.velocity.x, ball.velocity.y], "collision": ball.collision_budget_samples[-1] if not ball.collision_budget_samples.is_empty() else {}})
			else:
				budget_streak = 0
			max_budget_streak = maxi(max_budget_streak, budget_streak)
			previous_budget = current_budget
			if not ball.visible:
				continue
			query.transform = Transform2D(0, ball.global_position)
			var overlaps: Array = main.get_world_2d().direct_space_state.intersect_shape(query, 8)
			var geometry_overlap := false
			var paddle_overlap := false
			for overlap in overlaps:
				if overlap.collider == paddle:
					paddle_overlap = true
				else:
					geometry_overlap = true
			if geometry_overlap: penetration_frames += 1
			if geometry_overlap and overlap_examples.size() < 8:
				var objects: Array[String] = []
				for overlap in overlaps:
					if overlap.collider != paddle:
						objects.append(str(overlap.collider.name))
				overlap_examples.append({"frame": frame, "ball": [ball.position.x, ball.position.y], "velocity": [ball.velocity.x, ball.velocity.y], "objects": objects, "holding": is_instance_valid(ball.spring_hold), "budget": ball.collision_budget_exhaustions - budget_before})
			# Baseline side-overlap recovery is reported separately; see checkpoint-paddle-old/current.log.
			if paddle_overlap: paddle_overlap_frames += 1
			hold_frames = hold_frames + 1 if is_instance_valid(ball.spring_hold) else 0
			max_hold_frames = maxi(max_hold_frames, hold_frames)
			peak = maxf(peak, ball.velocity.length())
			if ball.is_resting() and ball.velocity.is_zero_approx():
				rests += 1
			suite.expect_true(ball.safe_center_bounds().grow(0.13).has_point(ball.position), "single Ball stays inside arena")
			if frame % 60 == 0:
				var snapshot: Dictionary = game.toys.export_snapshot()
				max_toys = maxi(max_toys, snapshot.toys.size())
				for toy in snapshot.toys:
					var envelope: Rect2 = game.toys._spawn_shape(toy.kind, Vector2(toy.kick[0], toy.kick[1])).get_rect()
					suite.expect_true(toy.position[1] + envelope.end.y <= game.toys._bottom_limit() + 0.001, "full geometry envelope stays above bottom and paddle path")
		var kinds: Dictionary = {}
		for event in game.events:
			kinds[event.kind] = int(kinds.get(event.kind, 0)) + 1
		ball.paddle_contact.disconnect(hit_counter)
		ball.wake_committed.disconnect(wake_counter)
		ball.surface_resolved.disconnect(surface_counter)
		suite.expect_equal(penetration_frames, 0, "no deep geometry/wall penetration in random evolution")
		suite.expect_equal(max_tick_gap, 1, "observer samples every physical tick")
		suite.expect_true(max_hold_frames <= 73, "every automatic hold is bounded")
		suite.expect_true(counts.paddle > 0, "mouse can still participate through true paddle contacts")
		var recoveries: int = ball.bounds_recovery_count - recoveries_before
		var budget_exhaustions: int = ball.collision_budget_exhaustions - budget_before
		suite.expect_true(peak <= main.tuning.max_speed + 0.01, "Ball keeps profile speed bound")
		suite.expect_equal(recoveries, 0, "ordinary geometry needs no exceptional recovery")
		suite.expect_true(max_budget_streak <= 2, "collision budget exhaustion does not persist into a stuck sequence")
		var report := {"motion_profile": main.tuning.motion_profile, "seed": seed_value, "seconds": frame_count / 60.0, "peak": peak, "rest_frames": rests, "recoveries": recoveries, "collision_budget_exhaustions": budget_exhaustions, "max_budget_streak": max_budget_streak, "budget_frame_examples": budget_frame_examples, "collision_budget_samples": ball.collision_budget_samples.duplicate(true), "max_tick_gap": max_tick_gap, "max_toys": max_toys, "overlap_examples": overlap_examples,
			"geometry_penetration_frames": penetration_frames, "paddle_overlap_frames": paddle_overlap_frames, "max_hold_frames": max_hold_frames, "player_events": counts, "events": kinds, "journal": game.toys.lifecycle_events.duplicate(true)}
		reports.append(report)
		print("GEOMETRY OBSERVE profile=", main.tuning.motion_profile, " seed=", seed_value, " peak=", peak, " rest=", rests, " recovery=", recoveries, " collision_budget=", budget_exhaustions, " max_toys=", max_toys, " geometry_overlap=", penetration_frames, " paddle_overlap=", paddle_overlap_frames, " events=", kinds)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(reports, "\t"))
	file.close()
	main.queue_free()
	clock.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline:
		await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
