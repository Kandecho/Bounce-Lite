extends SceneTree

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
	await _frames(35)
	await _save("complete")
	# Controlled initial position/velocity, followed by real collision and motion.
	main.ball.position = main.play_world.rotor_position + Vector2(-85, -45)
	main.ball.velocity = Vector2(280, 80)
	await _frames(24)
	await _save("rotor")
	main.ball.position = main.play_world.charge_position + Vector2(0, -65)
	main.ball.velocity = Vector2(20, 170)
	await _frames(36)
	await _save("charge")
	# Stop input and let the real simulation reach its subsequent quiet phase.
	await _frames(1000)
	await _save("later")
	main.free()
	quit()

func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://.godot/shared-world-" + label + ".png")
	print("SHARED WORLD RENDER ", label, " result=", result)
