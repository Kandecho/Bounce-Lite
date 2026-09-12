extends SceneTree

const World = preload("res://scripts/world/play_world.gd")
const Support = preload("res://tests/test_support.gd")
var offers := 0

func _init() -> void:
	call_deferred("_run")

func make_world(seed_value: int, region: Rect2):
	var world = World.new()
	world.set_seed(seed_value)
	root.add_child(world)
	world.configure(null, Rect2(0, 0, 960, 720), region)
	world.set_physics_process(false)
	return world

func _run() -> void:
	var suite = Support.new()
	var region := Rect2(72, 72, 816, 393)
	var a = make_world(184, region)
	var b = make_world(184, region)
	a._physics_process(10.0)
	suite.expect_equal(a.rotor_state, "absent", "initial spawn waits for ball context")
	a.set_seed(184)
	a.set_ball_context(Vector2(480, 250), 16.0)
	b.set_ball_context(Vector2(480, 250), 16.0)
	for step in range(100):
		a._physics_process(0.05)
		b._physics_process(0.05)
	suite.expect_equal(a.rotor_position, b.rotor_position, "seed reproduces rotor position")
	suite.expect_equal(a.charge_position, b.charge_position, "seed reproduces charge position")
	suite.expect_true(region.grow(-World.ROTOR_RADIUS).has_point(a.rotor_position), "rotor geometry in region")
	suite.expect_true(region.grow(-World.CHARGE_RADIUS).has_point(a.charge_position), "charge geometry in region")
	suite.expect_true(a.rotor_position.distance_to(Vector2(480, 250)) > World.ROTOR_RADIUS + 16.0, "spawn excludes ball")
	suite.expect_true(a.rotor_position.distance_to(a.charge_position) > World.ROTOR_RADIUS + World.CHARGE_RADIUS, "objects exclude each other")
	a.set_ball_context(a.rotor_position, 16.0)
	for step in range(800):
		a._physics_process(0.05)
	suite.expect_equal(a.rotor_state, "waiting", "nearby ball postpones rotor removal")
	a.set_ball_context(Vector2(950, 700), 16.0)
	a.angular_velocity = 0.0
	a._physics_process(0.05)
	suite.expect_equal(a.rotor_state, "fading", "safe rotor fades")
	await physics_frame
	await physics_frame
	suite.expect_equal(a.get_node("Rotor").collision_layer, 0, "fading has no hidden collision")
	var force_before: Vector2 = a.sample_acceleration(a.rotor_position + Vector2(60, 0), Vector2.ZERO)
	a.angular_velocity = 4.0
	suite.expect_equal(a.sample_acceleration(a.rotor_position + Vector2(60, 0), Vector2.ZERO), force_before, "inactive rotor contributes no turning force")
	var blocked = make_world(23, Rect2(10, 10, 30, 30))
	blocked.set_ball_context(Vector2(25, 25), 16.0)
	for step in range(100):
		blocked._physics_process(0.05)
	suite.expect_equal(blocked.rotor_state, "absent", "impossible region postpones rotor")
	suite.expect_equal(blocked.charge_state, "absent", "impossible region postpones charge")
	a.set_enabled(false)
	await physics_frame
	await physics_frame
	suite.expect_equal(a.get_node("Charge").monitoring, false, "disabled charge has no monitoring")
	var body := CharacterBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	body.add_child(shape)
	body.position = b.charge_position
	root.add_child(body)
	b.vitality_offered.connect(func(_amount, _position): offers += 1)
	for frame in range(4):
		await physics_frame
	suite.expect_equal(offers, 1, "random active charge offers on real overlap")
	b.set_enabled(false)
	b.charge_remaining = 0.0
	b._on_charge_body_entered(body)
	for frame in range(3):
		await physics_frame
	suite.expect_equal(offers, 1, "disabled random charge rejects resident overlap")
	suite.expect_equal(b.get_node("Charge").monitoring, false, "removed charge monitoring is off")
	body.free()
	a.free()
	b.free()
	blocked.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
