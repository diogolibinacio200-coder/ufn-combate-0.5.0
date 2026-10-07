extends SceneTree
## Run with a graphical Godot build (not --headless).
const App=preload("res://scripts/main.gd")
const Profile=preload("res://scripts/save_manager.gd")
var app
var output="res://docs/screens/v030/"

func _initialize():call_deferred("run")
func snap(name: String):
	app.screen_time=1.0
	for n in 5:await process_frame
	await RenderingServer.frame_post_draw
	var screenshot=root.get_texture().get_image()
	screenshot.save_png(ProjectSettings.globalize_path(output+name+".png"))
	print("CAPTURE %s window=%s logical=%s image=%s"%[name,root.size,root.get_visible_rect().size,screenshot.get_size()])

func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	app=App.new();app.profile=Profile.new("user://capture_polish.json");root.add_child(app)
	app.profile.data.settings.fullscreen=false;app.profile.data.settings.quality=0;app.apply_settings()
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	app.set_physics_process(false)
	app.chosen=[3,10];app.stage=0;app.mode="versus";app.start_match();app.intro_frames=0
	app.combat.fighters[0].meter=100;app.combat.fighters[1].meter=72
	await snap("fight_720p")
	for size in [Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1680,720)]:
		root.size=size
		await snap("fight_"+str(size.x)+"x"+str(size.y))
	root.size=Vector2i(1280,720)
	app.set_screen("help");app.help_page=5;await snap("commands_diogo")
	app.set_screen("select");app.cursors=[3,10];await snap("select")
	root.size=Vector2i(1024,768);await snap("select_1024x768")
	app.set_screen("controls");await snap("controls_1024x768")
	root.size=Vector2i(1280,720)
	app.set_screen("menu");app.menu_index=4;app.idle_frames=480
	for n in 280:app.update_demo(false)
	await snap("attract_menu")
	app.chosen=[3,3];app.skins=[0,1];app.start_match();app.intro_frames=0
	app.combat.fighters[0].x=430;app.combat.fighters[1].x=825
	for pose in ["idle","walk","dash","guard","crouch","jump","hit","light","heavy","special","uppercut","victory"]:
		for fighter in app.combat.fighters:
			fighter.move={};fighter.state=pose;fighter.frame=16
			if pose=="guard":fighter.state="block"
			if pose=="hit":fighter.frame=3
			if pose=="dash":fighter.dash_time=5
			if pose=="special":fighter.state="attack";fighter.move=app.combat.move_db.specials(3)[0];fighter.frame=18
			if pose=="light":fighter.state="attack";fighter.move=app.combat.move_db.normals()[0];fighter.frame=8
			if pose=="heavy":fighter.state="attack";fighter.move=app.combat.move_db.normals()[6];fighter.frame=19
			if pose=="uppercut":fighter.state="attack";fighter.move=app.combat.move_db.normals()[7];fighter.frame=12
		await snap("diogo_"+pose)
		for fighter in app.combat.fighters:fighter.dash_time=0
	for player in 2:
		app.combat._start_cinematic(app.combat.fighters[player],app.combat.fighters[1-player],app.combat.move_db.super_move(3))
		for frame in [24,58,94]:
			app.combat.cinematic.frame=frame
			await snap("diogo_ultimate_%d_%d"%[player,frame])
		app.combat.cinematic.active=false
	app.set_screen("kart");app.kart.start([3,10],[0,0],0,2);app.kart.phase="race"
	app.kart.set_physics_process(false)
	for racer in app.kart.racers:racer.speed=22
	await snap("kart_split")
	app.kart.stop();app.kart.horizontal_split=true;app.kart.start([3,2],[1,0],1,2);app.kart.phase="race";app.kart.set_physics_process(false)
	await snap("kart_horizontal")
	app.kart.stop();app.kart.race_mode="time_trial";app.kart.horizontal_split=false;app.kart.start([3],[0],0,1)
	app.kart.phase="race";app.kart.set_physics_process(false);app.kart.set_process(false);app.kart.hud.visible=false
	var kart=app.kart.racers[0].node
	var camera=app.kart.cameras[0]
	camera.fov=43
	camera.position=kart.to_global(Vector3(3.1,2.6,-4.8));camera.look_at(kart.to_global(Vector3(0,1.05,0)))
	await snap("pilot_diogo")
	app.kart.stop()
	# Exercise continuously rotating ball polygons over multiple phases.
	app.chosen=[5,6];app.skins=[0,0];app.start_match();app.intro_frames=0
	for fighter in app.combat.fighters:
		fighter.state="attack";fighter.move=app.combat.move_db.specials(fighter.id)[0];fighter.frame=18
	for n in 100:await process_frame
	await app.sound.shutdown()
	app.queue_free();await process_frame;await process_frame
	quit()
