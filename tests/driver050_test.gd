extends SceneTree
const Kart=preload("res://scripts/kart.gd")
const Driver=preload("res://scripts/kart_driver.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func run():
	var k=Kart.new();root.add_child(k);k.setup(null)
	k.world=Node3D.new();k.add_child(k.world)
	var references={}
	for id in 14:
		for skin in (2 if id==3 else 1):
			var vehicle=k._make_kart(id,skin)
			vehicle.position=Vector3(3,2,-5);vehicle.rotation.y=1.45
			var pilot=vehicle.get_node("Driver")
			var look=Driver.appearance(id,skin)
			references[look.reference]=true
			check(pilot.get_meta("character")==id and pilot.get_meta("skin")==skin,"identity %d/%d"%[id,skin])
			check(FileAccess.file_exists("res://assets/kart/references/"+look.reference+".jpeg"),"supplied image exists")
			check(pilot.head!=null and pilot.arms.size()==2,"seated articulation exists")
			for knee in pilot.knee_points:check(absf(knee.x)+.137<.40 and knee.y<1.0,"knees inside cockpit")
			for steer in [-1.0,0.0,1.0]:
				for boost in [0.0,1.0]:
					for n in 12:pilot.animate({"steer":steer,"speed":29.0,"boost":boost,"stun":.24,"jump":.45,"signature":.7},1.0/60.0)
					for arm in pilot.arms:
						var grip=pilot.wheel.global_transform*Vector3(float(arm.side)*.263,0,0)
						check(arm.hand.global_position.distance_to(grip)<.0001,"grip under turn boost hit jump")
						check(arm.upper.scale.y>.1 and arm.forearm.scale.y>.1,"limbs remain continuous")
			vehicle.queue_free()
	check(references.size()==15,"14 characters and Diogo skin preserve all 15 references")
	check(Driver.appearance(3,1).glasses=="dark" and Driver.appearance(3,1).hair_style=="bald","Careca sunglasses bald identity")
	check(Driver.appearance(2).hair_style=="long","Maria long hair")
	check(Driver.appearance(11).beard=="gray" and Driver.appearance(11).glasses=="clear","Leonardo gray beard and glasses")
	check(Driver.appearance(10).style=="tracksuit" and Driver.appearance(12).style=="puffer","different jacket silhouettes")
	check(Driver.appearance(3).kart_color!=Driver.appearance(3,1).kart_color,"Diogo skins retain separate kart paint")
	var paint=Driver.appearance(0);paint.shirt=Color.MAGENTA
	check(Driver.appearance(0).shirt!=Color.MAGENTA,"appearance copies cannot corrupt shared palette")
	k.queue_free();await process_frame;await process_frame
	print("DRIVER050: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
