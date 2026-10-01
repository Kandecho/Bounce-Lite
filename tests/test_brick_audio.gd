extends SceneTree
const Support = preload("res://tests/test_support.gd")
const Feedback = preload("res://scripts/world/geometry_feedback.gd")
var suite=Support.new()
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in range(5): await physics_frame
	var sound=main.geometry_playground.feedback
	var metrics: Dictionary={}
	for kind in ["toy_brick_crack","toy_brick_break","toy_reverse_assemble","toy_reverse_break"]:
		var data: PackedByteArray=sound.streams[kind].data
		var peak:=0.0
		var energy:=0.0
		for index in range(data.size()/2):
			var value:=float(data.decode_s16(index*2))/32767.0
			peak=maxf(peak,absf(value))
			energy+=value*value
		suite.expect_true(peak>0.05 and peak<=0.5,"bounded audible brick waveform "+kind)
		metrics[kind]={"peak":peak,"energy":energy,"duration":sound.streams[kind].get_length()}
	var normal_gain:=db_to_linear(-23+8*0.68)
	var reverse_gain:=db_to_linear(-15)
	suite.expect_true(metrics.toy_reverse_break.energy*reverse_gain*reverse_gain>metrics.toy_brick_break.energy*normal_gain*normal_gain,"reverse break has greater bounded routed energy")
	suite.expect_true(Feedback.MAX_VOICES==3 and 3*0.5*reverse_gain<0.267,"stronger effect keeps existing three-voice headroom")
	sound.set_muted(true)
	var before: int=sound.play_count
	sound.on_geometry_event("toy_reverse_break",Vector2(300,200),1)
	suite.expect_equal(sound.play_count,before,"brick respects shared mute")
	sound.set_muted(false)
	sound.advance_time(1)
	main.ball.set_physics_process(false)
	main.bricks.set_physics_process(false)
	main.bricks.clear()
	var body=main.bricks.add_brick("ordinary",Vector2(300,200),20)
	main.ball.position=Vector2(300,170)
	main.ball.start_active(Vector2.DOWN)
	main.ball.velocity=Vector2(0,500)
	var basic_before=main.get_node("BasicAudio").play_counts.duplicate()
	main.ball.resolve_surface_collision(0,Vector2.UP,false,0,body)
	suite.expect_equal(sound.play_count,before+1,"one real committed brick hit routes one dedicated sound")
	suite.expect_equal(main.get_node("BasicAudio").play_counts,basic_before,"brick does not duplicate generic wall sound")
	metrics.normal_gain=normal_gain
	metrics.reverse_gain=reverse_gain
	var file=FileAccess.open("res://.godot/brick-harvest-20261001/audio-metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")); file.close()
	main.queue_free()
	await process_frame
	var deadline:=Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<deadline: await process_frame
	suite.print_summary()
	quit(0 if suite.failures==0 else 1)
