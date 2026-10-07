extends SceneTree
const App=preload("res://scripts/main.gd")
const Profile=preload("res://scripts/save_manager.gd")
var app
var destination="res://docs/screens/v040/"
func _initialize():call_deferred("run")
func snap(label: String):
	for frame in 3:await process_frame
	# The headless renderer does not emit frame_post_draw; three process frames
	# are enough for deterministic screenshots in CI and local validation.
	if DisplayServer.get_name() != "headless":await RenderingServer.frame_post_draw
	var file=ProjectSettings.globalize_path(destination+label+".png")
	root.get_texture().get_image().save_png(file)
	print("CAPTURE "+label+" "+str(root.size))
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	app=App.new();app.profile=Profile.new("user://tower_capture.json");root.add_child(app)
	app.profile.data.settings.fullscreen=false;app.apply_settings();root.size=Vector2i(1280,720)
	app.set_physics_process(false)
	app.open_tower_selection();app.screen_time=1;app.tower_count=5;app.tower_difficulty=1
	await snap("tower_selection")
	for size in [Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1680,720)]:
		root.size=size;await snap("tower_selection_"+str(size.x)+"x"+str(size.y))
	root.size=Vector2i(1280,720)
	for count in [3,5,8,10]:
		app.tower_count=count;app.begin_mode("tower");app.cursors[0]=3;app.tick_select([{"attack_pressed":true},{}]);app.screen_time=1
		await snap("tower_"+str(count))
	app.arcade_index=8;app.chosen[1]=14;app.save_tower();app.set_screen("tower");app.screen_time=1
	await snap("tower_boss")
	app.open_tower_selection();app.screen_time=1;await snap("tower_resume")
	app.complete_tower();app.set_process(false)
	for frame in 100:
		app.screen_time=frame/25.0;app.clock_time+=.04;app.ui.queue_redraw()
		await process_frame
		if frame in [7,23,38,57,84]:await snap("tower_falls_"+str(frame))
	app.screen_time=4;app.tick_tower_complete([{},{}]);app.set_process(true);app.screen_time=1;await snap("tower_ending")
	await app.sound.shutdown();app.queue_free();await process_frame;await process_frame;quit()
