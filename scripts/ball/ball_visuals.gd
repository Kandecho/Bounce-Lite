class_name BallVisuals
extends Node2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")
const Tokens = preload("res://scripts/config/visual_tokens.gd")

var tuning: Resource = PrototypeTuningScript.new()
var vitality_ratio: float = 1.0
var motion_velocity := Vector2.ZERO
var activity_state: int = BallVitalityModelScript.ActivityState.ACTIVE
var trail_points: Array[Vector2] = []
var deformation := Vector2.ONE
var _previous_position := Vector2.ZERO
var _current_position := Vector2.ZERO
var _has_position := false
var _sample_elapsed := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func _process(delta: float) -> void:
	advance_feedback(delta)


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	Tokens.radial_texture()
	queue_redraw()


func set_vitality(value: float, state: int) -> void:
	vitality_ratio = clampf(value, 0.0, 1.0)
	activity_state = state
	queue_redraw()


func set_motion(value: Vector2) -> void:
	motion_velocity = value
	if value.is_zero_approx():
		clear_motion_history()
	queue_redraw()


func _visual_vitality() -> float:
	return 0.0 if activity_state == BallVitalityModelScript.ActivityState.RESTING else vitality_ratio


func core_color() -> Color:
	return Tokens.core_color(_visual_vitality())


func glow_color() -> Color:
	return Tokens.glow_color(_visual_vitality())


func glow_peak() -> float:
	if activity_state == BallVitalityModelScript.ActivityState.RESTING:
		return 0.25
	return lerpf(0.25, 0.85, vitality_ratio)


func glow_alpha_at_radius(radius: float) -> float:
	return glow_peak() * pow(1.0 - clampf((radius - 1.0) / 0.75, 0.0, 1.0), 1.6)


func trail_color() -> Color:
	return Tokens.glow_color(1.0)


func _speed_ratio() -> float:
	return clampf(motion_velocity.length() / maxf(tuning.max_speed, 0.001), 0.0, 1.0)


func trail_spacing() -> float:
	return maxf(motion_velocity.length() * Tokens.TRAIL_INTERVAL, Tokens.TRAIL_MIN_SPACING)


func clear_motion_history() -> void:
	trail_points.clear()
	_sample_elapsed = 0.0
	_has_position = false
	queue_redraw()


func advance_motion_history(value: Vector2, delta: float) -> void:
	if not _has_position:
		_previous_position = value
		_has_position = true
	_current_position = value
	if delta <= 0.0 or motion_velocity.is_zero_approx():
		_previous_position = value
		return
	var next_sample := Tokens.TRAIL_INTERVAL - _sample_elapsed
	while next_sample <= delta + 0.000001:
		trail_points.append(_previous_position.lerp(value, clampf(next_sample / delta, 0.0, 1.0)))
		next_sample += Tokens.TRAIL_INTERVAL
	_sample_elapsed = fposmod(_sample_elapsed + delta + 0.00000001, Tokens.TRAIL_INTERVAL)
	_previous_position = value
	# Extra history supports minimum spacing at low speed; only up to four ghosts draw.
	while trail_points.size() > 64:
		trail_points.pop_front()
	queue_redraw()


func trail_ghosts() -> Array[Vector2]:
	var ghosts: Array[Vector2] = []
	var count := clampi(roundi(Tokens.TRAIL_MAX_GHOSTS * _speed_ratio()), 0, Tokens.TRAIL_MAX_GHOSTS)
	if count == 0 or trail_points.is_empty():
		return ghosts
	var previous := _current_position
	var distance := 0.0
	var target := trail_spacing()
	for index in range(trail_points.size() - 1, -1, -1):
		var point := trail_points[index]
		var segment := previous.distance_to(point)
		if segment > 0.00001:
			while distance + segment >= target and ghosts.size() < count:
				ghosts.append(previous.lerp(point, (target - distance) / segment))
				target += trail_spacing()
		distance += segment
		previous = point
		if ghosts.size() == count:
			break
	return ghosts


func play_collision_feedback(kind: int, normal: Vector2) -> void:
	# Instant decoration is geometric only. Core/Glow never read event pulses.
	var squash: float = tuning.wall_hit_squash
	var stretch := 1.08
	if kind == SurfaceResponseModelScript.SurfaceKind.PADDLE:
		squash = tuning.paddle_hit_squash
		stretch = 1.24
	elif kind == SurfaceResponseModelScript.SurfaceKind.GROUND:
		squash = tuning.ground_hit_squash
		stretch = 1.16
	deformation = Vector2(squash, stretch) if absf(normal.x) > absf(normal.y) else Vector2(stretch, squash)
	queue_redraw()


func play_weak_feedback(strength: float) -> void:
	# Small geometric response only: no velocity, glow pulse or trail.
	var amount := clampf(strength, 0.0, 1.0) * 0.06
	deformation = Vector2(1.0 + amount * 0.5, 1.0 - amount)
	queue_redraw()


func play_wake_feedback() -> void:
	deformation = Vector2(0.82, 0.82)
	queue_redraw()


func advance_feedback(delta: float) -> void:
	if delta <= 0.0:
		return
	deformation = deformation.lerp(Vector2.ONE, 1.0 - exp(-tuning.feedback_recovery_speed * delta))
	queue_redraw()


func _draw() -> void:
	_draw_trail()
	var radius: float = tuning.ball_radius
	var envelope: float = radius * Tokens.GLOW_RADIUS
	# Glow's profile and envelope are independent of collision deformation.
	var glow := glow_color()
	glow.a = glow_peak()
	draw_texture_rect(Tokens.radial_texture(), Rect2(Vector2.ONE * -envelope, Vector2.ONE * envelope * 2.0), false, glow)
	draw_set_transform(Vector2.ZERO, 0.0, deformation)
	draw_circle(Vector2.ZERO, radius, core_color(), true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_trail() -> void:
	var ghosts := trail_ghosts()
	for index in range(ghosts.size() - 1, -1, -1):
		var age := float(index) / maxf(float(ghosts.size() - 1), 1.0)
		var radius: float = tuning.ball_radius * lerpf(1.0, 0.82, age)
		var envelope := radius * Tokens.GLOW_RADIUS
		var color := trail_color()
		color.a = lerpf(0.34, 0.05, age) * lerpf(0.30, 1.0, _speed_ratio())
		var center := to_local(ghosts[index])
		draw_texture_rect(Tokens.radial_texture(), Rect2(center - Vector2.ONE * envelope, Vector2.ONE * envelope * 2.0), false, color)
