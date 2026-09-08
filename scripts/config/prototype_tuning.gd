class_name PrototypeTuning
extends Resource

@export_group("Vitality")
@export_range(0.001, 100.0, 0.001) var max_vitality: float = 1.0
@export_range(0.0, 1.0, 0.001) var active_vitality_ratio: float = 0.70
@export_range(0.0, 1.0, 0.001) var rest_vitality_ratio: float = 0.08
@export_range(0.0, 1.0, 0.001) var wake_vitality_ratio: float = 0.85
@export_range(0.0, 500.0, 1.0) var rest_settle_speed: float = 45.0

@export_group("Energy and Speed")
@export_range(0.001, 100.0, 0.001) var max_energy: float = 1.0
@export_range(1.0, 2000.0, 1.0) var active_speed: float = 360.0
@export_range(1.0, 2000.0, 1.0) var max_speed: float = 520.0
@export_range(0.0, 3000.0, 1.0) var gravity_acceleration: float = 520.0
@export_range(1.0, 2000.0, 1.0) var active_threshold_speed: float = 300.0
@export_range(0.0, 500.0, 1.0) var rest_threshold_speed: float = 35.0
@export_range(0.0, 1.0, 0.001) var wall_energy_retention: float = 0.985
@export_range(0.0, 1.0, 0.001) var top_energy_retention: float = 0.985
@export_range(0.0, 1.0, 0.001) var ground_energy_retention: float = 0.65
@export_range(1.0, 2000.0, 1.0) var wake_speed: float = 330.0

@export_group("Paddle")
@export_range(1.0, 3000.0, 1.0) var wake_paddle_velocity: float = 450.0
@export_range(0.01, 1.0, 0.01) var wake_hold_seconds: float = 0.08
@export_range(1.0, 60.0, 0.5) var paddle_smoothing: float = 18.0
@export var paddle_size: Vector2 = Vector2(150.0, 18.0)

@export_group("Ball Visuals")
@export_range(2.0, 64.0, 1.0) var ball_radius: float = 16.0
@export_range(1, 64, 1) var trail_max_samples: int = 16
@export_range(1.0, 32.0, 1.0) var trail_sample_distance: float = 8.0
@export_range(1.0, 60.0, 0.5) var feedback_recovery_speed: float = 18.0
@export_range(0.5, 1.0, 0.01) var paddle_hit_squash: float = 0.70
@export_range(0.5, 1.0, 0.01) var wall_hit_squash: float = 0.90
@export_range(0.5, 1.0, 0.01) var ground_hit_squash: float = 0.76
@export_range(0.0, 1.0, 0.01) var paddle_glow_pulse: float = 0.65
@export_range(0.0, 1.0, 0.01) var wall_glow_pulse: float = 0.12
@export_range(0.0, 1.0, 0.01) var ground_darken_pulse: float = 0.38
@export_range(0.0, 1.5, 0.01) var wake_glow_pulse: float = 0.90
