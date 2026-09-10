extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

const GAME_LEFT := 175.0
const GAME_RIGHT := 786.0

var tuning: Resource = PrototypeTuningScript.new()

@onready var ball: CharacterBody2D = $GameArea/Ball
@onready var paddle: CharacterBody2D = $GameArea/Paddle
@onready var rules: Node = $EndlessRules
@onready var hud: CanvasLayer = $HUD
@onready var runtime_tuning_panel: Control = $DebugOverlay/RuntimeTuningPanel


func _ready() -> void:
	DisplayServer.window_set_title("Bouncing Ball")
	$Background.color = Tokens.DARK_WINDOW
	var panel_style: StyleBoxFlat = $GameArea/Panel.get_theme_stylebox("panel").duplicate()
	panel_style.bg_color = Tokens.DARK_PANEL
	panel_style.border_color = Tokens.DARK_PANEL_BORDER
	$GameArea/Panel.add_theme_stylebox_override("panel", panel_style)
	$HUD/ComboLabel.add_theme_color_override("font_color", Tokens.TEXT_SECONDARY)
	$HUD/TimerLabel.add_theme_color_override("font_color", Tokens.TEXT_PRIMARY)
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

	ball.paddle_hit.connect(_on_ball_paddle_hit)
	ball.surface_hit.connect(_on_ball_surface_hit)
	ball.activity_state_changed.connect(_on_ball_activity_state_changed)
	paddle.interaction_sampled.connect(_on_paddle_interaction_sampled)
	ball.weak_interaction.connect(_on_weak_interaction)
	ball.paddle_contact.connect(paddle.play_collision_feedback)
	ball.wake_committed.connect(_on_wake_committed)
	ball.surface_resolved.connect($BasicAudio.on_surface_resolved)
	ball.wake_committed.connect($BasicAudio.on_wake_committed)
	rules.combo_changed.connect(hud.set_combo)
	rules.active_time_changed.connect(hud.set_active_time)

	hud.set_combo(rules.combo)
	hud.set_active_time(rules.active_time_seconds)
	ball.start_active(Vector2(0.62, 1.0))


func _on_ball_paddle_hit(_vitality_before: float, _vitality_after: float) -> void:
	rules.handle_paddle_hit()


func _on_ball_surface_hit(kind: int, _vitality_before: float, _vitality_after: float) -> void:
	rules.handle_surface_hit(kind)


func _on_ball_activity_state_changed(_previous: int, current: int) -> void:
	rules.handle_activity_state_changed(current)


func _on_paddle_interaction_sampled(input_distance: float, paddle_position: Vector2) -> void:
	ball.apply_resting_interaction(input_distance, paddle_position)


func _on_weak_interaction(strength: float, ball_position: Vector2) -> void:
	paddle.play_wake_feedback(strength, 1.0, false, ball_position)


func _on_wake_committed(strength: float, activated: bool, ball_position: Vector2) -> void:
	if activated:
		rules.begin_wake_cycle()
	paddle.play_wake_feedback(strength, 1.0, activated, ball_position)
