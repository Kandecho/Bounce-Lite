extends Node2D

signal vitality_offered(amount: float, position: Vector2)
signal event_emitted(kind: String, position: Vector2, intensity: float)

const ROTOR_RADIUS := 24.0
const CHARGE_RADIUS := 27.0
const FADE_SECONDS := 0.65
const SPAWN_MARGIN := 22.0
const FIELD_RADIUS := 205.0
const MAX_ACCELERATION := 105.0
const CHARGE_COOLDOWN := 7.5
const CHARGE_AMOUNT := 0.32
const MINT := Color(0.37, 0.84, 0.76)
const AMBER := Color(1.0, 0.72, 0.39)

var rotor_position := Vector2(355, 335)
var charge_position := Vector2(615, 330)
var angular_velocity := 0.0
var rotor_angle := 0.0
var charge_remaining := 0.0
var enabled := true
var _time := 0.0
var _impact := 0.0
var _charge_flash := 0.0
var _arena := Rect2(0, 0, 960, 720)
var spawn_region := Rect2(72, 72, 816, 393)
var _rotor: StaticBody2D
var _charge: Area2D
var random_spawns_enabled := true
var rotor_state := "absent"
var charge_state := "absent"
var lifecycle_events: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _has_ball_context := false
var _ball_position := Vector2.ZERO
var _ball_radius := 16.0
var _states := {"rotor": "absent", "charge": "absent"}
var _timers := {"rotor": 0.2, "charge": 1.3}
var _alpha := {"rotor": 0.0, "charge": 0.0}
var geometry_toys: Node

func entity_envelopes() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for kind in ["rotor", "charge"]:
		if _states[kind] in ["absent", "fading"]: continue
		var radius := ROTOR_RADIUS if kind == "rotor" else CHARGE_RADIUS
		var point := rotor_position if kind == "rotor" else charge_position
		result.append(Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))
	return result

func _geometry_clear(point: Vector2, radius: float) -> bool:
	if is_instance_valid(geometry_toys):
		var bounds := Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		for envelope in geometry_toys.entity_envelopes():
			if bounds.intersects(envelope): return false
	return true

func reconcile_fixed_geometry() -> void:
	# Existing fixed controls keep their placements. Only the combined control
	# relocates a core whose old placement crosses a full geometry envelope.
	if random_spawns_enabled or not is_instance_valid(geometry_toys): return
	for kind in ["rotor", "charge"]:
		var radius := ROTOR_RADIUS if kind == "rotor" else CHARGE_RADIUS
		var point := rotor_position if kind == "rotor" else charge_position
		if _geometry_clear(point, radius): continue
		point = _candidate(kind)
		if point == Vector2.INF:
			push_error("No legal fixed coexistence placement for " + kind)
			continue
		if kind == "rotor":
			rotor_position = point
			_rotor.position = to_local(point)
		else:
			charge_position = point
			_charge.position = to_local(point)

func restart(seed_value: int) -> void:
	set_seed(seed_value)
	_time = 0.0
	angular_velocity = 0.0
	rotor_angle = 0.0
	charge_remaining = 0.0
	_impact = 0.0
	_charge_flash = 0.0
	lifecycle_events.clear()
	for kind in ["rotor", "charge"]:
		_set_state(kind, "absent" if random_spawns_enabled else "active")
		_alpha[kind] = 0.0 if random_spawns_enabled else 1.0
	_sync_interaction()

func export_snapshot() -> Dictionary:
	var journal: Array[Dictionary] = []
	for event in lifecycle_events:
		var entry: Dictionary = event.duplicate()
		if entry.position is Vector2: entry.position = [entry.position.x, entry.position.y]
		journal.append(entry)
	return {"rng_state": str(_rng.state), "rng_seed": str(_rng.seed), "time": _time,
		"random": random_spawns_enabled, "states": _states.duplicate(), "timers": _timers.duplicate(), "alpha": _alpha.duplicate(),
		"rotor": [rotor_position.x, rotor_position.y], "charge": [charge_position.x, charge_position.y],
		"spin": angular_velocity, "angle": rotor_angle, "cooldown": charge_remaining, "impact": _impact, "flash": _charge_flash,
		"journal": journal}

func restore_snapshot(data: Dictionary) -> bool:
	if not snapshot_valid(data): return false
	_rng.seed = int(data.rng_seed)
	_rng.state = int(data.rng_state)
	_time = float(data.time)
	random_spawns_enabled = bool(data.random)
	_states = data.states.duplicate()
	_timers = data.timers.duplicate()
	_alpha = data.alpha.duplicate()
	rotor_state = _states.rotor
	charge_state = _states.charge
	rotor_position = Vector2(data.rotor[0], data.rotor[1])
	charge_position = Vector2(data.charge[0], data.charge[1])
	angular_velocity = float(data.spin)
	rotor_angle = float(data.angle)
	charge_remaining = float(data.cooldown)
	_impact = float(data.impact)
	_charge_flash = float(data.flash)
	lifecycle_events.assign(data.journal)
	_rotor.position = to_local(rotor_position)
	_charge.position = to_local(charge_position)
	_sync_interaction()
	queue_redraw()
	return true

func snapshot_valid(data: Dictionary) -> bool:
	for key in ["rng_state", "rng_seed", "time", "random", "states", "timers", "alpha", "rotor", "charge", "spin", "angle", "cooldown", "impact", "flash", "journal"]:
		if not data.has(key): return false
	for kind in ["rotor", "charge"]:
		if not data.states is Dictionary or not data.timers is Dictionary or not data.alpha is Dictionary: return false
		if data.states.get(kind, "") not in ["absent", "appearing", "active", "waiting", "fading"]: return false
		if not data.timers.has(kind) or not data.alpha.has(kind): return false
		if not data[kind] is Array or data[kind].size() != 2: return false
		var point := Vector2(float(data[kind][0]), float(data[kind][1]))
		var radius := ROTOR_RADIUS if kind == "rotor" else CHARGE_RADIUS
		if not point.is_finite() or not spawn_region.encloses(Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2)): return false
	return data.journal is Array

func _init() -> void:
	_rng.randomize()
	_schedule_opening()

func set_seed(value: int) -> void:
	_rng.seed = value
	_schedule_opening()

func _schedule_opening() -> void:
	_timers.rotor = _rng.randf_range(0.15, 0.4)
	_timers.charge = _rng.randf_range(0.9, 1.6)

func set_ball_context(ball_position: Vector2, ball_radius: float) -> void:
	_ball_position = ball_position
	_ball_radius = maxf(0.0, ball_radius)
	_has_ball_context = true

func set_random_spawns_enabled(value: bool) -> void:
	random_spawns_enabled = value
	for kind in ["rotor", "charge"]:
		_set_state(kind, "absent" if value else "active")
		_alpha[kind] = 0.0 if value else 1.0
		_timers[kind] = 0.2 if kind == "rotor" else 1.3
	_sync_interaction()
	queue_redraw()

func _interactive(kind: String) -> bool:
	return enabled and _states[kind] in ["active", "waiting"]

func _set_state(kind: String, state: String) -> void:
	_states[kind] = state
	rotor_state = _states.rotor
	charge_state = _states.charge
	lifecycle_events.append({"time": _time, "object": kind, "state": state, "position": rotor_position if kind == "rotor" else charge_position})
	if lifecycle_events.size() > 256:
		lifecycle_events.pop_front()

func _sync_interaction() -> void:
	if is_instance_valid(_rotor):
		_rotor.set_deferred("collision_layer", 1 if _interactive("rotor") else 0)
		_charge.set_deferred("monitoring", _interactive("charge"))

func _candidate(kind: String) -> Vector2:
	var radius := ROTOR_RADIUS if kind == "rotor" else CHARGE_RADIUS
	var bounds := spawn_region.grow(-radius)
	if not bounds.has_area() or spawn_region.size.x < radius * 2.0 or spawn_region.size.y < radius * 2.0:
		return Vector2.INF
	var other := "charge" if kind == "rotor" else "rotor"
	var other_position := charge_position if kind == "rotor" else rotor_position
	for attempt in range(32):
		var point := bounds.position + Vector2(_rng.randf(), _rng.randf()) * bounds.size
		if point.distance_to(_ball_position) < radius + _ball_radius + SPAWN_MARGIN:
			continue
		if _states[other] != "absent" and point.distance_to(other_position) < ROTOR_RADIUS + CHARGE_RADIUS + SPAWN_MARGIN:
			continue
		if not _geometry_clear(point, radius): continue
		return point
	return Vector2.INF

func _advance_objects(delta: float) -> void:
	if not random_spawns_enabled or not _has_ball_context:
		return
	for kind in ["rotor", "charge"]:
		_timers[kind] -= delta
		var state: String = _states[kind]
		if state == "absent" and _timers[kind] <= 0.0:
			var point := _candidate(kind)
			if point == Vector2.INF:
				_timers[kind] = 0.7
				continue
			if kind == "rotor":
				rotor_position = point
				_rotor.position = to_local(point)
				angular_velocity = 0.0
			else:
				charge_position = point
				_charge.position = to_local(point)
				charge_remaining = 0.0
			_set_state(kind, "appearing")
			_timers[kind] = FADE_SECONDS
		elif state == "appearing":
			_alpha[kind] = clampf(1.0 - _timers[kind] / FADE_SECONDS, 0.0, 0.65)
			if _timers[kind] <= 0.0:
				# Recheck the ball before making an appearing solid interactive.
				var point := rotor_position if kind == "rotor" else charge_position
				var radius := ROTOR_RADIUS if kind == "rotor" else CHARGE_RADIUS
				if point.distance_to(_ball_position) < radius + _ball_radius + SPAWN_MARGIN or not _geometry_clear(point, radius):
					continue
				_set_state(kind, "active")
				_alpha[kind] = 1.0
				_timers[kind] = _rng.randf_range(16.0, 25.0) if kind == "rotor" else _rng.randf_range(12.0, 20.0)
				_sync_interaction()
		elif state == "active" and _timers[kind] <= 0.0:
			_set_state(kind, "waiting")
		elif state == "waiting":
			var point := rotor_position if kind == "rotor" else charge_position
			var safe_distance := FIELD_RADIUS + _ball_radius if kind == "rotor" else CHARGE_RADIUS + _ball_radius + SPAWN_MARGIN
			if point.distance_to(_ball_position) <= safe_distance or (kind == "rotor" and absf(angular_velocity) > 0.35):
				continue
			_set_state(kind, "fading")
			_timers[kind] = FADE_SECONDS
			_sync_interaction()
		elif state == "fading":
			_alpha[kind] = clampf(_timers[kind] / FADE_SECONDS, 0.0, 1.0)
			if _timers[kind] <= 0.0:
				_set_state(kind, "absent")
				_timers[kind] = _rng.randf_range(1.2, 3.0)

func configure(_tuning: Resource, arena_bounds: Rect2, valid_spawn_region := Rect2()) -> void:
	_arena = arena_bounds
	spawn_region = valid_spawn_region if valid_spawn_region.has_area() else arena_bounds
	# Fixed placements for now, expressed inside the valid spawn region.
	rotor_position = spawn_region.position + spawn_region.size * Vector2(0.27, 0.62)
	charge_position = spawn_region.position + spawn_region.size * Vector2(0.73, 0.60)
	if is_instance_valid(_rotor):
		_rotor.position = to_local(rotor_position)
		_charge.position = to_local(charge_position)

func _ready() -> void:
	_rotor = StaticBody2D.new()
	_rotor.name = "Rotor"
	_rotor.set_meta("surface_kind", 4)
	_rotor.collision_layer = 1 if _interactive("rotor") else 0
	_rotor.collision_mask = 2
	_rotor.position = to_local(rotor_position)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ROTOR_RADIUS
	shape.shape = circle
	_rotor.add_child(shape)
	add_child(_rotor)
	_charge = Area2D.new()
	_charge.name = "Charge"
	_charge.collision_layer = 0
	_charge.collision_mask = 2
	_charge.monitoring = _interactive("charge")
	_charge.position = to_local(charge_position)
	var charge_shape := CollisionShape2D.new()
	var charge_circle := CircleShape2D.new()
	charge_circle.radius = CHARGE_RADIUS
	charge_shape.shape = charge_circle
	_charge.add_child(charge_shape)
	_charge.body_entered.connect(_on_charge_body_entered)
	add_child(_charge)

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	_sync_interaction()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_time += delta
	_advance_objects(delta)
	angular_velocity *= exp(-delta * 0.19)
	rotor_angle = fposmod(rotor_angle + angular_velocity * delta, TAU)
	_impact = maxf(0.0, _impact - delta * 1.5)
	_charge_flash = maxf(0.0, _charge_flash - delta * 1.2)
	var was_empty := charge_remaining > 0.0
	charge_remaining = maxf(0.0, charge_remaining - delta)
	# A recovered seed offers again to a real resident overlap. No synthetic contact.
	if was_empty and charge_remaining == 0.0 and _interactive("charge"):
		event_emitted.emit("breeze", charge_position, 0.3)
		for body in _charge.get_overlapping_bodies():
			_on_charge_body_entered(body)
			if charge_remaining > 0.0:
				break
	queue_redraw()

func sample_acceleration(world_position: Vector2, _velocity: Vector2) -> Vector2:
	if not enabled or not _arena.has_point(world_position):
		return Vector2.ZERO
	var offset := world_position - rotor_position
	var distance := offset.length()
	var falloff := pow(maxf(0.0, 1.0 - distance / FIELD_RADIUS), 1.3)
	var tangent := Vector2(-offset.y, offset.x) / maxf(distance, 32.0)
	var turning := tangent * angular_velocity * 31.0 * falloff if _interactive("rotor") else Vector2.ZERO
	# Quiet breathing is deliberately too weak to replace a launch or maintain flight.
	var drift := Vector2(sin(_time * 0.23 + world_position.y * 0.008) * 8.0, -5.0)
	return (turning + drift).limit_length(MAX_ACCELERATION)

func on_surface_resolved(result: RefCounted, ball_position: Vector2) -> void:
	if not _interactive("rotor") or result.surface_kind != 4:
		return
	var offset := ball_position - rotor_position
	var incoming: Vector2 = result.velocity_before
	var torque := offset.normalized().cross(incoming) / 95.0
	if absf(torque) < 0.25:
		torque = (1.0 if incoming.x >= 0 else -1.0) * incoming.length() / 230.0
	angular_velocity = clampf(angular_velocity + torque, -4.2, 4.2)
	_impact = clampf(incoming.length() / 450.0, 0.15, 1.0)
	event_emitted.emit("rotor", rotor_position, _impact)
	queue_redraw()

func _on_charge_body_entered(body: Node2D) -> void:
	if not _interactive("charge") or charge_remaining > 0.0 or not body is PhysicsBody2D:
		return
	if (body.collision_layer & 2) == 0:
		return
	charge_remaining = CHARGE_COOLDOWN
	_charge_flash = 1.0
	vitality_offered.emit(CHARGE_AMOUNT, charge_position)
	event_emitted.emit("charge", charge_position, 1.0)
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	var center := to_local(rotor_position)
	var seed := to_local(charge_position)
	var spin := minf(absf(angular_velocity) / 4.2, 1.0)
	# Small advecting strokes show the same local tangent sampled by Physics.
	for ring in range(3):
		var radius := 58.0 + ring * 42.0
		for index in range(7):
			var angle := index * TAU / 7.0 + rotor_angle * (0.5 - ring * 0.1) + ring * 0.39 + _time * 0.025
			var arc_length := 0.055 + spin * 0.18
			draw_arc(center, radius, angle, angle + arc_length, 9, _tint("rotor", MINT, 0.055 + spin * 0.17), 1.2, true)
	for glow in range(5, 0, -1):
		draw_circle(center, 24.0 + glow * 4.0, _tint("rotor", MINT, (0.008 + _impact * 0.014) * (6 - glow)))
	draw_circle(center, ROTOR_RADIUS, _tint("rotor", Color(0.08, 0.16, 0.19), 1.0))
	draw_arc(center, ROTOR_RADIUS, 0, TAU, 64, _tint("rotor", MINT, 0.5 + _impact * 0.4), 1.2, true)
	for blade in range(3):
		var angle := rotor_angle + blade * TAU / 3.0
		var a := center + Vector2.from_angle(angle) * 7.0
		var b := center + Vector2.from_angle(angle + 0.32) * 21.0
		var c := center + Vector2.from_angle(angle + 1.15) * 17.0
		draw_colored_polygon(PackedVector2Array([a, b, c]), _tint("rotor", MINT, 0.43 + spin * 0.25))
	draw_circle(center, 3.2, _tint("rotor", MINT, 0.9))
	var fullness := 1.0 - charge_remaining / CHARGE_COOLDOWN
	var breath := 0.5 + sin(_time * 1.8) * 0.5
	for glow in range(6, 0, -1):
		draw_circle(seed, 13.0 + glow * 5.0, _tint("charge", AMBER, (0.008 + fullness * 0.012 + _charge_flash * 0.012) * (7 - glow)))
	draw_arc(seed, 26.0, -PI / 2.0, -PI / 2.0 + maxf(0.01, TAU * fullness), 64, _tint("charge", AMBER, 0.2 + fullness * 0.25), 1.1, true)
	var core := PackedVector2Array()
	for point in range(6):
		core.append(seed + Vector2.from_angle(point * TAU / 6.0 + _time * 0.08) * (8.0 + fullness * 3.0 + breath))
	draw_colored_polygon(core, _tint("charge", AMBER, 0.12 + fullness * 0.67))
	draw_circle(seed, 2.4, _tint("charge", Color(1.0, 0.92, 0.72), 0.3 + fullness * 0.7))

func _tint(kind: String, color: Color, opacity: float) -> Color:
	return Color(color, opacity * float(_alpha[kind]))
