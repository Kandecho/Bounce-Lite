extends Node2D
## Harvested pair/cooldown/offset rules from field_toys at 4947b67.
## No acceleration, vitality or Ball mutation: Physics accepts explicit requests.
signal event_emitted(kind: String, position: Vector2, intensity: float)
const RADIUS := 27.0
const FADE_SECONDS := 0.65
const COOLDOWN := 0.65
var main: Node2D
var mouths: Array[Vector2] = []
var phase := "absent"
var timer := 10.0
var clock := 0.0
var pair_id := 0
var cooldowns: Dictionary = {}
var events: Array[Dictionary] = []
var lifecycle_events: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _flash := 0.0

func configure(host: Node2D, seed_value: int) -> void:
	main = host
	restart(seed_value)

func restart(seed_value: int) -> void:
	_rng.seed = seed_value ^ 0x5f3759df
	clock = 0.0
	pair_id = 0
	phase = "absent"
	timer = _rng.randf_range(8.0, 14.0)
	mouths.clear()
	cooldowns.clear()
	events.clear()
	lifecycle_events.clear()
	_flash = 0.0
	queue_redraw()

func _log() -> void:
	lifecycle_events.append({"time":clock,"pair":pair_id,"phase":phase})
	if lifecycle_events.size()>128: lifecycle_events.pop_front()

func _physics_process(delta: float) -> void:
	if delta <= 0 or not is_finite(delta): return
	clock += delta
	timer -= delta
	_flash = maxf(0.0,_flash-delta)
	for id in cooldowns.keys():
		if not is_instance_id_valid(int(id)): cooldowns.erase(id)
	if timer <= 0:
		match phase:
			"absent":
				if _spawn_pair():
					phase="appearing"
					timer=FADE_SECONDS
					pair_id+=1
					_log()
				else: timer=3.0
			"appearing":
				phase="active"
				timer=_rng.randf_range(12.0,18.0)
				_log()
			"active":
				phase="fading"
				timer=FADE_SECONDS
				cooldowns.clear()
				_log()
			"fading":
				phase="absent"
				timer=_rng.randf_range(20.0,32.0)
				mouths.clear()
				cooldowns.clear()
				_log()
	queue_redraw()

func _spawn_pair() -> bool:
	var bounds: Rect2=main.spawn_region().grow(-RADIUS)
	for attempt in range(24):
		var a:=bounds.position+Vector2(_rng.randf(),_rng.randf())*bounds.size
		var b:=bounds.position+Vector2(_rng.randf(),_rng.randf())*bounds.size
		if a.distance_to(b)<240: continue
		if a.distance_to(main.ball.global_position)<RADIUS+main.tuning.ball_radius+22 or b.distance_to(main.ball.global_position)<RADIUS+main.tuning.ball_radius+22: continue
		if not outlet_clear(a,RADIUS,main.ball) or not outlet_clear(b,RADIUS,main.ball): continue
		if not outlet_clear(a+Vector2.LEFT*(RADIUS+main.tuning.ball_radius+7),main.tuning.ball_radius,main.ball): continue
		if not outlet_clear(b+Vector2.RIGHT*(RADIUS+main.tuning.ball_radius+7),main.tuning.ball_radius,main.ball): continue
		mouths=[a,b]
		return true
	return false

func outlet_clear(point: Vector2, radius: float, ball: CharacterBody2D) -> bool:
	if not point.is_finite() or not main.ball.arena_bounds.grow(-radius-2).has_point(point): return false
	if is_instance_valid(main.geometry_playground):
		for envelope in main.geometry_playground.toys.entity_envelopes():
			if envelope.grow(radius+2).has_point(point): return false
	var shape:=CircleShape2D.new()
	shape.radius=radius+2.0
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.transform=Transform2D(0,point)
	query.collision_mask=5
	query.exclude=[ball.get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _inside(point: Vector2, radius: float) -> bool:
	for mouth in mouths:
		if point.distance_to(mouth)<=RADIUS+radius+7: return true
	return false

func motion_request(from: Vector2, to: Vector2, velocity: Vector2, radius: float, ball: CharacterBody2D) -> Dictionary:
	if phase!="active" or mouths.size()!=2 or ball.is_resting() or is_instance_valid(ball.spring_hold): return {}
	if not from.is_finite() or not to.is_finite() or not velocity.is_finite(): return {}
	var id:=ball.get_instance_id()
	if cooldowns.has(id):
		if clock<float(cooldowns[id]) or _inside(from,radius): return {}
		cooldowns.erase(id)
	var travel:=to-from
	var hit:=2.0
	var index:=-1
	for i in range(2):
		var offset:=from-mouths[i]
		var fraction:=0.0
		if offset.length()>RADIUS:
			var length_squared:=travel.length_squared()
			if length_squared<0.000001: continue
			var dot:=offset.dot(travel)
			var discriminant:=dot*dot-length_squared*(offset.length_squared()-RADIUS*RADIUS)
			if discriminant<0: continue
			fraction=(-dot-sqrt(discriminant))/length_squared
			if fraction<0 or fraction>1: continue
		if fraction<hit:
			hit=fraction
			index=i
	if index<0: return {}
	var exit_index:=1-index
	var direction:=Vector2.LEFT if exit_index==0 else Vector2.RIGHT
	var destination:=mouths[exit_index]+direction*(RADIUS+radius+7)
	if not outlet_clear(destination,radius,ball): return {}
	return {"pair":pair_id,"entry":mouths[index],"exit":mouths[exit_index],"position":destination,"velocity":velocity.limit_length(main.tuning.max_speed),"fraction":hit}

func can_commit(request: Dictionary, ball: CharacterBody2D) -> bool:
	return phase=="active" and request.get("pair",-1)==pair_id and not cooldowns.has(ball.get_instance_id()) and not ball.is_resting() and not is_instance_valid(ball.spring_hold) and request.get("position") is Vector2 and outlet_clear(request.position,ball.tuning.ball_radius,ball)

func on_motion_committed(request: Dictionary, ball: CharacterBody2D) -> void:
	cooldowns[ball.get_instance_id()]=clock+COOLDOWN
	_flash=0.22
	events.append({"time":clock,"pair":pair_id,"entry":[request.entry.x,request.entry.y],"exit":[request.exit.x,request.exit.y],"position":[request.position.x,request.position.y],"velocity":[request.velocity.x,request.velocity.y]})
	if events.size()>128: events.pop_front()
	event_emitted.emit("toy_portal",request.entry,0.75)
	queue_redraw()

func export_snapshot() -> Dictionary:
	var positions:Array=[]
	for mouth in mouths: positions.append([mouth.x,mouth.y])
	return {"version":1,"phase":phase,"timer":timer,"clock":clock,"pair_id":pair_id,"mouths":positions,"rng_seed":str(_rng.seed),"rng_state":str(_rng.state),"journal":lifecycle_events.duplicate(true)}

func snapshot_valid(data: Dictionary) -> bool:
	if data.get("version")!=1 or data.get("phase","") not in ["absent","appearing","active","fading"]: return false
	if not data.get("mouths") is Array or data.mouths.size()!=(0 if data.phase=="absent" else 2): return false
	for key in ["timer","clock","pair_id"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(float(data[key])) or float(data[key])<0: return false
	for position in data.mouths:
		if not position is Array or position.size()!=2: return false
		for number in position:
			if not (number is int or number is float) or not is_finite(float(number)): return false
		if not main.ball.arena_bounds.grow(-RADIUS).has_point(Vector2(position[0],position[1])): return false
	return data.get("rng_seed") is String and data.get("rng_state") is String and data.get("journal") is Array

func restore_snapshot(data: Dictionary) -> bool:
	if not snapshot_valid(data): return false
	phase=data.phase
	timer=float(data.timer)
	clock=float(data.clock)
	pair_id=int(data.pair_id)
	mouths.clear()
	for position in data.mouths: mouths.append(Vector2(position[0],position[1]))
	_rng.seed=int(data.rng_seed)
	_rng.state=int(data.rng_state)
	lifecycle_events.assign(data.journal)
	cooldowns.clear()
	_flash=0
	queue_redraw()
	return true

func _draw() -> void:
	if phase=="absent": return
	var alpha:=1.0
	if phase=="appearing": alpha=clampf(1-timer/FADE_SECONDS,0,1)*0.65
	elif phase=="fading": alpha=clampf(timer/FADE_SECONDS,0,1)
	for i in range(mouths.size()):
		var point:=to_local(mouths[i])
		var color:=Color("78e3e6") if i==0 else Color("dcaaef")
		color.a=alpha
		draw_circle(point,RADIUS,Color(color,0.09*alpha))
		draw_arc(point,RADIUS,0,TAU,64,color,2.5,true)
		for angle in [0.55,PI+0.55]:
			draw_arc(point,RADIUS+5,angle,angle+0.22,8,color,2,true)
		if phase=="active": draw_arc(point,RADIUS-7,clock*0.65,clock*0.65+TAU*0.67,48,Color(color,0.65*alpha),1.6,true)
		var direction:=Vector2.LEFT if i==0 else Vector2.RIGHT
		var tip:=point+direction*(RADIUS+10)
		draw_line(tip-direction*6,tip,color,1.4,true)
		draw_line(tip,tip-direction.rotated(0.6)*4,color,1.4,true)
		draw_line(tip,tip-direction.rotated(-0.6)*4,color,1.4,true)
		if _flash>0: draw_arc(point,RADIUS+8+(0.22-_flash)*70,0,TAU,64,Color(color,_flash/0.22),3,true)
