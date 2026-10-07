extends SceneTree
const Arena=preload("res://scripts/arena_view.gd")
const Combat=preload("res://scripts/combat.gd")
var arena
var combat
class CaptureArena extends "res://scripts/arena_view.gd":
	var ally_pose_preview: String = ""
	func _draw() -> void:
		super._draw()
		if not ally_pose_preview.is_empty():
			_ufn_ally(Vector2(410,590),.5,0,1,ally_pose_preview,1)
			_ufn_ally(Vector2(860,590),.5,0,-1,ally_pose_preview,1)
func _initialize():call_deferred("run")
func snap(name: String):
	for i in 7:
		if arena.combat!=null:
			for f in arena.combat.fighters:arena.motion.update(f,1.0/60.0)
		arena.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screens/"+name+".png")
	print("CAPTURE "+name)
func run():
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screens"))
	arena=CaptureArena.new();root.add_child(arena);arena.set_process(false);arena.paused=true
	combat=Combat.new();arena.combat=combat
	for id in 16:
		combat.setup([id,id]);arena.motion.reset();arena.time=.3
		combat.fighters[0].x=425;combat.fighters[1].x=845
		for p in 2:
			var f=combat.fighters[p];f.state="walk";f.vel=Vector2(4.2,0)
			arena.motion.update(f,.016);arena.motion.states[p].phase=.25
		await snap("050_walk_%02d"%id)
		if id==10:
			for p in 2:arena.motion.states[p].phase=.75
			await snap("050_lorenzo_stride_b")
	for id in [9,4]:
		combat.setup([id,3]);arena.motion.reset()
		var frames=[1,49,111,124] if id==9 else [10,44,92,110,131,143]
		for frame in frames:
			combat.cinematic={"active":true,"frame":frame,"duration":126 if id==9 else 144,"character":id,"attacker":0,"defender":1}
			await snap("050_ultimate_%02d_%03d"%[id,frame])
	arena.combat=null
	for pose in ["guard","run0","run1","windup","punch0","punch1","kick"]:
		arena.ally_pose_preview=pose
		await snap("050_ally_"+pose+"_both_sides")
	arena.ally_pose_preview="";arena.combat=combat
	for face in [-1,1]:
		combat.setup([9,3]);arena.motion.reset()
		var f=combat.fighters[0]
		f.x=425 if face==1 else 855;f.face=face
		combat.fighters[1].x=855 if face==1 else 425
		combat.fighters[1].face=-face
		for mode in ["counter","feint","projectile"]:
			f.state="idle";f.move={};f.feint_time=0
			combat.projectiles=[]
			if mode=="counter":
				f.state="attack";f.move=combat.move_db.specials(9)[2];f.frame=12
			elif mode=="feint":f.feint_time=36
			else:
				combat.projectiles=[{"kind":"projectile","owner":0,"visual":"ally","x":640,"y":450,"age":15,"face":face,"uid":0}]
			await snap("050_ally_%s_%s"%[mode,"right" if face==1 else "left"])
	combat.setup([4,3]);arena.motion.reset();combat.fighters[0].transform=400
	for pose in ["idle","walk","crouch","jump"]:
		var f=combat.fighters[0]
		f.state=pose;f.x=425;f.y=520 if pose=="jump" else 590;f.vel=Vector2(4.2,-3)
		arena.motion.update(f,.2)
		await snap("050_mirkos_armor_"+pose)
	# Render repeated sequences and verify temporary graphics never add nodes.
	combat.cinematic={"active":true,"frame":1,"duration":144,"character":4,"attacker":0,"defender":1}
	var nodes=root.get_child_count()
	for i in 60:
		combat.cinematic.frame=1+i*2;arena.queue_redraw();await process_frame
	print("CINEMATIC NODE COUNT: ",nodes," -> ",root.get_child_count())
	quit()
