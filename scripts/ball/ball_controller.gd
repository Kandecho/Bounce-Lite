class_name BallController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")

signal surface_resolved(result: RefCounted)
signal surface_hit(kind: int, vitality_before: float, vitality_after: float)
signal paddle_hit(vitality_before: float, vitality_after: float)
signal vitality_changed(previous: float, current: float)
signal activity_state_changed(previous: int, current: int)

const MAX_COLLISIONS_PER_FRAME := 4
const MOTION_EPSILON := 0.001
const DEFAULT_DIRECTION := Vector2(0.65, -1.0)

var tuning: Resource = PrototypeTuningScript.new()
var vitality_model: RefCounted
var surface_response_model: RefCounted


func _ready() -> void:
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_update_visuals(false)


func _physics_process(delta: float) -> void:
	if vitality_model == null or is_resting() or delta <= 0.0:
		velocity = Vector2.ZERO
		_update_visuals(false)
		return
	advance_air_motion(delta)
	var remaining_motion := velocity * delta
	for collision_index in range(MAX_COLLISIONS_PER_FRAME):
		if remaining_motion.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
			break
		var collision := move_and_collide(remaining_motion)
		if collision == null:
			break
		var normal := collision.get_normal()
		var collider := collision.get_collider()
		var kind: int = SurfaceResponseModelScript.SurfaceKind.WALL
		if collider != null and collider.has_meta("surface_kind"):
			kind = int(collider.get_meta("surface_kind"))
		var valid_paddle_hit := (
			kind == SurfaceResponseModelScript.SurfaceKind.PADDLE
			and velocity.y > 0.0
			and normal.y < -0.5
		)
		var motion_before := remaining_motion.length()
		resolve_surface_collision(kind, normal, valid_paddle_hit)
		if is_resting():
			break
		var remaining_fraction := (
			collision.get_remainder().length()
			/ maxf(motion_before, MOTION_EPSILON)
		)
		remaining_motion = velocity * delta * remaining_fraction
	_update_visuals(true)


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	vitality_model = BallVitalityModelScript.new(tuning)
	surface_response_model = SurfaceResponseModelScript.new(tuning)
	vitality_model.activity_state_changed.connect(_on_vitality_state_changed)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	start_active(DEFAULT_DIRECTION)


func start_active(initial_direction: Vector2) -> void:
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
		return
	vitality_model.reset_active()
	velocity = _safe_direction(initial_direction) * tuning.initial_speed
	_update_visuals(false)


func advance_air_motion(delta: float) -> void:
	if vitality_model == null or is_resting() or delta <= 0.0:
		return
	velocity.y += tuning.gravity_acceleration * delta
	velocity = velocity.limit_length(tuning.max_speed)


func resolve_surface_collision(kind: int, normal: Vector2, valid_paddle_hit: bool) -> void:
	if vitality_model == null or surface_response_model == null:
		return
	var vitality_before: float = vitality_model.current_vitality
	var result: RefCounted = surface_response_model.resolve(
		velocity,
		normal,
		kind,
		vitality_model.vitality_ratio(),
		vitality_before,
		vitality_model.max_vitality,
		valid_paddle_hit
	)
	velocity = result.velocity_after.limit_length(tuning.max_speed)
	vitality_model.apply_delta(result.vitality_delta)
	vitality_model.resolve_activity(result.settle_allowed)
	if is_resting():
		velocity = Vector2.ZERO
	var vitality_after: float = vitality_model.current_vitality
	_update_visuals(false)
	surface_resolved.emit(result)
	vitality_changed.emit(vitality_before, vitality_after)
	_play_collision_feedback(result.effective_surface_kind, normal)
	if result.valid_paddle_hit:
		paddle_hit.emit(vitality_before, vitality_after)
	else:
		surface_hit.emit(result.effective_surface_kind, vitality_before, vitality_after)


func wake_from_paddle(paddle_velocity_x: float) -> bool:
	if vitality_model == null:
		return false
	var wake_vitality: float = vitality_model.max_vitality * tuning.wake_vitality_ratio
	if not vitality_model.wake(wake_vitality):
		return false
	var horizontal_sign := signf(paddle_velocity_x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = 1.0
	velocity = _safe_direction(Vector2(horizontal_sign * 0.35, -1.0)) * tuning.wake_speed
	_update_visuals(false)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("play_wake_feedback"):
		visuals.play_wake_feedback()
	return true


func is_resting() -> bool:
	return (
		vitality_model != null
		and vitality_model.state == BallVitalityModelScript.ActivityState.RESTING
	)


func _safe_direction(value: Vector2) -> Vector2:
	var safe_direction := value.normalized()
	if safe_direction.is_zero_approx():
		return DEFAULT_DIRECTION.normalized()
	return safe_direction


func _on_vitality_state_changed(previous: int, current: int) -> void:
	if current == BallVitalityModelScript.ActivityState.RESTING:
		velocity = Vector2.ZERO
	_update_visuals(false)
	activity_state_changed.emit(previous, current)


func _update_visuals(record_position: bool) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals == null or vitality_model == null:
		return
	if visuals.has_method("set_vitality"):
		visuals.set_vitality(vitality_model.vitality_ratio(), vitality_model.state)
	if visuals.has_method("set_motion"):
		visuals.set_motion(velocity)
	if record_position and visuals.has_method("record_ball_position"):
		visuals.record_ball_position(global_position)


func _play_collision_feedback(kind: int, normal: Vector2) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("play_collision_feedback"):
		visuals.play_collision_feedback(kind, normal)
