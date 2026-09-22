extends SceneTree
const Toys = preload("res://scripts/world/geometry_toys.gd")
const Result = preload("res://scripts/physics/surface_collision_result.gd")
const Support = preload("res://tests/test_support.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var suite = Support.new()
	var toys = Toys.new()
	root.add_child(toys)
	toys.configure(Rect2(0, 0, 960, 720))
	toys.set_physics_process(false)
	toys.set_paddle_context(Vector2(480, 570), Vector2(140, 18))
	toys.set_ball_context(Vector2(480, 650), 16)
	toys.set_layout(1)
	var ball := CharacterBody2D.new()
	ball.collision_layer = 2
	ball.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	ball.add_child(shape)
	root.add_child(ball)
	await physics_frame
	await physics_frame
	var result = Result.new()
	var seesaw: StaticBody2D = toys.get_children()[5]
	for step in range(600): toys._physics_process(0.01)
	suite.expect_float(seesaw.rotation, 0, 0.00001, "untouched seesaw is stationary")
	var rates: Array[float] = []
	for offset in [5.0, 60.0]:
		seesaw.set_meta("angular_velocity", 0.0)
		seesaw.set_meta("cooldown", 0.0)
		ball.position = seesaw.global_position + Vector2(offset, -60)
		var collision := ball.move_and_collide(Vector2(0, 80))
		suite.expect_not_null(collision, "seesaw receives actual contact")
		result.normal = collision.get_normal()
		result.velocity_before = Vector2(0, 350)
		var request: Dictionary = toys.contact_request(result, seesaw, ball.position)
		result.velocity_after = request.velocity
		suite.expect_equal(request.vitality_delta, 0.0, "mechanics grants no vitality")
		toys.on_contact_committed(seesaw, result, ball.position)
		rates.append(seesaw.get_meta("angular_velocity"))
	suite.expect_true(rates[1] > rates[0] * 3, "larger lever causes greater angular response")
	suite.expect_true(toys.contact_request(result, seesaw, ball.position).velocity != result.velocity_before.bounce(result.normal), "instantaneous surface motion affects reflection")
	for step in range(600): toys._physics_process(0.01)
	suite.expect_true(absf(seesaw.rotation) <= toys.seesaw_max_angle, "angle stays bounded")
	var spring: StaticBody2D = toys.get_children()[4]
	ball.position = spring.global_position + Vector2(0, -70)
	var contact := ball.move_and_collide(Vector2(0, 90))
	suite.expect_equal(contact.get_collider(), spring, "actual spring contact")
	result.normal = contact.get_normal()
	result.velocity_before = Vector2(0, 300)
	suite.expect_true(toys.contact_request(result, spring, ball.position).has("spring_capture"), "contact requests capture")
	suite.expect_true(toys.begin_spring_hold(spring), "capture can commit")
	toys._physics_process(0.16)
	suite.expect_float(spring.get_meta("compression"), 0.5, 0.01, "half compression")
	suite.expect_false(toys.spring_hold_request(spring, 16).release, "compression retains ball")
	toys._physics_process(0.17)
	suite.expect_true(toys.spring_hold_request(spring, 16).release, "release request is finite")
	toys.end_spring_hold(spring)
	suite.expect_false(toys.begin_spring_hold(spring), "recapture debounce")
	var platform: StaticBody2D = toys.get_children()[3]
	ball.position = platform.global_position + Vector2(0, -50)
	var support := ball.move_and_collide(Vector2(0, 60))
	suite.expect_equal(support.get_collider(), platform, "actual platform support contact")
	toys.set_supported_colliders([platform])
	platform.set_meta("remaining", 0.01)
	toys.random_mode = true
	toys._spawn_timer = 100.0
	toys._physics_process(0.1)
	suite.expect_equal(platform.collision_layer, 1, "support prevents collision removal")
	suite.expect_true(platform.get_meta("expired_pending"), "expiration waits on support")
	toys.set_supported_colliders([])
	toys._physics_process(0.01)
	suite.expect_equal(platform.collision_layer, 0, "leaving support permits fade")
	for seed_value in range(12):
		toys.set_random_mode(true, seed_value)
		for step in range(100): toys._physics_process(0.05)
		for body in toys.get_children():
			var envelope: Rect2 = toys._spawn_shape(body.get_meta("toy_kind"), body.get_meta("kick")).get_rect()
			suite.expect_true(body.global_position.y + envelope.end.y <= 543.0, "complete sweep stays above paddle corridor")
	var saved: Dictionary = toys.export_snapshot()
	suite.expect_true(toys.restore_snapshot(JSON.parse_string(JSON.stringify(saved))), "mechanical JSON restore")
	var old := saved.duplicate(true)
	old.version = 1
	suite.expect_false(toys.restore_snapshot(old), "old profile rejected")
	ball.free()
	toys.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
