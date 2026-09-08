class_name SurfaceResponseModel
extends RefCounted

const PrototypeTuningScript = preload("res://scripts/config/prototype_tuning.gd")
const SurfaceCollisionResultScript = preload("res://scripts/physics/surface_collision_result.gd")

enum SurfaceKind {
	WALL,
	TOP,
	GROUND,
	PADDLE,
}

var tuning: Resource


func _init(source_tuning: Resource = null) -> void:
	tuning = source_tuning if source_tuning != null else PrototypeTuningScript.new()


func resolve(
	velocity_before: Vector2,
	collision_normal: Vector2,
	surface_kind: int,
	vitality_ratio_before: float,
	vitality_before: float,
	max_vitality: float,
	valid_paddle_hit: bool
) -> RefCounted:
	var result: RefCounted = SurfaceCollisionResultScript.new()
	result.surface_kind = surface_kind
	result.effective_surface_kind = _effective_kind(surface_kind, valid_paddle_hit)
	result.normal = collision_normal.normalized()
	result.velocity_before = velocity_before
	result.velocity_after = velocity_before
	result.vitality_before = vitality_before
	result.vitality_after = clampf(vitality_before, 0.0, maxf(max_vitality, 0.001))
	result.valid_paddle_hit = (
		surface_kind == SurfaceKind.PADDLE and valid_paddle_hit
	)
	if result.normal.is_zero_approx():
		return result

	var ratio := clampf(vitality_ratio_before, 0.0, 1.0)
	var restitution := _restitution_for(result.effective_surface_kind, ratio)
	var tangent_retention := _tangent_retention_for(result.effective_surface_kind)
	var normal_component: Vector2 = result.normal * velocity_before.dot(result.normal)
	var tangent_component: Vector2 = velocity_before - normal_component
	result.velocity_after = (
		tangent_component * tangent_retention
		- normal_component * restitution
	)
	if result.valid_paddle_hit:
		result.velocity_after += result.normal * tuning.paddle_impulse
	result.velocity_after = result.velocity_after.limit_length(tuning.max_speed)

	result.vitality_delta = _vitality_delta_for(
		result.effective_surface_kind,
		vitality_before,
		max_vitality
	)
	result.vitality_after = clampf(
		vitality_before + result.vitality_delta,
		0.0,
		maxf(max_vitality, 0.001)
	)
	result.settle_allowed = (
		result.effective_surface_kind == SurfaceKind.GROUND
		and result.velocity_after.length() <= tuning.rest_settle_speed
	)
	return result


func _effective_kind(surface_kind: int, valid_paddle_hit: bool) -> int:
	if surface_kind == SurfaceKind.PADDLE and valid_paddle_hit:
		return SurfaceKind.PADDLE
	if surface_kind == SurfaceKind.TOP:
		return SurfaceKind.TOP
	if surface_kind == SurfaceKind.GROUND:
		return SurfaceKind.GROUND
	return SurfaceKind.WALL


func _restitution_for(kind: int, vitality_ratio: float) -> float:
	match kind:
		SurfaceKind.TOP:
			return lerpf(tuning.top_restitution_min, tuning.top_restitution_max, vitality_ratio)
		SurfaceKind.GROUND:
			return lerpf(tuning.ground_restitution_min, tuning.ground_restitution_max, vitality_ratio)
		SurfaceKind.PADDLE:
			return lerpf(tuning.paddle_restitution_min, tuning.paddle_restitution_max, vitality_ratio)
		_:
			return lerpf(tuning.wall_restitution_min, tuning.wall_restitution_max, vitality_ratio)


func _tangent_retention_for(kind: int) -> float:
	match kind:
		SurfaceKind.TOP:
			return clampf(tuning.top_tangent_retention, 0.0, 1.0)
		SurfaceKind.GROUND:
			return clampf(tuning.ground_tangent_retention, 0.0, 1.0)
		SurfaceKind.PADDLE:
			return clampf(tuning.paddle_tangent_retention, 0.0, 1.0)
		_:
			return clampf(tuning.wall_tangent_retention, 0.0, 1.0)


func _vitality_delta_for(kind: int, vitality_before: float, max_vitality: float) -> float:
	if kind == SurfaceKind.PADDLE:
		var missing_vitality := maxf(maxf(max_vitality, 0.001) - vitality_before, 0.0)
		return missing_vitality * clampf(tuning.paddle_vitality_restore, 0.0, 1.0)
	var retention := 1.0
	match kind:
		SurfaceKind.TOP:
			retention = tuning.top_vitality_retention
		SurfaceKind.GROUND:
			retention = tuning.ground_vitality_retention
		_:
			retention = tuning.wall_vitality_retention
	return vitality_before * clampf(retention, 0.0, 1.0) - vitality_before
