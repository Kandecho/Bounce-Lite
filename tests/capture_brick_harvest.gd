extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(960,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main=load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").set_muted(true)
	main.geometry_playground.feedback.set_muted(true)
	for node in [main.ball,main.paddle,main.play_world,main.portals,main.geometry_playground.toys,main.bricks]: node.set_physics_process(false)
	main.geometry_playground._restart_pending=false
	main.geometry_playground.toys.set_layout(0)
	main.play_world._states={"rotor":"absent","charge":"absent"}
	main.play_world._sync_interaction()
	main.portals.phase="absent"
	main.portals.mouths.clear()
	main.bricks.clear()
	var ordinary=main.bricks.add_brick("ordinary",Vector2(300,240),20)
	var reverse=main.bricks.add_brick("reverse",Vector2(680,240),20)
	main.bricks.spawn_timer=100
	var shots: Dictionary={}
	var timeline: Array=[]
	var count:=0
	for frame in range(240):
		if frame in [0,35,100,160]:
			main.ball.position=Vector2(300 if frame in [0,160] else 680,175)
			main.ball.start_active(Vector2.DOWN)
			main.ball.velocity=Vector2(0,780)
		main.ball._physics_process(1.0/60)
		main.bricks._physics_process(1.0/60)
		await physics_frame
		var names: Array[String]=[]
		if frame==0: names.append("reverse-scattered")
		if frame==12: names.append("ordinary-cracked")
		if frame==44: names.append("reverse-assembling")
		if frame==62: names.append("reverse-assembled")
		if frame==77: names.append("reverse-shattering")
		if frame==172: names.append("ordinary-shattering")
		for name in names:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://.godot/brick-harvest-20261001/"+name+".png")
		if main.bricks.events.size()!=count:
			count=main.bricks.events.size()
			timeline.append({"frame":frame,"events":main.bricks.events.duplicate(true),"bodies":main.bricks.export_snapshot()})
	var kinds: Array=[]
	for event in main.bricks.events: kinds.append(event.kind)
	var expected: Array=["toy_brick_crack","toy_reverse_assemble","toy_reverse_break","toy_brick_break"]
	var file=FileAccess.open("res://.godot/brick-harvest-20261001/controlled.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"controlled":true,"muted":true,"frames":240,"expected":expected,"actual":kinds,"timeline":timeline},"\t")); file.close()
	print("BRICK_CONTROLLED events=",kinds," remaining=",main.bricks.bodies.size())
	viewport.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline: await process_frame
	quit(0 if kinds==expected else 1)
