extends RefCounted
const Ball = preload("res://scripts/ball/ball_controller.gd")
const Tuning = preload("res://scripts/config/prototype_tuning.gd")

class Requests extends Node:
	var ball: CharacterBody2D
	var observed := Vector2.ZERO
	var requested := Vector2(1200, -1200)
	func contact_request(_result, _collider, _position) -> Dictionary:
		return {"velocity": requested, "vitality_delta": 0.04}
	func on_contact_committed(_collider, _result, _position) -> void:
		observed = ball.velocity

func run(suite: RefCounted) -> void:
	var ball = Ball.new()
	ball.configure(Tuning.new())
	suite.expect_true(ball.has_method("configure_geometry"), "Ball has narrow optional geometry hook")
	if not ball.has_method("configure_geometry"):
		ball.free()
		return
	var geometry := Requests.new()
	geometry.ball = ball
	ball.configure_geometry(geometry)
	var collider := StaticBody2D.new()
	collider.set_meta("toy_kind", "bumper")
	ball.velocity = Vector2(100, 200)
	ball.resolve_surface_collision(0, Vector2.UP, false, 0, collider)
	suite.expect_true(ball.velocity.length() <= 520.001, "geometry request is bounded by Physics")
	suite.expect_equal(geometry.observed, ball.velocity, "geometry notification follows motion commit")
	geometry.requested = Vector2.INF
	ball.velocity = Vector2(0, 200)
	ball.resolve_surface_collision(0, Vector2.UP, false, 0, collider)
	suite.expect_true(ball.velocity.is_finite(), "invalid requested velocity cannot poison motion")
	ball.configure_geometry(null)
	ball.velocity = Vector2(0, 200)
	ball.resolve_surface_collision(3, Vector2.UP, true)
	suite.expect_float(ball.velocity.x, 0, 0.001, "baseline Paddle gains no exploratory horizontal transfer")
	collider.free()
	geometry.free()
	ball.free()
