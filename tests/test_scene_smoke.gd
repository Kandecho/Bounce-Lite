extends RefCounted

const MAIN_SCENE_PATH := "res://scenes/main.tscn"


func run(suite: RefCounted) -> void:
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	suite.expect_not_null(packed, "main scene loads")
	if packed == null:
		return
	var main: Node = packed.instantiate()
	var ball := main.get_node_or_null("GameArea/Ball")
	suite.expect_not_null(ball, "scene owns a Ball")
	if ball != null:
		suite.expect_true(ball.has_method("apply_resting_interaction"),
			"Ball exposes Resting Wake Impulse")
	suite.expect_not_null(main.get_node_or_null("GameArea/Ball/Visuals"),
		"Ball owns procedural visuals")
	var paddle := main.get_node_or_null("GameArea/Paddle")
	suite.expect_not_null(paddle, "scene owns a Paddle")
	if paddle != null:
		suite.expect_true(paddle.has_signal("interaction_sampled"),
			"Paddle exposes continuous motion input")
	suite.expect_not_null(main.get_node_or_null("EndlessRules"), "scene owns Endless rules")
	suite.expect_not_null(main.get_node_or_null("HUD"), "scene owns a HUD")
	suite.expect_not_null(main.get_node_or_null("HUD/ComboLabel"), "HUD owns Combo text")
	suite.expect_not_null(main.get_node_or_null("HUD/TimerLabel"), "HUD owns Timer text")
	var tuning_panel := main.get_node_or_null("DebugOverlay/RuntimeTuningPanel")
	suite.expect_true(main.get_node("DebugOverlay").layer > main.get_node("HUD").layer,
		"debug overlay draws above the whole game and HUD")
	suite.expect_not_null(tuning_panel, "scene owns a runtime tuning panel")
	if tuning_panel != null:
		suite.expect_false(tuning_panel.visible, "runtime tuning panel is hidden by default")

	var ground := main.get_node_or_null("GameArea/Ground")
	suite.expect_not_null(ground, "scene owns a Ground boundary")
	if ground != null:
		suite.expect_true(ground.has_meta("surface_kind"),
			"Ground carries collision classification metadata")
	if ground != null and paddle != null and ball != null:
		var ground_top: float = ground.position.y - ground.get_node("CollisionShape2D").shape.size.y * 0.5
		var radius: float = ball.get_node("CollisionShape2D").shape.radius
		var paddle_bottom: float = paddle.position.y + paddle.get_node("CollisionShape2D").shape.size.y * 0.5
		suite.expect_true(ground_top - radius * 2.0 - paddle_bottom >= 2.9,
			"Paddle leaves a real gap above the resting circle")
		suite.expect_true(ball.z_index > paddle.z_index, "Ball draws above Paddle")
	main.free()
