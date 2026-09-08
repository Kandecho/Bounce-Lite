class_name BallVisuals
extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallEnergyModelScript = preload("res://scripts/ball/ball_energy_model.gd")

var tuning: Resource = PrototypeTuningScript.new()
var energy_ratio: float = 1.0
var activity_state: int = BallEnergyModelScript.ActivityState.ACTIVE
var trail_points: Array[Vector2] = []


func _ready() -> void:
	queue_redraw()


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	queue_redraw()


func set_activity(value: float, state: int) -> void:
	energy_ratio = clampf(value, 0.0, 1.0)
	activity_state = state
	if activity_state == BallEnergyModelScript.ActivityState.RESTING:
		trail_points.clear()
	_trim_trail()
	queue_redraw()


func record_ball_position(value: Vector2) -> void:
	if activity_state == BallEnergyModelScript.ActivityState.RESTING:
		return
	if trail_points.is_empty() or trail_points[-1].distance_to(value) >= tuning.trail_sample_distance:
		trail_points.append(value)
		_trim_trail()
		queue_redraw()


func _trail_capacity() -> int:
	if activity_state == BallEnergyModelScript.ActivityState.RESTING:
		return 0
	return maxi(2, roundi(lerpf(2.0, float(tuning.trail_max_samples), energy_ratio)))


func _trim_trail() -> void:
	var capacity := _trail_capacity()
	while trail_points.size() > capacity:
		trail_points.pop_front()


func _draw() -> void:
	_draw_trail()
	var rest_factor := 0.18 if activity_state == BallEnergyModelScript.ActivityState.RESTING else 1.0
	var glow_strength := lerpf(0.10, 0.42, energy_ratio) * rest_factor
	draw_circle(Vector2.ZERO, tuning.ball_radius * 2.25,
		Color(0.31, 0.72, 1.0, glow_strength * 0.22))
	draw_circle(Vector2.ZERO, tuning.ball_radius * 1.65,
		Color(0.47, 0.82, 1.0, glow_strength * 0.36))
	draw_circle(Vector2.ZERO, tuning.ball_radius * 1.20,
		Color(0.73, 0.91, 1.0, glow_strength * 0.52))
	draw_circle(Vector2.ZERO, tuning.ball_radius, Color(0.97, 0.99, 1.0, 1.0))
	draw_circle(Vector2(-4.0, -5.0), tuning.ball_radius * 0.28,
		Color(1.0, 1.0, 1.0, 0.58))


func _draw_trail() -> void:
	if trail_points.size() < 2 or activity_state == BallEnergyModelScript.ActivityState.RESTING:
		return
	var segment_count := trail_points.size() - 1
	for index in range(1, trail_points.size()):
		var progress := float(index) / float(segment_count)
		var alpha := progress * energy_ratio * 0.28
		var width := lerpf(2.0, tuning.ball_radius * 0.72, progress)
		draw_line(to_local(trail_points[index - 1]), to_local(trail_points[index]),
			Color(0.44, 0.82, 1.0, alpha), width, true)
