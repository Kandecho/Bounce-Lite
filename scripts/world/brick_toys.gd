extends Node2D
## Brick contact/count/crack rules selectively harvested from contact_toys 4947b67.
## No regrowth, local speed cap, vitality offering or physical fragments.
signal event_emitted(kind: String, position: Vector2, intensity: float)
const CORE := Vector2(72,28)
const FRAGILE_CORE := Vector2(72,12)
const GENERATION_RULE := "fragile60-ordinary25-reverse15"
const LEGACY_RULE := "legacy-two-kind"
var generation_rule := GENERATION_RULE
const FOOTPRINT := Vector2(84,40)
const FADE := 0.65
const ASSEMBLY := 0.28
const MAX_BRICKS := 3
var main: Node2D
var spawn_occupancy: RefCounted
var bodies: Array[StaticBody2D] = []
var clock := 0.0
var spawn_timer := 3.0
var next_id := 0
var events: Array[Dictionary] = []
var lifecycle_events: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func configure(host: Node2D, seed_value: int) -> void:
	main = host
	restart(seed_value)

func _exit_tree() -> void:
	if spawn_occupancy != null: spawn_occupancy.unregister(self)

func clear() -> void:
	for body in bodies:
		body.collision_layer = 0
		body.queue_free()
	bodies.clear()

func restart(seed_value: int) -> void:
	clear()
	generation_rule = GENERATION_RULE
	clock = 0.0
	next_id = 0
	events.clear()
	lifecycle_events.clear()
	_rng.seed = seed_value ^ 0x3524ab91
	spawn_timer = _rng.randf_range(2,4)
	queue_redraw()

func _bounds(point: Vector2) -> Rect2:
	return Rect2(point-FOOTPRINT*0.5,FOOTPRINT)

func entity_envelopes() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for body in bodies: result.append(_bounds(body.global_position))
	return result

func snapshot_envelopes(data: Dictionary) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for entry in data.bodies: result.append(_bounds(Vector2(entry.position[0],entry.position[1])))
	return result

func _legal(point: Vector2, ignore: StaticBody2D = null) -> bool:
	if not point.is_finite(): return false
	var allowed: Rect2 = main.spawn_region()
	if not allowed.encloses(_bounds(point)): return false
	if _bounds(point).grow(main.tuning.ball_radius+2).has_point(main.ball.global_position): return false
	if _bounds(point).intersects(Rect2(main.paddle.global_position-main.tuning.paddle_size*0.5,main.tuning.paddle_size).grow(2)): return false
	if spawn_occupancy != null and not spawn_occupancy.is_clear(_bounds(point),self): return false
	for body in bodies:
		if body != ignore and _bounds(point).intersects(_bounds(body.global_position)): return false
	return true

func core_size(kind: String) -> Vector2:
	return FRAGILE_CORE if kind=="fragile" else CORE

func kind_for_roll(roll: float) -> String:
	if generation_rule==LEGACY_RULE: return "reverse" if roll<0.5 else "ordinary"
	return "fragile" if roll<0.6 else ("ordinary" if roll<0.85 else "reverse")

func _try_spawn() -> bool:
	if bodies.size() >= MAX_BRICKS: return false
	var region: Rect2 = main.spawn_region()
	for attempt in range(24):
		var point := region.position+Vector2(_rng.randf(),_rng.randf())*region.size
		if not _legal(point): continue
		var body := add_brick(kind_for_roll(_rng.randf()),point,_rng.randf_range(14,22))
		body.set_meta("phase","appearing")
		body.set_meta("phase_time",0.0)
		body.collision_layer = 0
		_log(body)
		return true
	return false

func add_brick(kind: String, point: Vector2, lifetime: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Brick_%d" % next_id
	body.position = to_local(point)
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("brick_kind",kind)
	body.set_meta("brick_id",next_id)
	body.set_meta("surface_kind",0)
	body.set_meta("stage","scattered" if kind=="reverse" else "whole")
	body.set_meta("phase","active")
	for key in ["phase_time","assembly_time","flash","last_hit"]: body.set_meta(key,0.0)
	body.set_meta("remaining",lifetime)
	body.set_meta("locked",false)
	next_id += 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = core_size(kind)
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	bodies.append(body)
	return body

func _log(body: StaticBody2D) -> void:
	lifecycle_events.append({"time":clock,"id":body.get_meta("brick_id"),"kind":body.get_meta("brick_kind"),"phase":body.get_meta("phase"),"stage":body.get_meta("stage"),"position":[body.global_position.x,body.global_position.y]})
	if lifecycle_events.size()>256: lifecycle_events.pop_front()

func on_contact_committed(collider: Object, result: RefCounted, ball: CharacterBody2D) -> void:
	if not is_instance_valid(collider) or collider not in bodies or collider.get_meta("phase")!="active" or ball.is_resting(): return
	if -result.velocity_before.dot(result.normal.normalized()) < 30: return
	var stage: String = collider.get_meta("stage")
	# Any assembly collision latches the Ball, including a return during assembly.
	if stage=="assembling":
		collider.set_meta("locked",true)
		return
	if collider.get_meta("locked"): return
	collider.set_meta("locked",true)
	collider.set_meta("last_hit",clock)
	collider.set_meta("flash",1.0)
	var kind: String = collider.get_meta("brick_kind")
	var event := "toy_brick_crack"
	if kind=="reverse" and stage=="scattered":
		collider.set_meta("stage","assembling")
		collider.set_meta("assembly_time",0.0)
		event="toy_reverse_assemble"
	elif kind=="ordinary" and stage=="whole": collider.set_meta("stage","cracked")
	else:
		collider.set_meta("phase","shattering")
		collider.set_meta("phase_time",0.0)
		collider.collision_layer=0
		event="toy_reverse_break" if kind=="reverse" else "toy_brick_break"
	var intensity := 1.0 if event=="toy_reverse_break" else 0.68
	events.append({"time":clock,"id":collider.get_meta("brick_id"),"kind":event,"position":[collider.global_position.x,collider.global_position.y]})
	if events.size()>256: events.pop_front()
	event_emitted.emit(event,collider.global_position,intensity)
	_log(collider)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if delta<=0 or not is_finite(delta): return
	clock+=delta
	spawn_timer-=delta
	if spawn_timer<=0:
		_try_spawn()
		spawn_timer=_rng.randf_range(5,8)
	for body in bodies.duplicate():
		body.set_meta("flash",maxf(0,float(body.get_meta("flash"))-delta*4))
		body.set_meta("remaining",maxf(0,float(body.get_meta("remaining"))-delta))
		var phase: String = body.get_meta("phase")
		var stage: String = body.get_meta("stage")
		if phase=="appearing":
			body.set_meta("phase_time",float(body.get_meta("phase_time"))+delta)
			if body.get_meta("phase_time")>=FADE and _legal(body.global_position,body):
				body.set_meta("phase","active")
				body.collision_layer=1
				_log(body)
		elif phase=="active":
			if stage=="assembling":
				body.set_meta("assembly_time",float(body.get_meta("assembly_time"))+delta)
				if body.get_meta("assembly_time")>=ASSEMBLY:
					body.set_meta("stage","assembled")
					_log(body)
			elif clock-float(body.get_meta("last_hit"))>=0.12 and not _bounds(body.global_position).grow(main.tuning.ball_radius+2).has_point(main.ball.global_position):
				body.set_meta("locked",false)
		if phase in ["appearing","active"] and body.get_meta("remaining")<=0:
			body.set_meta("phase","fading")
			body.set_meta("phase_time",0.0)
			body.collision_layer=0
			_log(body)
		elif phase in ["fading","shattering"]:
			body.set_meta("phase_time",float(body.get_meta("phase_time"))+delta)
			if body.get_meta("phase_time")>=FADE:
				bodies.erase(body)
				body.queue_free()
	queue_redraw()

func export_snapshot() -> Dictionary:
	var entries: Array = []
	for body in bodies:
		var entry := {"kind":body.get_meta("brick_kind"),"id":body.get_meta("brick_id"),"position":[body.global_position.x,body.global_position.y]}
		for key in ["phase","stage","phase_time","assembly_time","remaining","flash","last_hit"]: entry[key]=body.get_meta(key)
		entries.append(entry)
	return {"version":2,"generation_rule":generation_rule,"clock":clock,"spawn_timer":spawn_timer,"next_id":next_id,"rng_seed":str(_rng.seed),"rng_state":str(_rng.state),"bodies":entries,"journal":lifecycle_events.duplicate(true)}

func snapshot_valid(data: Dictionary) -> bool:
	if not (data.get("version") is int or data.get("version") is float) or (data.version!=1 and data.version!=2) or not data.get("bodies") is Array or data.bodies.size()>MAX_BRICKS: return false
	for key in ["clock","spawn_timer","next_id"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(float(data[key])) or float(data[key])<0: return false
	if data.version==2 and data.get("generation_rule") not in [GENERATION_RULE,LEGACY_RULE]: return false
	var bounds: Array[Rect2] = []
	var identities: Array[int] = []
	for entry in data.bodies:
		if not entry is Dictionary or entry.get("kind") not in (["ordinary","reverse"] if data.version==1 else ["fragile","ordinary","reverse"]) or entry.get("phase") not in ["appearing","active","fading","shattering"]: return false
		if entry.get("stage") not in (["whole"] if entry.kind=="fragile" else (["whole","cracked"] if entry.kind=="ordinary" else ["scattered","assembling","assembled"])): return false
		if data.get("generation_rule",LEGACY_RULE)==LEGACY_RULE and entry.kind=="fragile": return false
		if not entry.get("position") is Array or entry.position.size()!=2: return false
		for number in entry.position:
			if not (number is float or number is int) or not is_finite(float(number)): return false
		for key in ["id","phase_time","assembly_time","remaining","flash","last_hit"]:
			if not (entry.get(key) is float or entry.get(key) is int) or not is_finite(float(entry[key])) or float(entry[key])<0: return false
		if float(entry.id)!=int(entry.id) or int(entry.id) in identities or int(entry.id)>=int(data.next_id): return false
		identities.append(int(entry.id))
		if entry.stage=="assembling" and float(entry.assembly_time)>=ASSEMBLY: return false
		if float(entry.flash)>1.0 or float(entry.last_hit)>float(data.clock): return false
		var rectangle := _bounds(Vector2(entry.position[0],entry.position[1]))
		if not main.spawn_region().encloses(rectangle): return false
		for other in bounds:
			if rectangle.intersects(other): return false
		bounds.append(rectangle)
	return data.get("rng_seed") is String and data.get("rng_state") is String and data.get("journal") is Array

func restore_snapshot(data: Dictionary) -> bool:
	if not snapshot_valid(data): return false
	clear()
	generation_rule=LEGACY_RULE if data.version==1 else str(data.generation_rule)
	clock=float(data.clock)
	spawn_timer=float(data.spawn_timer)
	for entry in data.bodies:
		var body := add_brick(entry.kind,Vector2(entry.position[0],entry.position[1]),entry.remaining)
		body.set_meta("brick_id",int(entry.id))
		for key in ["phase","stage","phase_time","assembly_time","remaining","flash","last_hit"]: body.set_meta(key,entry[key])
		body.collision_layer=1 if entry.phase=="active" else 0
	next_id=int(data.next_id)
	_rng.seed=int(data.rng_seed)
	_rng.state=int(data.rng_state)
	lifecycle_events.assign(data.journal)
	events.clear()
	queue_redraw()
	return true

func _fragment_base(index: int) -> Vector2:
	return [Vector2(-25,-4),Vector2(-17,7),Vector2(-6,-7),Vector2(5,5),Vector2(17,-3),Vector2(26,6)][index]

func _fragment_angle(index: int) -> float:
	return [-0.22,0.28,-0.14,0.4,-0.34,0.17][index]

func _fragment_polygon(index: int) -> PackedVector2Array:
	var scale := 0.8+float(index%3)*0.1
	return PackedVector2Array([Vector2(-7,-3)*scale,Vector2(4,-4)*scale,Vector2(7,2)*scale,Vector2(-3,4)*scale])

func _draw() -> void:
	for body in bodies:
		var kind: String = body.get_meta("brick_kind")
		var stage: String = body.get_meta("stage")
		var phase: String = body.get_meta("phase")
		var time: float = body.get_meta("phase_time")
		var alpha := minf(0.65,time/FADE) if phase=="appearing" else (maxf(0,1-time/FADE) if phase in ["fading","shattering"] else 1.0)
		var color := Color("a9cabf") if kind=="reverse" else Color("73c3a4")
		color.a=alpha
		draw_set_transform(body.position)
		var scatter := 1.0 if stage=="scattered" else (1-clampf(float(body.get_meta("assembly_time"))/ASSEMBLY,0,1) if stage=="assembling" else 0.0)
		if kind=="reverse" and phase!="shattering":
			# A quiet Ball-like halo; shard edges stay the clearest information.
			for ring in range(5,0,-1):
				draw_circle(Vector2.ZERO,27+ring*3,Color(Color("8bd5da"),alpha*0.009*(6-ring)))
		if phase=="shattering" or scatter>0:
			for shard in range(6):
				var base := _fragment_base(shard)
				if kind=="fragile": base.y*=FRAGILE_CORE.y/CORE.y
				var point := base
				var angle := _fragment_angle(shard)
				if phase=="shattering":
					point+=base.normalized()*time*(90 if kind=="reverse" else 55)
					angle+=time*(4 if shard%2 else -4)
				else:
					var target := Vector2((shard%3-1)*24,(floori(shard/3.0)-0.5)*14)
					point=target.lerp(base,scatter)
					angle*=scatter
				draw_set_transform(body.position+point,angle)
				draw_colored_polygon(_fragment_polygon(shard),Color(color,alpha*(1.0 if phase=="shattering" else scatter)))
			draw_set_transform(body.position)
		if phase!="shattering" and scatter<1:
			var face := Rect2(-core_size(kind)*0.5,core_size(kind))
			draw_rect(face,Color(color,alpha*(1-scatter)*0.3))
			draw_rect(face,Color(color,alpha*(1-scatter)),false,1.2)
			if stage=="cracked": draw_polyline(PackedVector2Array([Vector2(-7,-14),Vector2(5,-2),Vector2(-5,4),Vector2(7,14)]),Color("192027"),2.4,true)
		draw_set_transform(Vector2.ZERO)
