extends SceneTree
const Support = preload("res://tests/test_support.gd")
class Blocker extends Node:
	func entity_envelopes() -> Array[Rect2]: return [Rect2(0,0,960,720)]
var suite = Support.new()
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	suite.expect_not_null(main.get("spawn_occupancy"), "default entry registers shared core occupancy")
	if main.get("spawn_occupancy") != null: await _check(main)
	main.queue_free()
	await process_frame
	await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)

func _check(main) -> void:
	var registry = main.spawn_occupancy
	var world = main.play_world
	var toys = main.geometry_playground.toys
	var portals = main.portals
	for node in [world,toys,portals,main.ball,main.paddle]: node.set_physics_process(false)
	toys.set_layout(0)
	toys.set_ball_context(Vector2(480,650),16)
	main.ball.global_position = Vector2(480,650)
	world._states = {"rotor":"absent","charge":"absent"}
	portals.mouths.assign([Vector2(260,240),Vector2(750,240)])
	for phase in ["appearing","active","fading"]:
		portals.phase = phase
		suite.expect_false(world._geometry_clear(Vector2(260,240),24),"rotor candidate avoids portal "+phase)
		suite.expect_false(world._geometry_clear(Vector2(750,240),27),"charge candidate avoids portal "+phase)
		suite.expect_false(toys._legal_point("bumper",Vector2(260,240),Vector2.UP),"geometry candidate avoids portal "+phase)
		suite.expect_true(world._geometry_clear(Vector2(350,240),24),"rotor field may overlap portal "+phase)
	portals.phase = "absent"
	suite.expect_true(world._geometry_clear(Vector2(260,240),24),"absent mouths release occupancy")
	world.rotor_position = Vector2(300,240)
	world.charge_position = Vector2(600,240)
	for phase in ["appearing","active","waiting","fading"]:
		world._states = {"rotor":phase,"charge":phase}
		suite.expect_false(portals.outlet_clear(Vector2(300,240),27,main.ball),"portal avoids rotor core "+phase)
		suite.expect_false(portals.outlet_clear(Vector2(600,240),27,main.ball),"portal avoids Area2D charge "+phase)
		suite.expect_false(toys._legal_point("bumper",Vector2(600,240),Vector2.UP),"geometry avoids charge "+phase)
	world._states = {"rotor":"absent","charge":"absent"}
	toys._add("seesaw",Vector2(400,300))
	var body = toys._toys.back()
	body.set_meta("phase","fading")
	suite.expect_false(portals.outlet_clear(Vector2(470,332),27,main.ball),"portal avoids full seesaw motion envelope during fade")
	suite.expect_false(world._geometry_clear(Vector2(470,332),24),"rotor avoids full seesaw envelope")
	suite.expect_false(toys._legal_point("bumper",Vector2(400,300),Vector2.UP),"same-family fading body retains shape occupancy")
	registry.register(toys,false)
	suite.expect_true(world._geometry_clear(Vector2(470,332),24),"opt-out provider does not block candidates")
	portals.phase = "active"
	suite.expect_true(toys._legal_point("bumper",Vector2(260,240),Vector2.UP),"opt-out candidate skips foreign occupancy")
	suite.expect_false(toys._legal_point("bumper",Vector2(260,710),Vector2.UP),"opt-out keeps boundary and paddle safety")
	registry.register(toys)
	suite.expect_false(toys._legal_point("bumper",Vector2(260,240),Vector2.UP),"register defaults back to participation")
	registry.unregister(portals)
	suite.expect_true(world._geometry_clear(Vector2(260,240),24),"unregistered provider releases occupancy")
	registry.register(portals)
	var temporary = Node.new()
	registry.register(temporary)
	temporary.free()
	suite.expect_true(registry.is_clear(Rect2(850,100,10,10),world),"dead weak providers are safely removed")
	# All finite retries see a genuinely occupied spawn region; no force placement.
	toys.set_layout(0)
	world.spawn_region = Rect2(245,225,35,35)
	suite.expect_equal(world._candidate("charge"),Vector2.INF,"no available charge placement does not force spawn")
	world.spawn_region = main.spawn_region()
	var blocker := Blocker.new()
	registry.register(blocker)
	portals.phase = "absent"
	portals.mouths.clear()
	suite.expect_false(portals._spawn_pair(),"no available portal placement does not force pair")
	suite.expect_true(portals.mouths.is_empty(),"failed portal placement leaves no half pair")
	suite.expect_false(toys._try_spawn(),"no available geometry placement stays bounded")
	suite.expect_equal(world._candidate("rotor"),Vector2.INF,"occupied region does not force rotor spawn")
	registry.unregister(blocker)
	blocker.free()
	var departing = load("res://scripts/world/geometry_toys.gd").new()
	departing.spawn_occupancy = registry
	registry.register(departing)
	root.add_child(departing)
	departing._add("bumper",Vector2(850,150))
	suite.expect_false(registry.is_clear(Rect2(840,140,20,20),world),"entered provider registers occupancy")
	root.remove_child(departing)
	suite.expect_true(registry.is_clear(Rect2(840,140,20,20),world),"exit-tree unregisters still-live provider")
	departing.free()
	# Snapshot rejection must happen before any geometry/world/portal mutation.
	portals.phase = "absent"
	portals.mouths.clear()
	main.geometry_playground.restart_world(184)
	main.geometry_playground._restart_pending = false
	suite.expect_true(main.geometry_playground.save_combination(),"save current v3 combination")
	var path: String = main.geometry_playground.last_saved_path
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.portals.phase = "active"
	data.portals.mouths = [[300,240],[740,240]]
	data.world.states.rotor = "active"
	data.world.rotor = [300,240]
	var invalid_path := "res://.godot/portal-clearance-20261001/overlap-v3.json"
	var file = FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	var before := JSON.stringify(main.play_world.export_snapshot())
	var geometry_before := JSON.stringify(toys.export_snapshot())
	var portal_before := JSON.stringify(portals.export_snapshot())
	suite.expect_false(main.geometry_playground.restore_combination(invalid_path),"old overlapping v3 explicitly rejected")
	suite.expect_equal(JSON.stringify(main.play_world.export_snapshot()),before,"rejected restore leaves world unchanged")
	suite.expect_equal(JSON.stringify(portals.export_snapshot()),portal_before,"rejected restore leaves entire portal state unchanged")
	suite.expect_equal(JSON.stringify(toys.export_snapshot()),geometry_before,"rejected restore leaves entire geometry state unchanged")
	data.world.states.rotor = "absent"
	data.world.states.charge = "fading"
	data.world.charge = [740,240]
	file = FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	suite.expect_false(main.geometry_playground.restore_combination(invalid_path),"v3 fading Area2D overlap also rejected")
	data.world.states.charge = "absent"
	toys._add("seesaw",Vector2(300,240))
	data.geometry = toys.export_snapshot()
	toys.set_layout(0)
	file = FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	suite.expect_false(main.geometry_playground.restore_combination(invalid_path),"v3 full geometry overlap also rejected")
	suite.expect_true(main.geometry_playground.restore_combination(path),"nonoverlapping v3 remains compatible")
