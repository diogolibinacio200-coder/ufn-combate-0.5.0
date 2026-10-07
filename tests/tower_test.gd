extends SceneTree
const App=preload("res://scripts/main.gd")
const Profile=preload("res://scripts/save_manager.gd")
var app
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(value: bool, label: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)
func press():return [{"attack_pressed":true},{}]
func win_match():
	app.combat.winner=0;app.resolve_round()
	app.combat.winner=0;app.resolve_round()

func run():
	app=App.new();app.profile=Profile.new("user://tower_test_%d.json"%OS.get_process_id());root.add_child(app)
	app.profile.data=app.profile.defaults()
	app.set_process(false);app.set_physics_process(false)
	app.profile.data.settings.difficulty=3
	app.set_screen("menu");app.menu_index=1;app.tick_menu(press())
	check(app.screen=="tower_select","menu opens four selectable towers even without a save")
	app.tower_count=10;app.tower_focus=0;app.tick_tower_select([{"right_pressed":true},{}])
	check(app.tower_count==3,"tower sizes wrap using horizontal navigation")
	app.tick_tower_select([{"down_pressed":true},{}]);app.tick_tower_select([{"right_pressed":true},{}])
	check(app.tower_difficulty==2 and app.tower_count==3,"difficulty changes independently of length")
	app.tick_tower_select(press())
	check(app.tower_focus==0 and app.screen=="tower_select","confirm difficulty returns to tower selection")
	app.tick_tower_select(press())
	check(app.screen=="select" and app.mode=="tower","confirm tower chooses a UFN fighter")
	app.tick_select([{"block_pressed":true},{}])
	check(app.screen=="tower_select" and app.tower_count==3 and app.tower_difficulty==2,"gamepad/back returns to the tower choices without resetting them")
	for count in [3,5,8,10]:
		for level in 3:
			for fighter in 14:
				app.tower_count=count;app.tower_difficulty=level;app.begin_mode("tower");app.cursors[0]=fighter;app.tick_select(press())
				var order=app.arcade_order
				check(order.size()==count+2 and order[-2]==14 and order[-1]==15,"correct regular length and both final bosses for every playable fighter")
				var regular=order.slice(0,count)
				var unique={}
				for id in regular:unique[id]=true
				check(not fighter in regular and unique.size()==regular.size() and regular.all(func(id):return id>=0 and id<14),"no self-opponent, repeated rival or early boss")
			app.skins[0]=1;app.chosen[0]=3
			# Build a fresh valid Diogo ladder before exercising persistence.
			app.begin_mode("tower");app.cursors[0]=3;app.tick_select(press())
			var order=app.arcade_order.duplicate()
			app.start_match();check(app.combat.difficulty==level,"tower difficulty reaches the combat engine")
			check(app.profile.data.settings.difficulty==3,"tower choices preserve other modes' difficulty")
			win_match()
			check(app.screen=="result" and int(app.profile.data.progress.tower.step)==1,"winning an intermediate floor saves the NEXT rival before leaving results")
			app.profile.load_profile();app.open_setup("tower");app.tick_tower_select(press())
			check(app.screen=="tower" and app.arcade_index==1 and app.chosen==[3,int(order[1])],"resume advances to the saved rival")
			check(app.tower_count==count and app.tower_difficulty==level and app.skins[0]==1 and app.arcade_order==order,"length, difficulty, skin and opponents survive reload")
			app.start_match();app.combat.winner=1;app.resolve_round();app.combat.winner=1;app.resolve_round()
			check(app.profile.data.progress.tower.step==1,"defeat never advances the tower")
			app.screen_time=1;app.result_index=0;app.tick_result(press())
			check(app.screen=="fight" and app.arcade_index==1,"retry keeps the same rival")
			for step in range(1,count+2):
				app.start_match();win_match()
				if step<count+1:
					app.screen_time=1;app.result_index=0;app.tick_result(press())
			check(app.screen=="tower_complete" and app.arcade_index==count+2,"last boss automatically starts dismantling the tower")
			app.profile.load_profile()
			var key="torre_%d_%d"%[count,level]
			check(app.profile.data.progress.tower.is_empty() and app.profile.data.progress.records.get(key)==1,"completion is saved before the animation")
			app.complete_tower()
			check(app.profile.data.progress.records.get(key)==1,"repeated completion never duplicates the record")
			app.screen_time=.2;app.tick_tower_complete(press())
			check(app.screen=="tower_complete","winning attack cannot immediately skip the celebration")
			app.screen_time=4;app.tick_tower_complete([{},{}])
			check(app.screen=="ending","dismantling returns automatically to the fighter ending")
	# Old ten-floor saves remain valid; malformed/partial ladders are rejected.
	var p=Profile.new("user://tower_sanitize_%d.json"%OS.get_process_id())
	var legacy={"character":3,"skin":1,"difficulty":1,"step":8,"order":[0,1,2,4,5,6,10,13,14,15]}
	p.data.progress.tower=legacy.duplicate(true);p._sanitize()
	check(p.data.progress.tower.get("count")==8 and p.data.progress.tower.step==8,"legacy ten-floor profile migrates without losing its floor")
	for malformed in [[],[0,14,14],[0,15,14],[3,14,15],[0,0,2,14,15],[99,14,15],[0,1,14,15],[0,14,"15"]]:
		p.data.progress.tower=legacy.duplicate(true);p.data.progress.tower.order=malformed;p.data.progress.tower.step=0;p._sanitize()
		check(p.data.progress.tower.is_empty(),"invalid tower cannot resume with missing or repeated bosses")
	for invalid in [-1,3,99,"x",.5]:
		p.data.progress.tower={"character":3,"difficulty":1,"step":invalid,"order":[0,14,15]};p._sanitize()
		check(p.data.progress.tower.is_empty(),"invalid saved floor rejected")
	await app.sound.shutdown();app.queue_free();await process_frame;await process_frame
	print("TOWERS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
