extends SceneTree

const Support = preload("res://tests/test_support.gd")
const MainScene = preload("res://scenes/main.tscn")
const Surface = preload("res://scripts/physics/surface_response_model.gd")
var suite = Support.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var snapshots: Array = []
	for muted in [false, true]:
		var main = MainScene.instantiate()
		root.add_child(main)
		var ball = main.get_node("GameArea/Ball")
		var paddle = main.get_node("GameArea/Paddle")
		var audio = main.get_node("BasicAudio")
		ball.set_physics_process(false)
		paddle.set_physics_process(false)
		audio.set_physics_process(false)
		audio.set_muted(muted)
		await physics_frame
		await physics_frame
		# Real descending Paddle collision, with both visual and domain signals emitted.
		ball.position = Vector2(480, 480)
		ball.vitality_model.set_vitality(0.2)
		ball.velocity = Vector2(0, 200)
		for frame in range(15):
			await physics_frame
			audio.advance_time(1.0 / 60)
			ball._physics_process(1.0 / 60)
		suite.expect_equal(audio.play_counts[0], 0 if muted else 1, "one real Paddle hit has one audio trigger")
		# Real Ground hit away from the Paddle.
		ball.position = Vector2(250, 540)
		ball.velocity = Vector2(0, 100)
		for frame in range(20):
			await physics_frame
			audio.advance_time(1.0 / 60)
			ball._physics_process(1.0 / 60)
		suite.expect_equal(audio.play_counts[1], 0 if muted else 1, "one real Ground hit has one audio trigger")
		# Accepted weak Wake emits only on commit, never on raw input or a state change.
		ball.vitality_model.set_vitality(0.04)
		ball.vitality_model.resolve_activity(true)
		ball.position = Vector2(480, 564.92)
		ball.advance_resting_time(0.12)
		ball.apply_resting_wake_impulse(Vector2(100, 0), paddle.position)
		suite.expect_equal(audio.play_counts[2], 0, "pending weak input is silent")
		ball.advance_resting_time(0.05)
		suite.expect_equal(audio.play_counts[2], 0, "weak Wake commit has no dedicated cue")
		ball.apply_resting_wake_impulse(Vector2(500, 0), paddle.position)
		suite.expect_equal(audio.play_counts[2], 0, "consumed Wake cannot replay audio")
		# Weak Wake still produces physical contact audio; no global weak-state mute.
		var contact_counts: Array = audio.play_counts.duplicate()
		audio.advance_time(0.2)
		ball.velocity = Vector2(0, 60)
		ball.resolve_surface_collision(Surface.SurfaceKind.PADDLE, Vector2.UP, false)
		suite.expect_equal(audio.play_counts[0], contact_counts[0] + (0 if muted else 1), "weak Wake Paddle contact remains audible without vitality restoration")
		suite.expect_true(ball.is_resting(), "Paddle audio does not activate weak Wake")
		audio.advance_time(0.2)
		ball.velocity = Vector2(-60, 0)
		ball.resolve_surface_collision(Surface.SurfaceKind.WALL, Vector2.RIGHT, false)
		suite.expect_equal(audio.play_counts[3], contact_counts[3] + (0 if muted else 1), "weak Wake Wall contact remains audible")
		audio.advance_time(0.2)
		ball.velocity = Vector2(0, 60)
		ball.resolve_surface_collision(Surface.SurfaceKind.GROUND, Vector2.UP, false)
		suite.expect_equal(audio.play_counts[1], contact_counts[1] + (0 if muted else 1), "weak Wake Ground contact remains audible")
		ball.advance_resting_time(0.12)
		audio.advance_time(0.2)
		ball.apply_resting_wake_impulse(Vector2(500, 0), paddle.position)
		suite.expect_equal(audio.play_counts[2], 0 if muted else 1, "strong Wake sounds once despite state and visual signals")
		var before: Array = audio.play_counts.duplicate()
		audio.advance_time(0.2)
		ball.resolve_surface_collision(Surface.SurfaceKind.PADDLE, Vector2.DOWN, false)
		before[0] += 0 if muted else 1
		suite.expect_equal(audio.play_counts, before, "real underside impact sounds as Paddle, never Wall")
		audio.advance_time(0.2)
		ball.velocity = Vector2(-100, 0)
		ball.resolve_surface_collision(Surface.SurfaceKind.WALL, Vector2.RIGHT, false)
		before[3] += 0 if muted else 1
		suite.expect_equal(audio.play_counts, before, "Wall collision emits one quiet accent")
		ball.velocity = Vector2(0, -100)
		ball.resolve_surface_collision(Surface.SurfaceKind.TOP, Vector2.DOWN, false)
		suite.expect_equal(audio.play_counts, before, "same-tick wall/top burst does not stack")
		ball.velocity = Vector2(100, 5)
		ball.resolve_surface_collision(Surface.SurfaceKind.GROUND, Vector2.UP, false)
		suite.expect_equal(audio.play_counts, before, "tiny ground normal speed does not chatter")
		snapshots.append([ball.position, ball.velocity, ball.vitality_model.current_vitality, ball.vitality_model.state, main.get_node("EndlessRules").combo])
		if not muted:
			suite.expect_true(audio.players[2].playing, "engine playback starts for committed Wake")
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_F4
			audio._unhandled_key_input(key)
			suite.expect_equal(audio.selected[2], 0, "F4 safely retains the single Wake variant")
			suite.expect_true(audio._status.visible, "audition selection is visible")
			key.echo = true
			audio._unhandled_key_input(key)
			suite.expect_equal(audio.selected[2], 0, "key repeat does not cycle variants")
			key.echo = false
			key.keycode = KEY_F6
			audio._unhandled_key_input(key)
			suite.expect_equal(audio.selected[3], 1, "F6 switches Wall candidate")
			audio.set_muted(true)
			for player in audio.players:
				suite.expect_false(player.playing, "mute stops existing voices immediately")
		main.free()
	suite.expect_equal(snapshots[0], snapshots[1], "audio on/off leaves physics vitality state and combo identical")
	suite.print_summary()
	# Let the audio thread retire stopped voices before destroying the engine.
	OS.delay_msec(100)
	await process_frame
	quit(0 if suite.failures == 0 else 1)
