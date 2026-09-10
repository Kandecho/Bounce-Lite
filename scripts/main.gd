extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

const GAME_LEFT := 175.0
const GAME_RIGHT := 786.0

var tuning: Resource = PrototypeTuningScript.new()

@onready var ball: CharacterBody2D = $GameArea/Ball
@onready var paddle: CharacterBody2D = $GameArea/Paddle
@onready var runtime_tuning_panel: Control = $DebugOverlay/RuntimeTuningPanel


func _ready() -> void:
	DisplayServer.window_set_title("Bouncing Ball")
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

	paddle.interaction_sampled.connect(_on_paddle_interaction_sampled)
	ball.paddle_contact.connect(paddle.play_collision_feedback)
	ball.surface_resolved.connect($BasicAudio.on_surface_resolved)
	ball.wake_committed.connect($BasicAudio.on_wake_committed)

	ball.start_active(Vector2(0.62, 1.0))


func _on_paddle_interaction_sampled(input_distance: float, paddle_position: Vector2) -> void:
	ball.apply_resting_interaction(input_distance, paddle_position)
