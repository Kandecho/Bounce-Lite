extends SceneTree

const World = preload("res://scripts/world/play_world.gd")
const Result = preload("res://scripts/physics/surface_collision_result.gd")
const Support = preload("res://tests/test_support.gd")
var offers := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var suite = Support.new()
	var world = World.new()
	world.set_random_spawns_enabled(false)
	root.add_child(world)
	world.configure(null, Rect2(173, 133, 615, 448))
	world.set_physics_process(false)
	var result = Result.new()
	result.surface_kind = 4
	result.velocity_before = Vector2(170, 250)
	world.on_surface_resolved(result, world.rotor_position + Vector2(0, -40))
	var spin: float = world.angular_velocity
	suite.expect_true(absf(spin) > 0.2, "contact leaves rotor memory")
	var before: float = world.rotor_angle
	world._physics_process(1.0)
	suite.expect_true(absf(world.angular_velocity) < absf(spin), "rotor memory decays")
	suite.expect_true(world.rotor_angle != before, "memory advances angle")
	var angle: float = world.rotor_angle
	var force := world.sample_acceleration(world.rotor_position + Vector2(60, 0), Vector2(1, 2))
	suite.expect_equal(world.rotor_angle, angle, "sampling is read-only")
	suite.expect_true(force.length() <= World.MAX_ACCELERATION, "force bounded")
	for x in range(173, 789, 15):
		for y in range(133, 582, 15):
			suite.expect_true(world.sample_acceleration(Vector2(x, y), Vector2(9999, -9999)).length() <= World.MAX_ACCELERATION + 0.001, "field bound")
	var body := CharacterBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16
	collider.shape = circle
	body.add_child(collider)
	body.position = Vector2(700, 450)
	root.add_child(body)
	world.vitality_offered.connect(func(_amount: float, _position: Vector2): offers += 1)
	for frame in range(3):
		await physics_frame
	suite.expect_equal(offers, 0, "no offer without overlap")
	body.position = world.charge_position
	for frame in range(4):
		await physics_frame
	suite.expect_equal(offers, 1, "real overlap offers once")
	world._on_charge_body_entered(body)
	suite.expect_equal(offers, 1, "cooldown throttles repeated contact")
	world._physics_process(World.CHARGE_COOLDOWN + 0.01)
	suite.expect_equal(offers, 2, "recovery offers to real resident overlap")
	world.set_enabled(false)
	world._physics_process(World.CHARGE_COOLDOWN + 0.01)
	suite.expect_equal(offers, 2, "disabled world cannot offer")
	suite.expect_equal(world.sample_acceleration(world.rotor_position, Vector2.ZERO), Vector2.ZERO, "disabled field is zero")
	await physics_frame
	await physics_frame
	suite.expect_equal(world.get_node("Rotor").collision_layer, 0, "disabled physical rotor")
	body.free()
	world.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
