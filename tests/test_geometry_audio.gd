extends SceneTree
const Feedback = preload("res://scripts/world/geometry_feedback.gd")
func _init() -> void:
	var suite = load("res://tests/test_support.gd").new()
	var sound = Feedback.new()
	sound.initialize()
	suite.expect_true(sound.players.size() == 3, "geometry voices bounded")
	var hashes: Dictionary = {}
	for kind in Feedback.TONES:
		var stream: AudioStreamWAV = sound.streams[kind]
		suite.expect_true(stream.get_length() <= 0.24, "short contact sound " + kind)
		var peak := 0.0
		for i in range(stream.data.size() / 2): peak = maxf(peak, absf(float(stream.data.decode_s16(i * 2)) / 32767.0))
		suite.expect_true(peak > 0.05 and peak <= 0.5, "audible bounded waveform " + kind)
		hashes[hash(stream.data)] = true
	suite.expect_true(hashes.size() == 6, "six distinct waveforms")
	sound.on_geometry_event("toy_bumper", Vector2.ZERO, 1.0)
	sound.on_geometry_event("toy_bumper", Vector2.ZERO, 1.0)
	suite.expect_true(sound.play_count == 1, "repeated contact throttled")
	sound.on_geometry_event("toy_sling", Vector2.ZERO, 1.0)
	sound.on_geometry_event("toy_spring", Vector2.ZERO, 1.0)
	sound.on_geometry_event("toy_ramp", Vector2.ZERO, 1.0)
	suite.expect_true(sound.play_count == 3, "voice saturation drops excess sound")
	sound.advance_time(1.0)
	sound.on_geometry_event("toy_bumper", Vector2.ZERO, 0.8)
	suite.expect_true(sound.play_count == 4, "later contact can sound")
	sound.set_muted(true)
	sound.on_geometry_event("toy_seesaw", Vector2.ZERO, 1.0)
	suite.expect_true(sound.play_count == 4 and sound.voice_remaining[0] == 0, "mute stops and prevents sound")
	sound.set_muted(false)
	sound.on_geometry_event("portal", Vector2.ZERO, 1.0)
	sound.on_geometry_event("toy_bumper", Vector2.ZERO, NAN)
	suite.expect_true(sound.play_count == 4, "invalid events rejected")
	sound.free()
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)
