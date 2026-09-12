extends SceneTree
## Presentation-only comparison: committed event at identical origin and intensity.
## Does not stand in for actual launch physics or user experience.

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(640, 480)
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("10191f")
	background.size = Vector2(640, 480)
	stage.add_child(background)
	var feedback = preload("res://scripts/world/world_feedback.gd").new()
	stage.add_child(feedback)
	feedback.set_process(false)
	feedback.set_muted(true)
	for index in range(2):
		var label := Label.new()
		label.text = "Wake" if index == 0 else "Continue"
		label.position = Vector2(145 + index * 300, 150)
		stage.add_child(label)
	feedback.on_world_event("wake", Vector2(170, 270), 1.0)
	feedback.on_world_event("resume", Vector2(470, 270), 1.0)
	feedback.advance_time(0.10)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/wake-continue-010.png")
	feedback.advance_time(0.22)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/wake-continue-032.png")
	print("Captured committed feedback at 0.10 and 0.32 seconds")
	quit()
