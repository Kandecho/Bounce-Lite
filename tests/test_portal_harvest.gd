extends SceneTree
const Support = preload("res://tests/test_support.gd")
var suite = Support.new()
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	suite.expect_not_null(main.get("portals"), "second harvest default contains one portal family beside approved coexistence")
	if main.get("portals") != null: await _check(main)
	main.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures == 0 else 1)

func _check(main) -> void:
	var portals = main.portals
	var ball = main.ball
	var game = main.geometry_playground
	ball.set_physics_process(false)
	main.paddle.set_physics_process(false)
	portals.set_physics_process(false)
	game.toys.set_physics_process(false)
	main.play_world.set_physics_process(false)
	# Controlled empty upper lane, while world/geometry remain connected and enabled.
	portals.mouths.assign([Vector2(160, 100), Vector2(790, 100)])
	portals.phase = "active"
	portals.timer = 15.0
	ball.start_active(Vector2.RIGHT)
	var request: Dictionary = portals.motion_request(Vector2(110,100), Vector2(210,100), Vector2(780,0), main.tuning.ball_radius, ball)
	suite.expect_true(not request.is_empty(), "swept center detects high-speed crossing with both endpoints outside")
	if request.is_empty(): return
	suite.expect_equal(request.velocity, Vector2(780,0), "portal preserves world momentum and accepted cap")
	suite.expect_true(ball.safe_center_bounds().has_point(request.position), "whole ball exit remains in arena")
	suite.expect_true(not portals.motion_request(Vector2(110,127),Vector2(210,127),Vector2.RIGHT*780,16,ball).is_empty(),"exact swept aperture tangent triggers reliably")
	suite.expect_true(portals.motion_request(Vector2(110,127.1),Vector2(210,127.1),Vector2.RIGHT*780,16,ball).is_empty(),"near miss outside aperture stays ordinary flight")
	var vitality: float = ball.vitality_model.current_vitality
	suite.expect_true(ball.commit_portal(request), "Physics commits validated portal request")
	suite.expect_false(ball.commit_portal(request), "already committed request cannot transport or sound twice")
	suite.expect_equal(ball.vitality_model.current_vitality, vitality, "portal gives no vitality or state reward")
	suite.expect_true(portals.motion_request(Vector2(790,100), Vector2(770,100), Vector2(-780,0),16,ball).is_empty(), "same pair cannot immediately return")
	portals._physics_process(0.7)
	suite.expect_true(portals.motion_request(Vector2(790,100),Vector2(790,100),Vector2.LEFT*780,16,ball).is_empty(), "cooldown expiry alone cannot rearm resident overlap")
	portals.motion_request(Vector2(900,100),Vector2(900,100),Vector2.LEFT*780,16,ball)
	suite.expect_true(not portals.motion_request(Vector2(210,100),Vector2(110,100),Vector2.LEFT*780,16,ball).is_empty(), "leave both mouths rearms pair after cooldown")
	for state in ["absent","appearing","fading"]:
		portals.phase=state
		suite.expect_true(portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball).is_empty(), "only complete active phase transports: "+state)
	portals.phase="active"
	portals.cooldowns.clear()
	ball.vitality_model.set_vitality(0.04)
	Support.prepare_resting(ball)
	suite.expect_true(portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball).is_empty(), "RESTING ball cannot teleport")
	ball.start_active(Vector2.RIGHT)
	game.toys.set_layout(1)
	await physics_frame
	ball.spring_hold=game.toys.get_children()[4]
	suite.expect_true(portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball).is_empty(), "mechanically held ball cannot teleport")
	ball.clear_geometry_relationships()
	var seesaw=game.toys.get_children()[5]
	suite.expect_false(portals.outlet_clear(seesaw.position+Vector2(0,-32),16,ball),"outlet avoids full seesaw rotation risk even above its current thin surface")
	suite.expect_false(portals.outlet_clear(main.paddle.position,16,ball),"outlet avoids actual paddle body")
	# Block the one defined outlet with an actual body; no alternate search.
	var blocker := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius=30
	collider.shape=circle
	blocker.add_child(collider)
	blocker.position=Vector2(790+27+16+7,100)
	main.get_node("GameArea").add_child(blocker)
	await physics_frame
	var original: Vector2=ball.position
	var original_velocity: Vector2=ball.velocity
	suite.expect_true(portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball).is_empty(), "blocked outlet denies request")
	suite.expect_equal(ball.position,original,"blocked request does not change ball position")
	suite.expect_equal(ball.velocity,original_velocity,"blocked request does not change velocity")
	suite.expect_true(portals.cooldowns.is_empty(),"blocked exit does not consume cooldown")
	blocker.queue_free()
	await physics_frame
	portals.mouths[1]=Vector2(945,100)
	suite.expect_true(portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball).is_empty(),"edge outlet denies instead of clamping")
	portals.mouths.assign([Vector2(160,100),Vector2(790,100)])
	# Actual engine flight crosses the mouth and clears the discontinuous trail.
	ball.position=Vector2(125,100)
	ball.velocity=Vector2(780,0)
	ball.set_physics_process(true)
	for frame in range(6): await physics_frame
	ball.set_physics_process(false)
	suite.expect_true(ball.position.x>790,"fast real physics travel reaches paired exit")
	suite.expect_true(portals.events.size()>0,"commit publishes paired feedback only after transport")
	await _path_order(main)
	suite.expect_true(game.save_combination(),"portal combination saves")
	var saved: Dictionary=portals.export_snapshot()
	game.restart_world(7)
	suite.expect_true(game.restore_combination(),"portal combination restores")
	suite.expect_equal(JSON.stringify(portals.export_snapshot()),JSON.stringify(saved),"portal lifecycle and random progress restore")
	suite.expect_true(portals.cooldowns.is_empty(),"fresh launch does not reuse previous-ball cooldown")
	portals.phase="active"
	portals.timer=0.01
	portals._physics_process(0.02)
	suite.expect_equal(portals.phase,"fading","pair leaves together")
	portals._physics_process(0.66)
	suite.expect_equal(portals.phase,"absent","pair completes departure")
	suite.expect_true(portals.mouths.is_empty() and portals.cooldowns.is_empty(),"departure leaves no trigger or resident lock")

func _path_order(main) -> void:
	var portals=main.portals
	var ball=main.ball
	portals.cooldowns.clear()
	portals.mouths.assign([Vector2(160,100),Vector2(790,100)])
	portals.phase="active"
	var other=ball.duplicate()
	root.add_child(other)
	other.set_physics_process(false)
	other.start_active(Vector2.RIGHT)
	var request: Dictionary=portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,ball)
	ball.commit_portal(request)
	suite.expect_true(not portals.motion_request(Vector2(110,100),Vector2(210,100),Vector2.RIGHT*780,16,other).is_empty(),"same pair cooldown belongs to each ball independently")
	other.queue_free()
	portals.cooldowns.clear()
	var wall:=StaticBody2D.new()
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=Vector2(8,90)
	shape.shape=box
	wall.add_child(shape)
	wall.position=Vector2(171,100)
	main.get_node("GameArea").add_child(wall)
	await physics_frame
	var counts={"surface":0}
	var callback=func(_result):counts.surface+=1
	ball.surface_resolved.connect(callback)
	ball.position=Vector2(125,100)
	ball.velocity=Vector2(780,0)
	ball.start_active(Vector2.RIGHT)
	ball.velocity=Vector2(780,0)
	var audio_before:int=main.geometry_playground.feedback.play_count
	main.geometry_playground.feedback.set_muted(false)
	main.geometry_playground.feedback.advance_time(1.0)
	ball._physics_process(0.08)
	suite.expect_true(ball.position.x>790,"portal before later wall transports during actual traveled segment")
	suite.expect_equal(counts.surface,0,"later abandoned wall collision publishes no contact or energy")
	suite.expect_equal(main.geometry_playground.feedback.play_count,audio_before+1,"paired entry/exit publishes exactly one portal sound")
	for point in ball.get_node("Visuals").trail_points:
		suite.expect_true(point.x>790,"discontinuous trail cannot bridge entrance and outlet")
	portals.cooldowns.clear()
	wall.position=Vector2(120,100)
	await physics_frame
	ball.position=Vector2(90,100)
	ball.start_active(Vector2.RIGHT)
	ball.velocity=Vector2(780,0)
	var before:int=portals.events.size()
	ball._physics_process(0.08)
	suite.expect_equal(portals.events.size(),before,"solid obstruction before portal prevents behind-wall trigger")
	suite.expect_true(counts.surface>0,"real preceding wall still resolves")
	ball.surface_resolved.disconnect(callback)
	wall.queue_free()
	await physics_frame
