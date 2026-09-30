extends Node2D

signal event_emitted(kind: String, position: Vector2, intensity: float)

# Lifecycle and JSON reproducibility adapted from the random playground 4947b67.
# This module contains only the first harvest geometry/mechanical family.
const Tuning = preload("res://scripts/config/prototype_tuning.gd")
const FADE_TIME := 0.65
const KINDS := ["bumper", "sling", "ramp", "platform", "spring", "seesaw"]
const PALETTE := {"bumper": Color("efba69"), "sling": Color("e68a83"), "ramp": Color("85bcb2"), "platform": Color("9cbbcc"), "spring": Color("72c9e8"), "seesaw": Color("d6b284")}
const SNAPSHOT_PROFILE := "geometry-refinement-v2"
@export var spring_hold_seconds := 0.20
@export var spring_recapture_delay := 1.0
@export var spring_compression_travel := 14.0
@export var seesaw_max_angle := 0.34
@export var seesaw_max_angular_velocity := 1.8
@export var seesaw_impulse_inertia := 24000.0
@export var seesaw_damping := 3.5
@export var seesaw_return_strength := 1.8
@export var seesaw_pivot_variation := 18.0
@export var bottom_geometry_clearance := 150.0
@export var paddle_path_clearance := 18.0
var _arena := Rect2(0, 0, 960, 720)
var _toys: Array[StaticBody2D] = []
var _balls: Array[Dictionary] = []
var _clock := 0.0
var _next_id := 0
var layout := 0
var random_mode := false
var lifecycle_events: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.1
var _paddle_position := Vector2.INF
var _paddle_size := Vector2.ZERO
var _supported_colliders: Array = []
var tuning: Resource = Tuning.new()
var play_world: Node

func entity_envelopes() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for body in _toys:
		if body.get_meta("phase", "active") == "fading": continue
		var bounds := _spawn_shape(body.get_meta("toy_kind"), body.get_meta("kick")).get_rect()
		result.append(Rect2(body.global_position + bounds.position, bounds.size))
	return result

func configure_tuning(source: Resource) -> void:
	tuning = source if source != null else Tuning.new()

func set_supported_colliders(colliders: Array) -> void:
	_supported_colliders = colliders.duplicate()

func begin_spring_hold(collider: Object) -> bool:
	if not _owned(collider) or collider.get_meta("toy_kind") != "spring" or collider.get_meta("cooldown") > 0.0 or collider.get_meta("holding"):
		return false
	collider.set_meta("holding", true)
	collider.set_meta("hold_elapsed", 0.0)
	event_emitted.emit("toy_spring_seat", collider.global_position, 0.6)
	return true

func spring_hold_request(collider: Object, ball_radius: float) -> Dictionary:
	if not _owned(collider) or not collider.get_meta("holding", false):
		return {"release": true}
	var top := -12.0 + float(collider.get_meta("compression")) * spring_compression_travel
	return {"position": collider.global_position + Vector2(0, top - ball_radius - 0.6), "release": float(collider.get_meta("hold_elapsed")) >= spring_hold_seconds}

func end_spring_hold(collider: Object) -> void:
	if not is_instance_valid(collider) or collider not in _toys:
		return
	collider.set_meta("holding", false)
	collider.set_meta("cooldown", spring_recapture_delay)
	collider.set_meta("flash", 1.0)
	event_emitted.emit("toy_spring_release", collider.global_position, 1.0)

func cancel_spring_hold(collider: Object) -> void:
	if not is_instance_valid(collider) or collider not in _toys:
		return
	collider.set_meta("holding", false)
	collider.set_meta("hold_elapsed", 0.0)
	collider.set_meta("cooldown", spring_recapture_delay)

func clear_spring_holds() -> void:
	for body in _toys:
		if body.get_meta("holding"):
			cancel_spring_hold(body)

func _engaged(body: StaticBody2D) -> bool:
	return bool(body.get_meta("holding")) or (body.get_meta("toy_kind") == "platform" and body in _supported_colliders)

func _bottom_limit() -> float:
	var limit := _arena.end.y - bottom_geometry_clearance
	if _paddle_size.y > 0.0:
		# The gap is a Ball passage, so geometry's full envelope must clear
		# the Paddle path by at least a Ball diameter plus contact tolerance.
		var ball_passage: float = tuning.ball_radius * 2.0 + 2.0
		limit = minf(limit, _paddle_position.y - _paddle_size.y * 0.5 - maxf(paddle_path_clearance, ball_passage))
	return limit
func set_paddle_context(position: Vector2, size: Vector2) -> void:
	_paddle_position = position
	_paddle_size = size

func set_random_mode(value: bool, seed_value: int) -> void:
	set_layout(0)
	random_mode = value
	_rng.seed = seed_value
	_spawn_timer = 0.1
	_clock = 0.0
	_next_id = 0
	lifecycle_events.clear()

func _log_phase(body: StaticBody2D, phase: String) -> void:
	lifecycle_events.append({"time": _clock, "id": body.get_meta("toy_id"), "kind": body.get_meta("toy_kind"), "phase": phase, "position": [body.global_position.x, body.global_position.y], "lifetime": body.get_meta("lifetime", 0.0)})
	if lifecycle_events.size() > 512:
		lifecycle_events.pop_front()

func _spawn_shape(kind: String, kick: Vector2) -> Shape2D:
	if kind in ["bumper"]:
		var circle := CircleShape2D.new()
		circle.radius = 27.0
		return circle
	if kind in ["sling", "ramp"]:
		var triangle := ConvexPolygonShape2D.new()
		triangle.points = _polygon(kind, kick)
		return triangle
	var box := RectangleShape2D.new()
	box.size = Vector2(2.0 * (75.0 + seesaw_pivot_variation + 1.0), 2.0 * ((75.0 + seesaw_pivot_variation) * sin(seesaw_max_angle) + 8.0)) if kind == "seesaw" else _box_size(kind)
	return box

func _legal_point(kind: String, point: Vector2, kick: Vector2, ignore: StaticBody2D = null) -> bool:
	var shape := _spawn_shape(kind, kick)
	var envelope := shape.get_rect()
	var allowed := _arena.grow(-3.0)
	allowed.position.y += 34.0
	allowed.size.y -= 34.0
	allowed.size.y = maxf(0.0, _bottom_limit() - allowed.position.y)
	if not allowed.encloses(Rect2(point + envelope.position, envelope.size)):
		return false
	if is_instance_valid(play_world):
		for bounds in play_world.entity_envelopes():
			if Rect2(point + envelope.position, envelope.size).intersects(bounds): return false
	var transform := Transform2D(0.0, point)
	for ball in _balls:
		var circle := CircleShape2D.new()
		circle.radius = float(ball.get("radius", 16.0)) + 2.0
		if shape.collide(transform, circle, Transform2D(0.0, ball.get("position", Vector2.ZERO))):
			return false
	if _paddle_size.x > 0.0:
		var paddle := RectangleShape2D.new()
		paddle.size = _paddle_size + Vector2(4, 4)
		if shape.collide(transform, paddle, Transform2D(0.0, _paddle_position)):
			return false
	for other in _toys:
		if other == ignore or other.get_meta("phase", "active") == "fading":
			continue
		var other_shape := _spawn_shape(other.get_meta("toy_kind"), other.get_meta("kick"))
		if shape.collide(transform, other_shape, Transform2D(0.0, other.global_position)):
			return false
	return true

func configure(arena: Rect2) -> void:
	_arena = arena

func set_ball_context(position: Vector2, radius: float) -> void:
	_balls = [{"position": position, "radius": radius}]

func set_balls_context(balls: Array[Dictionary]) -> void:
	_balls = balls.duplicate()

func set_layout(preset: int) -> void:
	random_mode = false
	for body in _toys:
		body.collision_layer = 0
		body.set_meta("active", false)
		remove_child(body)
		body.queue_free()
	_toys.clear()
	layout = preset
	if preset != 0:
		_add("bumper", Vector2(250, 300))
		_add("sling", Vector2(730, 410), Vector2(-1, -1))
		_add("ramp", Vector2(460, 290), Vector2(1, -1))
		_add("platform", Vector2(700, 230))
		_add("spring", Vector2(250, 460))
		_add("seesaw", Vector2(500, 420))
	queue_redraw()

func _polygon(kind: String, kick: Vector2) -> PackedVector2Array:
	var side := 1.0 if kick.x > 0.0 else -1.0
	if kind == "ramp":
		return PackedVector2Array([Vector2(-58 * side, -24), Vector2(58 * side, 24), Vector2(-58 * side, 24)])
	return PackedVector2Array([Vector2(-32 * side, -36), Vector2(32 * side, 36), Vector2(-32 * side, 36)])

func _box_size(kind: String) -> Vector2:
	match kind:
		"spring": return Vector2(78, 24)
		"seesaw": return Vector2(150, 14)
	return Vector2(116, 16)

func _add(kind: String, point: Vector2, kick := Vector2.UP) -> void:
	var body := StaticBody2D.new()
	body.name = "Geometry_%s_%d" % [kind, _next_id]
	body.position = to_local(_arena.position + point * _arena.size / Vector2(960, 720))
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("toy_kind", kind)
	body.set_meta("toy_id", _next_id)
	body.set_meta("surface_kind", 0)
	body.set_meta("kick", kick.normalized())
	body.set_meta("active", true)
	body.set_meta("phase", "active")
	body.set_meta("holding", false)
	body.set_meta("expired_pending", false)
	for key in ["compression", "flash", "cooldown", "phase_time", "lifetime", "remaining", "hold_elapsed", "angular_velocity", "pivot_offset"]:
		body.set_meta(key, 0.0)
	_next_id += 1
	var collider := CollisionShape2D.new()
	if kind == "seesaw":
		var box := RectangleShape2D.new()
		box.size = _box_size(kind)
		collider.shape = box
	else:
		collider.shape = _spawn_shape(kind, kick)
	body.add_child(collider)
	add_child(body)
	_toys.append(body)

func _owned(body: Object) -> bool:
	return is_instance_valid(body) and body is StaticBody2D and body in _toys and body.get_meta("active", false)

func contact_request(result: RefCounted, collider: Object, ball_position: Vector2) -> Dictionary:
	if not _owned(collider):
		return {}
	var incoming: Vector2 = result.velocity_before
	var normal: Vector2 = result.normal.normalized()
	if normal.length_squared() < 0.1:
		normal = (ball_position - collider.global_position).normalized()
	if normal.length_squared() < 0.1:
		normal = Vector2.UP
	var output := incoming.bounce(normal)
	var kind: String = collider.get_meta("toy_kind")
	var ready: bool = collider.get_meta("cooldown") <= 0.0
	if ready and kind == "bumper":
		# Preserve the tangent; the circular contact normal explains the extra rebound.
		output += normal * maxf(0.0, tuning.bumper_normal_speed - output.dot(normal))
	elif ready and kind == "sling" and normal.y < -0.3 and absf(normal.x) > 0.3:
		output += normal * maxf(0.0, tuning.sling_normal_speed - output.dot(normal))
	elif ready and kind == "spring" and normal.y < -0.8 and incoming.dot(normal) < -tuning.spring_capture_speed and not collider.get_meta("holding"):
		return {"velocity": Vector2.ZERO, "vitality_delta": 0.0, "spring_capture": collider}
	elif kind == "seesaw":
		# Moving surface response comes from the same angular motion drawn on screen.
		var omega: float = collider.get_meta("angular_velocity")
		var offset: Vector2 = ball_position - collider.global_position
		var surface_velocity := Vector2(-offset.y, offset.x) * omega
		output = (incoming - surface_velocity).bounce(normal) + surface_velocity
		# The normal exchange is physical contact; later global speed clipping is not.
		result.set_meta("seesaw_normal_exchange", (incoming - output).dot(normal))
	return {"velocity": output, "vitality_delta": 0.0}

func on_contact_committed(collider: Object, result: RefCounted, ball_position: Vector2) -> void:
	if not _owned(collider) or collider.get_meta("cooldown") > 0.0:
		return
	collider.set_meta("cooldown", 0.12)
	if collider.get_meta("toy_kind") == "seesaw":
		var lever: Vector2 = ball_position - collider.global_position
		var impulse: Vector2 = result.normal.normalized() * float(result.get_meta("seesaw_normal_exchange", 0.0))
		collider.set_meta("angular_velocity", clampf(float(collider.get_meta("angular_velocity")) + lever.cross(impulse) / seesaw_impulse_inertia, -seesaw_max_angular_velocity, seesaw_max_angular_velocity))
	collider.set_meta("flash", clampf(result.velocity_before.length() / 450.0, 0.2, 1.0))
	if not collider.get_meta("holding"):
		event_emitted.emit("toy_" + str(collider.get_meta("toy_kind")), collider.global_position, collider.get_meta("flash"))
	queue_redraw()

func _physics_process(delta: float) -> void:
	_clock += delta
	if random_mode:
		_random_tick(delta)
	for body in _toys:
		if body.get_meta("holding"):
			var before: float = body.get_meta("hold_elapsed")
			body.set_meta("hold_elapsed", float(body.get_meta("hold_elapsed")) + delta)
			if before < spring_hold_seconds * 0.2 and float(body.get_meta("hold_elapsed")) >= spring_hold_seconds * 0.2:
				event_emitted.emit("toy_spring_compress", body.global_position, 0.7)
			body.set_meta("compression", clampf(float(body.get_meta("hold_elapsed")) / spring_hold_seconds, 0.0, 1.0))
		else:
			body.set_meta("compression", maxf(0.0, float(body.get_meta("compression")) - delta * 8.0))
		body.set_meta("flash", maxf(0.0, float(body.get_meta("flash")) - delta * 3.6))
		body.set_meta("cooldown", maxf(0.0, float(body.get_meta("cooldown")) - delta))
		if body.get_meta("toy_kind") == "seesaw":
			var omega: float = body.get_meta("angular_velocity")
			omega = (omega - body.rotation * seesaw_return_strength * delta) * exp(-seesaw_damping * delta)
			body.rotation = clampf(body.rotation + omega * delta, -seesaw_max_angle, seesaw_max_angle)
			if absf(body.rotation) >= seesaw_max_angle and signf(omega) == signf(body.rotation): omega = 0.0
			if absf(body.rotation) < 0.0001 and absf(omega) < 0.0001:
				body.rotation = 0.0
				omega = 0.0
			body.set_meta("angular_velocity", omega)
		_sync_mechanical_shape(body)
	queue_redraw()

func _sync_mechanical_shape(body: StaticBody2D) -> void:
	var collider: CollisionShape2D = body.get_child(0)
	if body.get_meta("toy_kind") == "seesaw":
		collider.position = Vector2(-float(body.get_meta("pivot_offset")), 0)
	elif body.get_meta("toy_kind") == "spring":
		var travel := float(body.get_meta("compression")) * spring_compression_travel
		collider.position.y = travel * 0.5
		collider.shape.size.y = 24.0 - travel

func _shade(color: Color, opacity: float) -> Color:
	return Color(color, color.a * opacity)

func _draw() -> void:
	for body in _toys:
		var kind: String = body.get_meta("toy_kind")
		var color: Color = PALETTE[kind]
		var phase: String = body.get_meta("phase")
		if phase == "appearing":
			color.a *= minf(0.5, float(body.get_meta("phase_time")) / FADE_TIME)
		elif phase == "fading":
			color.a *= maxf(0.0, 1.0 - float(body.get_meta("phase_time")) / FADE_TIME)
		var flash: float = body.get_meta("flash")
		var line := color.lerp(Color.WHITE, flash * 0.6)
		line.a = color.a
		if kind == "seesaw":
			draw_set_transform(body.position)
			draw_colored_polygon(PackedVector2Array([Vector2(0, 5), Vector2(-12, 29), Vector2(12, 29)]), _shade(color, 0.4))
		draw_set_transform(body.position, body.rotation)
		if kind == "seesaw":
			draw_set_transform(body.position + Vector2(-float(body.get_meta("pivot_offset")), 0).rotated(body.rotation), body.rotation)
		if kind == "bumper":
			draw_circle(Vector2.ZERO, 27, _shade(color, 0.16))
			draw_arc(Vector2.ZERO, 27, 0, TAU, 56, line, 2.6, true)
			draw_circle(Vector2.ZERO, 14 + flash * 5, _shade(line, 0.85))
			if flash > 0.0:
				draw_arc(Vector2.ZERO, 29 + (1 - flash) * 15, 0, TAU, 56, _shade(color, flash * 0.4), 2.0, true)
		elif kind in ["ramp", "sling"]:
			var points := _polygon(kind, body.get_meta("kick"))
			draw_colored_polygon(points, _shade(color, 0.13 + flash * 0.12))
			var outline := points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, _shade(line, 0.6), 1.7, true)
			draw_line(points[0], points[1], line, 3.3 if kind == "sling" else 2.3, true)
			if kind == "sling":
				var midpoint := (points[0] + points[1]) * 0.5
				var outward := Vector2(points[1].y - points[0].y, points[0].x - points[1].x).normalized()
				if outward.y > 0: outward = -outward
				draw_line(midpoint - outward * 7, midpoint - outward * 15, line, 2.0, true)
		else:
			var size := _box_size(kind)
			var rect := Rect2(-size / 2, size)
			if kind == "spring":
				rect.position.y += float(body.get_meta("compression")) * spring_compression_travel
				rect.size.y -= float(body.get_meta("compression")) * spring_compression_travel
			draw_rect(rect, _shade(color, 0.12))
			draw_rect(rect, _shade(line, 0.65), false, 1.5)
			draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), line, 2.7, true)
			if kind == "spring":
				var coil := PackedVector2Array()
				for index in range(9):
					coil.append(Vector2(-28 + index * 7, rect.get_center().y + (1 if index % 2 == 0 else -1) * (rect.size.y * 0.3)))
				draw_polyline(coil, line, 1.8, true)
				draw_line(Vector2(-31, 9), Vector2(31, 9), _shade(line, 0.5), 1.5, true)
			elif kind == "seesaw":
				draw_circle(Vector2(float(body.get_meta("pivot_offset")), 0), 4.0, line)
		draw_set_transform(Vector2.ZERO)

func _try_spawn() -> bool:
	if _balls.is_empty() or _toys.size() >= 6:
		return false
	var kind: String = KINDS[_rng.randi_range(0, KINDS.size() - 1)]
	var kick := Vector2(-1 if _rng.randf() < 0.5 else 1, -1).normalized()
	for attempt in range(24):
		var point := _arena.position + Vector2(_rng.randf(), _rng.randf()) * _arena.size
		if not _legal_point(kind, point, kick):
			continue
		_add(kind, (point - _arena.position) / _arena.size * Vector2(960, 720), kick)
		var body: StaticBody2D = _toys.back()
		body.set_meta("phase", "appearing")
		body.set_meta("phase_time", 0.0)
		body.set_meta("lifetime", _rng.randf_range(10.0, 24.0))
		body.set_meta("remaining", body.get_meta("lifetime"))
		if kind == "seesaw":
			body.set_meta("pivot_offset", _rng.randi_range(-1, 1) * seesaw_pivot_variation)
			_sync_mechanical_shape(body)
		body.set_meta("active", false)
		body.collision_layer = 0
		_log_phase(body, "appearing")
		return true
	return false

func _random_tick(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var spawned := _try_spawn()
		_spawn_timer = (0.45 if _next_id < 3 else _rng.randf_range(1.5, 3.5)) if spawned else 0.5
	for body in _toys.duplicate():
		body.set_meta("remaining", body.get_meta("remaining") - delta)
		body.set_meta("phase_time", body.get_meta("phase_time") + delta)
		var phase: String = body.get_meta("phase")
		if phase == "appearing" and body.get_meta("phase_time") >= FADE_TIME:
			if _legal_point(body.get_meta("toy_kind"), body.global_position, body.get_meta("kick"), body):
				body.set_meta("phase", "active")
				body.set_meta("active", true)
				body.collision_layer = 1
				_log_phase(body, "active")
		if phase != "fading" and body.get_meta("remaining") <= 0.0:
			if _engaged(body):
				body.set_meta("expired_pending", true)
				continue
			body.set_meta("expired_pending", false)
			body.set_meta("phase", "fading")
			body.set_meta("phase_time", 0.0)
			body.set_meta("active", false)
			body.collision_layer = 0
			_log_phase(body, "fading")
		elif phase == "fading" and body.get_meta("phase_time") >= FADE_TIME:
			_log_phase(body, "removed")
			_toys.erase(body)
			remove_child(body)
			body.queue_free()

func export_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for body in _toys:
		var point := body.global_position
		var kick: Vector2 = body.get_meta("kick")
		var entry := {"kind": body.get_meta("toy_kind"), "id": body.get_meta("toy_id"), "position": [point.x, point.y], "kick": [kick.x, kick.y], "rotation": body.rotation}
		for key in ["compression", "flash", "cooldown", "active", "phase", "phase_time", "lifetime", "remaining", "angular_velocity", "pivot_offset", "hold_elapsed", "holding", "expired_pending"]:
			entry[key] = body.get_meta(key)
		entries.append(entry)
	return {"version": 2, "profile": SNAPSHOT_PROFILE, "random_mode": random_mode, "layout": layout, "clock": _clock, "spawn_timer": _spawn_timer, "next_id": _next_id, "rng_seed": str(_rng.seed), "rng_state": str(_rng.state), "toys": entries}

func restore_snapshot(data: Dictionary) -> bool:
	if data.get("version") != 2 or data.get("profile") != SNAPSHOT_PROFILE or not data.get("toys") is Array or data.toys.size() > 24:
		return false
	for entry in data.toys:
		if not entry is Dictionary or not entry.get("kind") in KINDS or not entry.get("position") is Array or entry.position.size() != 2 or not entry.get("kick") is Array or entry.kick.size() != 2:
			return false
		if not entry.has("id") or not entry.get("phase", "active") in ["appearing", "active", "fading"]:
			return false
		for value in entry.position + entry.kick:
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
		for key in ["id", "compression", "flash", "cooldown", "phase_time", "lifetime", "remaining", "angular_velocity", "pivot_offset", "hold_elapsed", "rotation"]:
			var value: Variant = entry.get(key, 0.0)
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
		var point := Vector2(float(entry.position[0]), float(entry.position[1]))
		var envelope := _spawn_shape(entry.kind, Vector2(float(entry.kick[0]), float(entry.kick[1]))).get_rect()
		if point.y + envelope.end.y > _bottom_limit() or absf(float(entry.get("pivot_offset", 0))) > seesaw_pivot_variation or absf(float(entry.get("rotation", 0))) > seesaw_max_angle or absf(float(entry.get("angular_velocity", 0))) > seesaw_max_angular_velocity:
			return false
	if bool(data.get("random_mode", false)) and data.toys.size() > 6:
		return false
	set_layout(0)
	random_mode = bool(data.get("random_mode", false))
	layout = int(data.get("layout", 0))
	_clock = float(data.get("clock", 0.0))
	_spawn_timer = float(data.get("spawn_timer", 0.5))
	for entry in data.toys:
		var point := Vector2(float(entry.position[0]), float(entry.position[1]))
		_add(entry.kind, (point - _arena.position) / _arena.size * Vector2(960, 720), Vector2(float(entry.kick[0]), float(entry.kick[1])))
		var body: StaticBody2D = _toys.back()
		body.set_meta("toy_id", int(entry.id))
		for key in ["compression", "flash", "cooldown", "active", "phase", "phase_time", "lifetime", "remaining", "angular_velocity", "pivot_offset", "hold_elapsed", "holding", "expired_pending"]:
			body.set_meta(key, entry.get(key, body.get_meta(key)))
		body.rotation = float(entry.get("rotation", 0.0))
		_sync_mechanical_shape(body)
		body.collision_layer = 1 if body.get_meta("active") and body.get_meta("phase") == "active" else 0
	_next_id = int(data.get("next_id", _next_id))
	_rng.seed = int(str(data.get("rng_seed", "0")))
	_rng.state = int(str(data.get("rng_state", "0")))
	queue_redraw()
	return true
