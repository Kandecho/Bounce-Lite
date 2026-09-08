extends RefCounted

const MAIN_SCENE_PATH := "res://scenes/main.tscn"


func run(suite: RefCounted) -> void:
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	suite.expect_not_null(packed, "main scene loads")
	if packed == null:
		return
	var main: Node = packed.instantiate()
	suite.expect_not_null(main.get_node_or_null("GameArea/Ball"), "scene owns a Ball")
	suite.expect_not_null(main.get_node_or_null("GameArea/Ball/Visuals"),
		"Ball owns procedural visuals")
	suite.expect_not_null(main.get_node_or_null("GameArea/Paddle"), "scene owns a Paddle")
	suite.expect_not_null(main.get_node_or_null("EndlessRules"), "scene owns Endless rules")
	suite.expect_not_null(main.get_node_or_null("HUD"), "scene owns a HUD")
	suite.expect_not_null(main.get_node_or_null("HUD/ComboLabel"), "HUD owns Combo text")
	suite.expect_not_null(main.get_node_or_null("HUD/TimerLabel"), "HUD owns Timer text")

	var ground := main.get_node_or_null("GameArea/Ground")
	suite.expect_not_null(ground, "scene owns a Ground boundary")
	if ground != null:
		suite.expect_true(ground.has_meta("surface_kind"),
			"Ground carries collision classification metadata")
	main.free()
