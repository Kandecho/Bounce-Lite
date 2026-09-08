extends RefCounted

const TUNING_PATH := "res://scripts/config/prototype_tuning.gd"
const ENERGY_PATH := "res://scripts/ball/ball_energy_model.gd"
const CONTROLLER_PATH := "res://scripts/ball/ball_controller.gd"


func run(suite: RefCounted) -> void:
	var tuning_script: Script = load(TUNING_PATH)
	var energy_script: Script = load(ENERGY_PATH)
	var controller_script: Script = load(CONTROLLER_PATH)
	suite.expect_not_null(tuning_script, "PrototypeTuning is available to Ball tests")
	suite.expect_not_null(energy_script, "BallEnergyModel is available to Ball tests")
	suite.expect_not_null(controller_script, "BallController exists")
	if tuning_script == null or energy_script == null or controller_script == null:
		return
	suite.expect_true(controller_script.can_instantiate(), "BallController parses")
	if not controller_script.can_instantiate():
		return

	var tuning: Resource = tuning_script.new()
	var ball: CharacterBody2D = controller_script.new()
	ball.configure(tuning)
	ball.start_active(Vector2(1.0, -1.0))
	suite.expect_float(ball.velocity.length(), 360.0, 0.01,
		"active Ball starts at mapped speed")
	suite.expect_float(ball.direction.length(), 1.0, 0.0001,
		"Ball stores a normalized direction")

	ball.start_active(Vector2.DOWN)
	ball.resolve_surface_collision(energy_script.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_true(ball.velocity.y < 0.0, "ground collision reflects upward")
	suite.expect_float(ball.energy_model.current_energy, 0.75, 0.0001,
		"ground collision dissipates energy")
	suite.expect_float(ball.velocity.length(), 311.7691, 0.01,
		"ground loss lowers speed through the energy mapping")

	ball.start_active(Vector2.RIGHT)
	ball.resolve_surface_collision(energy_script.SurfaceKind.WALL, Vector2.LEFT, false)
	suite.expect_true(ball.velocity.x < 0.0, "wall collision reflects horizontally")
	suite.expect_float(ball.energy_model.current_energy, 0.985, 0.0001,
		"wall collision applies light loss")

	ball.energy_model.set_energy(0.2)
	ball.set_direction(Vector2.DOWN)
	ball.resolve_surface_collision(energy_script.SurfaceKind.PADDLE, Vector2.UP, true)
	suite.expect_float(ball.energy_model.current_energy, 1.0, 0.0001,
		"valid Paddle hit restores max energy")
	suite.expect_float(ball.velocity.length(), 360.0, 0.01,
		"Paddle recovery returns to normal active speed")
	suite.expect_true(ball.velocity.y < 0.0, "valid Paddle hit sends the Ball upward")

	ball.start_active(Vector2.DOWN)
	ball.resolve_surface_collision(energy_script.SurfaceKind.PADDLE, Vector2.UP, false)
	suite.expect_float(ball.energy_model.current_energy, 0.985, 0.0001,
		"invalid Paddle side or underside contact does not restore energy")

	ball.start_active(Vector2.DOWN)
	for index in range(17):
		ball.resolve_surface_collision(energy_script.SurfaceKind.GROUND, Vector2.UP, false)
	suite.expect_true(ball.is_resting(), "repeated environmental loss eventually rests the Ball")
	suite.expect_float(ball.velocity.length(), 0.0, 0.0001,
		"resting Ball stops moving")
	suite.expect_true(ball.wake_from_paddle(-500.0), "resting Ball accepts a valid Wake")
	suite.expect_float(ball.velocity.length(), 330.0, 0.01,
		"Wake restores the configured launch speed")
	suite.expect_true(ball.velocity.x < 0.0 and ball.velocity.y < 0.0,
		"Wake launches upward and follows Paddle direction")
	suite.expect_false(ball.wake_from_paddle(500.0),
		"an already active Ball cannot be woken repeatedly")
	ball.free()
