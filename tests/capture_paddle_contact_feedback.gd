extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const Surface = preload("res://scripts/physics/surface_response_model.gd")
const OUT := "res://.godot/paddle-feedback-20260925/"
var viewport: SubViewport
var main: Node2D
var ball: CharacterBody2D
var paddle: CharacterBody2D
var evidence: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = MainScene.instantiate()
	viewport.add_child(main)
	ball = main.get_node("GameArea/Ball")
	paddle = main.get_node("GameArea/Paddle")
	ball.set_physics_process(false)
	paddle.set_physics_process(false)
	paddle.set_process(false)
	ball.get_node("Visuals").set_process(false)
	main.set_physics_process(false)
	main.get_node("BasicAudio").set_muted(true)
	if is_instance_valid(main.geometry_playground):
		main.geometry_playground.visible = false
	paddle.position.x = 480.0
	paddle.configure(main.tuning, 0.0, 960.0, 570.0)
	for item in [{"label": "weak", "speed": 65.0}, {"label": "strong", "speed": 430.0}]:
		paddle.advance_feedback(1.0)
		ball.get_node("Visuals").advance_feedback(1.0)
		ball.position = Vector2(480.0, 570.0 - main.tuning.paddle_size.y * 0.5 - main.tuning.ball_radius)
		ball.velocity = Vector2(650.0, item.speed)
		ball.resolve_surface_collision(Surface.SurfaceKind.PADDLE, Vector2.UP, true)
		await _save(item.label)
		evidence.append({"kind": "controlled_response", "label": item.label, "normal_speed": item.speed, "accent": paddle.contact_strength(), "ball_deformation": ball.get_node("Visuals").deformation, "paddle_volume_db": main.get_node("BasicAudio").players[0].volume_db, "paddle_pitch": main.get_node("BasicAudio").players[0].pitch_scale})
	paddle.advance_feedback(0.2)
	ball.get_node("Visuals").advance_feedback(0.2)
	await _save("recovered")
	# A short engine sweep, starting above the Paddle; no direct resolve call.
	paddle.advance_feedback(1.0)
	ball.position = Vector2(480.0, 500.0)
	ball.velocity = Vector2(0.0, 240.0)
	var actual_contacts: Array[RefCounted] = []
	ball.surface_resolved.connect(func(result: RefCounted):
		if result.surface_kind == Surface.SurfaceKind.PADDLE:
			actual_contacts.append(result)
	)
	for frame in range(24):
		paddle.advance_feedback(1.0 / 60.0)
		ball.get_node("Visuals").advance_feedback(1.0 / 60.0)
		await physics_frame
		ball._physics_process(1.0 / 60.0)
		if frame == 8 or frame == 12 or actual_contacts.size() > 0:
			await _save("dynamic-%02d" % frame)
		if actual_contacts.size() > 0:
			break
	evidence.append({"kind": "engine_sweep", "frames": 24, "paddle_contacts": actual_contacts.size(), "ball_position": ball.position, "ball_velocity": ball.velocity})
	var file := FileAccess.open(OUT + "capture-evidence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t"))
	file.close()
	print("F09 CAPTURE ", evidence)
	viewport.queue_free()
	await process_frame
	quit(0 if actual_contacts.size() > 0 else 1)

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	var result := picture.save_png(OUT + label + ".png")
	print("F09 RENDER ", label, " result=", result, " size=", picture.get_size())
