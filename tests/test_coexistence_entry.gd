extends SceneTree
const Support = preload("res://tests/test_support.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var suite = Support.new()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(8): await physics_frame
	var args := OS.get_cmdline_user_args()
	if args.has("--geometry-baseline") or args.has("--v02-baseline"):
		suite.expect_true(main.geometry_playground == null, "baseline has no geometry")
		suite.expect_equal(main.play_world == null, args.has("--v02-baseline"), "baseline retains its explicit world setting")
	else:
		var game = main.geometry_playground
		var alone := args.has("--geometry-only")
		suite.expect_equal(main.play_world == null, alone, "entry explicitly selects coexistence or geometry control")
		suite.expect_true(game.save_combination(), "entry saves its own mode")
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.latest_path))
		suite.expect_equal(data.world_mode, "geometry-only" if alone else "coexistence", "snapshot mode matches entry")
		suite.expect_true(game.latest_path.ends_with("latest.json" if alone else "latest-coexistence.json"), "mode has a separate latest record")
		data.erase("world_mode")
		data.erase("world")
		var path := "res://.godot/geometry-coexistence-20260930/legacy-entry.json"
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		suite.expect_equal(game.restore_combination(path), alone, "legacy v2 is accepted only in original geometry mode")
		if not alone:
			for core in main.play_world.entity_envelopes():
				for envelope in game.toys.entity_envelopes():
					suite.expect_false(core.intersects(envelope), "fixed coexistence entity envelopes remain disjoint")
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
