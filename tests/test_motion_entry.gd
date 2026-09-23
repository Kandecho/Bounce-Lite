extends SceneTree
const Support = preload("res://tests/test_support.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var suite = Support.new()
	var profile := "fast"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--motion-profile="): profile = argument.trim_prefix("--motion-profile=")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	var expected_scale := 1.5 if profile == "fast" else 1.0
	suite.expect_equal(main.tuning.motion_profile, profile, "CLI selects profile")
	suite.expect_float(main.tuning.max_speed, 520.0 * expected_scale, 0.01, "Ball cap follows CLI")
	suite.expect_float(main.geometry_playground.toys.tuning.spring_release_speed, 500.0 * expected_scale, 0.01, "geometry shares profile tuning")
	suite.expect_equal(main.geometry_playground.world_seed, 184, "same seed enters both profiles")
	suite.expect_true(main.geometry_playground.save_combination(), "snapshot saves motion profile")
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.geometry_playground.latest_path))
	suite.expect_equal(snapshot.motion_profile, profile, "snapshot records motion profile")
	suite.expect_equal(snapshot.get("rules", ""), "spring-200ms-lateral50-motion150", "snapshot identifies the new motion and spring rules")
	var old_rules: Dictionary = snapshot.duplicate(true)
	old_rules.erase("rules")
	var old_path := "res://.godot/motion-ab/old-rules-%s.json" % profile
	var old_file := FileAccess.open(old_path, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old_rules))
	old_file.close()
	var original_seed: int = main.geometry_playground.world_seed
	suite.expect_false(main.geometry_playground.restore_combination(old_path), "old same-profile v2 rules cannot silently load")
	suite.expect_equal(main.geometry_playground.world_seed, original_seed, "rejected snapshot leaves active world untouched")
	var other: Dictionary = snapshot.duplicate(true)
	other.motion_profile = "current" if profile == "fast" else "fast"
	var path := "res://.godot/motion-ab/mismatched-%s.json" % profile
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(other))
	file.close()
	suite.expect_false(main.geometry_playground.restore_combination(path), "opposite profile cannot load")
	other.erase("motion_profile")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(other))
	file.close()
	suite.expect_false(main.geometry_playground.restore_combination(path), "legacy v2 without motion profile is explicit reject")
	suite.expect_true(main.geometry_playground.restore_combination(), "matching profile loads")
	var base_cap: float = main.tuning.max_speed
	main.tuning.max_speed = base_cap + 123.0
	main.geometry_playground.restart_world(184)
	suite.expect_equal(main.tuning.motion_profile, profile, "R preserves selected motion profile")
	suite.expect_float(main.tuning.max_speed, base_cap + 123.0, 0.001, "R preserves session cap adjustment")
	main.geometry_playground.restart_world(20260914)
	suite.expect_equal(main.tuning.motion_profile, profile, "N preserves selected motion profile")
	suite.expect_float(main.tuning.max_speed, base_cap + 123.0, 0.001, "N does not reapply or compound profile")
	main.queue_free()
	await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
