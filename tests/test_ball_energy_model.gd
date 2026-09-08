extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const ENERGY_PATH := "res://scripts/ball/ball_energy_model.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var energy_script: Script = load(ENERGY_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning exists")
	suite.expect_not_null(energy_script, "BallEnergyModel exists")
	if tuning_script == null or energy_script == null:
		return
	suite.expect_true(tuning_script.can_instantiate(), "PrototypeTuning parses")
	suite.expect_true(energy_script.can_instantiate(), "BallEnergyModel parses")
	if not tuning_script.can_instantiate() or not energy_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var model: RefCounted = energy_script.new(tuning)

	suite.expect_float(model.speed_for_current_energy(), 360.0, 0.001,
		"max energy maps to the normal active speed")

	model.reset_active()
	model.apply_environment_collision(energy_script.SurfaceKind.WALL)
	suite.expect_float(model.current_energy, 0.985, 0.0001,
		"wall collision applies light energy loss")

	model.reset_active()
	model.apply_environment_collision(energy_script.SurfaceKind.TOP)
	suite.expect_float(model.current_energy, 0.985, 0.0001,
		"top collision applies light energy loss")

	model.reset_active()
	model.apply_environment_collision(energy_script.SurfaceKind.GROUND)
	suite.expect_float(model.current_energy, 0.75, 0.0001,
		"ground collision keeps seventy-five percent energy")
	suite.expect_true(model.current_energy < 0.985,
		"ground collision loses more energy than a wall collision")

	model.set_energy(0.2)
	model.restore_from_paddle()
	suite.expect_float(model.current_energy, 1.0, 0.0001,
		"paddle restores energy to max")
	model.restore_from_paddle()
	suite.expect_float(model.current_energy, 1.0, 0.0001,
		"repeated paddle hits cannot exceed max energy")

	model.set_energy(0.25)
	suite.expect_float(model.speed_for_current_energy(), 180.0, 0.001,
		"quarter energy maps to half active speed")

	model.set_energy(0.8)
	suite.expect_equal(model.state, energy_script.ActivityState.ACTIVE,
		"high energy derives ACTIVE")
	model.set_energy(0.5)
	suite.expect_equal(model.state, energy_script.ActivityState.DECAYING,
		"mid energy derives DECAYING")
	model.set_energy(0.009)
	suite.expect_equal(model.state, energy_script.ActivityState.RESTING,
		"energy below the rest threshold derives RESTING")

	model.wake()
	suite.expect_float(model.speed_for_current_energy(), 330.0, 0.001,
		"wake restores the configured wake speed")
	suite.expect_equal(model.state, energy_script.ActivityState.ACTIVE,
		"wake energy derives ACTIVE")

	model.set_energy(2.0)
	suite.expect_float(model.current_energy, 1.0, 0.0001,
		"energy clamps to max")
	model.set_energy(-1.0)
	suite.expect_float(model.current_energy, 0.0, 0.0001,
		"energy clamps to zero")
