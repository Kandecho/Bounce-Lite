extends SceneTree

func _init() -> void:
	var suite = preload("res://tests/test_support.gd").new()
	preload("res://tests/test_world_feedback.gd").new().run(suite)
	preload("res://tests/test_ball_visuals.gd").new().run(suite)
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
