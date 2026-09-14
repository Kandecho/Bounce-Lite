extends SceneTree
const Feedback = preload("res://scripts/world/geometry_feedback.gd")
func _init() -> void:
	var combined := PackedByteArray()
	for kind in Feedback.TONES:
		var stream: AudioStreamWAV = Feedback.synthesize(kind)
		stream.save_to_wav("res://.godot/geometry-audio-" + kind + ".wav")
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
			combined.encode_s16(at, int(float(stream.data.decode_s16(i * 2)) * db_to_linear(-15.0)))
		var silence := PackedByteArray()
		silence.resize(Feedback.SAMPLE_RATE * 2 / 2)
		combined.append_array(silence)
	var demo := AudioStreamWAV.new()
	demo.format = AudioStreamWAV.FORMAT_16_BITS
	demo.mix_rate = Feedback.SAMPLE_RATE
	demo.data = combined
	demo.save_to_wav("res://.godot/geometry-audio-six-at-runtime-gain.wav")
	quit()
