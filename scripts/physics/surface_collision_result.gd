class_name SurfaceCollisionResult
extends RefCounted

var surface_kind: int = 0
var effective_surface_kind: int = 0
var normal: Vector2 = Vector2.ZERO
var velocity_before: Vector2 = Vector2.ZERO
var velocity_after: Vector2 = Vector2.ZERO
var vitality_before: float = 0.0
var vitality_delta: float = 0.0
var vitality_after: float = 0.0
var valid_paddle_hit: bool = false
var settle_allowed: bool = false
