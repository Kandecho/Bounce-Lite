extends SceneTree
const Toys = preload("res://scripts/world/geometry_toys.gd")
const Result = preload("res://scripts/physics/surface_collision_result.gd")
const Support = preload("res://tests/test_support.gd")
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var suite = Support.new()
	var toys = Toys.new()
	root.add_child(toys)
	toys.configure(Rect2(0, 0, 960, 720))
	toys.set_physics_process(false)
	toys.set_layout(1)
	var result = Result.new()
	result.normal = Vector2.UP
	result.velocity_before = Vector2(120, 300)
	for body in toys.get_children():
		var response: Dictionary = toys.contact_request(result, body, body.position + Vector2(0, -30))
		suite.expect_true(response.velocity.is_finite(), "geometry response is finite before Ball's global cap")
		suite.expect_equal(response.vitality_delta, 0.0, "no geometry contact grants vitality")
		if body.get_meta("toy_kind") in ["platform", "ramp"]:
			suite.expect_equal(response.velocity, Vector2(120, -300), "ordinary geometry only reflects")
		if body.get_meta("toy_kind") == "spring":
			suite.expect_true(response.has("spring_capture"), "spring top requests capture")
			result.normal = Vector2.DOWN
			result.velocity_before = Vector2(120, -300)
			suite.expect_equal(toys.contact_request(result, body, body.position).velocity, Vector2(120, 300), "spring bottom is ordinary surface")
			result.normal = Vector2.UP
			result.velocity_before = Vector2(120, 300)
	var probe := CharacterBody2D.new()
	probe.collision_layer = 2
	probe.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	probe.add_child(shape)
	root.add_child(probe)
	await physics_frame
	await physics_frame
	for collider in toys.get_children():
		probe.position = collider.global_position + Vector2(0, -80)
		var contact := probe.move_and_collide(Vector2(0, 120))
		suite.expect_not_null(contact, "real geometry contact exists")
		if contact == null: continue
		suite.expect_equal(contact.get_collider(), collider, "real contact identifies matching shape")
		result.normal = contact.get_normal()
		result.velocity_before = Vector2(0, 300)
		var response: Dictionary = toys.contact_request(result, collider, probe.position)
		if collider.get_meta("toy_kind") in ["ramp", "sling"]:
			suite.expect_true(absf(result.normal.x) > 0.3 and result.normal.y < -0.3, "sloped geometry has actual sloped normal")
		if collider.get_meta("toy_kind") in ["ramp", "platform"]:
			suite.expect_float(response.velocity.length(), 300, 0.01, "plain surface preserves incident speed")
			suite.expect_float(response.vitality_delta, 0, 0.001, "plain surface grants no vitality")
	probe.free()
	toys.set_ball_context(Vector2(480, 640), 16)
	toys.set_paddle_context(Vector2(480, 570), Vector2(140, 18))
	toys.set_random_mode(true, 912)
	for step in range(120):
		toys._physics_process(0.05)
	var saved: Dictionary = toys.export_snapshot()
	suite.expect_true(saved.toys.size() > 1, "random objects coexist")
	for body in toys.get_children():
		suite.expect_true(toys._legal_point(body.get_meta("toy_kind"), body.global_position, body.get_meta("kick"), body), "geometry and sweep spawn legally")
	var twin = Toys.new()
	root.add_child(twin)
	twin.configure(Rect2(0, 0, 960, 720))
	twin.set_physics_process(false)
	twin.set_ball_context(Vector2(480, 640), 16)
	twin.set_paddle_context(Vector2(480, 570), Vector2(140, 18))
	twin.set_random_mode(true, 912)
	for step in range(120):
		twin._physics_process(0.05)
	suite.expect_equal(JSON.stringify(twin.export_snapshot()), JSON.stringify(saved), "same seed reproduces world")
	suite.expect_true(twin.restore_snapshot(JSON.parse_string(JSON.stringify(saved))), "JSON restore succeeds")
	suite.expect_equal(JSON.stringify(twin.export_snapshot()), JSON.stringify(saved), "snapshot preserves rng and geometry")
	var body: StaticBody2D = twin.get_children()[0]
	body.set_meta("remaining", 0.01)
	twin._physics_process(0.05)
	suite.expect_equal(body.collision_layer, 0, "fade disables collision")
	twin._physics_process(0.7)
	suite.expect_false(body in twin.get_children(), "finite fade deletes body")
	toys.free()
	twin.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
