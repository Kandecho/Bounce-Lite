class_name EndlessRules
extends Node

const BallVitalityModelScript = preload("res://scripts/ball/ball_vitality_model.gd")
const SurfaceResponseModelScript = preload("res://scripts/physics/surface_response_model.gd")

signal combo_changed(value: int)
signal active_time_changed(seconds: float)
signal rest_started()
signal wake_started()

var combo: int = 0
var active_time_seconds: float = 0.0
var timer_running: bool = true


func _process(delta: float) -> void:
	advance_active_time(delta)


func handle_paddle_hit() -> void:
	combo += 1
	combo_changed.emit(combo)


func handle_surface_hit(kind: int) -> void:
	if kind == SurfaceResponseModelScript.SurfaceKind.GROUND:
		combo = 0
		combo_changed.emit(combo)


func handle_activity_state_changed(state: int) -> void:
	if state == BallVitalityModelScript.ActivityState.RESTING:
		timer_running = false
		rest_started.emit()


func begin_wake_cycle() -> void:
	active_time_seconds = 0.0
	timer_running = true
	active_time_changed.emit(active_time_seconds)
	wake_started.emit()


func advance_active_time(delta: float) -> void:
	if not timer_running or delta <= 0.0:
		return
	active_time_seconds += delta
	active_time_changed.emit(active_time_seconds)
