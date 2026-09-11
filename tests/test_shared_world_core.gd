extends RefCounted

const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Ball = preload("res://scripts/ball/ball_controller.gd")
const Rhythm = preload("res://scripts/ball/play_rhythm.gd")
const Surface = preload("res://scripts/physics/surface_response_model.gd")

class Wind extends RefCounted:
	func sample_acceleration(_position: Vector2, _velocity: Vector2) -> Vector2:
		return Vector2(100000, 0)

func run(suite: RefCounted) -> void:
	var rhythm = Rhythm.new()
	rhythm.note_input(20.0)
	suite.expect_true(not rhythm.advance(0.5, true), "resume waits through a visible pause")
	suite.expect_true(rhythm.advance(0.5, true), "recent input permits one resume request")
	suite.expect_true(not rhythm.advance(60.0, true), "no infinite unattended resumes")
	rhythm.note_input(20.0)
	rhythm.advance(16.0, false)
	suite.expect_true(not rhythm.advance(2.0, true), "stale input leaves quiet intact")
	var tuning = Tuning.new()
	tuning.shared_world_enabled = true
	tuning.paddle_vitality_restore = 0.30
	var response = Surface.new(tuning).resolve(Vector2(30, 200), Vector2.UP, Surface.SurfaceKind.PADDLE, 0.2, 0.2, 1.0, true)
	suite.expect_true(response.vitality_after > 0.2 and response.vitality_after < 0.6, "ordinary contact restores only part of vitality")
	var ball = Ball.new()
	ball.configure(tuning)
	ball.configure_world(Wind.new())
	ball.velocity = Vector2(0, -200)
	ball.advance_air_motion(1.0)
	suite.expect_true(ball.velocity.x > 0 and ball.velocity.length() <= tuning.max_speed + 0.001, "physics applies environment and caps speed")
	var before: Vector2 = ball.velocity
	ball.receive_world_vitality(0.2)
	suite.expect_true(ball.velocity == before, "world vitality does not secretly apply motion")
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	suite.expect_true(ball.velocity == before, "Activity notification cannot change physics")
	ball.velocity = Vector2.ZERO
	ball.support_kind = Ball.SupportKind.GROUND
	ball.note_player_input(20.0)
	ball.advance_play_rhythm(0.5)
	suite.expect_true(ball.velocity.is_zero_approx(), "physical rest retains pause")
	ball.advance_play_rhythm(0.5)
	suite.expect_true(ball.velocity.y < 0.0 and not ball.is_resting(), "physics commits requested resume")
	suite.expect_true(ball.support_kind == Ball.SupportKind.NONE, "resume relinquishes support")
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = Ball.SupportKind.GROUND
	ball.advance_play_rhythm(2.0)
	suite.expect_true(ball.velocity.is_zero_approx(), "new settle does not refill continuation credit")
	ball.receive_world_vitality(0.2)
	suite.expect_true(ball.is_resting() and ball.velocity.is_zero_approx(), "world energy alone cannot launch supported rest")
	ball.free()
	_test_pinch_geometry(suite)

func _test_pinch_geometry(suite: RefCounted) -> void:
	var ball = Ball.new()
	var paddle := Node2D.new()
	ball.configure(Tuning.new())
	ball.configure_arena(Rect2(173, 133, 615, 448))
	ball.configure_support(paddle)
	for side in [-1.0, 1.0]:
		for vertical in [-1.0, 1.0]:
			paddle.position = Vector2(270 if side < 0 else 690, 537)
			ball.position = paddle.position + Vector2(side * 79.0, vertical * 15.0)
			ball.velocity = Vector2(0, vertical * 100)
			var before: Vector2 = ball.position
			var vitality: float = ball.vitality_model.current_vitality
			ball._resolve_paddle_wall_pinch()
			suite.expect_true((ball.position.y - before.y) * vertical > 0.0, "pinch clears correct upper/lower side on either wall")
			suite.expect_true(ball.position.x == before.x, "pinch does not move toward wall")
			suite.expect_true(ball.velocity == Vector2(0, vertical * 100), "separating contact gets no added motion")
			suite.expect_true(ball.vitality_model.current_vitality == vitality, "separating contact adds no vitality")
	paddle.position = Vector2(480, 537)
	ball.position = Vector2(559, 522)
	var open_position: Vector2 = ball.position
	ball._resolve_paddle_wall_pinch()
	suite.expect_true(ball.position == open_position, "available sideways exit uses normal engine collision")
	paddle.position = Vector2(690, 537)
	ball.position = Vector2(769, 490)
	var clear_position: Vector2 = ball.position
	ball._resolve_paddle_wall_pinch()
	suite.expect_true(ball.position == clear_position, "nonoverlap has no correction")
	paddle.position.x = 681
	ball.position = Vector2(771, 526)
	ball.velocity = Vector2(-100, 100)
	ball.vitality_model.set_vitality(0.2)
	ball._resolve_paddle_wall_pinch()
	suite.expect_true(ball.vitality_model.current_vitality <= 0.2, "shallow corner normal cannot award a top hit")
	ball.position = Vector2(251.0198, 565.0435)
	ball.velocity = Vector2(82.8825, 2.668215)
	ball.vitality_model.set_vitality(0.2)
	var expected = Surface.new(ball.tuning).resolve(ball.velocity, Vector2.UP, Surface.SurfaceKind.GROUND, 0.2, 0.2, 1.0, false)
	var ground_events: Array[int] = []
	ball.surface_resolved.connect(func(result: RefCounted): ground_events.append(result.surface_kind))
	ball._resolve_shallow_ground_contact()
	suite.expect_true(ball.position.y <= 565.0 and ball.velocity.is_equal_approx(expected.velocity_after), "near tangent floor penetration uses ordinary ground response")
	suite.expect_true(is_equal_approx(ball.vitality_model.current_vitality, expected.vitality_after), "shallow floor contact applies ordinary loss exactly once")
	ball._resolve_shallow_ground_contact()
	suite.expect_equal(ground_events.size(), 1, "outgoing contact cannot duplicate events or audio")
	ball.position.y = 560
	ball.velocity.y = 10
	ball._resolve_shallow_ground_contact()
	suite.expect_true(ball.position.y == 560 and ground_events.size() == 1, "no ground crossing leaves motion and events alone")
	ball.position.y = 570
	var deep_position: Vector2 = ball.position
	ball.velocity.y = 10
	ball._resolve_shallow_ground_contact()
	suite.expect_true(ball.position == deep_position, "large penetration remains exceptional recovery")
	ball.free()
	paddle.free()
