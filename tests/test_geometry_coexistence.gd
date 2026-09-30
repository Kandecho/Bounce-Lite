extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	suite.expect_not_null(main.play_world, "default really connects rotor and charge beside geometry")
	suite.expect_not_null(main.geometry_playground, "default retains six geometry kinds")
	suite.expect_equal(main.get_node("GameArea").find_children("WorldFeedback", "", false, false).size(), 1, "committed launch feedback has one owner")
	if main.play_world != null:
		await _check_combination(main)
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)

func _check_combination(main) -> void:
	var world = main.play_world
	var game = main.geometry_playground
	var toys = game.toys
	suite.expect_true(main.ball.play_world == world, "Ball samples the real connected field")
	suite.expect_true(world.has_method("export_snapshot"), "combination records original world state")
	suite.expect_true(world.has_method("entity_envelopes"), "original world supplies entity envelopes")
	suite.expect_true(toys.has_method("entity_envelopes"), "geometry supplies full motion envelopes")
	if not world.has_method("export_snapshot") or not toys.has_method("entity_envelopes"): return
	world.set_physics_process(false)
	toys.set_physics_process(false)
	main.ball.set_physics_process(false)
	main.paddle.set_physics_process(false)
	game.restart_world(184)
	for frame in range(5): await physics_frame
	main.ball.set_physics_process(false)
	toys.set_layout(1)
	world.set_random_spawns_enabled(false)
	world.angular_velocity = 4.2
	world.rotor_position = Vector2(490, 360)
	world.get_node("Rotor").position = world.rotor_position
	var seesaw = toys.get_children()[5]
	suite.expect_true(toys.entity_envelopes()[5].size.y > 16, "seesaw reserves complete rotation envelope")
	suite.expect_false(toys._legal_point("platform", world.rotor_position, Vector2.ZERO), "geometry cannot spawn through rotor core")
	suite.expect_true(world.sample_acceleration(seesaw.position, Vector2.ZERO).length() > 1, "field can naturally reach geometry")
	for kind in ["rotor", "charge"]:
		for attempt in range(150):
			var point: Vector2 = world._candidate(kind)
			if point == Vector2.INF: continue
			var radius: float = world.ROTOR_RADIUS if kind == "rotor" else world.CHARGE_RADIUS
			var bounds := Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2)
			suite.expect_true(world.spawn_region.encloses(bounds), "world full core stays inside spawn region")
			for envelope in toys.entity_envelopes():
				suite.expect_false(bounds.intersects(envelope), "world spawn avoids complete geometry envelope")
	var before: float = main.ball.vitality_model.current_vitality
	main.ball.resolve_surface_collision(0, Vector2.UP, false, 0, toys.get_children()[0])
	suite.expect_true(main.ball.vitality_model.current_vitality <= before, "geometry grants no vitality beside charge")
	main.ball.vitality_model.set_vitality(0.2)
	world.charge_remaining = 0
	world._on_charge_body_entered(main.ball)
	suite.expect_float(main.ball.vitality_model.current_vitality, 0.52, 0.001, "connected charge retains its 0.32 offer")
	world._on_charge_body_entered(main.ball)
	suite.expect_float(main.ball.vitality_model.current_vitality, 0.52, 0.001, "one offer does not double apply")
	await _mechanical_field(main)
	suite.expect_true(game.save_combination(), "coexistence combination saves")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.latest_path))
	suite.expect_equal(data.get("world_mode", ""), "coexistence", "record identifies coexistence")
	var saved: Dictionary = world.export_snapshot()
	game.restart_world(7)
	suite.expect_true(game.restore_combination(), "matching coexistence record restores")
	suite.expect_equal(JSON.stringify(world.export_snapshot()), JSON.stringify(saved), "all original world state and RNG restore at saved JSON precision")
	data.erase("world_mode")
	data.erase("world")
	var file := FileAccess.open("res://.godot/geometry-coexistence-20260930/legacy.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	suite.expect_false(game.restore_combination("res://.godot/geometry-coexistence-20260930/legacy.json"), "default refuses geometry-only legacy combination")

func _mechanical_field(main) -> void:
	var game = main.geometry_playground
	var toys = game.toys
	var world = main.play_world
	var ball = main.ball
	for body in toys.get_children(): body.set_meta("remaining", 100.0)
	var spring = toys.get_children()[4]
	world.rotor_position = spring.position + Vector2(90, 0)
	world.get_node("Rotor").position = world.rotor_position
	world.angular_velocity = 4.2
	suite.expect_true(world.sample_acceleration(spring.position + Vector2(0, -35), Vector2.ZERO).length() > 10, "controlled spring is inside a turning rotor field")
	ball.start_active(Vector2.DOWN)
	ball.position = spring.position + Vector2(0, -35)
	ball.velocity = Vector2(100, 180)
	ball.set_physics_process(true)
	for frame in range(15):
		await physics_frame
		if is_instance_valid(ball.spring_hold): break
	suite.expect_equal(ball.spring_hold, spring, "real contact captures while rotor force is enabled")
	ball.set_physics_process(false)
	var lateral: float = ball._spring_incoming_x
	toys._physics_process(0.10)
	ball._advance_spring_hold(0.10)
	suite.expect_equal(ball.spring_hold, spring, "field cannot pull a held ball away halfway through hold")
	suite.expect_true(ball.velocity.is_zero_approx(), "captured velocity stays zero")
	spring.set_meta("remaining", -1.0)
	toys._spawn_timer = 100
	toys._random_tick(0.01)
	toys._physics_process(0.11)
	suite.expect_equal(spring.get_meta("phase"), "active", "expired spring waits while holding")
	ball._advance_spring_hold(0.11)
	suite.expect_true(ball.spring_hold == null, "normal release survives active field")
	suite.expect_float(ball.velocity.y, -main.tuning.spring_release_speed, 0.001, "field does not replace spring impulse")
	suite.expect_float(ball.velocity.x, lateral * 0.5, 0.001, "release preserves half actual field-influenced incidence")
	var launch: Vector2 = ball.velocity
	ball.advance_air_motion(1.0 / 60)
	suite.expect_true(ball.velocity != launch and ball.velocity.length() <= main.tuning.max_speed + 0.001, "field resumes after release with shared cap")
	# A real platform landing, then explicit qualified Continue and Wake.
	var platform = toys.get_children()[3]
	world.rotor_position = platform.position + Vector2(-100, 20)
	world.get_node("Rotor").position = world.rotor_position
	ball.clear_geometry_relationships()
	ball.start_active(Vector2.DOWN)
	ball.position = platform.position + Vector2(0, -26)
	ball.velocity = Vector2(0, 20)
	ball.vitality_model.set_vitality(0.04)
	ball.set_physics_process(true)
	for frame in range(120): await physics_frame
	suite.expect_true(ball.is_resting() and ball.support_kind == ball.SupportKind.GEOMETRY, "real platform settles inside rotor field")
	var resting_position: Vector2 = ball.position
	for frame in range(30): await physics_frame
	suite.expect_equal(ball.position, resting_position, "field does not secretly wake supported RESTING ball")
	ball.set_physics_process(false)
	toys.set_supported_colliders(ball.geometry_supported_colliders())
	platform.set_meta("remaining", -1.0)
	toys._random_tick(0.01)
	suite.expect_equal(platform.get_meta("phase"), "active", "expired supported platform waits")
	ball.receive_world_vitality(0.32)
	suite.expect_true(ball.is_resting() and ball.velocity.is_zero_approx(), "charge offer changes vitality without implicit launch")
	ball.play_rhythm.note_input(20)
	for step in range(90): ball.advance_play_rhythm(1.0 / 60)
	suite.expect_true(not ball.is_resting() and ball.velocity.y < 0, "qualified Continue remains explicit in coexistence")
	suite.expect_float(ball.velocity.y, -main.tuning.continue_launch_speed, 0.001, "Continue preserves accepted profile")
	ball.position = resting_position
	ball.velocity = Vector2.ZERO
	ball.support_kind = ball.SupportKind.GEOMETRY
	ball.support_geometry = platform
	ball.vitality_model.set_vitality(0.04)
	Support.prepare_resting(ball)
	ball.rest_elapsed_time = main.tuning.wake_rest_delay_seconds + 0.01
	suite.expect_true(ball.apply_resting_interaction(20, Vector2(ball.position.x, 570)), "Wake remains available from geometry in coexistence")
	suite.expect_float(ball.velocity.y, -main.tuning.wake_launch_speed, 0.001, "Wake retains stronger accepted profile")
	toys.set_supported_colliders([])
	toys._random_tick(0.01)
	suite.expect_equal(platform.get_meta("phase"), "fading", "unengaged expired platform can leave")
