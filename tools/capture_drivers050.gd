extends SceneTree
## Render a repeatable 15-pilot reference review. Graphical Godot required.
const Kart=preload("res://scripts/kart.gd")
var output="res://docs/screens/v050/pilots.png"
func _initialize():call_deferred("run")
func run():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	root.size=Vector2i(1280,800)
	var sheet=SubViewport.new();sheet.size=Vector2i(1600,1040);sheet.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(sheet)
	var background=ColorRect.new();background.color=Color("0b1220");background.size=Vector2(1600,1040);sheet.add_child(background)
	var heading=Label.new();heading.text="UFN COMBATE  /  0.5.0";heading.position=Vector2(26,14);heading.add_theme_font_size_override("font_size",28);sheet.add_child(heading)
	var subheading=Label.new();subheading.text="15 referências • 14 personagens + skin Diogo Careca • pilotos articulados";subheading.position=Vector2(27,53);subheading.add_theme_color_override("font_color",Color("9aaac1"));sheet.add_child(subheading)
	var k=Kart.new();root.add_child(k);k.setup(null)
	for index in 15:
		var id=index if index<14 else 3
		var skin=0 if index<14 else 1
		var vp=SubViewport.new();vp.size=Vector2i(306,276);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;vp.own_world_3d=true;sheet.add_child(vp)
		var world=Node3D.new();vp.add_child(world);k.world=world
		var env=WorldEnvironment.new();var settings=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("182337");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("bec9dc");settings.ambient_light_energy=.65;settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=settings;world.add_child(env)
		var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-34,0);light.light_energy=1.8;world.add_child(light)
		var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,135,0);fill.light_color=Color("92b4ef");fill.light_energy=.7;world.add_child(fill)
		var vehicle=k._make_kart(id,skin)
		var pilot=vehicle.get_node("Driver");pilot.animate({"steer":-.28,"speed":12.0},.15)
		if vehicle.has_node("SignatureDecoration"):vehicle.get_node("SignatureDecoration").visible=false
		var camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(3.3,2.7,-5.4);camera.look_at(Vector3(0,1.0,0));camera.fov=31;camera.current=true
		var image=TextureRect.new();image.texture=vp.get_texture();image.position=Vector2(16+(index%5)*317,89+(index/5)*313);image.size=Vector2(306,276);sheet.add_child(image)
		var label=Label.new();label.text=k.NAMES[id] if skin==0 else "DIOGO CARECA · SKIN";label.position=image.position+Vector2(8,278);label.add_theme_font_size_override("font_size",18);sheet.add_child(label)
	var preview=TextureRect.new();preview.texture=sheet.get_texture();preview.size=Vector2(1280,832);root.add_child(preview)
	for n in 12:await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var result=sheet.get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	print("PILOTS CAPTURE ",output," result=",result)
	k.queue_free();sheet.queue_free();await process_frame;await process_frame;quit()
