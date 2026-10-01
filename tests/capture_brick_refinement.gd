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
	main.bricks.add_brick("ordinary",Vector2(300,240),20)
	main.bricks.add_brick("reverse",Vector2(680,240),20)
	main.bricks.add_brick("fragile",Vector2(480,350),20)
	main.bricks.spawn_timer=100
	var scheduled: Dictionary={0:"mixed-initial"}
	var count:=0
	var timeline: Array=[]
	for frame in range(240):
		if frame in [0,35,70,110,180]:
			main.ball.position=Vector2(480,285) if frame==70 else Vector2(300 if frame in [0,35] else 680,175)
			main.ball.start_active(Vector2.DOWN)
			main.ball.velocity=Vector2(0,780)
		main.ball._physics_process(1.0/60)
		main.bricks._physics_process(1.0/60)
		await physics_frame
		if main.bricks.events.size()!=count:
			count=main.bricks.events.size()
			var event: Dictionary=main.bricks.events.back()
			timeline.append({"frame":frame,"event":event,"bodies":main.bricks.export_snapshot()})
			if event.kind=="toy_brick_crack": scheduled[frame+7]="ordinary-cracked"
			elif event.kind=="toy_reverse_assemble":
				scheduled[frame+7]="reverse-assembling"
				scheduled[frame+20]="reverse-assembled"
			elif event.kind=="toy_reverse_break": scheduled[frame+7]="reverse-shattering"
			elif event.id==0: scheduled[frame+7]="fragment-language-comparison"
			else: scheduled[frame+7]="fragile-shattering"
		if scheduled.has(frame):
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://.godot/brick-refinement-20261001/"+scheduled[frame]+".png")
	var actual: Array=[]
	for event in main.bricks.events: actual.append(event.kind)
	var expected: Array=["toy_brick_crack","toy_brick_break","toy_brick_break","toy_reverse_assemble","toy_reverse_break"]
	var file=FileAccess.open("res://.godot/brick-refinement-20261001/controlled.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"controlled":true,"muted":true,"integration_steps":240,"timeline":timeline,"actual":actual,"expected":expected},"\t")); file.close()
	print("BRICK_REFINEMENT_CAPTURE events=",actual," remaining=",main.bricks.bodies.size())
	viewport.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline: await process_frame
	quit(0 if actual==expected else 1)
