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
var rest_elapsed_time: float = 0.0
var resting_wake_impulse_consumed := false


func _ready() -> void:
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_update_visuals(false)


func _physics_process(delta: float) -> void:
	if vitality_model == null or delta <= 0.0:
		velocity = Vector2.ZERO
		_update_visuals(false)
		return
	advance_resting_time(delta)
	if is_resting() and velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
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
			not is_resting()
			and kind == SurfaceResponseModelScript.SurfaceKind.PADDLE
			and velocity.y > 0.0
			and normal.y < -0.5
		)
		var motion_before := remaining_motion.length()
		resolve_surface_collision(kind, normal, valid_paddle_hit)
		if velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
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
	rest_elapsed_time = 0.0
	resting_wake_impulse_consumed = false
	velocity = _safe_direction(initial_direction) * tuning.initial_speed
	_update_visuals(false)


func advance_air_motion(delta: float) -> void:
	if vitality_model == null or delta <= 0.0:
		return
	if is_resting() and velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
		return
	velocity.y += tuning.gravity_acceleration * delta
	velocity = velocity.limit_length(tuning.max_speed)


func resolve_surface_collision(kind: int, normal: Vector2, valid_paddle_hit: bool) -> void:
	if vitality_model == null or surface_response_model == null:
		return
	var was_resting := is_resting()
	var effective_paddle_hit := valid_paddle_hit and not was_resting
	var vitality_before: float = vitality_model.current_vitality
	var result: RefCounted = surface_response_model.resolve(
		velocity,
		normal,
		kind,
		vitality_model.vitality_ratio(),
		vitality_before,
		vitality_model.max_vitality,
		effective_paddle_hit
	)
	velocity = result.velocity_after.limit_length(tuning.max_speed)
	vitality_model.apply_delta(result.vitality_delta)
	if was_resting:
		if result.effective_surface_kind == SurfaceResponseModelScript.SurfaceKind.GROUND \
			and result.settle_allowed:
			_settle_resting_motion()
	else:
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


func advance_resting_time(delta: float) -> void:
	if not is_resting() or delta <= 0.0:
		return
	rest_elapsed_time += delta


func apply_resting_wake_impulse(
	paddle_velocity: Vector2,
	paddle_position: Vector2
) -> bool:
	if vitality_model == null or not is_resting():
		return false
	if resting_wake_impulse_consumed:
		return false
	if rest_elapsed_time + 0.000001 < tuning.wake_rest_delay_seconds:
		return false
	if not _paddle_is_in_wake_range(paddle_position.x):
		return false
	var paddle_speed := absf(paddle_velocity.x)
	if is_zero_approx(paddle_speed):
		return false

	var impulse := Vector2(
		paddle_velocity.x * tuning.wake_horizontal_factor,
		-paddle_speed * tuning.wake_vertical_factor
	).limit_length(tuning.max_speed)
	resting_wake_impulse_consumed = true
	velocity = (velocity + impulse).limit_length(tuning.max_speed)

	var activated := false
	if impulse.length() + 0.000001 >= tuning.wake_activation_impulse:
		var restored_vitality: float = (
			vitality_model.current_vitality
			+ vitality_model.max_vitality * tuning.wake_vitality_restore_ratio
		)
		activated = vitality_model.wake(restored_vitality)
	_update_visuals(false)
	if activated:
		var visuals := get_node_or_null("Visuals")
		if visuals != null and visuals.has_method("play_wake_feedback"):
			visuals.play_wake_feedback()
	return activated


func is_resting() -> bool:
	return (
		vitality_model != null
		and vitality_model.state == BallVitalityModelScript.ActivityState.RESTING
	)


func _paddle_is_in_wake_range(paddle_x: float) -> bool:
	var horizontal_reach: float = (
		tuning.paddle_size.x * 0.5
		+ tuning.ball_radius
		+ tuning.wake_horizontal_margin
	)
	return absf(global_position.x - paddle_x) <= horizontal_reach


func _settle_resting_motion() -> void:
	velocity = Vector2.ZERO
	rest_elapsed_time = 0.0
	resting_wake_impulse_consumed = false


func _safe_direction(value: Vector2) -> Vector2:
	var safe_direction := value.normalized()
	if safe_direction.is_zero_approx():
		return DEFAULT_DIRECTION.normalized()
	return safe_direction


func _on_vitality_state_changed(previous: int, current: int) -> void:
	if current == BallVitalityModelScript.ActivityState.RESTING:
		_settle_resting_motion()
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
