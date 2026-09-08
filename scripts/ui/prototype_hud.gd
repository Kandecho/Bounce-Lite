class_name PrototypeHUD
extends CanvasLayer

var combo_value: int = 0
var active_time_seconds: float = 0.0

@onready var combo_label: Label = $ComboLabel
@onready var timer_label: Label = $TimerLabel


func _ready() -> void:
	_refresh_combo()
	_refresh_timer()


func set_combo(value: int) -> void:
	combo_value = maxi(value, 0)
	_refresh_combo()


func set_active_time(value: float) -> void:
	active_time_seconds = maxf(value, 0.0)
	_refresh_timer()


static func format_time(seconds: float) -> String:
	var whole_seconds := maxi(floori(maxf(seconds, 0.0)), 0)
	var minutes := whole_seconds / 60
	var remaining_seconds := whole_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _refresh_combo() -> void:
	if is_instance_valid(combo_label):
		combo_label.text = "COMBO %d" % combo_value


func _refresh_timer() -> void:
	if is_instance_valid(timer_label):
		timer_label.text = "TIME %s" % format_time(active_time_seconds)
