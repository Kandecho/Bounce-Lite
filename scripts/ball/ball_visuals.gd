class_name BallVisuals
extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")

var tuning: Resource = PrototypeTuningScript.new()
var vitality_ratio: float = 1.0
var motion_velocity: Vector2 = Vector2.ZERO
var motion_speed_ratio: float = 1.0
var activity_state: int = BallVitalityModelScript.ActivityState.ACTIVE
var trail_points: Array[Vector2] = []
var deformation: Vector2 = Vector2.ONE
var glow_pulse: float = 0.0
var darken_pulse: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	advance_feedback(delta)


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	queue_redraw()


func set_vitality(value: float, state: int) -> void:
	vitality_ratio = clampf(value, 0.0, 1.0)
	activity_state = state
	queue_redraw()


func set_motion(value: Vector2) -> void:
	motion_velocity = value
	motion_speed_ratio = clampf(
		value.length() / maxf(tuning.max_speed, 0.001),
		0.0,
		1.0
	)
	_trim_trail()
	queue_redraw()


func play_collision_feedback(kind: int, normal: Vector2) -> void:
	match kind:
		SurfaceResponseModelScript.SurfaceKind.PADDLE:
			deformation = _deformation_for_normal(normal, tuning.paddle_hit_squash, 1.24)
			glow_pulse = tuning.paddle_glow_pulse
			darken_pulse = 0.0
		SurfaceResponseModelScript.SurfaceKind.GROUND:
			deformation = _deformation_for_normal(normal, tuning.ground_hit_squash, 1.16)
			glow_pulse = 0.0
			darken_pulse = tuning.ground_darken_pulse
		_:
			deformation = _deformation_for_normal(normal, tuning.wall_hit_squash, 1.08)
			glow_pulse = tuning.wall_glow_pulse
			darken_pulse = 0.0
	queue_redraw()


func play_wake_feedback() -> void:
	deformation = Vector2(0.82, 0.82)
	glow_pulse = tuning.wake_glow_pulse
	darken_pulse = 0.0
	queue_redraw()


func advance_feedback(delta: float) -> void:
	if delta <= 0.0:
		return
	var recovery_weight := 1.0 - exp(-tuning.feedback_recovery_speed * delta)
	deformation = deformation.lerp(Vector2.ONE, recovery_weight)
	glow_pulse = lerpf(glow_pulse, 0.0, recovery_weight)
	darken_pulse = lerpf(darken_pulse, 0.0, recovery_weight)
	queue_redraw()


func record_ball_position(value: Vector2) -> void:
	if motion_velocity.is_zero_approx():
		return
	if trail_points.is_empty() or trail_points[-1].distance_to(value) >= tuning.trail_sample_distance:
		trail_points.append(value)
		_trim_trail()
		queue_redraw()


func _trail_capacity() -> int:
	if motion_velocity.is_zero_approx():
		return 0
	return maxi(2, roundi(lerpf(
		2.0,
		float(tuning.trail_max_samples),
		motion_speed_ratio
	)))


func _trim_trail() -> void:
	var capacity := _trail_capacity()
	while trail_points.size() > capacity:
		trail_points.pop_front()


func _draw() -> void:
	_draw_trail()
	var rest_factor := 0.18 if activity_state == BallVitalityModelScript.ActivityState.RESTING else 1.0
	var glow_strength := (lerpf(0.10, 0.42, vitality_ratio) + glow_pulse) * rest_factor
	var core_color := Color(0.97, 0.99, 1.0, 1.0).darkened(darken_pulse)
	draw_set_transform(Vector2.ZERO, 0.0, deformation)
	draw_circle(Vector2.ZERO, tuning.ball_radius * 2.25,
		Color(0.31, 0.72, 1.0, clampf(glow_strength * 0.22, 0.0, 0.65)))
	draw_circle(Vector2.ZERO, tuning.ball_radius * 1.65,
		Color(0.47, 0.82, 1.0, clampf(glow_strength * 0.36, 0.0, 0.75)))
	draw_circle(Vector2.ZERO, tuning.ball_radius * 1.20,
		Color(0.73, 0.91, 1.0, clampf(glow_strength * 0.52, 0.0, 0.88)))
	draw_circle(Vector2.ZERO, tuning.ball_radius, core_color)
	draw_circle(Vector2(-4.0, -5.0), tuning.ball_radius * 0.28,
		Color(1.0, 1.0, 1.0, 0.58 * (1.0 - darken_pulse)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_trail() -> void:
	if trail_points.size() < 2 or motion_velocity.is_zero_approx():
		return
	var segment_count := trail_points.size() - 1
	var trail_strength := lerpf(0.35, 1.0, motion_speed_ratio)
	var local_points := PackedVector2Array()
	var outer_colors := PackedColorArray()
	var inner_colors := PackedColorArray()
	for index in range(trail_points.size()):
		var progress := float(index) / float(segment_count)
		local_points.append(to_local(trail_points[index]))
		outer_colors.append(Color(0.34, 0.70, 1.0, progress * trail_strength * 0.10))
		inner_colors.append(Color(0.68, 0.89, 1.0, progress * trail_strength * 0.22))
	draw_polyline_colors(local_points, outer_colors, tuning.ball_radius * 1.95, true)
	draw_polyline_colors(local_points, inner_colors, tuning.ball_radius * 1.20, true)


func _deformation_for_normal(normal: Vector2, squash: float, stretch: float) -> Vector2:
	if absf(normal.x) > absf(normal.y):
		return Vector2(squash, stretch)
	return Vector2(stretch, squash)
