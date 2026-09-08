extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const VITALITY_PATH := "res://scripts/ball/ball_vitality_model.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var vitality_script: Script = load(VITALITY_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning exists for Vitality tests")
	suite.expect_not_null(vitality_script, "BallVitalityModel exists")
	if tuning_script == null or vitality_script == null:
		return
	suite.expect_true(tuning_script.can_instantiate(), "PrototypeTuning parses for Vitality tests")
	suite.expect_true(vitality_script.can_instantiate(), "BallVitalityModel parses")
	if not tuning_script.can_instantiate() or not vitality_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var model: RefCounted = vitality_script.new(tuning)
	suite.expect_float(model.current_vitality, 1.0, 0.0001,
		"Vitality starts at max")
	suite.expect_equal(model.state, vitality_script.ActivityState.ACTIVE,
		"maximum Vitality starts ACTIVE")
	suite.expect_false(model.has_method("speed_for_current_energy"),
		"Vitality has no Energy-to-Speed mapping")
	suite.expect_false(model.has_method("energy_for_speed"),
		"Vitality has no Speed-to-Energy mapping")

	model.set_vitality(0.5)
	model.apply_delta(-0.2)
	suite.expect_float(model.current_vitality, 0.3, 0.0001,
		"Vitality applies a negative delta")
	model.apply_delta(0.1)
	suite.expect_float(model.current_vitality, 0.4, 0.0001,
		"Vitality applies a positive delta")

	model.set_vitality(2.0)
	suite.expect_float(model.current_vitality, 1.0, 0.0001,
		"Vitality clamps to max")
	model.set_vitality(-1.0)
	suite.expect_float(model.current_vitality, 0.0, 0.0001,
		"Vitality clamps to zero")

	model.set_vitality(0.70)
	model.resolve_activity(false)
	suite.expect_equal(model.state, vitality_script.ActivityState.ACTIVE,
		"active threshold remains ACTIVE")
	model.set_vitality(0.69)
	model.resolve_activity(false)
	suite.expect_equal(model.state, vitality_script.ActivityState.DECAYING,
		"Vitality below active threshold becomes DECAYING")

	model.set_vitality(0.05)
	model.resolve_activity(false)
	suite.expect_equal(model.state, vitality_script.ActivityState.DECAYING,
		"low Vitality stays DECAYING when physics cannot settle")
	suite.expect_false(model.wake(0.85),
		"Wake is rejected while the Ball is not RESTING")
	model.resolve_activity(true)
	suite.expect_equal(model.state, vitality_script.ActivityState.RESTING,
		"low Vitality rests only when physics allows settling")
	suite.expect_true(model.wake(0.85),
		"RESTING Ball accepts Wake")
	suite.expect_float(model.current_vitality, 0.85, 0.0001,
		"Wake restores the requested Vitality independently")
	suite.expect_equal(model.state, vitality_script.ActivityState.ACTIVE,
		"Wake returns the Ball to ACTIVE")
	suite.expect_false(model.wake(0.5),
		"an ACTIVE Ball cannot be woken repeatedly")

	model.set_vitality(0.25)
	suite.expect_float(model.vitality_ratio(), 0.25, 0.0001,
		"Vitality ratio is independent of motion")
	model.reset_active()
	suite.expect_float(model.current_vitality, 1.0, 0.0001,
		"reset_active restores max Vitality")
