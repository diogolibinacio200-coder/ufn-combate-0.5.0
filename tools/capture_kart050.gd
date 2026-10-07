extends SceneTree
const App=preload("res://scripts/main.gd")
const Profile=preload("res://scripts/save_manager.gd")
var app
var output="res://docs/screens/v050/"

func _initialize():call_deferred("run")

func snap(file: String):
	for n in 8:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+file+".png"))
	print("CAPTURE ",file)

func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	app=App.new();app.profile=Profile.new("user://capture050.json");root.add_child(app)
	app.profile.data.settings.fullscreen=false;app.profile.data.settings.quality=0;app.apply_settings()
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	app.set_physics_process(false)
	app.set_screen("kart_stage");app.stage_cursor=4;app.kart_mode="quick";await snap("kart_selection")
	app.set_screen("kart");app.kart.start([3,10],[0,0],4,1)
	app.kart.set_physics_process(false);app.kart.set_process(false);app.kart.phase="race"
	app.kart.paused=false
	await snap("andradas_start")
	var game=app.kart
	var r=game.racers[0]
	for section in [0,1,2,3]:
		var s=game.sample_road(game.total_length*float(section)/4+14)
		r.pos=s.pos;r.heading=Vector2(s.dir).angle();r.speed=22
		game._sync_kart(r,1.0/60);game._update_cameras(1,true)
		await snap("andradas_section_"+str(section))
	game.hud.visible=false
	game.cameras[0].position=Vector3(155,160,150);game.cameras[0].look_at(Vector3(0,0,0));game.cameras[0].fov=53
	await snap("andradas_overview")
	game.stop();app.kart.horizontal_split=true;app.kart.start([4,9],[0,0],4,2)
	app.kart.set_physics_process(false);app.kart.phase="race";app.kart.paused=false
	await snap("andradas_split")
	app.kart.stop()
	app.set_screen("menu");app.menu_index=4;await snap("menu_050")
	await app.sound.shutdown();app.queue_free();await process_frame;await process_frame;quit()
