extends SceneTree
## Deterministic release contracts for both authored ultimates, independent of art.
const Combat=preload("res://scripts/combat.gd")
var checks:int=0
var failures:int=0

func _initialize() -> void: call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FALHOU: "+label)

func fresh(id:int,side:int=0,distance:float=140.0):
	var c=Combat.new()
	var ids:Array=[0,0]
	ids[side]=id
	c.setup(ids)
	c.fighters[0].x=400.0
	c.fighters[1].x=400.0+distance
	return c

func activate(c,side:int,defend:bool=false) -> void:
	c.fighters[side].meter=100.0
	var inputs:Array=[{},{}]
	inputs[side]={"block":true,"heavy":true,"heavy_pressed":true}
	inputs[1-side]={"block":defend}
	c.tick(inputs)

func frames(c,n:int,inputs:Array=[{},{}]) -> Array:
	var log:Array=[]
	for _i in n:
		c.tick(inputs)
		log.append_array(c.events.duplicate(true))
	return log

func has_event(log:Array,type:String) -> bool:
	return log.any(func(e):return e.type==type)

func confirmed(id:int,side:int) -> void:
	var c=fresh(id,side)
	var a:Dictionary=c.fighters[side]
	var d:Dictionary=c.fighters[1-side]
	activate(c,side)
	check(a.meter==0.0,"Ultimate consumes full meter %d/%d"%[id,side])
	var log:Array=c.events.duplicate(true)
	var started:bool=false
	var finished:bool=false
	var frozen_clock:int=0
	var timer_stable:bool=true
	var tint_seen:bool=false
	var no_early_armor:bool=true
	var input_during_capture:Array=[{"right":true,"attack_pressed":true},{"left":true,"attack_pressed":true}]
	for _i in 320:
		c.tick(input_during_capture if started else [{},{}])
		log.append_array(c.events.duplicate(true))
		if c.cinematic.active:
			if not started: frozen_clock=c.time_frames
			started=true
			timer_stable=timer_stable and c.time_frames==frozen_clock
			tint_seen=tint_seen or d.ultimate_tint
			if id==4: no_early_armor=no_early_armor and a.transform==0
			check(a.state=="super" and d.state=="super_victim","Capture ignores movement and attack input")
		elif started:
			finished=true
			break
	check(started and finished,"Confirmed sequence begins and finishes %d/%d"%[id,side])
	check(timer_stable,"Round timer pauses throughout authored sequence")
	check(is_equal_approx(d.hp,720.0 if id==9 else 800.0),"Exact balanced damage, no duplicated opener")
	check(a.combo==(15 if id==9 else 6),"Every authored strike counted once")
	check(log.filter(func(e):return e.type=="super_hit").size()==(15 if id==9 else 6),"Strike events match simulation")
	check(log.filter(func(e):return e.type=="super_hit" and e.final).size()==1,"Single stronger finisher")
	check(a.state=="idle" and a.move.is_empty() and a.buffer_time==0,"Attacker control and buffers restored")
	check(not d.ultimate_tint and not c.cinematic.captured and c.cinematic.impact_pause==0,"Capture tint and impact pause cleared")
	check(d.state=="knockdown" and signf(d.vel.x)==a.face,"Finisher knockback points away from attacker")
	check(c.projectiles.is_empty(),"No robots or projectile objects left behind")
	if id==9:
		check(not tint_seen,"Vitor do Mal keeps the ally choreography without red capture feedback")
		check(has_event(log,"ultimate_phase"),"Vitor exposes authored phases")
	else:
		check(no_early_armor and a.transform==480,"Armor is granted only after assembly, full original duration")
		var phases:Array=log.filter(func(e):return e.type=="ultimate_phase").map(func(e):return e.phase)
		check(phases.has("robots") and phases.has("recall") and phases.has("assembly"),"Robots recall before assembly")
		var normal:Dictionary=c.move_db.normals()[0]
		c._start_move(a,normal)
		check(is_equal_approx(a.move.damage,normal.damage*1.2) and a.move.range==normal.range+30.0,"Original armor normal damage and reach buffs preserved")
	frames(c,80)
	check(c._free(d),"Defender recovers after bounded knockdown")
	var position:float=d.x
	var controls:Array=[{},{}]
	controls[1-side]={"right":true} if side==0 else {"left":true}
	c.tick(controls)
	check(d.x!=position,"Defender movement works after sequence")
	if id==4:
		frames(c,a.transform)
		check(a.transform==0,"Armor expires on exact remaining timer")
		var normal:Dictionary=c.move_db.normals()[0]
		c._start_move(a,normal)
		check(is_equal_approx(a.move.damage,normal.damage) and a.move.range==normal.range,"Armor never modifies baseline stats permanently")

func defended_and_whiff(id:int,side:int) -> void:
	for defended in [true,false]:
		var c=fresh(id,side,140.0 if defended else 650.0)
		var a:Dictionary=c.fighters[side]
		var d:Dictionary=c.fighters[1-side]
		activate(c,side,defended)
		var inputs:Array=[{},{}]
		inputs[1-side]={"block":defended}
		var log:Array=frames(c,170,inputs)
		check(not has_event(log,"cinematic_start") and not c.cinematic.active,"Block/whiff never captures opponent %d/%d"%[id,side])
		check(not d.ultimate_tint and c._free(d) and c._free(a),"Both controls recover on block/whiff")
		check(is_equal_approx(d.hp,1000.0-(c.move_db.super_move(id).damage*0.04 if defended else 0.0)),"Only intended chip, zero damage on whiff")
		check(has_event(log,"block")==defended,"Defended hit uses regular block rules")
		check(a.meter<3.0,"No energy refund for whiff/block")
		if id==4: check(a.transform>0,"Uninterrupted robot recovery still finishes armor on whiff/block")
		else: check(a.transform==0,"Vitor cannot acquire armor")

func interruption(id:int,side:int) -> void:
	var c=fresh(id,side)
	var a:Dictionary=c.fighters[side]
	var d:Dictionary=c.fighters[1-side]
	activate(c,side)
	c.hitstop=0
	c._apply_hit(d,a,c.move_db.normals()[0],c.EMPTY,false)
	frames(c,240)
	check(not c.cinematic.active and a.transform==0 and not d.ultimate_tint,"Startup interruption cancels all rewards and capture")
	check(c._free(a) and d.hp==1000,"Interrupted super never deals delayed damage")
	c=fresh(id,side)
	a=c.fighters[side]
	d=c.fighters[1-side]
	activate(c,side)
	for _i in 100:
		c.tick([{},{}])
		if c.cinematic.active: break
	frames(c,40)
	var hp_before:float=d.hp
	c.cancel_cinematic()
	check(not c.cinematic.active and c._free(a) and c._free(d),"Explicit cancellation releases both actors")
	check(not d.ultimate_tint and a.transform==0 and c.hitstop==0,"Cancellation clears visual state and does not grant armor")
	frames(c,200)
	check(d.hp==hp_before,"Cancellation prevents future strike damage")
	c.reset_round()
	check(not c.cinematic.active and c.projectiles.is_empty() and c.fighters[0].hp==1000,"Round reset removes cinematic state")
	check(c.fighters.all(func(f):return not f.ultimate_tint and f.transform==0 and f.buffer_time==0),"Reset clears tint, armor and buffers")

func edge_cases(id:int,side:int) -> void:
	var c=fresh(id,side)
	var a:Dictionary=c.fighters[side]
	var d:Dictionary=c.fighters[1-side]
	var move:Dictionary=c.move_db.super_move(id)
	a.combo=3
	a.combo_timer=60
	d.state="hitstun"
	d.stun=32
	c._start_move(a,move)
	c._apply_hit(a,d,move,c.EMPTY,false)
	frames(c,260)
	check(d.hp==1000.0-roundf(move.damage*0.64),"Combo scaling preserves one exact budget %d/%d"%[id,side])
	c=fresh(id,side)
	a=c.fighters[side]
	d=c.fighters[1-side]
	c._start_move(a,move)
	d.parry_age=0
	var guard:Dictionary=c.EMPTY.duplicate()
	guard.block=true
	c._apply_hit(a,d,move,guard,false)
	check(not c.cinematic.active and a.state=="hitstun" and d.hp==1000.0,"Parry defeats capture before cinematic starts")
	frames(c,180)
	check(a.transform==0 and c._free(a),"Parried Mirkos cannot gain delayed armor")
	c=fresh(id,side)
	a=c.fighters[side]
	d=c.fighters[1-side]
	d.invuln=65
	activate(c,side)
	var log:Array=frames(c,170)
	check(not has_event(log,"cinematic_start") and d.hp==1000.0,"Invulnerable dodge/wakeup cannot be captured")
	c=fresh(id,side)
	a=c.fighters[side]
	d=c.fighters[1-side]
	a.x=1070.0 if side==0 else 200.0
	d.x=1180.0 if side==0 else 90.0
	activate(c,side)
	frames(c,320)
	check(d.x>=90.0 and d.x<=1190.0 and absf(a.x-d.x)>=66.0,"Finisher respects corner bounds and pushboxes")
	c=fresh(id,side)
	a=c.fighters[side]
	d=c.fighters[1-side]
	activate(c,side)
	for _i in 100:
		c.tick([{},{}])
		if c.cinematic.active: break
	c.reset_round()
	check(not c.cinematic.active and c.fighters.all(func(f):return f.state=="idle" and not f.ultimate_tint),"Reset during active sequence clears locked actors immediately")
	frames(c,200)
	check(c.fighters[1-side].hp==1000.0 and c.fighters[side].transform==0,"Reset prevents orphan damage and armor rewards")

func confirmed_vitor_bem_red() -> void:
	# Vitor do Bem keeps his original counter-ultimate trigger. The authored
	# cinematic begins only after the opponent attacks into the counter window.
	var c=fresh(1,0,95.0)
	var a:Dictionary=c.fighters[0]
	var d:Dictionary=c.fighters[1]
	activate(c,0)
	frames(c,22)
	c.tick([{}, {"attack":true,"attack_pressed":true}])
	var started:bool=false
	var tint_seen:bool=false
	var log:Array=[]
	for _i in 300:
		c.tick([{},{}])
		log.append_array(c.events.duplicate(true))
		started=started or c.cinematic.active
		tint_seen=tint_seen or d.ultimate_tint
		if c.cinematic.active:
			check(a.state=="super" and d.state=="super_victim","Vitor do Bem counter locks the cinematic actors")
	check(started,"Vitor do Bem starts the authored red ultimate after a counter-hit")
	check(is_equal_approx(d.hp,720.0),"Vitor do Bem red ultimate keeps the 280 damage budget")
	check(log.filter(func(e):return e.type=="super_hit").size()==15,"Vitor do Bem red ultimate keeps fifteen authored impacts")
	check(tint_seen,"Only Vitor do Bem applies the red capture feedback")
	check(not c.cinematic.active and not d.ultimate_tint,"Vitor do Bem returns control and clears the red feedback")

func run() -> void:
	confirmed_vitor_bem_red()
	for id in [9,4]:
		for side in 2:
			confirmed(id,side)
			defended_and_whiff(id,side)
			interruption(id,side)
			edge_cases(id,side)
		var c=fresh(id)
		c.fighters[1].hp=100.0
		activate(c,0)
		frames(c,320)
		check(c.winner==0 and not c.cinematic.active and not c.fighters[1].ultimate_tint,"Lethal cinematic settles KO without a locked fighter")
		c=fresh(id)
		c.training=true
		activate(c,0)
		frames(c,320)
		check(c.winner==-1 and c.fighters[1].hp==1000,"Training restores health after completed ultimate")
	print("ULTIMATES 0.5.0: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
