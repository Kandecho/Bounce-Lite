extends SceneTree

const Support = preload("res://tests/test_support.gd")
var suite = Support.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_cmdline_user_args().has("--observe-world") or OS.get_cmdline_user_args().has("--observe-room") or OS.get_cmdline_user_args().has("--pinch-repro"):
		await _observe_world()
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame
	var ball = main.get_node("GameArea/Ball")
	var paddle = main.get_node("GameArea/Paddle")
	ball.set_physics_process(false)
	paddle.set_physics_process(false)
	suite.expect_true(main.tuning.shared_world_enabled, "default scene enables shared world")
	suite.expect_not_null(main.play_world, "default scene creates world")
	suite.expect_not_null(main.world_feedback, "default scene creates feedback")
	suite.expect_true(ball.play_world == main.play_world, "ball samples the connected world")
	var events: Array[String] = []
	main.play_world.event_emitted.connect(func(kind: String, _position: Vector2, _intensity: float): events.append(kind))
	var resumptions: Array[Vector2] = []
	ball.resume_committed.connect(func(position: Vector2): resumptions.append(position))
	# Start beside the paddle so the outgoing arc is not immediately blocked below it.
	ball.position = Vector2(260, ball.safe_center_bounds().end.y)
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = ball.SupportKind.GROUND
	ball.note_player_input(20.0)
	for frame in range(65):
		ball._physics_process(1.0 / 60.0)
		await physics_frame
	suite.expect_equal(resumptions.size(), 1, "actual loop resumes once after recent input and rest")
	suite.expect_true(ball.velocity.y < 0.0, "actual loop applies upward continuation")
	main.get_node("BasicAudio").muted = true
	main._physics_process(1.0 / 60.0)
	suite.expect_true(main.world_feedback.muted, "world feedback follows F5 mute source")
	# Reproduce the moving paddle corner pinning a circle against the right wall.
	# Recorded in the old framed arena (right face 788, Paddle y 537); shifted rigidly
	# so the same wall/corner relationship holds in the full client-area world.
	var shift := Vector2(ball.arena_bounds.end.x - 788.0, paddle.position.y - 537.0)
	ball.global_position = Vector2(769.879, 521.3489) + shift
	ball.velocity = Vector2(-336.4177, -153.487)
	ball.vitality_model.set_vitality(0.7)
	ball.support_kind = ball.SupportKind.NONE
	paddle.position = Vector2(690.6726, 537.0) + shift
	await physics_frame
	ball._physics_process(1.0 / 60.0)
	paddle.position.x = 695.9411 + shift.x
	await physics_frame
	ball._physics_process(1.0 / 60.0)
	suite.expect_equal(ball.bounds_recovery_count, 0, "moving paddle corner cannot eject ball through right wall")
	main.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)


func _observe_world() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var ball = main.get_node("GameArea/Ball")
	var paddle = main.get_node("GameArea/Paddle")
	paddle.set_physics_process(false)
	main.get_node("BasicAudio").muted = true
	var counts := {"rotor": 0, "charge": 0, "resume": 0, "paddle": 0}
	main.play_world.event_emitted.connect(func(kind: String, _point: Vector2, _strength: float):
		if counts.has(kind): counts[kind] += 1)
	ball.resume_committed.connect(func(_point: Vector2): counts.resume += 1)
	ball.paddle_contact.connect(func(valid: bool, _point: Vector2):
		if valid: counts.paddle += 1)
	var peak_speed := 0.0
	var quiet_rest_frames := 0
	var quiet_resumes_before := 0
	var previous_recoveries := 0
	var give_room := OS.get_cmdline_user_args().has("--observe-room")
	print("OBSERVE strategy=", "give-room" if give_room else "follow", " duration=120 simulated seconds (7200 physics steps)")
	# 90 seconds of bounded paddle aiming, followed by 30 seconds hands off.
	# Only input targets change; ball positions, velocities and events are untouched.
	var frame_count := 1200 if OS.get_cmdline_user_args().has("--pinch-repro") else 7200
	for frame in range(frame_count):
		var seconds := frame / 60.0
		if frame < 5400:
			var aim: float = ball.global_position.x + sin(seconds * 0.57) * 48.0
			# Occasionally wait instead of catching, allowing natural pauses.
			if fmod(seconds, 24.0) > 18.0:
				aim = 260.0
			if give_room and ball.global_position.y > paddle.global_position.y:
				aim = 700.0 if ball.global_position.x < 480.0 else 260.0
			var next: float = move_toward(paddle.target_x, aim, 380.0 / 60.0)
			paddle.set_target_x(next)
		elif frame == 5400:
			quiet_resumes_before = counts.resume
		var paddle_before: Vector2 = paddle.global_position
		paddle.advance_motion(1.0 / 60.0)
		var position_before: Vector2 = ball.global_position
		var velocity_before: Vector2 = ball.velocity
		var support_before: int = ball.support_kind
		await physics_frame
		if ball.bounds_recovery_count != previous_recoveries:
			print("RECOVERY frame=", frame, " t=", seconds, " before=", position_before, " velocity=", velocity_before,
				" support=", support_before, " after=", ball.global_position, " outgoing=", ball.velocity,
				" paddle=", paddle.global_position, " paddle_delta=", paddle.global_position - paddle_before)
			previous_recoveries = ball.bounds_recovery_count
		peak_speed = maxf(peak_speed, ball.velocity.length())
		if frame > 6300 and ball.is_resting() and ball.velocity.is_zero_approx():
			quiet_rest_frames += 1
		if frame % 1800 == 1799:
			print("OBSERVE t=", (frame + 1) / 60, " events=", counts, " position=", ball.global_position)
	print("OBSERVE FINAL events=", counts, " peak_speed=", peak_speed, " recoveries=", ball.bounds_recovery_count,
		" quiet_final_15s_rest_frames=", quiet_rest_frames, " quiet_resumes=", counts.resume - quiet_resumes_before)
	suite.expect_true(peak_speed <= main.tuning.max_speed + 0.01, "two minute speed bound")
	suite.expect_equal(ball.bounds_recovery_count, 0, "two minute ordinary motion needs no bounds recovery")
	main.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
