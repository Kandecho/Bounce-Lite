class_name RuntimeTuningPanel
extends PanelContainer

const PARAMETER_SPECS: Array[Dictionary] = [
	{
		"group": "PHYSICS",
		"id": "gravity_acceleration",
		"label": "Gravity",
		"target": "gravity_acceleration",
		"minimum": 0.0,
		"maximum": 3000.0,
		"step": 10.0,
	},
	{
		"group": "PHYSICS",
		"id": "max_speed",
		"label": "Max velocity",
		"target": "max_speed",
		"minimum": 1.0,
		"maximum": 2000.0,
		"step": 10.0,
	},
	{
		"group": "PHYSICS",
		"id": "paddle_impulse",
		"label": "Paddle impulse",
		"target": "paddle_impulse",
		"minimum": 0.0,
		"maximum": 1000.0,
		"step": 10.0,
	},
	{
		"group": "SURFACE RESPONSE",
		"id": "wall_restitution_max",
		"label": "Wall restitution max",
		"target": "wall_restitution_max",
		"minimum": 0.0,
		"maximum": 1.0,
		"step": 0.005,
	},
	{
		"group": "SURFACE RESPONSE",
		"id": "ground_restitution_max",
		"label": "Ground restitution max",
		"target": "ground_restitution_max",
		"minimum": 0.0,
		"maximum": 1.0,
		"step": 0.01,
	},
	{
		"group": "VITALITY",
		"id": "wall_vitality_loss",
		"label": "Wall vitality loss",
		"target": "wall_vitality_retention",
		"minimum": 0.0,
		"maximum": 1.0,
		"step": 0.005,
		"invert": true,
	},
	{
		"group": "VITALITY",
		"id": "ground_vitality_loss",
		"label": "Ground vitality loss",
		"target": "ground_vitality_retention",
		"minimum": 0.0,
		"maximum": 1.0,
		"step": 0.01,
		"invert": true,
	},
	{
		"group": "VITALITY",
		"id": "paddle_vitality_restore",
		"label": "Paddle vitality restore",
		"target": "paddle_vitality_restore",
		"minimum": 0.0,
		"maximum": 1.0,
		"step": 0.05,
	},
]

var tuning: Resource
var _controls: Dictionary = {}
var _specs_by_id: Dictionary = {}
var _ui_built := false


func _init() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)


func _ready() -> void:
	_ensure_ui()
	_sync_from_tuning()


func configure(source_tuning: Resource) -> void:
	tuning = source_tuning
	_ensure_ui()
	_sync_from_tuning()


func has_parameter(parameter_id: String) -> bool:
	return _controls.has(parameter_id)


func set_parameter_value(parameter_id: String, value: float) -> bool:
	var spin_box: SpinBox = _controls.get(parameter_id)
	if spin_box == null:
		return false
	var clamped_value := clampf(value, spin_box.min_value, spin_box.max_value)
	spin_box.set_value_no_signal(clamped_value)
	_apply_parameter_value(parameter_id, clamped_value)
	return true


func handle_toggle_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	if key_event.keycode != KEY_F1 and key_event.physical_keycode != KEY_F1:
		return false
	visible = not visible
	return true


func _input(event: InputEvent) -> void:
	if not handle_toggle_event(event):
		return
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	custom_minimum_size = Vector2(326.0, 0.0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.045, 0.065, 0.96)
	panel_style.border_color = Color(0.42, 0.50, 0.64, 0.75)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title := Label.new()
	title.text = "RUNTIME PHYSICS TUNING"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	content.add_child(title)

	var hint := Label.new()
	hint.text = "F1 · temporary · not saved"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.63, 0.69, 0.79))
	content.add_child(hint)

	var active_group := ""
	var grid: GridContainer
	for spec in PARAMETER_SPECS:
		var group_name: String = spec["group"]
		if group_name != active_group:
			active_group = group_name
			var group_label := Label.new()
			group_label.text = group_name
			group_label.add_theme_font_size_override("font_size", 12)
			group_label.add_theme_color_override("font_color", Color(0.56, 0.78, 0.96))
			content.add_child(group_label)
			grid = GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 4)
			content.add_child(grid)
		_add_parameter_row(grid, spec)


func _add_parameter_row(grid: GridContainer, spec: Dictionary) -> void:
	var parameter_id: String = spec["id"]
	var label := Label.new()
	label.text = spec["label"]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	grid.add_child(label)

	var spin_box := SpinBox.new()
	spin_box.custom_minimum_size = Vector2(112.0, 30.0)
	spin_box.min_value = spec["minimum"]
	spin_box.max_value = spec["maximum"]
	spin_box.step = spec["step"]
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.update_on_text_changed = true
	spin_box.value_changed.connect(_on_parameter_value_changed.bind(parameter_id))
	grid.add_child(spin_box)
	_controls[parameter_id] = spin_box
	_specs_by_id[parameter_id] = spec


func _sync_from_tuning() -> void:
	if tuning == null:
		return
	for parameter_id in _controls:
		var spec: Dictionary = _specs_by_id[parameter_id]
		var target: String = spec["target"]
		var display_value := float(tuning.get(target))
		if spec.get("invert", false):
			display_value = 1.0 - display_value
		var spin_box: SpinBox = _controls[parameter_id]
		spin_box.set_value_no_signal(display_value)


func _on_parameter_value_changed(value: float, parameter_id: String) -> void:
	_apply_parameter_value(parameter_id, value)


func _apply_parameter_value(parameter_id: String, display_value: float) -> void:
	if tuning == null or not _specs_by_id.has(parameter_id):
		return
	var spec: Dictionary = _specs_by_id[parameter_id]
	var target: String = spec["target"]
	var stored_value := display_value
	if spec.get("invert", false):
		stored_value = 1.0 - display_value
	tuning.set(target, stored_value)
