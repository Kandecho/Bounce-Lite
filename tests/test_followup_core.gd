extends RefCounted

const Ball = preload("res://scripts/ball/ball_controller.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const Paddle = preload("res://scripts/paddle/paddle_controller.gd")

func run(suite: RefCounted) -> void:
	var tuning = Tuning.new()
	tuning.shared_world_enabled = true
	var ball = Ball.new()
	ball.configure(tuning)
	ball.position = Vector2(300, 400)
	ball.note_player_input(20)
	suite.expect_false(ball.play_rhythm.continuation_available, "raw input cannot grant continuation")
	if not ball.has_method("note_paddle_action"):
		suite.expect_true(false, "related physical paddle action API exists")
		ball.free()
		return
	ball.note_paddle_action(20, Vector2(800, 570), Vector2(-100, 0))
	suite.expect_false(ball.play_rhythm.continuation_available, "far movement is unrelated")
	ball.note_paddle_action(20, Vector2(250, 570), Vector2(-100, 0))
	suite.expect_false(ball.play_rhythm.continuation_available, "movement away is unrelated")
	ball.note_paddle_action(0, Vector2(250, 570), Vector2(100, 0))
	suite.expect_false(ball.play_rhythm.continuation_available, "no actual movement grants nothing")
	ball.note_paddle_action(5, Vector2(250, 570), Vector2(100, 0))
	suite.expect_true(ball.play_rhythm.continuation_available, "near directed physical movement grants once")
	ball.play_rhythm.advance(13, false)
	suite.expect_false(ball.play_rhythm.continuation_available, "qualification explicitly expires")
	ball.note_paddle_action(5, Vector2(250, 570), Vector2(100, 0))
	ball.configure_arena(Rect2(0, 0, 960, 720))
	ball.position.y = ball.safe_center_bounds().end.y
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = Ball.SupportKind.GROUND
	ball.rest_elapsed_time = 1
	var notifications: Array = []
	ball.vitality_model.activity_state_changed.connect(func(_old, current): notifications.append([current, ball.velocity, ball.support_kind]))
	suite.expect_true(ball.apply_resting_interaction(20, Vector2(300, 570)), "wake succeeds")
	suite.expect_equal(notifications[0][0], 0, "wake immediately enters ACTIVE")
	suite.expect_true(notifications[0][1].y == -350 and notifications[0][2] == Ball.SupportKind.NONE, "physics precedes activity notification")
	suite.expect_false(ball.play_rhythm.continuation_available, "wake consumes old opportunity")
	ball.velocity = Vector2(0, 200)
	ball.resolve_surface_collision(3, Vector2.UP, true)
	suite.expect_true(ball.play_rhythm.continuation_available, "valid physical contact grants opportunity")
	ball.velocity = Vector2.ZERO
	ball.vitality_model.set_vitality(0.04)
	ball.vitality_model.resolve_activity(true)
	ball.support_kind = Ball.SupportKind.GROUND
	notifications.clear()
	ball.advance_play_rhythm(1)
	suite.expect_equal(notifications[0][0], 0, "Continue immediately enters ACTIVE")
	suite.expect_true(notifications[0][1].y == -290 and notifications[0][2] == Ball.SupportKind.NONE, "Continue motion precedes Activity")
	suite.expect_float(ball.vitality_model.current_vitality, 0.22, 0.00001, "Continue restores less Vitality than Wake")
	suite.expect_false(ball.play_rhythm.continuation_available, "Continue consumes its one opportunity")
	tuning.legacy_rhythm_enabled = true
	ball.start_active(Vector2.DOWN)
	ball.resolve_surface_collision(3, Vector2.UP, true)
	suite.expect_false(ball.play_rhythm.continuation_available, "legacy contact alone cannot grant opportunity")
	ball.free()
	tuning.legacy_rhythm_enabled = false
	var paddle = Paddle.new()
	paddle.position.x = 480
	paddle.configure(tuning, 0, 960, 570)
	var samples: Array = []
	paddle.interaction_sampled.connect(func(distance, _point): samples.append(distance))
	paddle.set_target_x(800)
	paddle.set_target_x(480)
	paddle.advance_motion(1.0 / 60)
	suite.expect_float(samples[0], 0, 0.00001, "cancelled target change is not motion")
	paddle.free()
