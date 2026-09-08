extends SceneTree

const TestSupport = preload("res://tests/test_support.gd")

const TEST_PATHS: Array[String] = [
	"res://tests/test_ball_vitality_model.gd",
	"res://tests/test_ball_energy_model.gd",
	"res://tests/test_endless_rules.gd",
	"res://tests/test_paddle_wake.gd",
	"res://tests/test_ball_controller.gd",
	"res://tests/test_ball_visuals.gd",
	"res://tests/test_scene_smoke.gd",
]


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var suite := TestSupport.new()
	for test_path in TEST_PATHS:
		var test_script: Script = load(test_path)
		suite.expect_not_null(test_script, "test script loads: %s" % test_path)
		if test_script != null:
			suite.expect_true(test_script.can_instantiate(),
				"test script parses: %s" % test_path)
		if test_script != null and test_script.can_instantiate():
			var test_case: RefCounted = test_script.new()
			test_case.run(suite)
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
