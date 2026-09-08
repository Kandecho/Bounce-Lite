class_name BallEnergyModel
extends RefCounted

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")

signal activity_state_changed(previous: ActivityState, current: ActivityState)

enum ActivityState {
	ACTIVE,
	DECAYING,
	RESTING,
}

enum SurfaceKind {
	WALL,
	TOP,
	GROUND,
	PADDLE,
}

var tuning: Resource
var current_energy: float = 0.0
var max_energy: float = 1.0
var state: ActivityState = ActivityState.ACTIVE


func _init(source_tuning: Resource = null) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	max_energy = maxf(tuning.max_energy, 0.001)
	reset_active()


func reset_active() -> void:
	_set_energy(max_energy)


func set_energy(value: float) -> void:
	_set_energy(value)


func speed_for_current_energy() -> float:
	var ratio := clampf(current_energy / max_energy, 0.0, 1.0)
	return minf(tuning.active_speed * sqrt(ratio), tuning.max_speed)


func energy_for_speed(speed: float) -> float:
	var safe_active_speed := maxf(tuning.active_speed, 0.001)
	var ratio := clampf(speed / safe_active_speed, 0.0, 1.0)
	return max_energy * ratio * ratio


func apply_environment_collision(kind: SurfaceKind) -> void:
	_set_energy(current_energy * _retention_for(kind))


func restore_from_paddle() -> void:
	_set_energy(max_energy)


func enter_rest_if_needed() -> bool:
	_refresh_state()
	return state == ActivityState.RESTING


func wake() -> bool:
	if state != ActivityState.RESTING:
		return false
	_set_energy(energy_for_speed(tuning.wake_speed))
	return state == ActivityState.ACTIVE


func activity_ratio() -> float:
	return clampf(speed_for_current_energy() / maxf(tuning.active_speed, 0.001), 0.0, 1.0)


func _retention_for(kind: SurfaceKind) -> float:
	match kind:
		SurfaceKind.WALL:
			return clampf(tuning.wall_energy_retention, 0.0, 1.0)
		SurfaceKind.TOP:
			return clampf(tuning.top_energy_retention, 0.0, 1.0)
		SurfaceKind.GROUND:
			return clampf(tuning.ground_energy_retention, 0.0, 1.0)
		_:
			return 1.0


func _set_energy(value: float) -> void:
	current_energy = clampf(value, 0.0, max_energy)
	_refresh_state()


func _refresh_state() -> void:
	var previous := state
	var rest_threshold := energy_for_speed(tuning.rest_threshold_speed)
	var active_threshold := energy_for_speed(tuning.active_threshold_speed)
	if current_energy <= rest_threshold:
		state = ActivityState.RESTING
	elif current_energy < active_threshold:
		state = ActivityState.DECAYING
	else:
		state = ActivityState.ACTIVE
	if previous != state:
		activity_state_changed.emit(previous, state)
