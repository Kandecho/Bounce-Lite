class_name BallVitalityModel
extends RefCounted

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")

signal activity_state_changed(previous: ActivityState, current: ActivityState)

enum ActivityState {
	ACTIVE,
	DECAYING,
	RESTING,
}

var tuning: Resource
var current_vitality: float = 0.0
var max_vitality: float = 1.0
var state: ActivityState = ActivityState.ACTIVE


func _init(source_tuning: Resource = null) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()
	max_vitality = maxf(tuning.max_vitality, 0.001)
	reset_active()


func reset_active() -> void:
	_set_vitality(max_vitality)
	_set_state(ActivityState.ACTIVE)


func set_vitality(value: float) -> void:
	_set_vitality(value)
	resolve_activity(false)


func apply_delta(delta: float) -> void:
	_set_vitality(current_vitality + delta)


func resolve_activity(settle_allowed: bool) -> void:
	var ratio := vitality_ratio()
	if settle_allowed and ratio <= tuning.rest_vitality_ratio:
		_set_state(ActivityState.RESTING)
	elif ratio < tuning.active_vitality_ratio:
		_set_state(ActivityState.DECAYING)
	else:
		_set_state(ActivityState.ACTIVE)


func wake(target_vitality: float) -> bool:
	if state != ActivityState.RESTING:
		return false
	_set_vitality(target_vitality)
	_set_state(ActivityState.ACTIVE)
	return state != ActivityState.RESTING


func vitality_ratio() -> float:
	return clampf(current_vitality / max_vitality, 0.0, 1.0)


func _set_vitality(value: float) -> void:
	current_vitality = clampf(value, 0.0, max_vitality)


func _set_state(value: ActivityState) -> void:
	if state == value:
		return
	var previous := state
	state = value
	activity_state_changed.emit(previous, state)
