class_name PaddleController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

signal interaction_sampled(input_distance: float, paddle_position: Vector2)
var _pending_input_distance := 0.0

var tuning: Resource = PrototypeTuningScript.new()
var left_bound: float = 0.0
var right_bound: float = 960.0
var fixed_y: float = 0.0
var target_x: float = 0.0
# Energy transfer is the Paddle's only visual change: the body dims when it hands
# Vitality to the Ball, then recovers. Contact itself draws nothing extra.
# Any real transfer is clearly visible; larger transfers dim deeper.
const DIM_MIN_DEPTH := 0.55
const ENERGY_FOR_FULL_DIM := 0.2
const DIM_HOLD := 0.08
const DIM_RECOVERY := 0.5
var _dim_peak := 0.0
var _dim_elapsed := DIM_HOLD + DIM_RECOVERY
var _core_box := StyleBoxFlat.new()


func _ready() -> void:
	target_x = position.x
	fixed_y = position.y
	queue_redraw()


func _physics_process(delta: float) -> void:
	set_target_x(get_global_mouse_position().x)
	advance_motion(delta)


func _process(delta: float) -> void:
	advance_feedback(delta)


# Feedback only: called after Physics/Interaction already committed the Vitality change.
func play_energy_transfer(amount: float) -> void:
	if amount <= 0.0:
		return
	var depth := lerpf(DIM_MIN_DEPTH, 1.0, clampf(amount / ENERGY_FOR_FULL_DIM, 0.0, 1.0))
	_dim_peak = maxf(depth, dim_strength())
	_dim_elapsed = 0.0
	queue_redraw()


func dim_strength() -> float:
	if _dim_elapsed <= DIM_HOLD:
		return _dim_peak
	var t := clampf((_dim_elapsed - DIM_HOLD) / DIM_RECOVERY, 0.0, 1.0)
	# Ease-out recovery: reads as the Paddle refilling rather than a flicker.
	return _dim_peak * pow(1.0 - t, 2.0)


func advance_feedback(delta: float) -> void:
	if delta <= 0.0 or _dim_elapsed >= DIM_HOLD + DIM_RECOVERY:
		return
	_dim_elapsed = minf(_dim_elapsed + delta, DIM_HOLD + DIM_RECOVERY)
	queue_redraw()


func feedback_color() -> Color:
	return Tokens.PADDLE_IDLE.lerp(Tokens.PADDLE_DIM, dim_strength())


func configure(source_tuning: Resource, left: float, right: float, y_position: float) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	set_horizontal_bounds(left, right)
	fixed_y = y_position
	position.y = fixed_y
	target_x = clampf(position.x, _minimum_center_x(), _maximum_center_x())
	_pending_input_distance = 0.0
	queue_redraw()


func set_horizontal_bounds(left: float, right: float) -> void:
	left_bound = minf(left, right)
	right_bound = maxf(left, right)


func set_target_x(value: float) -> void:
	var next_target := clampf(value, _minimum_center_x(), _maximum_center_x())
	_pending_input_distance += absf(next_target - target_x)
	target_x = next_target


func advance_motion(delta: float) -> void:
	if delta <= 0.0:
		velocity = Vector2.ZERO
		return
	var previous_x := position.x
	var smoothing_weight := 1.0 - exp(-tuning.paddle_smoothing * delta)
	position.x = lerpf(previous_x, target_x, smoothing_weight)
	position.x = clampf(position.x, _minimum_center_x(), _maximum_center_x())
	position.y = fixed_y
	velocity = Vector2((position.x - previous_x) / delta, 0.0)
	interaction_sampled.emit(_pending_input_distance if tuning.legacy_rhythm_enabled else absf(position.x - previous_x), global_position)
	_pending_input_distance = 0.0


func _minimum_center_x() -> float:
	return left_bound + tuning.paddle_size.x * 0.5


func _maximum_center_x() -> float:
	return right_bound - tuning.paddle_size.x * 0.5


func _draw() -> void:
	_core_box.bg_color = feedback_color()
	_core_box.set_corner_radius_all(9)
	draw_style_box(_core_box, Rect2(-tuning.paddle_size * 0.5, tuning.paddle_size))
