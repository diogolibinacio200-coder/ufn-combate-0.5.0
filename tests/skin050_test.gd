extends SceneTree
## Cosmetic variants must share the canonical character and all progression.
const App=preload("res://scripts/main.gd")
const Combat=preload("res://scripts/combat.gd")
const Fighter=preload("res://scripts/fighter.gd")
const Profile=preload("res://scripts/save_manager.gd")
var checks:int=0
var failures:int=0

func _initialize() -> void: call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FALHOU: "+label)

func mechanics() -> void:
	var plain=Combat.new()
	var alternate=Combat.new()
	plain.setup([3,0])
	alternate.setup([3,0])
	alternate.fighters[0].skin=1
	for c in [plain,alternate]:
		c.fighters[0].x=420.0
		c.fighters[1].x=550.0
	var identical:bool=true
	for frame in 600:
		var commands:Dictionary={}
		if frame%75==0: commands={"attack_pressed":true}
		if frame==150: commands={"heavy_pressed":true}
		if frame==250: commands={"up_pressed":true,"up":true}
		if frame==340:
			for c in [plain,alternate]:
				c.fighters[0].meter=100.0
				c.fighters[0].x=400.0
				c.fighters[1].x=665.0
			commands={"block":true,"heavy_pressed":true}
		plain.tick([commands,{}])
		alternate.tick([commands,{}])
		var state_a:Dictionary=plain.snapshot()
		var state_b:Dictionary=alternate.snapshot()
		for f in state_a.fighters:f.erase("skin")
		for f in state_b.fighters:f.erase("skin")
		identical=identical and state_a==state_b
	check(identical,"Both Diogo appearances produce identical movement, attacks, ultimate, damage, meter and timers")
	check(plain.fighters[0].damage_dealt>0 and plain.fighters[0].supers==1,"Comparison executes connected attacks and the same ultimate")
	for state in ["idle","walk","crouch","jump","attack","block","crouch_block","hitstun"]:
		var a:Dictionary=Fighter.create(3,0)
		var b:Dictionary=Fighter.create(3,0)
		a.state=state
		b.state=state
		b.skin=1
		check(Fighter.hurtbox(a)==Fighter.hurtbox(b) and Fighter.pushbox(a)==Fighter.pushbox(b),"Cosmetic variant has identical hitboxes: "+state)

func run() -> void:
	mechanics()
	var app=App.new()
	app.profile=Profile.new("user://skin050_test_"+str(OS.get_process_id())+".json")
	root.add_child(app)
	app.set_process(false)
	app.set_physics_process(false)
	check(app.PLAYABLE==14 and app.combat.move_db.IDS.count("diogo")==1 and not app.combat.move_db.IDS.has("diogo_alt"),"Selection has one Diogo slot among fourteen playable characters")
	app.begin_mode("versus")
	app.cursors=[3,0]
	app.chosen=[3,0]
	app.skins=[0,0]
	app.tick_select([{"heavy_pressed":true},{}])
	check(app.cursors[0]==3 and app.chosen[0]==3 and app.skins[0]==1 and not app.ready_players[0],"Skin button toggles appearance without extra slot or premature confirmation")
	app.tick_select([{"attack_pressed":true},{"attack_pressed":true}])
	check(app.chosen==[3,0] and app.skins[0]==1,"Confirmed alternate skin retains character ID three")
	app.start_match()
	check(app.combat.fighters[0].id==3 and app.combat.fighters[0].skin==1,"Match receives canonical Diogo plus cosmetic index")
	app.start_round()
	check(app.combat.fighters[0].id==3 and app.combat.fighters[0].skin==1,"Round reset preserves chosen appearance")
	check(app.arena.sprite_atlas.has("diogo") and app.arena.sprite_atlas.has("diogo_alt") and app.arena.sprite_atlas.diogo!=app.arena.sprite_atlas.diogo_alt,"Original and alternative sprite atlases remain distinct and available")
	check(app.arena.portrait_art.diogo!=app.arena.portrait_art.diogo_alt,"Both original portraits are preserved")
	app.match_winner=0
	app.save_match()
	app.skins[0]=0
	app.save_match()
	check(app.profile.data.stats.most_played.get("3",0)==2 and app.profile.data.stats.most_played.size()==2,"Both skins accumulate the same character statistics")
	app.mode="tower"
	app.arcade_order=[0,1,2,14,15]
	app.arcade_index=1
	app.skins[0]=1
	app.save_tower()
	app.profile.load_profile()
	check(app.profile.data.progress.tower.character==3 and app.profile.data.progress.tower.skin==1,"Tower stores one character identity with separate cosmetic field")
	app.skins[0]=0
	app.resume_tower()
	check(app.chosen[0]==3 and app.skins[0]==1 and app.arcade_index==1,"Tower resume restores same progress and chosen skin")
	app.mode="teams"
	app.chosen=[0,1]
	app.reserves=[3,4]
	app.skins=[0,0]
	app.reserve_skins=[1,0]
	app.start_match()
	check(app.combat.tag(0) and app.combat.fighters[0].id==3 and app.combat.fighters[0].skin==1,"Team reserve keeps Diogo cosmetic without a separate fighter")
	app.kart.race_mode="time_trial"
	app.kart.start([3],[1],4,1)
	app.kart.set_process(false)
	app.kart.set_physics_process(false)
	var racer:Dictionary=app.kart.racers[0]
	var driver=racer.node.get_node("Driver")
	check(racer.character==3 and racer.skin==1 and driver.get_meta("character")==3 and driver.get_meta("skin")==1,"Kart driver uses same Diogo identity and alternative appearance")
	check(app.kart.IDS.count("diogo")==1 and app.kart.IDS.size()==14,"Kart roster also has no duplicate Diogo character")
	app.kart.stop()
	await app.sound.shutdown()
	app.queue_free()
	await process_frame
	await process_frame
	print("SKINS 0.5.0: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

