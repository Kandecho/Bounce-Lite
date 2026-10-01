extends SceneTree
const Feedback = preload("res://scripts/world/geometry_feedback.gd")
const Toys = preload("res://scripts/world/geometry_toys.gd")
func _init() -> void:
	var output_dir := "res://.godot/"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--audio-output="):
			output_dir = argument.trim_prefix("--audio-output=").trim_suffix("/") + "/"
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) == OK)
	var combined := PackedByteArray()
	for kind in Feedback.TONES:
		var stream: AudioStreamWAV = Feedback.synthesize(kind)
		assert(stream.save_to_wav(output_dir + "geometry-audio-" + kind + ".wav") == OK)
		var peak := 0.0
		var sum := 0.0
		for i in range(stream.data.size() / 2):
			var sample := float(stream.data.decode_s16(i * 2)) / 32767.0
			peak = maxf(peak, absf(sample))
			sum += sample * sample
		print("GEOMETRY AUDIO ", kind, " duration=", stream.get_length(), " peak=", peak, " RMS=", sqrt(sum / (stream.data.size() / 2)))
		# Listening sampler uses actual maximum runtime gain, not raw waveform loudness.
		for i in range(stream.data.size() / 2):
			var at := combined.size()
			combined.resize(at + 2)
			var gain := -20.0 if kind == "toy_spring_compress" else (-17.0 if kind in ["toy_spring", "toy_spring_seat"] else -15.0)
			combined.encode_s16(at, int(float(stream.data.decode_s16(i * 2)) * db_to_linear(gain)))
		var silence := PackedByteArray()
		silence.resize(Feedback.SAMPLE_RATE * 2 / 2)
		combined.append_array(silence)
	var demo := AudioStreamWAV.new()
	demo.format = AudioStreamWAV.FORMAT_16_BITS
	demo.mix_rate = Feedback.SAMPLE_RATE
	demo.data = combined
	assert(demo.save_to_wav(output_dir + "geometry-audio-refined-at-runtime-gain.wav") == OK)
	var toys := Toys.new()
	var hold_seconds: float = toys.spring_hold_seconds
	toys.free()
	var sequence := PackedByteArray()
	sequence.resize(Feedback.SAMPLE_RATE * 2)
	# GeometryToys emits compression after 20% of the shared hold duration.
	var phases := [["toy_spring_seat", 0.0, -17.0], ["toy_spring_compress", hold_seconds * 0.2, -20.0], ["toy_spring_release", hold_seconds, -15.0]]
	for phase in phases:
		var sound: AudioStreamWAV = Feedback.synthesize(phase[0])
		var offset := int(float(phase[1]) * Feedback.SAMPLE_RATE)
		if offset * 2 + sound.data.size() > sequence.size():
			sequence.resize(offset * 2 + sound.data.size())
		for i in range(sound.data.size() / 2):
			var sample := int(float(sound.data.decode_s16(i * 2)) * db_to_linear(float(phase[2])))
			sequence.encode_s16((offset + i) * 2, sequence.decode_s16((offset + i) * 2) + sample)
	demo.data = sequence
	var sequence_path := output_dir + "geometry-spring-sequence-%dms.wav" % roundi(hold_seconds * 1000.0)
	assert(demo.save_to_wav(sequence_path) == OK)
	print("SPRING SAMPLE phase starts 0/", hold_seconds * 0.2, "/", hold_seconds, " seconds, parameter-derived waveform demonstration, not recorded live input; output=", sequence_path)
	quit()
