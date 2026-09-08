class_name BallController
extends CharacterBody2D

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const BallEnergyModelScript = preload("res://scripts/ball/ball_energy_model.gd")

signal surface_hit(kind: int, energy_before: float, energy_after: float)
signal paddle_hit(energy_before: float, energy_after: float)
signal activity_state_changed(previous: int, current: int)

const MAX_COLLISIONS_PER_FRAME := 4
const MOTION_EPSILON := 0.001

var tuning: Resource = PrototypeTuningScript.new()
var energy_model: RefCounted
var direction: Vector2 = Vector2(0.65, -1.0).normalized()


func _ready() -> void:
	if energy_model == null:
		configure(tuning)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_update_visuals(false)


func _physics_process(delta: float) -> void:
	if energy_model == null or is_resting() or delta <= 0.0:
		velocity = Vector2.ZERO
		_update_visuals(false)
		return
	_sync_velocity_from_energy()
	var remaining_motion := velocity * delta
	for collision_index in range(MAX_COLLISIONS_PER_FRAME):
		if remaining_motion.length_squared() <= MOTION_EPSILON * MOTION_EPSILON:
			break
		var collision := move_and_collide(remaining_motion)
		if collision == null:
			break
		var normal := collision.get_normal()
		var collider := collision.get_collider()
		var kind: int = BallEnergyModelScript.SurfaceKind.WALL
		if collider != null and collider.has_meta("surface_kind"):
			kind = int(collider.get_meta("surface_kind"))
		var valid_paddle_hit := (
			kind == BallEnergyModelScript.SurfaceKind.PADDLE
			and direction.y > 0.0
			and normal.y < -0.5
		)
		var speed_before := maxf(velocity.length(), MOTION_EPSILON)
		resolve_surface_collision(kind, normal, valid_paddle_hit)
		if is_resting():
			break
		var speed_ratio := velocity.length() / speed_before
		remaining_motion = collision.get_remainder().bounce(normal) * speed_ratio
	_update_visuals(true)


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	energy_model = BallEnergyModelScript.new(tuning)
	energy_model.activity_state_changed.connect(_on_energy_state_changed)
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("configure"):
		visuals.configure(tuning)
	_sync_velocity_from_energy()


func start_active(initial_direction: Vector2) -> void:
	if energy_model == null:
		configure(tuning)
	energy_model.reset_active()
	set_direction(initial_direction)
	_sync_velocity_from_energy()


func set_direction(value: Vector2) -> void:
	direction = value.normalized()
	if direction.is_zero_approx():
		direction = Vector2(0.65, -1.0).normalized()
	_sync_velocity_from_energy()


func resolve_surface_collision(kind: int, normal: Vector2, valid_paddle_hit: bool) -> void:
	if energy_model == null:
		return
	var energy_before: float = energy_model.current_energy
	if not normal.is_zero_approx():
		direction = direction.bounce(normal.normalized()).normalized()
	if kind == BallEnergyModelScript.SurfaceKind.PADDLE and valid_paddle_hit:
		energy_model.restore_from_paddle()
		_sync_velocity_from_energy()
		paddle_hit.emit(energy_before, energy_model.current_energy)
		return
	var effective_kind := kind
	if kind == BallEnergyModelScript.SurfaceKind.PADDLE:
		effective_kind = BallEnergyModelScript.SurfaceKind.WALL
	energy_model.apply_environment_collision(effective_kind)
	_sync_velocity_from_energy()
	surface_hit.emit(effective_kind, energy_before, energy_model.current_energy)


func wake_from_paddle(paddle_velocity_x: float) -> bool:
	if energy_model == null or not energy_model.wake():
		return false
	var horizontal_sign := signf(paddle_velocity_x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = 1.0
	set_direction(Vector2(horizontal_sign * 0.35, -1.0))
	_sync_velocity_from_energy()
	return true


func is_resting() -> bool:
	return (
		energy_model != null
		and energy_model.state == BallEnergyModelScript.ActivityState.RESTING
	)


func _sync_velocity_from_energy() -> void:
	if energy_model == null or is_resting():
		velocity = Vector2.ZERO
		_update_visuals(false)
		return
	var speed: float = minf(energy_model.speed_for_current_energy(), tuning.max_speed)
	velocity = direction * speed
	_update_visuals(false)


func _on_energy_state_changed(previous: int, current: int) -> void:
	if current == BallEnergyModelScript.ActivityState.RESTING:
		velocity = Vector2.ZERO
	_update_visuals(false)
	activity_state_changed.emit(previous, current)


func _update_visuals(record_position: bool) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals == null or energy_model == null:
		return
	if visuals.has_method("set_activity"):
		visuals.set_activity(energy_model.activity_ratio(), energy_model.state)
	if record_position and visuals.has_method("record_ball_position"):
		visuals.record_ball_position(global_position)
