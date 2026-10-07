extends SceneTree
## Gameplay contracts for v0.3; exercises the public tick with both players,
## mirrored sides, real timing, cost failures, recovery and scene lifecycle.
const Combat=preload("res://scripts/combat.gd")
const App=preload("res://scripts/main.gd")
const Profile=preload("res://scripts/save_manager.gd")
const Kart=preload("res://scripts/kart.gd")
var checks=0
var failures=0

func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func fresh(id: int, player: int=0, mirror: bool=false):
	var c=Combat.new();c.setup([id,id])
	c.fighters[player].x=840.0 if mirror else 400.0
	c.fighters[1-player].x=400.0 if mirror else 840.0
	c.fighters[player].meter=100.0
	return c
func press(c, p: int, input: Dictionary):
	var values=[{},{}];values[p]=input;c.tick(values)
func advance(c, frames: int):
	for n in frames:c.tick([{},{}])

func run():
	for id in 16:
		for p in 2:
			for mirror in [false,true]:
				var front="left" if mirror else "right"
				var back="right" if mirror else "left"
				var c=fresh(id,p,mirror)
				press(c,p,{back:true,"attack_pressed":true})
				check(c.fighters[p].move.get("name","")==c.move_db.specials(id)[0].name,"back+light %d P%d mirror%s"%[id,p,mirror])
				check(c.fighters[p].face==(-1 if mirror else 1),"power faces opponent immediately")
				c=fresh(id,p,mirror)
				press(c,p,{front:true,"down":true,"heavy_pressed":true})
				check(c.fighters[p].move.get("name","")==c.move_db.offensive_special(id).name,"front/down+heavy priority %d P%d"%[id,p])
				check(c.fighters[p].attacks==1 and c.fighters[p].meter==74.0,"one command, one energy charge")
				c=fresh(id,p,mirror)
				press(c,p,{front:true});advance(c,3);press(c,p,{"down":true});advance(c,3)
				press(c,p,{"heavy_pressed":true})
				check(c.fighters[p].move.get("name","")==c.move_db.offensive_special(id).name,"sequential front/down/button accepted")
				c=fresh(id,p,mirror)
				press(c,p,{back:true,"down":true,"attack_pressed":true})
				check(c.fighters[p].move.get("name","")==c.move_db.specials(id)[1].name,"diagonal alternate outranks back+light")
				c=fresh(id,p,mirror)
				press(c,p,{"down":true});advance(c,2);press(c,p,{front:true});advance(c,2);press(c,p,{"kick_pressed":true})
				check(c.fighters[p].move.get("name","")==c.move_db.specials(id)[2].name,"down/front+third action")
	var c=fresh(3)
	press(c,0,{"right":true});advance(c,21);press(c,0,{"down":true,"heavy_pressed":true})
	check(c.fighters[0].move.get("family","")=="normal","expired sequence cannot hijack a normal")
	c=fresh(3);c.fighters[0].meter=0
	press(c,0,{"left":true,"attack_pressed":true})
	check(c.fighters[0].move.is_empty() and c.fighters[0].attacks==0,"unaffordable special never becomes a jab")
	c=fresh(3)
	press(c,0,{"right":true,"down":true,"heavy_pressed":true})
	var spent=c.fighters[0].meter
	for frame in 90:press(c,0,{"right":true,"down":true,"heavy":true})
	check(c.fighters[0].attacks==1 and c.fighters[0].meter==spent,"held button never spams specials")
	for mirror in [false,true]:
		c=fresh(3,0,mirror)
		c._start_move(c.fighters[0],c.move_db.normals()[6])
		c.fighters[0].frame=46
		press(c,0,{("right" if mirror else "left"):true,"attack_pressed":true})
		advance(c,5)
		check(c.fighters[0].move.get("name","")=="CHICOTE DE CIPÓ","special buffered during recovery on both sides")
	c=fresh(3)
	var start_x=c.fighters[0].x
	press(c,0,{"dodge_pressed":true})
	check(c.fighters[0].state=="evade","dodge enters evasive state")
	advance(c,9)
	check(c.fighters[0].invuln==0 and c.fighters[0].x<start_x,"dodge invulnerability expires before recovery")
	advance(c,12);press(c,0,{"dodge_pressed":true})
	check(c.fighters[0].state!="evade","dodge cooldown prevents invulnerability loop")
	advance(c,35);press(c,0,{"dodge_pressed":true})
	check(c.fighters[0].state=="evade","dodge can be used after cooldown")
	# Three actual connected light presses must complete the beginner combo.
	c=fresh(3);c.fighters[0].x=540;c.fighters[1].x=623
	for step in 3:
		press(c,0,{"attack_pressed":true})
		for n in 35:
			if c.fighters[0].combo>=step+1:break
			advance(c,1)
	check(c.fighters[0].combo==3,"three light taps connect a three-hit combo")
	check(c.fighters[0].move.get("chain_stage",0)==2,"light combo finishes and cannot loop itself")
	# Each playable character has equal base movement, health and jump stats.
	for id in c.move_db.PLAYABLE:
		check(c.move_db.character(id).base==c.move_db.character(0).base,"equal base attributes for playable %d"%id)
	var app=App.new();app.profile=Profile.new("user://polish_test_"+str(OS.get_process_id())+".json");root.add_child(app)
	app.set_process(false);app.set_physics_process(false)
	app.set_screen("menu");app.stage=5;app.chosen=[3,10]
	var stats=app.profile.data.stats.duplicate(true)
	app.idle_frames=479;app.update_demo(false)
	check(not app.demo_active,"demo respects the idle delay")
	app.idle_frames=480
	for n in 180:app.update_demo(false)
	check(app.demo_active and app.demo_combat.tick_count>0,"menu demo runs an isolated fight")
	check(app.stage==5 and app.chosen==[3,10] and app.profile.data.stats==stats,"demo does not overwrite selections/progress")
	app.update_demo(true)
	check(not app.demo_active and app.screen=="menu","interaction stops demo immediately in the same screen")
	app.set_screen("select");app.cursors=[10,3];app.tab_pressed=true;app.tick_select([{},{}]);app.tab_pressed=false
	check(app.screen=="help" and app.help_page==12 and app.previous_screen=="select","selection opens the selected character guide")
	app.escape_pressed=true;app.tick_help([{},{}]);app.escape_pressed=false
	check(app.screen=="select" and app.cursors==[10,3],"guide returns without losing selection")
	var k=Kart.new();root.add_child(k);k.setup(null)
	k.world=Node3D.new();k.add_child(k.world)
	for id in 14:
		for skin in (2 if id==3 else 1):
			var vehicle=k._make_kart(id,skin)
			var pilot=vehicle.get_node("Driver")
			check(pilot.get_meta("character")==id and pilot.get_meta("skin")==skin,"chosen pilot represented in cockpit")
			for steer in [-1.0,0.0,1.0]:
				pilot.animate({"steer":steer,"speed":25.0,"boost":.5,"stun":.2,"jump":.4,"signature":.4},.1)
				for arm in pilot.arms:
					var expected=pilot.wheel.global_transform*Vector3(float(arm.side)*.263,0,0)
					check(arm.hand.global_position.distance_to(expected)<.001,"hand stays attached to wheel under lean/impact")
			check(vehicle.get_meta("wheel_nodes").size()==4,"four separately animated wheels")
			vehicle.queue_free()
	var dummy={"heading":0.0,"pos":Vector2.ZERO}
	for n in 150:k.add_skid_marks(dummy)
	check(k.skid_marks.size()==96,"skid pool is bounded during long drifts")
	for skin in ["diogo","diogo_alt"]:
		var data=app.arena.sprite_data[skin]
		for name in data.animations.uppercut:
			check(data.frames.has(name),"Diogo ascending animation uses complete source frames")
		check(data.sockets.has("punch0") and data.sockets.has("upper"),"Diogo casting uses per-pose hand attachments")
	await app.sound.shutdown()
	k.queue_free();app.queue_free()
	await process_frame;await process_frame
	print("POLISH: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
