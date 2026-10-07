extends SceneTree
## Release validation: actual driving and adversarial boundaries, no visual mocks.
const Kart=preload("res://scripts/kart.gd")
const STEP=1.0/60.0
var checks:int=0
var failures:int=0

func _initialize() -> void: call_deferred("run")

func check(value:bool,label:String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FALHOU: "+label)

func pilot(game,distance:float=0.0,id:int=0) -> Dictionary:
	var sample:Dictionary=game.sample_road(distance)
	return {"id":id,"character":id%14,"invincible":0.0,"jump":0.0,"signature":0.0,"pos":sample.pos,"previous_pos":sample.pos,"heading":Vector2(sample.dir).angle(),"velocity":Vector2.ZERO,"speed":0.0,"steer":0.0,"lap":1,"next_gate":1,"gates":0,"rank":id+1,"item":0,"drift":0.0,"drifting":false,"boost":0.0,"shield":0.0,"stun":0.0,"hit_flash":0.0,"offroad":false,"wrongway":false,"progress":0.0,"finish_time":-1.0,"notice":"","notice_time":0.0,"recovery":0.0,"trail_timer":0.0,"max_speed":31.8,"bot_timer":3.0,"human":false}

func crossing(game,r:Dictionary,index:int,forward:bool=true,offset:float=0.0,length:float=2.0) -> void:
	var gate:Dictionary=game.checkpoints[index]
	var dir:Vector2=gate.dir
	var normal:Vector2=Vector2(-dir.y,dir.x)
	r.previous_pos=Vector2(gate.pos)+normal*offset+dir*(-length/2 if forward else length/2)
	r.pos=Vector2(gate.pos)+normal*offset+dir*(length/2 if forward else -length/2)
	game.check_gate(r)

func legal_ai(game) -> void:
	for track in game.TRACK_NAMES.size():
		game.track_id=track
		game._build_track()
		game.racers.clear()
		var r:Dictionary=pilot(game,1.0)
		game.elapsed=0.0
		var max_speed:float=0.0
		for frame in 18000:
			game.step_racer(r,game._bot_input(r,STEP),STEP)
			game.elapsed+=STEP
			max_speed=maxf(max_speed,absf(r.speed))
			if r.finish_time>=0: break
		check(r.finish_time>=0 and r.lap==4 and r.gates==60,"AI drives three complete legal laps on track %d (%.1fs gates%d)"%[track,game.elapsed,r.gates])
		check(max_speed<=r.max_speed+.5,"AI respects same unboosted speed budget track%d"%track)
		check(game.nearest_road(r.pos).offset<=game.BARRIER_OFFSET,"AI remains inside track corridor")
		print("TRACK %d: %.1f s, %d gates, %.2f peak"%[track,game.elapsed,r.gates,max_speed])

func gates_and_contacts(game) -> void:
	game.track_id=4
	game._build_track()
	var r:Dictionary=pilot(game)
	crossing(game,r,0)
	crossing(game,r,2)
	crossing(game,r,1,false)
	crossing(game,r,1,true,game.ROAD_HALF+3)
	crossing(game,r,1,true,0,50)
	check(r.gates==0 and r.next_gate==1 and r.lap==1,"Finish, skip, reverse, offroad and teleport do not award checkpoints")
	for lap in 3:
		for gate in range(1,game.GATES): crossing(game,r,gate)
		crossing(game,r,0)
	check(r.gates==60 and r.lap==4 and r.finish_time>=0,"All ordered finite gates award exactly three laps")
	var final_gates:int=r.gates
	crossing(game,r,1)
	check(r.gates==final_gates,"Finished racer cannot accumulate extra checkpoints")
	r=pilot(game,25)
	r.gates=6
	r.next_gate=7
	r.pos=Vector2(999,999)
	game.step_racer(r,{"throttle":1.0},STEP)
	check(r.gates==6 and r.next_gate==7 and r.recovery>0,"Off-track recovery preserves exact checkpoint entitlement")
	check(game.nearest_road(r.pos).offset<1,"Off-track recovery returns kart to legal road")
	var s:Dictionary=game.sample_road(20)
	var tangent:Vector2=s.dir
	var normal:Vector2=Vector2(-tangent.y,tangent.x)
	r=pilot(game,20)
	r.pos=Vector2(s.pos)+normal*(game.BARRIER_OFFSET+2)
	r.velocity=tangent*23+normal*8
	r.heading=tangent.angle()
	r.speed=25.0
	game._resolve_track_contact(r,game.nearest_road(r.pos))
	check(game.nearest_road(r.pos).offset<=game.BARRIER_OFFSET-game.KART_RADIUS+.01,"Wall contact contains entire kart radius")
	check(Vector2(r.velocity).dot(tangent)>20 and Vector2(r.velocity).dot(normal)<=0,"Glancing wall collision preserves forward motion and rejects outward motion")
	r=pilot(game,20)
	var other:Dictionary=pilot(game,20,1)
	r.velocity=tangent*25
	other.velocity=-tangent*12
	game.racers.assign([r,other])
	game._check_collisions()
	check(Vector2(r.pos).distance_to(other.pos)>=1.89,"Exactly coincident karts separate without NaN")
	check(Vector2(r.pos).is_finite() and Vector2(other.velocity).is_finite(),"Coincident collision positions and velocity stay finite")
	game.track_obstacles.assign([{"pos":s.pos,"radius":1.2,"kind":"test"}])
	r.pos=Vector2(s.pos)
	r.velocity=tangent*15
	game._resolve_obstacles(r)
	check(Vector2(r.pos).distance_to(s.pos)>=2.14,"Kart centered on obstacle is separated safely")
	game.track_obstacles.clear()
	game.racers.clear()

func traffic(game) -> void:
	game.track_id=4
	game._build_track()
	game.racers.clear()
	for id in 8: game.racers.append(pilot(game,1.0-id*3,id))
	var blocked:Dictionary=game.sample_road(28)
	game.track_obstacles.assign([{"pos":blocked.pos,"radius":1.1,"kind":"cone"}])
	var follower:Dictionary=game.racers[0]
	follower.speed=20.0
	var before:Dictionary=game._bot_input(follower,STEP)
	var lane_before:float=follower.ai_lane
	var lead:Dictionary=game.racers[1]
	lead.pos=Vector2(follower.pos)+Vector2(cos(follower.heading),sin(follower.heading))*6
	for _i in 30:game._bot_input(follower,STEP)
	check(absf(float(follower.ai_lane)-lane_before)>.5,"Bot chooses passing lane for competitor ahead")
	check(absf(float(before.steer))<=1,"CPU steering remains within human input range")
	game.respawn_racer(follower)
	game.elapsed=0.0
	for frame in 18000:
		for r in game.racers:
			game.step_racer(r,game._bot_input(r,STEP),STEP)
		game._check_collisions()
		game.elapsed+=STEP
		if game.racers.all(func(r):return r.finish_time>=0): break
	for r in game.racers:
		check(r.finish_time>=0 and r.gates==60,"Traffic bot%d recovers, avoids obstacle and finishes three valid laps (gates%d %.1fs)"%[r.id,r.gates,game.elapsed])
	game.racers.clear()
	game.track_obstacles.clear()

func key(host,code:int,pressed:bool) -> void:
	var event=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	host.input.update()

func run() -> void:
	var game=Kart.new()
	root.add_child(game)
	var host=Node.new()
	host.set_script(load("res://tests/kart_input_host.gd"))
	root.add_child(host)
	game.setup(host)
	game.rng.seed=50817
	legal_ai(game)
	gates_and_contacts(game)
	traffic(game)
	game.start([3,4],[1,0],4,2)
	game.set_process(false)
	game.set_physics_process(false)
	check(game.track_id==4 and game.track_name=="UFN / ANDRADAS","Urban track is independently selectable")
	check(game.scenery_bounds.size()>=20 and game.track_obstacles.size()>=7,"Urban buildings and visible props provide camera/collision bounds")
	var text:String=""
	for node in game.world.find_children("*","Label3D",true,false): text+=node.text+" "
	check(text.contains("CONJUNTO II") and text.contains("ENGENHARIAS") and text.contains("ANDRADAS") and text.contains("SERAFIM"),"City identifies UFN and the surrounding real streets")
	check(game.views.size()==2 and game.views[0].world_3d==game.views[1].world_3d,"Two players retain independent cameras in shared world")
	game.auto_accelerate=false
	var accelerator:int=host.input.get_binding(0,"attack",true)
	var brake:int=host.input.get_binding(0,"heavy",true)
	key(host,accelerator,true)
	check(game._human_input(0).throttle==1.0 and game._human_input(0).throttle==1.0,"Manual accelerator remains held across samples")
	key(host,accelerator,false)
	check(game._human_input(0).throttle==0.0,"Manual release removes throttle")
	game.auto_accelerate=true
	check(game._human_input(0).throttle==1.0,"Auto accelerator applies when enabled")
	key(host,brake,true)
	check(game._human_input(0).throttle==-1.0,"Manual brake overrides auto acceleration")
	key(host,brake,false)
	check(game._human_input(0).throttle==1.0,"Auto accelerator resumes after brake release")
	game.auto_accelerate=false
	var racer:Dictionary=game.racers[0]
	racer.speed=0.0
	game._update_cameras(1.0,true)
	var slow_fov:float=game.cameras[0].fov
	racer.speed=32.0
	for _i in 90:game._update_cameras(STEP)
	var fast_fov:float=game.cameras[0].fov
	check(fast_fov>slow_fov+4 and fast_fov<slow_fov+6,"Camera modestly widens FOV with speed")
	racer.speed=0.0
	for _i in 120:game._update_cameras(STEP)
	check(absf(game.cameras[0].fov-slow_fov)<.1,"Camera FOV smoothly returns at rest")
	game.scenery_bounds.assign([Rect2(Vector2(-6,-2),Vector2(2,4))])
	var focus:Vector3=Vector3(0,1.3,0)
	var desired:Vector3=Vector3(-8,3.1,0)
	var safe:Vector3=game._camera_clear_position(focus,desired)
	check(safe.x>-3.3 and safe.distance_to(focus)<desired.distance_to(focus),"Obstructed chase camera shortens before building facade")
	check(not game.scenery_bounds[0].grow(.7).has_point(Vector2(safe.x,safe.z)),"Camera remains outside expanded obstruction")
	game.burst(Vector2.ZERO,Color.WHITE,1000,.2)
	check(game.effects.size()<=game.MAX_EFFECTS,"Burst allocation has fixed particle cap")
	for _i in 150:game.add_skid_marks(racer)
	check(game.skid_marks.size()==96,"Drift marks reuse fixed pool")
	game._update_effects(1.0)
	check(game.effects.is_empty(),"Expired particles are removed")
	game.stop()
	await process_frame
	await process_frame
	check(game.effects.is_empty() and game.skid_marks.is_empty() and game.racers.is_empty() and game.camera_targets.is_empty(),"Stop releases racers, effects, marks and camera state")
	game.start([3],[0],4,1)
	game.set_process(false)
	game.set_physics_process(false)
	check(game.racers.size()==8 and game.racers[0].skin==0 and game.effects.is_empty(),"Restart creates fresh race without prior skin/effect state")
	game.stop()
	await process_frame
	game.queue_free()
	host.queue_free()
	await process_frame
	print("KART 0.5.0: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
