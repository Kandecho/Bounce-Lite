extends SceneTree
## Full real scene at logical 960x720, downsampled to the default 640x480 client area.
## Controlled starting positions/Vitality establish reproducible Wake/Continue cases;
## every subsequent launch and world event runs through normal physics and wiring.

var viewport: SubViewport
var main: Node2D
var ball: CharacterBody2D
var paddle: CharacterBody2D
var evidence: Array[Dictionary] = []
var step := 0
var pending_launch := ""
var launch_step := -1
var captured_states: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	ball = main.get_node("GameArea/Ball")
	paddle = main.get_node("GameArea/Paddle")
	ball.set_physics_process(false)
	paddle.set_physics_process(false)
	main.play_world.set_physics_process(false)
	main.set_physics_process(false)
	main.get_node("BasicAudio").muted = true
	main.world_feedback.set_muted(true)
	main.play_world.set_seed(184)
	ball.wake_committed.connect(func(_strength, _activated, _point): record_launch("wake"))
	ball.resume_committed.connect(func(_point): record_launch("continue"))
	# Wake: settled ball, paddle already beside its vertical launch path.
	ball.start_active(Vector2.DOWN)
	ball.position = Vector2(260, ball.safe_center_bounds().end.y)
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = ball.SupportKind.GROUND
	paddle.position.x = 420
	paddle.configure(main.tuning, 0, 960, 570)
	for frame in range(110):
		if frame == 12:
			paddle.set_target_x(380)
		await advance()
	# Continue: airborne low-energy ball falls to the ground naturally after
	# the actual nearby paddle action qualifies. No direct qualification injection.
	ball.start_active(Vector2.DOWN)
	ball.position = Vector2(260, 665)
	ball.velocity = Vector2(0, 10)
	ball.vitality_model.set_vitality(0.04)
	paddle.position.x = 420
	paddle.configure(main.tuning, 0, 960, 570)
	paddle.set_target_x(380)
	for frame in range(1900):
		await advance()
	await save("quiet")
	var file := FileAccess.open("res://.godot/followup-scene-evidence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 184, "controlled_initial_conditions": true,
		"render_size": "960x720 downsampled to 640x480", "launches": evidence,
		"lifecycle": main.play_world.lifecycle_events, "recoveries": ball.bounds_recovery_count}, "\t"))
	file.close()
	print("FOLLOWUP SCENE launches=", evidence, " states=", captured_states.keys(), " recoveries=", ball.bounds_recovery_count)
	viewport.queue_free()
	await process_frame
	quit(0 if evidence.size() >= 2 else 1)

func record_launch(kind: String) -> void:
	evidence.append({"kind": kind, "step": step, "position": ball.position,
		"velocity": ball.velocity, "activity": ball.vitality_model.state,
		"vitality": ball.vitality_model.current_vitality})
	pending_launch = kind
	launch_step = step

func advance() -> void:
	paddle.advance_motion(1.0 / 60.0)
	main._physics_process(1.0 / 60.0)
	ball._physics_process(1.0 / 60.0)
	main.play_world.set_ball_context(ball.global_position, main.tuning.ball_radius)
	main.play_world._physics_process(1.0 / 60.0)
	await process_frame
	if launch_step >= 0 and step - launch_step == 6:
		await save(pending_launch + "-010")
	if launch_step >= 0 and step - launch_step == 19:
		await save(pending_launch + "-032")
	var state: String = main.play_world.rotor_state
	if state == "absent" and step > 100:
		state = "removed"
	if not captured_states.has(state):
		captured_states[state] = true
		await save("rotor-" + state)
	step += 1

func save(label: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	picture.resize(640, 480, Image.INTERPOLATE_LANCZOS)
	var result := picture.save_png("res://.godot/followup-scene-" + label + ".png")
	print("SCENE CAPTURE ", label, " step=", step, " result=", result)
