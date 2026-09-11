extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

const GAME_LEFT := 175.0
const GAME_RIGHT := 786.0

var tuning: Resource = PrototypeTuningScript.new()
var play_world: Node2D
var world_feedback: Node2D

@onready var ball: CharacterBody2D = $GameArea/Ball
@onready var paddle: CharacterBody2D = $GameArea/Paddle
@onready var runtime_tuning_panel: Control = $DebugOverlay/RuntimeTuningPanel


func _ready() -> void:
	DisplayServer.window_set_title("Bouncing Ball")
	_set_e01_enabled(not OS.get_cmdline_user_args().has("--e01-baseline"))
	tuning.shared_world_enabled = not OS.get_cmdline_user_args().has("--v02-baseline")
	if tuning.shared_world_enabled:
		tuning.paddle_vitality_restore = 0.30
	_update_title()
	$Background.color = Tokens.DARK_WINDOW
	var panel_style: StyleBoxFlat = $GameArea/Panel.get_theme_stylebox("panel").duplicate()
	panel_style.bg_color = Tokens.DARK_PANEL
	panel_style.border_color = Tokens.DARK_PANEL_BORDER
	$GameArea/Panel.add_theme_stylebox_override("panel", panel_style)
	runtime_tuning_panel.configure(tuning)
	paddle.configure(tuning, GAME_LEFT, GAME_RIGHT, paddle.position.y)
	ball.configure(tuning)
	ball.configure_support(paddle)
	# Use the inner collision faces, not the decorative Panel or Paddle bounds.
	var left: float = $GameArea/LeftWall.position.x + $GameArea/LeftWall/CollisionShape2D.shape.size.x * 0.5
	var right: float = $GameArea/RightWall.position.x - $GameArea/RightWall/CollisionShape2D.shape.size.x * 0.5
	var top: float = $GameArea/Top.position.y + $GameArea/Top/CollisionShape2D.shape.size.y * 0.5
	var bottom: float = $GameArea/Ground.position.y - $GameArea/Ground/CollisionShape2D.shape.size.y * 0.5
	ball.configure_arena(Rect2(Vector2(left, top), Vector2(right - left, bottom - top)))
	if tuning.shared_world_enabled:
		play_world = load("res://scripts/world/play_world.gd").new()
		play_world.name = "PlayWorld"
		$GameArea.add_child(play_world)
		play_world.configure(tuning, ball.arena_bounds)
		ball.configure_world(play_world)
		world_feedback = load("res://scripts/world/world_feedback.gd").new()
		world_feedback.name = "WorldFeedback"
		$GameArea.add_child(world_feedback)
		play_world.vitality_offered.connect(_on_world_vitality_offered)
		play_world.event_emitted.connect(world_feedback.on_world_event)
		ball.surface_resolved.connect(_on_world_surface_resolved)
		ball.resume_committed.connect(_on_resume_committed)

	paddle.interaction_sampled.connect(_on_paddle_interaction_sampled)
	ball.paddle_energy_transferred.connect(paddle.play_energy_transfer)
	ball.surface_resolved.connect($BasicAudio.on_surface_resolved)
	ball.wake_committed.connect($BasicAudio.on_wake_committed)

	ball.start_active(Vector2(0.62, 1.0))


func _on_paddle_interaction_sampled(input_distance: float, paddle_position: Vector2) -> void:
	ball.note_player_input(input_distance)
	ball.apply_resting_interaction(input_distance, paddle_position)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(world_feedback):
		world_feedback.set_muted($BasicAudio.muted)


func _on_world_vitality_offered(amount: float, _position: Vector2) -> void:
	ball.receive_world_vitality(amount)


func _on_world_surface_resolved(result: RefCounted) -> void:
	play_world.on_surface_resolved(result, ball.global_position)


func _on_resume_committed(ball_position: Vector2) -> void:
	world_feedback.on_world_event("resume", ball_position, 0.65)


func _set_e01_enabled(enabled: bool) -> void:
	tuning.e01_contact_enabled = enabled
	_update_title()
	print("E01: ", "contact" if enabled else "baseline", " (F7 switches future contacts only)")


func _update_title() -> void:
	DisplayServer.window_set_title("Bouncing Ball | 0.2 " + ("shared world" if tuning.shared_world_enabled else "baseline") + " | E01 " + ("contact" if tuning.e01_contact_enabled else "off"))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		_set_e01_enabled(not tuning.e01_contact_enabled)
		get_viewport().set_input_as_handled()
