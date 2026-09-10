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
var _feedback_elapsed := 1.0
var _feedback_duration := 0.0
var _feedback_peak := 0.0
var _contact_point := Vector2.ZERO
var _invalid_contact := false
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


func play_collision_feedback(valid: bool, contact_position: Vector2) -> void:
	_begin_feedback(1.0 if valid else 0.28, 0.22 if valid else 0.12, contact_position, not valid)


func play_wake_feedback(impulse: float, threshold: float, activated: bool, ball_position: Vector2) -> void:
	var strength := 0.85 if activated else lerpf(0.15, 0.45, clampf(impulse / maxf(threshold, 0.001), 0.0, 1.0))
	_begin_feedback(strength, 0.26 if activated else 0.15,
		Vector2(ball_position.x, global_position.y - tuning.paddle_size.y * 0.5), false)


func _begin_feedback(strength: float, duration: float, contact: Vector2, invalid: bool) -> void:
	_feedback_peak = strength
	_feedback_duration = duration
	_feedback_elapsed = 0.0
	_contact_point = (contact - global_position).clamp(-tuning.paddle_size * 0.5, tuning.paddle_size * 0.5)
	_invalid_contact = invalid
	queue_redraw()


func advance_feedback(delta: float) -> void:
	if delta <= 0.0 or _feedback_elapsed >= _feedback_duration:
		return
	_feedback_elapsed = minf(_feedback_elapsed + delta, _feedback_duration)
	queue_redraw()


func feedback_strength() -> float:
	if _feedback_elapsed >= _feedback_duration:
		return 0.0
	return _feedback_peak * exp(-_feedback_elapsed / Tokens.FEEDBACK_TAU)


func feedback_color() -> Color:
	var flash := Tokens.PADDLE_FLASH
	if _invalid_contact:
		flash = Color.from_hsv(flash.h, flash.s * 0.35, flash.v)
	return Tokens.PADDLE_IDLE.lerp(flash, feedback_strength())


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
	interaction_sampled.emit(_pending_input_distance, global_position)
	_pending_input_distance = 0.0


func _minimum_center_x() -> float:
	return left_bound + tuning.paddle_size.x * 0.5


func _maximum_center_x() -> float:
	return right_bound - tuning.paddle_size.x * 0.5


func _draw() -> void:
	_core_box.bg_color = feedback_color()
	_core_box.set_corner_radius_all(9)
	draw_style_box(_core_box, Rect2(-tuning.paddle_size * 0.5, tuning.paddle_size))
	var strength := feedback_strength()
	if strength <= 0.0:
		return
	var progress := clampf(_feedback_elapsed / _feedback_duration, 0.0, 1.0)
	var travel := lerpf(14.0, 60.0, progress)
	var color := Tokens.PADDLE_DISTURBANCE
	color.a = strength * pow(1.0 - progress, 1.3) * 0.95
	var half_width: float = tuning.paddle_size.x * 0.5 - 9.0
	for direction in [-1.0, 1.0]:
		var x: float = _contact_point.x + direction * travel
		var start := clampf(x - 11.0, -half_width, half_width)
		var end := clampf(x + 11.0, -half_width, half_width)
		if end > start:
			draw_line(Vector2(start, _contact_point.y), Vector2(end, _contact_point.y), color, 1.5, true)
	color.a = strength * pow(1.0 - progress, 2.6) * 0.85
	draw_line(_contact_point, _contact_point + Vector2(0, -7), color, 1.5, true)
