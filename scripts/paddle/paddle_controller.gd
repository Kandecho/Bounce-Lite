class_name PaddleController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")

signal motion_sampled(paddle_velocity: Vector2, paddle_position: Vector2)

var tuning: Resource = PrototypeTuningScript.new()
var left_bound: float = 0.0
var right_bound: float = 960.0
var fixed_y: float = 0.0
var target_x: float = 0.0


func _ready() -> void:
	target_x = position.x
	fixed_y = position.y
	queue_redraw()


func _physics_process(delta: float) -> void:
	set_target_x(get_global_mouse_position().x)
	advance_motion(delta)


func configure(source_tuning: Resource, left: float, right: float, y_position: float) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	set_horizontal_bounds(left, right)
	fixed_y = y_position
	position.y = fixed_y
	target_x = clampf(position.x, _minimum_center_x(), _maximum_center_x())
	queue_redraw()


func set_horizontal_bounds(left: float, right: float) -> void:
	left_bound = minf(left, right)
	right_bound = maxf(left, right)


func set_target_x(value: float) -> void:
	target_x = clampf(value, _minimum_center_x(), _maximum_center_x())


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
	if not velocity.is_zero_approx():
		motion_sampled.emit(velocity, global_position)


func _minimum_center_x() -> float:
	return left_bound + tuning.paddle_size.x * 0.5


func _maximum_center_x() -> float:
	return right_bound - tuning.paddle_size.x * 0.5


func _draw() -> void:
	var glow_box := StyleBoxFlat.new()
	glow_box.bg_color = Color(0.38, 0.95, 0.75, 0.16)
	glow_box.corner_radius_top_left = 13
	glow_box.corner_radius_top_right = 13
	glow_box.corner_radius_bottom_left = 13
	glow_box.corner_radius_bottom_right = 13
	var glow_rect := Rect2(-tuning.paddle_size * 0.5 - Vector2(5.0, 5.0), tuning.paddle_size + Vector2(10.0, 10.0))
	draw_style_box(glow_box, glow_rect)

	var core_box := StyleBoxFlat.new()
	core_box.bg_color = Color("60f1bf")
	core_box.corner_radius_top_left = 9
	core_box.corner_radius_top_right = 9
	core_box.corner_radius_bottom_left = 9
	core_box.corner_radius_bottom_right = 9
	draw_style_box(core_box, Rect2(-tuning.paddle_size * 0.5, tuning.paddle_size))
