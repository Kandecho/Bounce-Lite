extends SceneTree
const Support=preload("res://tests/test_support.gd")
var suite=Support.new()
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	var bricks=main.bricks
	for node in [bricks,main.play_world,main.portals,main.geometry_playground.toys,main.ball,main.paddle]: node.set_physics_process(false)
	suite.expect_true(bricks.has_method("core_size"),"same family supplies real thin fragile shape")
	if bricks.has_method("core_size"): await _check(main)
	main.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures==0 else 1)
func _check(main) -> void:
	var bricks=main.bricks
	var ball=main.ball
	bricks.clear()
	main.geometry_playground.toys.set_layout(0)
	main.play_world._states={"rotor":"absent","charge":"absent"}
	main.portals.phase="absent"
	main.portals.mouths.clear()
	var body=bricks.add_brick("fragile",Vector2(480,200),20)
	suite.expect_equal(body.get_child(0).shape.size,Vector2(72,12),"fragile thin collider matches drawn thin face")
	suite.expect_equal(bricks.entity_envelopes()[0].size,Vector2(84,40),"thin brick keeps conservative footprint")
	ball.position=Vector2(480,140)
	ball.start_active(Vector2.DOWN)
	ball.velocity=Vector2(0,780)
	ball.set_physics_process(true)
	for frame in range(8): await physics_frame
	ball.set_physics_process(false)
	suite.expect_equal(body.get_meta("phase"),"shattering","single actual780 collision breaks fragile brick")
	var count: int=bricks.events.size()
	ball.velocity=Vector2(0,780)
	ball.resolve_surface_collision(0,Vector2.UP,false,0,body)
	suite.expect_equal(bricks.events.size(),count,"shattering fragile contact cannot double break")
	suite.expect_equal(bricks.events.back().kind,"toy_brick_break","fragile reuses ordinary break audio")
	suite.expect_false(main.portals.outlet_clear(Vector2(480,200),27,ball),"visible thin shatter retains outlet occupancy")
	bricks._physics_process(0.66)
	suite.expect_true(bricks.bodies.is_empty(),"fragile departs without regrowth")
	var counts: Dictionary={"fragile":0,"ordinary":0,"reverse":0}
	for index in range(10000): counts[bricks.kind_for_roll(float(index)/10000)]+=1
	suite.expect_equal(counts,{"fragile":6000,"ordinary":2500,"reverse":1500},"deterministic weights60/25/15")
	for point in [0.0,0.5999,0.6,0.8499,0.85,0.9999]:
		suite.expect_true(bricks.kind_for_roll(point) in counts,"weight boundaries select valid same-family kind")
	bricks.add_brick("ordinary",Vector2(200,200),20)
	var legacy: Dictionary=bricks.export_snapshot()
	legacy.version=1
	legacy.erase("generation_rule")
	suite.expect_true(bricks.restore_snapshot(legacy),"old v4 brickv1 accepted without rearrangement")
	suite.expect_equal(bricks.generation_rule,"legacy-two-kind","old random progression retains original two-kind schedule")
	suite.expect_equal(bricks.kind_for_roll(0.2),"reverse","legacy half-range remains reverse")
	suite.expect_equal(bricks.kind_for_roll(0.8),"ordinary","legacy upper half remains ordinary")
	suite.expect_true(main.geometry_playground.save_combination(),"fullv4 saves accepted legacy composition")
	var data4=JSON.parse_string(FileAccess.get_file_as_string(main.geometry_playground.last_saved_path))
	data4.bricks.version=1
	data4.bricks.erase("generation_rule")
	var path: String="res://.godot/brick-refinement-20261001/legacy-v4.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data4)); file.close()
	suite.expect_true(main.geometry_playground.restore_combination(path),"previous fullv4 restores old ordinary/reverse state")
	suite.expect_equal(bricks.generation_rule,"legacy-two-kind","fullv4 compatibility retains prior generator")
	for keycode in [KEY_R,KEY_N]:
		var key:=InputEventKey.new()
		key.keycode=keycode
		key.pressed=true
		root.push_input(key)
		suite.expect_equal(bricks.generation_rule,"fragile60-ordinary25-reverse15","actual R/N returns to current policy")
	bricks.restart(184)
	suite.expect_equal(bricks.generation_rule,"fragile60-ordinary25-reverse15","R/N restart selects approved new default")
	bricks.add_brick("fragile",Vector2(300,200),20)
	var data: Dictionary=bricks.export_snapshot()
	suite.expect_equal(data.version,2,"new brick subformat records weighted policy")
	suite.expect_true(bricks.restore_snapshot(data),"new fragile snapshot restores")
	suite.expect_true(main.geometry_playground.save_combination(),"newv2 full composition saves to disk")
	var new_path: String=main.geometry_playground.last_saved_path
	main.geometry_playground.restart_world(185)
	suite.expect_true(main.geometry_playground.restore_combination(new_path),"newv2 JSON full composition restores")
	suite.expect_equal(bricks.bodies[0].get_meta("brick_kind"),"fragile","newv2 JSON restores actual thin kind")
	for invalid in [0,3,1.5,"1",true]:
		var malformed: Dictionary=data.duplicate(true)
		malformed.version=invalid
		suite.expect_false(bricks.snapshot_valid(malformed),"unsupported or wrongly typed subversion refused")
	data.bodies[0].stage="cracked"
	suite.expect_false(bricks.snapshot_valid(data),"fragile invalid cracked state rejected")
	data.bodies[0].stage="whole"
	data.version=1
	data.erase("generation_rule")
	suite.expect_false(bricks.snapshot_valid(data),"legacy subformat cannot smuggle fragile kind")
	bricks.clear()

	# Actual generator repeatability, rather than only threshold counts.
	ball.position=Vector2(480,650)
	bricks.restart(271)
	for index in range(3): suite.expect_true(bricks._try_spawn(),"mixed actual generator has legal placement")
	var generated: String=JSON.stringify(bricks.export_snapshot())
	bricks.restart(271)
	for index in range(3): bricks._try_spawn()
	suite.expect_equal(JSON.stringify(bricks.export_snapshot()),generated,"same seed repeats kinds, positions and random progress")
	suite.expect_false(bricks._try_spawn(),"weighted mixed family still obeys max3")
	bricks.clear()
