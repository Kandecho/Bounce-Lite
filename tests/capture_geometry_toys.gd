extends SceneTree
const Toys = preload("res://scripts/world/geometry_toys.gd")
const Result = preload("res://scripts/physics/surface_collision_result.gd")
var viewport: SubViewport
var toys: Node2D
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.canvas_transform = Transform2D(0.0, Vector2(2.0 / 3.0, 2.0 / 3.0), 0.0, Vector2.ZERO)
	toys = Toys.new()
	viewport.add_child(toys)
	toys.configure(Rect2(0, 0, 960, 720))
	toys.set_layout(1)
	toys.set_physics_process(false)
	await save("family")
	var result = Result.new()
	result.velocity_before = Vector2(0, 400)
	result.normal = Vector2.UP
	for body in toys.get_children():
		toys.on_contact_committed(body, result, body.global_position + Vector2(0, -25))
	toys._physics_process(0.05)
	await save("impact")
	toys._physics_process(0.25)
	await save("rebound")
	toys.set_ball_context(Vector2(480, 640), 16)
	toys.set_paddle_context(Vector2(480, 570), Vector2(140, 18))
	toys.set_random_mode(true, 912)
	for step in range(120): toys._physics_process(0.05)
	await save("random-six-seconds")
	for step in range(340): toys._physics_process(0.05)
	await save("random-23-seconds")
	var log_file := FileAccess.open("res://.godot/geometry-lifecycle.json", FileAccess.WRITE)
	log_file.store_string(JSON.stringify(toys.lifecycle_events, "\t"))
	toys.free()
	quit()
func save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	print("GEOMETRY CAPTURE ", label, " result=", viewport.get_texture().get_image().save_png("res://.godot/geometry-" + label + ".png"))
