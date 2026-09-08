extends RefCounted

const VITALITY_PATH := "res://scripts/ball/ball_vitality_model.gd"
const RESPONSE_PATH := "res://scripts/physics/surface_response_model.gd"
const RULES_PATH := "res://scripts/rules/endless_rules.gd"


func run(suite: RefCounted) -> void:
	var vitality_script: Script = load(VITALITY_PATH)
	var response_script: Script = load(RESPONSE_PATH)
	var rules_script: Script = load(RULES_PATH)
	suite.expect_not_null(vitality_script, "BallVitalityModel is available to rules tests")
	suite.expect_not_null(response_script, "SurfaceResponseModel is available to rules tests")
	suite.expect_not_null(rules_script, "EndlessRules exists")
	if vitality_script == null or response_script == null or rules_script == null:
		return
	suite.expect_true(rules_script.can_instantiate(), "EndlessRules parses")
	if not rules_script.can_instantiate():
		return

	var rules: Node = rules_script.new()
	rules.handle_paddle_hit()
	suite.expect_equal(rules.combo, 1, "paddle hit increments combo")
	rules.handle_paddle_hit()
	suite.expect_equal(rules.combo, 2, "successive paddle hits accumulate combo")

	rules.handle_surface_hit(response_script.SurfaceKind.WALL)
	suite.expect_equal(rules.combo, 2, "wall hit leaves combo unchanged")
	rules.handle_surface_hit(response_script.SurfaceKind.TOP)
	suite.expect_equal(rules.combo, 2, "top hit leaves combo unchanged")
	rules.handle_surface_hit(response_script.SurfaceKind.GROUND)
	suite.expect_equal(rules.combo, 0, "ground hit clears combo without ending the run")

	rules.advance_active_time(0.5)
	suite.expect_float(rules.active_time_seconds, 0.5, 0.0001,
		"active timer advances while the Ball is active")
	rules.handle_activity_state_changed(vitality_script.ActivityState.RESTING)
	suite.expect_false(rules.timer_running, "rest pauses active timer")
	rules.advance_active_time(1.0)
	suite.expect_float(rules.active_time_seconds, 0.5, 0.0001,
		"resting time is not counted as active time")
	rules.begin_wake_cycle()
	suite.expect_true(rules.timer_running, "wake resumes active timer")
	suite.expect_float(rules.active_time_seconds, 0.0, 0.0001,
		"wake begins a new active-time cycle")
	rules.free()
