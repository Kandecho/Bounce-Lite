extends SceneTree
func _init() -> void:call_deferred("_run")
func _run() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(960,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main=load("res://scenes/main.tscn").instantiate()
	viewport.add_child(main)
	main.get_node("BasicAudio").muted=true
	var game=main.geometry_playground
	var portals=main.portals
	var ball=main.ball
	var paddle=main.paddle
	game.restart_world(184)
	paddle.set_physics_process(false)
	var controlled:=OS.get_cmdline_user_args().has("--portal-controlled")
	var length:=24 if controlled else 7200
	var samples:Array[Dictionary]=[]
	var world_events:Array[Dictionary]=[]
	main.play_world.event_emitted.connect(func(kind,point,_intensity):world_events.append({"kind":kind,"time":game.elapsed,"position":[point.x,point.y]}))
	var counts={"wake":0,"continue":0,"surface":0}
	ball.wake_committed.connect(func(_s,_a,_p):counts.wake+=1)
	ball.resume_committed.connect(func(_p):counts.continue+=1)
	ball.surface_resolved.connect(func(_r):counts.surface+=1)
	var overlap_frames:=0
	var peak:=0.0
	var max_mouths:=0
	var max_bricks:=0
	var max_geometry:=0
	var rests:=0
	var states:Dictionary={}
	var active_frames:=0
	var first_active:=false
	var first_commit:=false
	var max_gap:=0
	var previous_tick:int=Engine.get_physics_frames()
	var start_tick:int=previous_tick
	var cap:float=main.tuning.max_speed
	if controlled:
		for frame in range(5):await physics_frame
		portals.set_physics_process(false)
		portals.mouths.assign([Vector2(180,180),Vector2(780,260)])
		portals.phase="active"
		portals.timer=15
		ball.position=Vector2(135,180)
		ball.start_active(Vector2.RIGHT)
		ball.velocity=Vector2(780,0)
	for frame in range(length):
		if not controlled:
			var seconds:=frame/60.0
			var aim:float=ball.position.x+sin(seconds*0.6)*45
			if fmod(seconds,24)>18:aim=250
			if ball.position.y>paddle.position.y:aim=ball.position.x+(135 if ball.position.x<480 else -135)
			paddle.set_target_x(aim)
			paddle.advance_motion(1.0/60)
		await physics_frame
		var tick:int=Engine.get_physics_frames()
		max_gap=maxi(max_gap,tick-previous_tick)
		previous_tick=tick
		var snapshots := {main.play_world: main.play_world.export_snapshot(),game.toys:game.toys.export_snapshot(),portals:portals.export_snapshot(),main.bricks:main.bricks.export_snapshot()}
		if not main.spawn_occupancy.snapshots_clear(snapshots): overlap_frames += 1
		peak=maxf(peak,ball.velocity.length())
		max_mouths=maxi(max_mouths,portals.mouths.size())
		max_geometry=maxi(max_geometry,game.toys.get_child_count())
		max_bricks=maxi(max_bricks,main.bricks.bodies.size())
		if ball.is_resting():rests+=1
		states[str(ball.vitality_model.state)]=true
		if portals.phase=="active":active_frames+=1
		if frame%60==0 or controlled:samples.append({"frame":frame,"time":game.elapsed,"phase":portals.phase,"pair":portals.pair_id,"ball":[ball.position.x,ball.position.y],"velocity":[ball.velocity.x,ball.velocity.y],"vitality":ball.vitality_model.current_vitality,"activity":ball.vitality_model.state,"held":is_instance_valid(ball.spring_hold),"events":portals.events.size()})
		var shot:=""
		if portals.phase=="active" and not first_active:
			first_active=true
			shot="controlled-active" if controlled else "natural-active"
		if not portals.events.is_empty() and not first_commit:
			first_commit=true
			shot="controlled-transport" if controlled else "natural-transport"
		if controlled and frame==23:shot="controlled-recovered"
		if not controlled and frame==7199:shot="natural-120s"
		if not shot.is_empty():
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://.godot/brick-harvest-20261001/"+shot+".png")
	var output:={"overlap_frames":overlap_frames,"seed":184,"controlled":controlled,"input_only":not controlled,"loop_steps":length,"actual_physics_frames":Engine.get_physics_frames()-start_tick,"max_tick_gap":max_gap,"samples":samples,"portal_events":portals.events,"portal_lifecycle":portals.lifecycle_events,"world_events":world_events,"geometry_events":game.events,"max_speed":peak,"max_mouths":max_mouths,"max_geometry":max_geometry,"max_bricks":max_bricks,"brick_events":main.bricks.events,"brick_lifecycle":main.bricks.lifecycle_events,"active_frames":active_frames,"rest_frames":rests,"states":states,"counts":counts,"bounds_recoveries":ball.bounds_recovery_count,"collision_budget_exhaustions":ball.collision_budget_exhaustions}
	var file:=FileAccess.open("res://.godot/brick-harvest-20261001/"+("controlled" if controlled else "natural")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	file.close()
	print("PORTAL_CAPTURE controlled=",controlled," mouths=",max_mouths," events=",portals.events.size()," phases=",portals.lifecycle_events.size()," peak=",peak)
	viewport.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline:await process_frame
	quit(0 if overlap_frames==0 and max_mouths<=2 and max_geometry<=6 and max_bricks<=3 and peak<=cap+0.01 else 1)
