extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")

const GAME_LEFT := 175.0
const GAME_RIGHT := 786.0
const PADDLE_Y := 550.0

var tuning: Resource = PrototypeTuningScript.new()

@onready var ball: CharacterBody2D = $GameArea/Ball
@onready var paddle: CharacterBody2D = $GameArea/Paddle
@onready var rules: Node = $EndlessRules
@onready var hud: CanvasLayer = $HUD
@onready var runtime_tuning_panel: Control = $RuntimeTuningPanel


func _ready() -> void:
	DisplayServer.window_set_title("Bouncing Ball")
	runtime_tuning_panel.configure(tuning)
	paddle.configure(tuning, GAME_LEFT, GAME_RIGHT, PADDLE_Y)
	ball.configure(tuning)

	ball.paddle_hit.connect(_on_ball_paddle_hit)
	ball.surface_hit.connect(_on_ball_surface_hit)
	ball.activity_state_changed.connect(_on_ball_activity_state_changed)
	paddle.motion_sampled.connect(_on_paddle_motion_sampled)
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


func _on_paddle_motion_sampled(paddle_velocity: Vector2, paddle_position: Vector2) -> void:
	if ball.apply_resting_wake_impulse(paddle_velocity, paddle_position):
		rules.begin_wake_cycle()
