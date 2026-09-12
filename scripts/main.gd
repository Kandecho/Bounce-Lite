extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

# World objects appear only inside this region: away from the side walls and top,
# and kept clear of the Paddle band so the Ball can pass between them.
const SPAWN_MARGIN := 72.0
const SPAWN_PADDLE_CLEARANCE := 96.0

var tuning: Resource = PrototypeTuningScript.new()
var play_world: Node2D
var world_feedback: Node2D

@onready var ball: CharacterBody2D = $GameArea/Ball
@onready var paddle: CharacterBody2D = $GameArea/Paddle
@onready var runtime_tuning_panel: Control = $DebugOverlay/RuntimeTuningPanel


func _ready() -> void:
	DisplayServer.window_set_title("Bouncing Ball")
	_set_e01_enabled(not OS.get_cmdline_user_args().has("--e01-baseline"))
	tuning.legacy_rhythm_enabled = OS.get_cmdline_user_args().has("--v02-legacy-rhythm")
	tuning.shared_world_enabled = not OS.get_cmdline_user_args().has("--v02-baseline")
	if tuning.shared_world_enabled:
		tuning.paddle_vitality_restore = 0.30
	_update_title()
	# The whole visible client area is the world; no framed panel.
	$Background.color = Tokens.WORLD_BACKGROUND
	RenderingServer.set_default_clear_color(Tokens.WORLD_BACKGROUND)
	runtime_tuning_panel.configure(tuning)
	# Use the inner collision faces, which sit exactly on the viewport edges.
	var left: float = $GameArea/LeftWall.position.x + $GameArea/LeftWall/CollisionShape2D.shape.size.x * 0.5
	var right: float = $GameArea/RightWall.position.x - $GameArea/RightWall/CollisionShape2D.shape.size.x * 0.5
	var top: float = $GameArea/Top.position.y + $GameArea/Top/CollisionShape2D.shape.size.y * 0.5
	var bottom: float = $GameArea/Ground.position.y - $GameArea/Ground/CollisionShape2D.shape.size.y * 0.5
	paddle.configure(tuning, left, right, paddle.position.y)
	ball.configure(tuning)
	ball.configure_support(paddle)
	ball.configure_arena(Rect2(Vector2(left, top), Vector2(right - left, bottom - top)))
	if tuning.shared_world_enabled:
		play_world = load("res://scripts/world/play_world.gd").new()
		play_world.name = "PlayWorld"
		$GameArea.add_child(play_world)
		play_world.set_ball_context(ball.global_position, tuning.ball_radius)
		play_world.set_random_spawns_enabled(not OS.get_cmdline_user_args().has("--v02-fixed-world"))
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--world-seed="):
				play_world.set_seed(int(argument.trim_prefix("--world-seed=")))
		play_world.configure(tuning, ball.arena_bounds, spawn_region())
		ball.configure_world(play_world)
		world_feedback = load("res://scripts/world/world_feedback.gd").new()
		world_feedback.name = "WorldFeedback"
		$GameArea.add_child(world_feedback)
		play_world.vitality_offered.connect(_on_world_vitality_offered)
		play_world.event_emitted.connect(world_feedback.on_world_event)
		ball.surface_resolved.connect(_on_world_surface_resolved)
		ball.resume_committed.connect(_on_resume_committed)
		ball.wake_committed.connect(_on_wake_committed)

	paddle.interaction_sampled.connect(_on_paddle_interaction_sampled)
	ball.paddle_energy_transferred.connect(paddle.play_energy_transfer)
	ball.surface_resolved.connect($BasicAudio.on_surface_resolved)
	ball.wake_committed.connect($BasicAudio.on_wake_committed)

	ball.start_active(Vector2(0.62, 1.0))


func spawn_region() -> Rect2:
	var arena: Rect2 = ball.arena_bounds
	var paddle_top: float = paddle.position.y - tuning.paddle_size.y * 0.5
	var region_top := arena.position.y + SPAWN_MARGIN
	return Rect2(
		Vector2(arena.position.x + SPAWN_MARGIN, region_top),
		Vector2(arena.size.x - SPAWN_MARGIN * 2.0, paddle_top - SPAWN_PADDLE_CLEARANCE - region_top)
	)


func _on_paddle_interaction_sampled(input_distance: float, paddle_position: Vector2) -> void:
	ball.note_paddle_action(input_distance, paddle_position, paddle.velocity)
	ball.apply_resting_interaction(input_distance, paddle_position)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(play_world):
		play_world.set_ball_context(ball.global_position, tuning.ball_radius)
	if is_instance_valid(world_feedback):
		world_feedback.set_muted($BasicAudio.muted)


func _on_world_vitality_offered(amount: float, _position: Vector2) -> void:
	ball.receive_world_vitality(amount)


func _on_world_surface_resolved(result: RefCounted) -> void:
	play_world.on_surface_resolved(result, ball.global_position)


func _on_resume_committed(ball_position: Vector2) -> void:
	world_feedback.on_world_event("resume", ball_position, 0.65)


func _on_wake_committed(_strength: float, activated: bool, ball_position: Vector2) -> void:
	if activated:
		world_feedback.on_world_event("wake", ball_position, 1.0)


func _set_e01_enabled(enabled: bool) -> void:
	tuning.e01_contact_enabled = enabled
	_update_title()
	print("E01: ", "contact" if enabled else "baseline", " (F7 switches future contacts only)")


func _update_title() -> void:
	DisplayServer.window_set_title("Bouncing Ball | v0.2.0 " + ("shared world" if tuning.shared_world_enabled else "baseline") + " | E01 " + ("contact" if tuning.e01_contact_enabled else "off"))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		_set_e01_enabled(not tuning.e01_contact_enabled)
		get_viewport().set_input_as_handled()
