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
			var gain := -20.0 if kind == "toy_spring_compress" else (-17.0 if kind in ["toy_spring", "toy_spring_seat"] else -15.0)
			combined.encode_s16(at, int(float(stream.data.decode_s16(i * 2)) * db_to_linear(gain)))
		var silence := PackedByteArray()
		silence.resize(Feedback.SAMPLE_RATE * 2 / 2)
		combined.append_array(silence)
	var demo := AudioStreamWAV.new()
	demo.format = AudioStreamWAV.FORMAT_16_BITS
	demo.mix_rate = Feedback.SAMPLE_RATE
	demo.data = combined
	demo.save_to_wav("res://.godot/geometry-audio-refined-at-runtime-gain.wav")
	var sequence := PackedByteArray()
	sequence.resize(Feedback.SAMPLE_RATE * 2)
	var phases := [["toy_spring_seat", 0.0, -17.0], ["toy_spring_compress", 0.064, -20.0], ["toy_spring_release", 0.32, -15.0]]
	for phase in phases:
		var sound: AudioStreamWAV = Feedback.synthesize(phase[0])
		var offset := int(float(phase[1]) * Feedback.SAMPLE_RATE)
		for i in range(sound.data.size() / 2):
			var sample := int(float(sound.data.decode_s16(i * 2)) * db_to_linear(float(phase[2])))
			sequence.encode_s16((offset + i) * 2, sequence.decode_s16((offset + i) * 2) + sample)
	demo.data = sequence
	demo.save_to_wav("res://.godot/geometry-spring-sequence-320ms.wav")
	print("SPRING SAMPLE phase starts 0/0.064/0.32 seconds, waveform demonstration of committed phase timing, not recorded live input")
	quit()
