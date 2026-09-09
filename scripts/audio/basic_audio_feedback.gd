extends Node

# V0.1.4 audition only: four replaceable streams, no audio manager or processing chain.
enum Event { PADDLE, GROUND, WAKE, WALL }
const Surface = preload("res://scripts/physics/surface_response_model.gd")
# Kenney Digital Audio, CC0: https://kenney.nl/assets/digital-audio
const ROOT := "res://assets/audio/kenney-digital/"
const FILES := [
	["pepSound3.ogg", "pepSound5.ogg"],
	["res://assets/audio/kenney-scifi/forceField_000-pu-160ms.wav", "res://assets/audio/kenney-scifi/forceField_001-pu-180ms.wav"],
	["pepSound3.ogg"],
	["pepSound3.ogg", "pepSound1.ogg"],
]
# Ground: Kenney Sci-fi Sounds (CC0), https://kenney.nl/assets/sci-fi-sounds
# forceField_000[0.120:0.280] / forceField_001[0.120:0.300], single decay body.
# 3 ms fade-in, 40/45 ms fade-out; original OGGs and License.txt retained alongside.
const START_SECONDS := [[0.072, 0.094], [0.0, 0.0], [0.072], [0.072, 0.108]]
const VOLUME_DB := [-23.0, -25.0, -19.0, -28.0]
# Fixed Ground lift toward the bounce register; slightly lower Wake. No pitch curves.
const PITCH_SCALE := [1.0, 1.5, 0.92, 1.0]
const COOLDOWN := [0.08, 0.16, 0.12, 0.12]
const BURST_GAP := 0.04

var candidates: Array = []
var players: Array[AudioStreamPlayer] = []
var selected := [0, 0, 0, 0]
var play_counts := [0, 0, 0, 0]
var muted := false
var _elapsed := 0.0
var _last_event := [-100.0, -100.0, -100.0, -100.0]
var _last_any := -100.0
var _last_kind := -1
var _status: Label
var _status_seconds := 0.0


func _ready() -> void:
	initialize()
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(190, 610)
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 4)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.hide()
	layer.add_child(_status)


func initialize() -> void:
	if not players.is_empty():
		return
	for event in range(FILES.size()):
		var streams: Array[AudioStream] = []
		for filename in FILES[event]:
			streams.append(load(filename if filename.begins_with("res://") else ROOT + filename))
		candidates.append(streams)
		var player := AudioStreamPlayer.new()
		player.max_polyphony = 1
		player.volume_db = VOLUME_DB[event]
		player.pitch_scale = PITCH_SCALE[event]
		add_child(player)
		players.append(player)


func _physics_process(delta: float) -> void:
	advance_time(delta)


func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null


func advance_time(delta: float) -> void:
	_elapsed += maxf(delta, 0.0)
	_status_seconds -= maxf(delta, 0.0)
	if _status != null and _status_seconds <= 0.0:
		_status.hide()


func on_surface_resolved(result: RefCounted) -> void:
	var approach_speed: float = -result.velocity_before.dot(result.normal)
	if result.surface_kind == Surface.SurfaceKind.PADDLE and (result.valid_paddle_hit or approach_speed >= 45.0):
		# Physical Paddle contact can sound without being a valid vitality-restoring hit.
		request_sound(Event.PADDLE)
	elif result.effective_surface_kind == Surface.SurfaceKind.GROUND:
		# Ignore tiny normal motion at settle/rolling; tangential speed is irrelevant.
		if -result.velocity_before.dot(result.normal) >= 45.0:
			request_sound(Event.GROUND)
	elif result.surface_kind in [Surface.SurfaceKind.WALL, Surface.SurfaceKind.TOP]:
		# Use original kind: invalid Paddle responses must not masquerade as walls.
		if -result.velocity_before.dot(result.normal) >= 45.0:
			request_sound(Event.WALL)


func on_wake_committed(_strength: float, activated: bool, _position: Vector2) -> void:
	if activated:
		request_sound(Event.WAKE)


func request_sound(event: int, gain_db: float = 0.0) -> bool:
	if muted or event < 0 or event >= FILES.size():
		return false
	if _elapsed - _last_event[event] + 0.000001 < COOLDOWN[event]:
		return false
	if _elapsed - _last_any + 0.000001 < BURST_GAP:
		if _last_kind != Event.WALL or event == Event.WALL:
			return false
		# Quiet boundary accents cannot suppress a primary interaction.
		players[Event.WALL].stop()
	_last_event[event] = _elapsed
	_last_any = _elapsed
	_last_kind = event
	play_counts[event] += 1
	var player := players[event]
	player.stream = candidates[event][selected[event]]
	player.volume_db = VOLUME_DB[event] + gain_db
	if is_inside_tree():
		player.play(START_SECONDS[event][selected[event]])
	return true


func select_candidate(event: int, index: int) -> void:
	if event < 0 or event >= FILES.size() or index < 0 or index >= FILES[event].size():
		return
	selected[event] = index
	players[event].stop()


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for player in players:
			player.stop()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F2, KEY_F3, KEY_F4:
			var kind: int = event.keycode - KEY_F2
			select_candidate(kind, (selected[kind] + 1) % FILES[kind].size())
		KEY_F5:
			set_muted(not muted)
		KEY_F6:
			select_candidate(Event.WALL, 1 - selected[Event.WALL])
		_:
			return
	_status.text = "AUDIO AUDITION (temporary) | F5: " + ("muted" if muted else "on")
	for kind in range(FILES.size()):
		_status.text += "\nF%d %s: %s" % [[2, 3, 4, 6][kind], ["Paddle", "Ground", "Wake", "Wall"][kind], FILES[kind][selected[kind]].get_file()]
		if FILES[kind].size() == 1:
			_status.text += " (single variant)"
	_status_seconds = 4.0
	_status.show()
	get_viewport().set_input_as_handled()
