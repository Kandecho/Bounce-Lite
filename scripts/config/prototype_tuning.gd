class_name PrototypeTuning
extends Resource

@export_group("Vitality")
@export_range(0.001, 100.0, 0.001) var max_vitality: float = 1.0
@export_range(0.0, 1.0, 0.001) var active_vitality_ratio: float = 0.70
@export_range(0.0, 1.0, 0.001) var rest_vitality_ratio: float = 0.08
@export_range(0.0, 500.0, 1.0) var rest_settle_speed: float = 45.0

@export_group("Physics")
@export_range(1.0, 2000.0, 1.0) var initial_speed: float = 360.0
@export_range(1.0, 2000.0, 1.0) var max_speed: float = 520.0
@export_range(0.0, 3000.0, 1.0) var gravity_acceleration: float = 260.0

@export_group("Resting Wake")
@export_range(0.0, 1.0, 0.01) var wake_rest_delay_seconds: float = 0.12
@export_range(1.0, 100.0, 0.5) var wake_interaction_distance: float = 12.5
@export_range(1.0, 1000.0, 1.0) var wake_launch_speed: float = 350.0
@export_range(0.0, 1.0, 0.01) var wake_vitality_restore_ratio: float = 0.15
@export_range(0.0, 500.0, 1.0) var wake_horizontal_range: float = 200.0
@export_range(0.0, 0.1, 0.001) var wake_sample_seconds: float = 0.05

@export_group("Surface Response")
@export_range(0.0, 1.0, 0.001) var wall_restitution_min: float = 0.96
@export_range(0.0, 1.0, 0.001) var wall_restitution_max: float = 0.995
@export_range(0.0, 1.0, 0.001) var wall_tangent_retention: float = 0.995
@export_range(0.0, 1.0, 0.001) var wall_vitality_retention: float = 0.985
@export_range(0.0, 1.0, 0.001) var top_restitution_min: float = 0.96
@export_range(0.0, 1.0, 0.001) var top_restitution_max: float = 0.995
@export_range(0.0, 1.0, 0.001) var top_tangent_retention: float = 0.995
@export_range(0.0, 1.0, 0.001) var top_vitality_retention: float = 0.985
@export_range(0.0, 1.0, 0.001) var ground_restitution_min: float = 0.12
@export_range(0.0, 1.0, 0.001) var ground_restitution_max: float = 0.78
@export_range(0.0, 1.0, 0.001) var ground_tangent_retention: float = 0.80
@export_range(0.0, 1.0, 0.001) var ground_vitality_retention: float = 0.65
@export_range(0.0, 1.0, 0.001) var paddle_restitution_min: float = 0.72
@export_range(0.0, 1.0, 0.001) var paddle_restitution_max: float = 0.92
@export_range(0.0, 1.0, 0.001) var paddle_tangent_retention: float = 1.0
@export_range(0.0, 1000.0, 1.0) var paddle_impulse: float = 160.0
@export_range(0.0, 1.0, 0.01) var paddle_vitality_restore: float = 1.0

@export_group("Paddle")
@export_range(1.0, 60.0, 0.5) var paddle_smoothing: float = 18.0
@export var paddle_size: Vector2 = Vector2(150.0, 18.0)

@export_group("Ball Visuals")
@export_range(2.0, 64.0, 1.0) var ball_radius: float = 16.0
@export_range(1.0, 60.0, 0.5) var feedback_recovery_speed: float = 18.0
@export_range(0.5, 1.0, 0.01) var paddle_hit_squash: float = 0.70
@export_range(0.5, 1.0, 0.01) var wall_hit_squash: float = 0.90
@export_range(0.5, 1.0, 0.01) var ground_hit_squash: float = 0.76
