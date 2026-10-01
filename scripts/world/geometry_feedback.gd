extends Node
## Original procedural contact timbres; no sampled assets or gameplay mutation.
const SAMPLE_RATE := 22050
const MAX_VOICES := 3
# frequency, length, pitch sweep, overtone ratio, overtone weight, noise weight
const TONES := {
	"toy_brick_crack": [420.0, 0.08, -120.0, 2.7, 0.21, 0.30],
	"toy_brick_break": [270.0, 0.16, -110.0, 3.4, 0.28, 0.48],
	"toy_reverse_assemble": [360.0, 0.19, 430.0, 2.1, 0.24, 0.04],
	"toy_reverse_break": [230.0, 0.23, -150.0, 3.8, 0.34, 0.65],
	"toy_portal": [620.0, 0.16, -360.0, 2.0, 0.20, 0.025],
	"toy_bumper": [210.0, 0.23, -95.0, 2.0, 0.20, 0.01],
	"toy_sling": [510.0, 0.105, -160.0, 2.7, 0.16, 0.16],
	"toy_ramp": [760.0, 0.075, -30.0, 3.1, 0.22, 0.10],
	"toy_platform": [430.0, 0.09, -25.0, 2.4, 0.28, 0.14],
	"toy_spring": [180.0, 0.065, -45.0, 2.8, 0.22, 0.12],
	"toy_spring_seat": [180.0, 0.065, -45.0, 2.8, 0.22, 0.12],
	"toy_spring_compress": [240.0, 0.20, -100.0, 2.02, 0.18, 0.02],
	"toy_spring_release": [310.0, 0.22, 220.0, 2.02, 0.30, 0.025],
	"toy_seesaw": [285.0, 0.13, -40.0, 3.7, 0.32, 0.19],
}
const COOLDOWNS := {"toy_brick_crack":0.12,"toy_brick_break":0.12,"toy_reverse_assemble":0.12,"toy_reverse_break":0.12,"toy_portal": 0.12, "toy_bumper": 0.12, "toy_sling": 0.12, "toy_ramp": 0.09, "toy_platform": 0.10, "toy_spring": 0.18, "toy_spring_seat": 0.18, "toy_spring_compress": 0.20, "toy_spring_release": 0.18, "toy_seesaw": 0.14}
var muted := false
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var voice_remaining: Array[float] = []
var cooldown_remaining: Dictionary = {}
var play_count := 0

func _ready() -> void:
	initialize()

func initialize() -> void:
	if not streams.is_empty(): return
	for kind in TONES: streams[kind] = synthesize(kind)
	for i in range(MAX_VOICES):
		var player := AudioStreamPlayer.new()
		player.max_polyphony = 1
		add_child(player)
		players.append(player)
		voice_remaining.append(0.0)

func on_geometry_event(kind: String, position: Vector2, intensity: float) -> void:
	if muted or not TONES.has(kind) or not position.is_finite() or not is_finite(intensity) or intensity <= 0.0: return
	initialize()
	if float(cooldown_remaining.get(kind, 0.0)) > 0.0: return
	cooldown_remaining[kind] = COOLDOWNS[kind]
	for i in range(players.size()):
		if voice_remaining[i] > 0.0 or players[i].playing: continue
		players[i].stream = streams[kind]
		# <= 0.5 sample peak and three voices at -15 dB sum below 0.267.
		players[i].volume_db = -23.0 + 8.0 * clampf(intensity, 0.0, 1.0)
		if kind == "toy_spring_compress": players[i].volume_db -= 5.0
		elif kind in ["toy_spring", "toy_spring_seat"]: players[i].volume_db -= 2.0
		voice_remaining[i] = streams[kind].get_length()
		play_count += 1
		if is_inside_tree(): players[i].play()
		break

func set_muted(value: bool) -> void:
	muted = value
	if muted: _stop()

func _stop() -> void:
	for i in range(players.size()):
		players[i].stop()
		players[i].stream = null
		voice_remaining[i] = 0.0

func _exit_tree() -> void:
	_stop()
	streams.clear()
	cooldown_remaining.clear()

func _process(delta: float) -> void:
	advance_time(delta)

func advance_time(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0: return
	for key in cooldown_remaining: cooldown_remaining[key] = maxf(0.0, float(cooldown_remaining[key]) - delta)
	for i in range(voice_remaining.size()): voice_remaining[i] = maxf(0.0, voice_remaining[i] - delta)

static func synthesize(kind: String) -> AudioStreamWAV:
	var tone: Array = TONES[kind]
	var duration: float = tone[1]
	var data := PackedByteArray()
	data.resize(int(SAMPLE_RATE * duration) * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 914
	for i in range(data.size() / 2):
		var time := float(i) / SAMPLE_RATE
		var phase := TAU * (float(tone[0]) * time + float(tone[2]) * time * time / (2.0 * duration))
		var envelope := minf(time / 0.0025, 1.0) * exp(-time * 5.5 / duration) * minf((duration - time) / 0.012, 1.0)
		if kind == "toy_spring_compress":
			envelope = minf(time / 0.018, 1.0) * exp(-time * 1.8 / duration) * minf((duration - time) / 0.04, 1.0)
		var noise := rng.randf_range(-1.0, 1.0) * exp(-time * 85.0)
		var value := (sin(phase) + float(tone[4]) * sin(phase * float(tone[3])) + float(tone[5]) * noise) * envelope * 0.34
		data.encode_s16(i * 2, int(clampf(value, -0.5, 0.5) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
