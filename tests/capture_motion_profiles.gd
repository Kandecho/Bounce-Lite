extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	var profile: String = main.tuning.motion_profile
	var game = main.geometry_playground
	game.restart_world(184)
	for frame in range(121):
		await physics_frame
		if frame in [0, 120]:
			await RenderingServer.frame_post_draw
			var image := viewport.get_texture().get_image()
			var path := "res://.godot/motion-ab/render-%s-%03d.png" % [profile, frame]
			if image.save_png(path) != OK:
				push_error("Could not save " + path)
				quit(1)
				return
			print("MOTION RENDER profile=", profile, " seed=184 frame=", frame, " path=", path, " ball=", main.ball.position)
	viewport.queue_free()
	await process_frame
	quit(0)
