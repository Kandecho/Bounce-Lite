extends RefCounted

func run(suite: RefCounted) -> void:
	var script = load("res://scripts/audio/basic_audio_feedback.gd")
	suite.expect_not_null(script, "basic audio exists")
	if script == null or not script.can_instantiate():
		return
	var audio = script.new()
	audio.initialize()
	var wake_before: int = audio.play_counts[2]
	audio.on_wake_committed(70.0, false, Vector2.ZERO)
	suite.expect_equal(audio.play_counts[2], wake_before, "Weak Wake has no dedicated cue")
	suite.expect_equal(audio.candidates.size(), 4, "synthetic audition includes Wall")
	suite.expect_equal(audio.candidates[2].size(), 1, "only one same-family Strong Wake variant")
	suite.expect_true(audio.candidates[2][0] == audio.candidates[0][0], "Wake shares the Paddle baseline source")
	for event in range(audio.candidates.size()):
		suite.expect_true(audio.candidates[event].size() <= 2, "audition keeps at most two candidates")
		for stream in audio.candidates[event]:
			suite.expect_true(stream.get_length() > 0 and stream.get_length() < 0.7, "candidate is a short decodable sound")
			if stream is AudioStreamOggVorbis:
				suite.expect_false(stream.loop, "candidate never loops")
			else:
				suite.expect_equal(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "short Ground never loops")
		for index in range(audio.candidates[event].size()):
			suite.expect_true(audio.START_SECONDS[event][index] >= 0 and audio.START_SECONDS[event][index] < audio.candidates[event][index].get_length(), "fixed start lies within stream bounds")
	suite.expect_true(audio.request_sound(0), "first Paddle event accepted")
	suite.expect_false(audio.request_sound(0), "duplicate Paddle event suppressed")
	suite.expect_false(audio.request_sound(1), "same-tick cross-event burst suppressed")
	audio.advance_time(0.05)
	suite.expect_true(audio.request_sound(2), "separate Wake accepted")
	audio.advance_time(0.20)
	suite.expect_true(audio.request_sound(1), "Ground event accepted")
	var before: int = audio.play_counts[1]
	for i in range(20):
		audio.request_sound(1)
	suite.expect_equal(audio.play_counts[1], before, "contact burst cannot stack Ground sounds")
	audio.set_muted(true)
	audio.advance_time(1)
	suite.expect_false(audio.request_sound(0), "mute suppresses events")
	audio.set_muted(false)
	suite.expect_true(audio.request_sound(0), "unmute resumes future events")
	audio.select_candidate(0, 1)
	suite.expect_equal(audio.selected[0], 1, "alternative is selectable without random choice")
	audio.advance_time(0.2)
	suite.expect_true(audio.request_sound(3), "Wall accent accepted")
	suite.expect_true(audio.request_sound(1), "Wall cannot suppress immediate Ground")
	suite.expect_false(audio.request_sound(3), "Wall burst cannot replay over primary event")
	# Different source levels need different gains; raw dB ordering is not loudness.
	suite.expect_true(audio.VOLUME_DB[3] < audio.VOLUME_DB[0], "Wall has lowest gain")
	for index in range(audio.players.size()):
		var player = audio.players[index]
		suite.expect_equal(player.max_polyphony, 1, "one voice per event")
		suite.expect_float(player.pitch_scale, [1.0, 1.5, 0.92, 1.0][index], 0.001, "Ground lift and Wake lowering use fixed pitch only")
	for stream in audio.candidates[1]:
		suite.expect_true(stream.get_length() >= 0.15 and stream.get_length() <= 0.181, "Ground releases within the short puh window")
	suite.expect_true(audio.VOLUME_DB[2] > audio.VOLUME_DB[0], "same-source Wake is stronger than Paddle")
	audio.free()
