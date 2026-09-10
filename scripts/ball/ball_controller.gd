class_name BallController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")

signal surface_resolved(result: RefCounted)
signal paddle_contact(valid: bool, contact_position: Vector2)
signal wake_committed(strength: float, activated: bool, ball_position: Vector2)

enum SupportKind { NONE, GROUND, PADDLE }
var support_kind: SupportKind = SupportKind.NONE
var support_paddle: Node2D

const MAX_COLLISIONS_PER_FRAME := 4
const MOTION_EPSILON := 0.001
const DEFAULT_DIRECTION := Vector2(0.65, -1.0)

var tuning: Resource = PrototypeTuningScript.new()
var vitality_model: RefCounted
var surface_response_model: RefCounted
var rest_elapsed_time: float = 0.0
var wake_consumed := false
var _wake_sample_elapsed := 0.0
var _interaction_distance := 0.0
var arena_bounds := Rect2()
var bounds_recovery_count: int = 0
# Godot contact recovery can stop within its 0.08 px safe margin. Do not turn
# subpixel contact tolerance into a second normal collision response.
const BOUNDS_TOLERANCE := 0.12


func _ready() -> void:
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_update_visuals()


func _physics_process(delta: float) -> void:
	if vitality_model == null or delta <= 0.0:
		velocity = Vector2.ZERO
		_update_visuals()
		return
	recover_out_of_bounds()
	_refresh_support()
	advance_resting_time(delta)
	if is_resting() and support_kind != SupportKind.NONE and velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
		velocity = Vector2.ZERO
		_settle_ground_position()
		_update_visuals()
		return
	advance_air_motion(delta)
	_record_motion(0.0)
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
		if kind == SurfaceResponseModelScript.SurfaceKind.PADDLE and support_kind != SupportKind.PADDLE:
			paddle_contact.emit(valid_paddle_hit, collision.get_position())
		if velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
			break
		var remaining_fraction := (
			collision.get_remainder().length()
			/ maxf(motion_before, MOTION_EPSILON)
		)
		remaining_motion = velocity * delta * remaining_fraction
	recover_out_of_bounds()
	_update_visuals()
	_record_motion(delta)


func configure_arena(inner_faces: Rect2) -> void:
	arena_bounds = inner_faces


func safe_center_bounds() -> Rect2:
	return arena_bounds.grow(-(tuning.ball_radius + safe_margin))


func recover_out_of_bounds() -> bool:
	if not arena_bounds.has_area():
		return false
	var bounds := safe_center_bounds()
	var before := global_position
	if bounds.grow(BOUNDS_TOLERANCE).has_point(before):
		return false
	var below_ground := before.y > bounds.end.y + BOUNDS_TOLERANCE
	global_position = before.clamp(bounds.position, bounds.end)
	if (before.x < bounds.position.x and velocity.x < 0.0) or (before.x > bounds.end.x and velocity.x > 0.0):
		velocity.x = 0.0
	if (before.y < bounds.position.y and velocity.y < 0.0) or (before.y > bounds.end.y and velocity.y > 0.0):
		velocity.y = 0.0
	if below_ground and vitality_model.vitality_ratio() <= tuning.rest_vitality_ratio:
		_commit_resting_settle(SupportKind.GROUND)
	# Never join motion history across an exceptional position correction.
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("clear_motion_history"):
		visuals.clear_motion_history()
	bounds_recovery_count += 1
	_update_visuals()
	return true


func _settle_ground_position() -> void:
	if not arena_bounds.has_area():
		return
	var ground_y := safe_center_bounds().end.y
	# Only snap a supported/already penetrated resting circle, never an airborne nudge.
	if global_position.y >= ground_y - 0.5 and velocity.y >= 0.0:
		global_position.y = ground_y
		support_kind = SupportKind.GROUND


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	# Configuration supplies dependencies; only start_active starts a new cycle.
	if vitality_model == null:
		vitality_model = BallVitalityModelScript.new(tuning)
		vitality_model.activity_state_changed.connect(_on_vitality_state_changed)
	else:
		vitality_model.tuning = tuning
		vitality_model.max_vitality = maxf(tuning.max_vitality, 0.001)
		vitality_model.apply_delta(0.0)
	if surface_response_model == null:
		surface_response_model = SurfaceResponseModelScript.new(tuning)
	else:
		surface_response_model.tuning = tuning
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_update_visuals()


func start_active(initial_direction: Vector2) -> void:
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
	vitality_model.reset_active()
	rest_elapsed_time = 0.0
	wake_consumed = false
	support_kind = SupportKind.NONE
	_clear_wake_sample()
	velocity = _safe_direction(initial_direction) * tuning.initial_speed
	_update_visuals()


func advance_air_motion(delta: float) -> void:
	if vitality_model == null or delta <= 0.0:
		return
	if is_resting() and support_kind != SupportKind.NONE and velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
		return
	velocity.y += tuning.gravity_acceleration * delta
	velocity = velocity.limit_length(tuning.max_speed)


func resolve_surface_collision(kind: int, normal: Vector2, valid_paddle_hit: bool) -> void:
	if vitality_model == null or surface_response_model == null:
		return
	# Low-energy top contact is support, not a repeatedly rewarded hit.
	if kind == SurfaceResponseModelScript.SurfaceKind.PADDLE and normal.y < -0.5 \
		and velocity.y >= 0.0 and velocity.length() <= tuning.rest_settle_speed \
		and vitality_model.vitality_ratio() <= tuning.rest_vitality_ratio \
		and is_instance_valid(support_paddle) \
		and absf(global_position.x - support_paddle.global_position.x) <= tuning.paddle_size.x * 0.5 - 1.0:
		_commit_resting_settle(SupportKind.PADDLE)
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
	# Surface response grants physical settle permission; Activity is committed last.
	if result.settle_allowed and (was_resting or vitality_model.vitality_ratio() <= tuning.rest_vitality_ratio):
		_commit_resting_settle(SupportKind.GROUND)
	elif not was_resting:
		vitality_model.resolve_activity(false)
	_update_visuals()
	surface_resolved.emit(result)
	_play_collision_feedback(result.effective_surface_kind, normal)


func advance_resting_time(delta: float) -> void:
	if not is_resting() or delta <= 0.0:
		return
	rest_elapsed_time += delta
	if _interaction_distance > 0.0:
		_wake_sample_elapsed += delta
		if _wake_sample_elapsed + 0.000001 >= tuning.wake_sample_seconds:
			_clear_wake_sample()


func apply_resting_interaction(input_distance: float, paddle_position: Vector2) -> bool:
	if vitality_model == null or not is_resting() or wake_consumed:
		return false
	_refresh_support()
	if not _paddle_is_in_wake_range(paddle_position.x):
		_clear_wake_sample()
		return false
	if rest_elapsed_time + 0.000001 < tuning.wake_rest_delay_seconds or input_distance <= 0.0:
		return false
	_interaction_distance += input_distance
	var interaction_strength := clampf(_interaction_distance / maxf(tuning.wake_interaction_distance, 0.001), 0.0, 1.0)
	if interaction_strength + 0.000001 < 1.0:
		var visuals := get_node_or_null("Visuals")
		if visuals != null and visuals.has_method("play_weak_feedback"):
			visuals.play_weak_feedback(interaction_strength)
		return false
	var needs_start: bool = support_kind != SupportKind.NONE and velocity.length() <= tuning.rest_settle_speed
	_clear_wake_sample()
	var activated: bool = vitality_model.wake(vitality_model.current_vitality + vitality_model.max_vitality * tuning.wake_vitality_restore_ratio)
	if not activated:
		return false
	wake_consumed = true
	if needs_start:
		# A discrete self-start, never proportional to input and never horizontal.
		velocity.y = -tuning.wake_launch_speed
		velocity = velocity.limit_length(tuning.max_speed)
	support_kind = SupportKind.NONE
	_update_visuals()
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("play_wake_feedback"):
		visuals.play_wake_feedback()
	wake_committed.emit(1.0, true, global_position)
	return true


func is_resting() -> bool:
	return (
		vitality_model != null
		and vitality_model.state == BallVitalityModelScript.ActivityState.RESTING
	)


func _paddle_is_in_wake_range(paddle_x: float) -> bool:
	return absf(global_position.x - paddle_x) <= tuning.wake_horizontal_range


func _clear_wake_sample() -> void:
	_wake_sample_elapsed = 0.0
	_interaction_distance = 0.0


func _commit_resting_settle(kind: SupportKind) -> void:
	# Called only after Ground/Paddle settle eligibility or exceptional recovery.
	# Apply the physical result before any Activity observer is notified.
	velocity = Vector2.ZERO
	if kind == SupportKind.PADDLE:
		support_kind = kind
		global_position.y = _paddle_support_y()
	else:
		_settle_ground_position()
	# A new settled contact explicitly starts a fresh Interaction rest window.
	_clear_wake_sample()
	rest_elapsed_time = 0.0
	wake_consumed = false
	vitality_model.resolve_activity(true)


func _safe_direction(value: Vector2) -> Vector2:
	var safe_direction := value.normalized()
	if safe_direction.is_zero_approx():
		return DEFAULT_DIRECTION.normalized()
	return safe_direction


func _on_vitality_state_changed(_previous: int, _current: int) -> void:
	# Notification only: never mutate Position, Velocity, Support or Interaction.
	_update_visuals()


func _update_visuals() -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals == null or vitality_model == null:
		return
	if visuals.has_method("set_vitality"):
		visuals.set_vitality(vitality_model.vitality_ratio(), vitality_model.state)
	if visuals.has_method("set_motion"):
		visuals.set_motion(velocity)


func _record_motion(delta: float) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("advance_motion_history"):
		visuals.advance_motion_history(global_position, delta)


func _play_collision_feedback(kind: int, normal: Vector2) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("play_collision_feedback"):
		visuals.play_collision_feedback(kind, normal)


func configure_support(paddle: Node2D) -> void:
	support_paddle = paddle


func _paddle_support_y() -> float:
	return support_paddle.global_position.y - tuning.paddle_size.y * 0.5 - tuning.ball_radius - safe_margin


func _refresh_support() -> void:
	if not is_resting() or velocity.length_squared() > MOTION_EPSILON * MOTION_EPSILON:
		support_kind = SupportKind.NONE
		return
	var previous := support_kind
	support_kind = SupportKind.NONE
	if arena_bounds.has_area() and absf(global_position.y - safe_center_bounds().end.y) <= 0.5:
		support_kind = SupportKind.GROUND
	elif is_instance_valid(support_paddle) \
		and absf(global_position.x - support_paddle.global_position.x) <= tuning.paddle_size.x * 0.5 - 1.0 \
		and absf(global_position.y - _paddle_support_y()) <= 0.5:
		support_kind = SupportKind.PADDLE
	if previous != SupportKind.NONE and support_kind == SupportKind.NONE:
		_clear_wake_sample()
