extends Node2D

signal vitality_offered(amount: float, position: Vector2)
signal event_emitted(kind: String, position: Vector2, intensity: float)

const ROTOR_RADIUS := 24.0
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
var _arena := Rect2(173, 133, 615, 448)
var _rotor: StaticBody2D
var _charge: Area2D

func configure(_tuning: Resource, arena_bounds: Rect2) -> void:
	_arena = arena_bounds
	rotor_position = _arena.position + _arena.size * Vector2(0.296, 0.451)
	charge_position = _arena.position + _arena.size * Vector2(0.719, 0.44)
	if is_instance_valid(_rotor):
		_rotor.position = to_local(rotor_position)
		_charge.position = to_local(charge_position)

func _ready() -> void:
	_rotor = StaticBody2D.new()
	_rotor.name = "Rotor"
	_rotor.set_meta("surface_kind", 4)
	_rotor.collision_layer = 1 if enabled else 0
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
	_charge.monitoring = enabled
	_charge.position = to_local(charge_position)
	var charge_shape := CollisionShape2D.new()
	var charge_circle := CircleShape2D.new()
	charge_circle.radius = 27.0
	charge_shape.shape = charge_circle
	_charge.add_child(charge_shape)
	_charge.body_entered.connect(_on_charge_body_entered)
	add_child(_charge)

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if is_instance_valid(_rotor):
		_rotor.set_deferred("collision_layer", 1 if value else 0)
		_charge.set_deferred("monitoring", value)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_time += delta
	angular_velocity *= exp(-delta * 0.19)
	rotor_angle = fposmod(rotor_angle + angular_velocity * delta, TAU)
	_impact = maxf(0.0, _impact - delta * 1.5)
	_charge_flash = maxf(0.0, _charge_flash - delta * 1.2)
	var was_empty := charge_remaining > 0.0
	charge_remaining = maxf(0.0, charge_remaining - delta)
	# A recovered seed offers again to a real resident overlap. No synthetic contact.
	if was_empty and charge_remaining == 0.0:
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
	var turning := tangent * angular_velocity * 31.0 * falloff
	# Quiet breathing is deliberately too weak to replace a launch or maintain flight.
	var drift := Vector2(sin(_time * 0.23 + world_position.y * 0.008) * 8.0, -5.0)
	return (turning + drift).limit_length(MAX_ACCELERATION)

func on_surface_resolved(result: RefCounted, ball_position: Vector2) -> void:
	if not enabled or result.surface_kind != 4:
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
	if not enabled or charge_remaining > 0.0 or not body is PhysicsBody2D:
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
			draw_arc(center, radius, angle, angle + arc_length, 9, Color(MINT, 0.055 + spin * 0.17), 1.2, true)
	for glow in range(5, 0, -1):
		draw_circle(center, 24.0 + glow * 4.0, Color(MINT, (0.008 + _impact * 0.014) * (6 - glow)))
	draw_circle(center, ROTOR_RADIUS, Color(0.08, 0.16, 0.19))
	draw_arc(center, ROTOR_RADIUS, 0, TAU, 64, Color(MINT, 0.5 + _impact * 0.4), 1.2, true)
	for blade in range(3):
		var angle := rotor_angle + blade * TAU / 3.0
		var a := center + Vector2.from_angle(angle) * 7.0
		var b := center + Vector2.from_angle(angle + 0.32) * 21.0
		var c := center + Vector2.from_angle(angle + 1.15) * 17.0
		draw_colored_polygon(PackedVector2Array([a, b, c]), Color(MINT, 0.43 + spin * 0.25))
	draw_circle(center, 3.2, Color(MINT, 0.9))
	var fullness := 1.0 - charge_remaining / CHARGE_COOLDOWN
	var breath := 0.5 + sin(_time * 1.8) * 0.5
	for glow in range(6, 0, -1):
		draw_circle(seed, 13.0 + glow * 5.0, Color(AMBER, (0.008 + fullness * 0.012 + _charge_flash * 0.012) * (7 - glow)))
	draw_arc(seed, 26.0, -PI / 2.0, -PI / 2.0 + maxf(0.01, TAU * fullness), 64, Color(AMBER, 0.2 + fullness * 0.25), 1.1, true)
	var core := PackedVector2Array()
	for point in range(6):
		core.append(seed + Vector2.from_angle(point * TAU / 6.0 + _time * 0.08) * (8.0 + fullness * 3.0 + breath))
	draw_colored_polygon(core, Color(AMBER, 0.12 + fullness * 0.67))
	draw_circle(seed, 2.4, Color(1.0, 0.92, 0.72, 0.3 + fullness * 0.7))
