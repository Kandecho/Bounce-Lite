extends SceneTree

const World = preload("res://scripts/world/play_world.gd")
var viewport: SubViewport
var world: Node2D

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.canvas_transform = Transform2D(0.0, Vector2(2.0 / 3.0, 2.0 / 3.0), 0.0, Vector2.ZERO)
	world = World.new()
	world.set_seed(184)
	viewport.add_child(world)
	world.configure(null, Rect2(0, 0, 960, 720), Rect2(72, 72, 816, 393))
	world.set_ball_context(Vector2(480, 600), 16.0)
	world.set_physics_process(false)
	await advance(0.45)
	await save("appearing")
	await advance(2.0)
	await save("active")
	world.set_ball_context(world.rotor_position, 16.0)
	await advance(28.0)
	await save("waiting")
	world.set_ball_context(Vector2(950, 700), 16.0)
	await advance(0.3)
	await save("fading")
	await advance(0.5)
	await save("removed")
	var file := FileAccess.open("res://.godot/world-lifecycle-seed184.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(world.lifecycle_events, "\t"))
	world.free()
	quit()

func advance(seconds: float) -> void:
	for step in range(int(ceil(seconds * 60.0))):
		world._physics_process(1.0 / 60.0)
		await process_frame

func save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png("res://.godot/world-lifecycle-" + label + ".png")
	print("WORLD CAPTURE ", label, " rotor=", world.rotor_state, " charge=", world.charge_state, " result=", error)
