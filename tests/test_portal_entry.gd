extends SceneTree
const Support=preload("res://tests/test_support.gd")
var suite=Support.new()
func _init() -> void:call_deferred("_run")
func _key(code: int) -> void:
	var key:=InputEventKey.new()
	key.pressed=true
	key.keycode=code
	root.push_input(key)
func _run() -> void:
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5):await physics_frame
	var args:=OS.get_cmdline_user_args()
	var expected:=not (args.has("--geometry-only") or args.has("--geometry-baseline") or args.has("--v02-baseline") or args.has("--no-portals"))
	suite.expect_equal(main.portals!=null,expected,"entry selects portals only in default coexistence")
	if main.geometry_playground!=null:
		var game=main.geometry_playground
		var seed_value:int=game.world_seed
		if expected:main.portals.clock=5
		_key(KEY_R)
		suite.expect_equal(game.world_seed,seed_value,"R retains displayed seed")
		if expected:
			suite.expect_float(main.portals.clock,0,0.001,"R restarts portal random timeline")
			suite.expect_true(main.portals.phase=="absent" and main.portals.timer>=8 and main.portals.timer<=14,"R uses original low-frequency first-pair schedule")
		_key(KEY_F8)
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.latest_path))
		suite.expect_equal(data.version,3 if expected else 2,"new portal format versus preserved no-portal v2")
		if expected:
			suite.expect_equal(data.world_mode,"coexistence-portals","portal combination declares mode")
			suite.expect_true(game.latest_path.ends_with("latest-portals.json"),"new mode has separate latest file")
		_key(KEY_N)
		suite.expect_true(game.world_seed!=seed_value,"N selects a new shared seed")
		_key(KEY_F9)
		suite.expect_equal(game.world_seed,seed_value,"F9 restores saved combination seed")
		if expected:
			suite.expect_equal(JSON.parse_string(JSON.stringify(main.portals.export_snapshot())),data.portals,"F9 restores portal random timeline at JSON numeric representation")
			data.version=2
			data.world_mode="coexistence"
			data.erase("portals")
			var path:="res://.godot/portal-harvest-20261001/old-v2.json"
			var file:=FileAccess.open(path,FileAccess.WRITE)
			file.store_string(JSON.stringify(data))
			file.close()
			suite.expect_false(game.restore_combination(path),"old coexistence v2 cannot silently become a portal world")
			suite.expect_equal(game.world_seed,seed_value,"rejected old record leaves seed unchanged")
	main.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline:await process_frame
	suite.print_summary()
	quit(0 if suite.failures==0 else 1)
