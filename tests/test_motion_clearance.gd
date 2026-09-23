extends SceneTree
const Toys = preload("res://scripts/world/geometry_toys.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Support = preload("res://tests/test_support.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var suite = Support.new()
	var toys = Toys.new()
	root.add_child(toys)
	toys.set_physics_process(false)
	toys.configure(Rect2(0, 0, 960, 720))
	toys.configure_tuning(Tuning.new())
	toys.set_ball_context(Vector2(100, 100), 16)
	toys.set_paddle_context(Vector2(480, 570), Vector2(150, 18))
	# A platform bottom at y=543 leaves only 18 px to the Paddle's top (y=561).
	# A 32 px Ball cannot fit; this must never be a legal random placement.
	suite.expect_false(toys._legal_point("platform", Vector2(700, 535), Vector2.UP), "random geometry leaves a full Ball diameter above paddle path")
	toys.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
