extends Node2D
## Transient presentation of committed events; never modifies world or Ball.

const SAMPLE_RATE := 22050
const MAX_VOICES := 3
const MAX_TRANSIENTS := 18
const COOLDOWNS := {"rotor": 0.16, "charge": 0.45, "breeze": 1.2, "resume": 0.5}
const COLORS := {"rotor": Color(0.37, 0.84, 0.76), "charge": Color(1.0, 0.72, 0.39), "breeze": Color("83aeb9"), "resume": Color("9bdde4")}
var enabled := true
var muted := false
var transients: Array[Dictionary] = []
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var voice_remaining: Array[float] = []
var cooldown_remaining: Dictionary = {}
var play_count := 0

func _ready() -> void:
	initialize()

func initialize() -> void:
	if not streams.is_empty():
		return
	streams["rotor"] = synthesize(310.0, 0.27, 0.0)
	streams["charge"] = synthesize(420.0, 0.48, 150.0)
	streams["resume"] = synthesize(350.0, 0.42, -35.0)
	if not players.is_empty():
		return
	for i in range(MAX_VOICES):
		var player := AudioStreamPlayer.new()
		player.max_polyphony = 1
		player.volume_db = -14.0
		add_child(player)
		players.append(player)
		voice_remaining.append(0.0)

func on_world_event(kind: String, world_position: Vector2, intensity: float) -> void:
	if not enabled or not COOLDOWNS.has(kind) or not world_position.is_finite() or not is_finite(intensity) or intensity <= 0.0:
		return
	initialize()
	if float(cooldown_remaining.get(kind, 0.0)) > 0.0:
		return
	cooldown_remaining[kind] = COOLDOWNS[kind]
	if transients.size() >= MAX_TRANSIENTS:
		transients.pop_front()
	transients.append({"kind": kind, "position": to_local(world_position) if is_inside_tree() else world_position, "intensity": clampf(intensity, 0.0, 1.0), "age": 0.0, "life": 0.65 if kind != "breeze" else 0.9})
	queue_redraw()
	if muted or kind == "breeze":
		return
	for i in range(players.size()):
		if voice_remaining[i] <= 0.0 and not players[i].playing:
			players[i].stream = streams[kind]
			players[i].volume_db = -19.0 + 5.0 * clampf(intensity, 0.0, 1.0)
			voice_remaining[i] = streams[kind].get_length()
			play_count += 1
			if is_inside_tree():
				players[i].play()
			break

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		_stop_voices()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_stop_voices()
		transients.clear()
		cooldown_remaining.clear()
		queue_redraw()

func _stop_voices() -> void:
	for i in range(players.size()):
		players[i].stop()
		players[i].stream = null
		voice_remaining[i] = 0.0

func _exit_tree() -> void:
	_stop_voices()
	streams.clear()
	transients.clear()
	cooldown_remaining.clear()

func _process(delta: float) -> void:
	advance_time(delta)

func advance_time(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	for kind in cooldown_remaining:
		cooldown_remaining[kind] = maxf(0.0, float(cooldown_remaining[kind]) - delta)
	for i in range(voice_remaining.size()):
		voice_remaining[i] = maxf(0.0, voice_remaining[i] - delta)
	for i in range(transients.size() - 1, -1, -1):
		transients[i]["age"] += delta
		if transients[i]["age"] >= transients[i]["life"]:
			transients.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for item in transients:
		var progress: float = item.age / item.life
		var strength: float = item.intensity
		var tint: Color = COLORS[item.kind]
		tint.a = (1.0 - progress) * (1.0 - progress) * 0.48 * strength
		var radius := 9.0 + progress * (22.0 + 18.0 * strength)
		if item.kind == "breeze":
			draw_arc(item.position, radius, -0.55, 0.55, 16, tint, 1.0, true)
		else:
			draw_arc(item.position, radius, 0.0, TAU, 40, tint, 1.2, true)
			for i in range(4):
				var offset := Vector2.from_angle(float(i) * TAU / 4.0 + 0.4) * radius
				draw_circle(item.position + offset, 1.5 * (1.0 - progress), tint)

static func synthesize(frequency: float, duration: float, rise: float) -> AudioStreamWAV:
	# Original analytic synthesis; no sampled or third-party material.
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var time := float(i) / SAMPLE_RATE
		var phase := TAU * (frequency * time + 0.5 * rise * time * time / duration)
		var envelope := minf(time / 0.008, 1.0) * exp(-time * 8.0 / duration) * clampf((duration - time) / 0.025, 0.0, 1.0)
		var sample := (sin(phase) + 0.24 * sin(phase * 2.0) + 0.10 * sin(phase * 3.0)) * envelope * 0.48
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream
