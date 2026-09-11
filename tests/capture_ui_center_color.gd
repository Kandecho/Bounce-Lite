extends SceneTree

# V0.2 UI trial capture: Scheme B Core/Glow plus shared center-color Paddle dimming.
const Main = preload("res://scenes/main.tscn")
var viewport: SubViewport
var main: Node2D

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = Main.instantiate()
	viewport.add_child(main)
	await _frames(30)
	var paddle: CharacterBody2D = main.paddle
	var ball: CharacterBody2D = main.ball
	paddle.set_physics_process(false)
	paddle.position.x = 480.0
	paddle.target_x = 480.0
	await _frames(2)
	await _save("active")
	# A real descending low-Vitality ball meets the Paddle; capture right after the transfer.
	var transferred := [0.0]
	ball.paddle_energy_transferred.connect(func(amount: float): transferred[0] = amount)
	ball.position = Vector2(470, 430)
	ball.velocity = Vector2(0, 300)
	ball.vitality_model.set_vitality(0.12)
	for frame in range(90):
		await physics_frame
		if transferred[0] > 0.0:
			break
	# Freeze the first frames after contact; slow capture rendering must not age the feedback.
	ball.set_physics_process(false)
	paddle.set_process(false)
	paddle.advance_feedback(1.0 / 60.0)
	print("UI CAPTURE transfer=", transferred[0], " dim=", paddle.dim_strength())
	await _save("hit")
	paddle.advance_feedback(0.3)
	await _save("hit-300ms")
	paddle.advance_feedback(1.0)
	ball.set_physics_process(true)
	paddle.set_process(true)
	await _frames(40)
	await _save("after-hit")
	# Resting on the ground beside the Paddle.
	ball.position = Vector2(300, ball.safe_center_bounds().end.y)
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.02)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = ball.SupportKind.GROUND
	ball.play_rhythm.continuation_available = false
	await _frames(10)
	await _save("rest")
	main.free()
	quit()

func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://.godot/ui-center-" + label + ".png")
	print("UI CAPTURE ", label, " result=", result)
