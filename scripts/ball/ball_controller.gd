class_name BallController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")
const PlayRhythm = preload("res://scripts/ball/play_rhythm.gd")

signal surface_resolved(result: RefCounted)
signal paddle_contact(valid: bool, contact_position: Vector2)
signal wake_committed(strength: float, activated: bool, ball_position: Vector2)
signal resume_committed(ball_position: Vector2)
# Feedback notification: Vitality the Paddle actually handed over (valid hit or Wake).
signal paddle_energy_transferred(amount: float)

var play_rhythm: RefCounted = PlayRhythm.new()
var geometry_contacts: Node
var support_geometry: CollisionObject2D
var spring_hold: CollisionObject2D
var _spring_elapsed := 0.0
var _spring_offset_x := 0.0
var play_world: Object
var _related_motion_distance := 0.0

enum SupportKind { NONE, GROUND, PADDLE, GEOMETRY }
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
	if spring_hold != null or _spring_elapsed > 0.0:
		_advance_spring_hold(delta)
		if _spring_elapsed > 0.0:
			return
		# Release already committed velocity; sweep away before the spring head rebounds.
	recover_out_of_bounds()
	_resolve_paddle_wall_pinch()
	_refresh_support()
	advance_resting_time(delta)
	advance_play_rhythm(delta)
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
		var contact_offset := 0.0
		if valid_paddle_hit and collider is Node2D:
			contact_offset = (collision.get_position().x - collider.global_position.x) / maxf(tuning.paddle_size.x * 0.5, 1.0)
		resolve_surface_collision(kind, normal, valid_paddle_hit, contact_offset, collider)
		if kind == SurfaceResponseModelScript.SurfaceKind.PADDLE and support_kind != SupportKind.PADDLE:
			paddle_contact.emit(valid_paddle_hit, collision.get_position())
		if velocity.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
			break
		var remaining_fraction := (
			collision.get_remainder().length()
			/ maxf(motion_before, MOTION_EPSILON)
		)
		remaining_motion = velocity * delta * remaining_fraction
	_resolve_shallow_ground_contact()
	recover_out_of_bounds()
	_update_visuals()
	_record_motion(delta)


func configure_arena(inner_faces: Rect2) -> void:
	arena_bounds = inner_faces


func _resolve_shallow_ground_contact() -> void:
	if not arena_bounds.has_area() or velocity.y <= 0.0:
		return
	var penetration: float = global_position.y + tuning.ball_radius - arena_bounds.end.y
	if penetration < 0.0 or penetration > 0.5:
		return
	# Near-tangent subpixel motion can miss the engine sweep at the ground plane.
	# This is the same real surface contact and response, not a bounds recovery.
	global_position.y = arena_bounds.end.y - tuning.ball_radius - safe_margin
	resolve_surface_collision(SurfaceResponseModelScript.SurfaceKind.GROUND, Vector2.UP, false)


func _resolve_paddle_wall_pinch() -> void:
	if not is_instance_valid(support_paddle) or not arena_bounds.has_area():
		return
	var half: Vector2 = tuning.paddle_size * 0.5
	var offset := global_position - support_paddle.global_position
	var closest := offset.clamp(-half, half)
	var separation := offset - closest
	var radius: float = tuning.ball_radius + safe_margin
	if separation.length_squared() >= radius * radius or absf(offset.x) < half.x:
		return
	var bounds := safe_center_bounds()
	var side := signf(offset.x)
	var side_exit: float = support_paddle.global_position.x + side * (half.x + radius)
	if side_exit >= bounds.position.x and side_exit <= bounds.end.x:
		return
	# The moving rectangle overlaps the circle, but its side exit is behind a wall.
	# Resolve this actual contact along the available top/bottom arc instead of
	# letting the engine's nearest-point recovery push through the wall.
	var vertical_side := -1.0 if offset.y <= 0.0 else 1.0
	var edge_distance := maxf(absf(offset.x) - half.x, 0.0)
	var vertical_clearance := sqrt(maxf(radius * radius - edge_distance * edge_distance, 0.0))
	global_position.y = support_paddle.global_position.y + vertical_side * (half.y + vertical_clearance + 0.01)
	# Preserve the circle-corner normal; shallow side contact is not a top hit.
	var normal := Vector2(side * edge_distance, vertical_side * vertical_clearance).normalized()
	if velocity.dot(normal) < 0.0:
		var valid := normal.y < -0.5 and velocity.y > 0.0 and not is_resting()
		resolve_surface_collision(SurfaceResponseModelScript.SurfaceKind.PADDLE, normal, valid, offset.x / half.x)
		paddle_contact.emit(valid, global_position - normal * tuning.ball_radius)


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
	clear_geometry_relationships()
	if vitality_model == null or surface_response_model == null:
		configure(tuning)
	vitality_model.reset_active()
	play_rhythm = PlayRhythm.new()
	play_rhythm.qualification_seconds = 15.0 if tuning.legacy_rhythm_enabled else 12.0
	_related_motion_distance = 0.0
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
	if tuning.shared_world_enabled and is_instance_valid(play_world):
		var environment: Vector2 = play_world.sample_acceleration(global_position, velocity)
		if environment.is_finite():
			velocity += environment * delta
	velocity = velocity.limit_length(tuning.max_speed)


func configure_world(world: Object) -> void:
	play_world = world


func note_player_input(distance: float) -> void:
	if tuning.shared_world_enabled and tuning.legacy_rhythm_enabled:
		play_rhythm.note_input(distance)


func note_paddle_action(distance: float, paddle_position: Vector2, paddle_velocity: Vector2) -> void:
	if tuning.legacy_rhythm_enabled:
		note_player_input(distance)
		return
	if not tuning.shared_world_enabled:
		return
	var offset := global_position - paddle_position
	var related: bool = not is_resting() and support_kind == SupportKind.NONE \
		and offset.length() <= tuning.continue_near_distance \
		and offset.x * paddle_velocity.x > 0.0 and distance > 0.0
	if not related:
		_related_motion_distance = 0.0
		return
	_related_motion_distance += distance
	if _related_motion_distance >= tuning.continue_action_distance:
		play_rhythm.note_input(_related_motion_distance)
		_related_motion_distance = 0.0


func receive_world_vitality(amount: float) -> void:
	if not tuning.shared_world_enabled or vitality_model == null or not is_finite(amount):
		return
	# An offer changes energy only. A supported resting ball awaits an explicit start.
	vitality_model.apply_delta(clampf(amount, 0.0, vitality_model.max_vitality))
	if not is_resting():
		vitality_model.resolve_activity(false)
	_update_visuals()


func advance_play_rhythm(delta: float) -> void:
	if not tuning.shared_world_enabled:
		return
	var settled := is_resting() and support_kind != SupportKind.NONE and velocity.is_zero_approx()
	if not play_rhythm.advance(delta, settled):
		return
	# Physics explicitly accepts the request, commits motion, then publishes Activity.
	velocity = Vector2(0.0, -290.0).limit_length(tuning.max_speed)
	support_kind = SupportKind.NONE
	wake_consumed = true
	vitality_model.wake(vitality_model.current_vitality + vitality_model.max_vitality * tuning.continue_vitality_restore_ratio)
	_update_visuals()
	resume_committed.emit(global_position)


func resolve_surface_collision(kind: int, normal: Vector2, valid_paddle_hit: bool, contact_offset: float = 0.0, collider: Object = null) -> void:
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
		effective_paddle_hit,
		contact_offset
	)
	var geometry_contact := is_instance_valid(geometry_contacts) and is_instance_valid(collider) and collider.has_meta("toy_kind")
	var capture: CollisionObject2D
	if geometry_contact:
		var request: Dictionary = geometry_contacts.contact_request(result, collider, global_position)
		if request.has("velocity") and request.velocity is Vector2 and request.velocity.is_finite():
			result.velocity_after = request.velocity.limit_length(tuning.max_speed)
		# Geometry changes motion only; the shared collision model owns Vitality.
		if request.get("spring_capture") == collider:
			capture = collider
	velocity = result.velocity_after.limit_length(tuning.max_speed)
	result.velocity_after = velocity
	if is_instance_valid(capture):
		spring_hold = capture
		_spring_elapsed = 0.000001
		_spring_offset_x = global_position.x - capture.global_position.x
		support_kind = SupportKind.NONE
		if not geometry_contacts.begin_spring_hold(capture):
			spring_hold = null
			_spring_elapsed = 0.0
			velocity = Vector2(0, -500).limit_length(tuning.max_speed)
			result.velocity_after = velocity
	vitality_model.apply_delta(result.vitality_delta)
	result.vitality_after = vitality_model.current_vitality
	result.vitality_delta = result.vitality_after - result.vitality_before
	result.set_meta("geometry_contact", geometry_contact)
	var transferred: float = vitality_model.current_vitality - vitality_before
	# Surface response grants physical settle permission; Activity is committed last.
	if geometry_contact and collider.get_meta("toy_kind") == "platform" and normal.y < -0.98 \
		and result.velocity_before.length() <= tuning.rest_settle_speed \
		and vitality_model.vitality_ratio() <= tuning.rest_vitality_ratio:
		velocity = Vector2.ZERO
		result.velocity_after = velocity
		support_kind = SupportKind.GEOMETRY
		support_geometry = collider
		_clear_wake_sample()
		rest_elapsed_time = 0.0
		wake_consumed = false
		vitality_model.resolve_activity(true)
	elif result.settle_allowed and (was_resting or vitality_model.vitality_ratio() <= tuning.rest_vitality_ratio):
		_commit_resting_settle(SupportKind.GROUND)
	elif not was_resting:
		vitality_model.resolve_activity(false)
	_update_visuals()
	if result.valid_paddle_hit and tuning.shared_world_enabled and not tuning.legacy_rhythm_enabled:
		play_rhythm.note_input(tuning.continue_action_distance)
	surface_resolved.emit(result)
	if geometry_contact:
		geometry_contacts.on_contact_committed(collider, result, global_position)
	if result.valid_paddle_hit and transferred > 0.0:
		paddle_energy_transferred.emit(transferred)
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
	var vitality_before_wake: float = vitality_model.current_vitality
	if needs_start:
		# A discrete self-start, never proportional to input and never horizontal.
		velocity.y = -tuning.wake_launch_speed
		velocity = velocity.limit_length(tuning.max_speed)
	support_kind = SupportKind.NONE
	wake_consumed = true
	play_rhythm.consume()
	vitality_model.wake(vitality_model.current_vitality + vitality_model.max_vitality * tuning.wake_vitality_restore_ratio)
	var wake_transferred: float = vitality_model.current_vitality - vitality_before_wake
	_update_visuals()
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("play_wake_feedback"):
		visuals.play_wake_feedback()
	wake_committed.emit(1.0, true, global_position)
	if wake_transferred > 0.0:
		paddle_energy_transferred.emit(wake_transferred)
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
	if support_kind == SupportKind.NONE and is_instance_valid(support_geometry) and support_geometry.collision_layer != 0:
		var support_probe := KinematicCollision2D.new()
		if test_move(global_transform, Vector2.DOWN * 0.8, support_probe) and support_probe.get_collider() == support_geometry:
			support_kind = SupportKind.GEOMETRY
	if previous != SupportKind.NONE and support_kind == SupportKind.NONE:
		_clear_wake_sample()


func configure_geometry(source: Node) -> void:
	geometry_contacts = source


func clear_geometry_relationships() -> void:
	if is_instance_valid(geometry_contacts) and is_instance_valid(spring_hold) and geometry_contacts.has_method("cancel_spring_hold"):
		geometry_contacts.cancel_spring_hold(spring_hold)
	spring_hold = null
	_spring_elapsed = 0.0
	support_geometry = null
	support_kind = SupportKind.NONE


func geometry_supported_colliders() -> Array:
	var colliders: Array = []
	if support_kind == SupportKind.GEOMETRY and is_instance_valid(support_geometry):
		colliders.append(support_geometry)
	if is_instance_valid(spring_hold):
		colliders.append(spring_hold)
	return colliders


func _advance_spring_hold(delta: float) -> void:
	_spring_elapsed += delta
	var request: Dictionary = {}
	if is_instance_valid(geometry_contacts) and is_instance_valid(spring_hold):
		request = geometry_contacts.spring_hold_request(spring_hold, tuning.ball_radius)
	var release := bool(request.get("release", true)) or _spring_elapsed >= 1.2
	if request.get("position") is Vector2 and request.position.is_finite():
		var target: Vector2 = request.position + Vector2(_spring_offset_x, 0)
		if safe_center_bounds().has_point(target):
			# Sweep against all physical objects. A compressed head is a real moving surface.
			move_and_collide(target - global_position)
	velocity = Vector2.ZERO
	if release:
		var launch: Vector2 = request.get("velocity", Vector2(0, -500))
		if not launch.is_finite() or launch.y >= 0.0:
			launch = Vector2(0, -500)
		velocity = launch.limit_length(tuning.max_speed)
		var released := spring_hold
		spring_hold = null
		_spring_elapsed = 0.0
		support_kind = SupportKind.NONE
		if is_instance_valid(geometry_contacts) and is_instance_valid(released):
			geometry_contacts.end_spring_hold(released)
	_update_visuals()
	if not release:
		_record_motion(delta)
