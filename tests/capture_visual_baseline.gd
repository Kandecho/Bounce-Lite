extends SceneTree

# Developer-only render evidence; writes ignored screenshots, never runtime assets.
const MainScene = preload("res://scenes/main.tscn")
var capture_viewport: Viewport


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	capture_viewport = root
	# Offscreen size override avoids the OS desktop work-area window-size clamp.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			var dimensions := argument.trim_prefix("--capture-size=").split("x")
			var viewport := SubViewport.new()
			viewport.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
			viewport.size_2d_override = Vector2i(960, 720)
			viewport.size_2d_override_stretch = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			capture_viewport = viewport
	var main := MainScene.instantiate()
	capture_viewport.add_child(main)
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var ball = main.get_node("GameArea/Ball")
	var visuals = ball.get_node("Visuals")
	var paddle = main.get_node("GameArea/Paddle")
	ball.position = Vector2(555, 325)
	visuals.set_vitality(1.0, 0)
	visuals.set_motion(Vector2(490, 0))
	visuals.clear_motion_history()
	visuals.advance_motion_history(Vector2(65, 325), 0.0)
	for frame in range(60):
		visuals.advance_motion_history(Vector2(65 + 490.0 * (frame + 1) / 60, 325), 1.0 / 60)
	paddle.play_collision_feedback(true, Vector2(480, 528))
	await _save("v013-active")
	visuals.set_vitality(0.4, 1)
	paddle.advance_feedback(0.14)
	await _save("v013-decaying")
	ball.position = Vector2(480, 564.92)
	visuals.set_motion(Vector2.ZERO)
	visuals.set_vitality(0.0, 2)
	paddle.advance_feedback(0.2)
	await _save("v013-resting")
	visuals.play_weak_feedback(0.9)
	await _save("v015-weak-ground")
	ball.position = Vector2(480, 511.92)
	await _save("v015-weak-paddle")
	# Put both game objects underneath the developer panel to expose layer regressions.
	main.get_node("DebugOverlay/RuntimeTuningPanel").show()
	ball.position = Vector2(700, 300)
	paddle.position = Vector2(700, 350)
	await _save("v013-debug-overlay")
	main.free()
	quit()


func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := capture_viewport.get_texture().get_image()
	var result := capture.save_png("res://.godot/" + label + "-" + str(capture.get_width()) + "x" + str(capture.get_height()) + ".png")
	print("RENDER ", label, " ", capture.get_size(), " result=", result)
