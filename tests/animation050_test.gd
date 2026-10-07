extends SceneTree
const Motion=preload("res://scripts/fighter_motion.gd")
const Arena=preload("res://scripts/arena_view.gd")
const Fighter=preload("res://scripts/fighter.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(value: bool,label: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)
func run():
	var arena=Arena.new();root.add_child(arena);arena.set_process(false)
	var rig=Motion.new()
	for id in 16:
		for skin in (2 if id==3 else 1):
			var f=Fighter.create(id,0);f.skin=skin
			var key="diogo_alt" if id==3 and skin else arena.NAMES[id]
			var original=f.duplicate(true)
			rig.update(f,.016)
			for state in ["idle","walk","dash","crouch","attack","jump"]:
				f.state=state;f.vel=Vector2(4.2,0);f.x+=31.5;rig.update(f,.016)
				var sample=rig.sample(f,state,.3,.5)
				var sequence=arena.sprite_data[key].animations.get(state,arena.sprite_data[key].animations.light)
				var frame=str(sequence[0])
				var mesh=rig.make_mesh(key,frame,arena.sprite_data[key],arena.sprite_atlas[key],sample)
				check(mesh.get_surface_count()==1,"connected mesh built for %s %s"%[key,state])
				var vertices=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var finite=true
				for vertex in vertices:finite=finite and is_finite(vertex.x) and is_finite(vertex.y)
				check(finite,"finite mesh vertices %s %s"%[key,state])
			f.state="walk";f.vel=Vector2(4.2,0);rig.states[0].phase=.25
			var forward=rig.sample(f,"walk",.2,0)
			f.vel.x=-4.2
			var backward=rig.sample(f,"walk",.2,0)
			check(backward.backward and not forward.backward,"directional backpedal %s"%key)
			var left=Vector2(125,304);var right=Vector2(250,304)
			var left_f=Motion.deform(left,forward);var right_f=Motion.deform(right,forward)
			var left_b=Motion.deform(left,backward)
			check(absf(left_f.x-left_b.x)>20,"feet reverse travel %s"%key)
			check(left_f.y<=.001 and right_f.y<=.001,"soles never penetrate floor %s"%key)
			check(absf(left_f.y-right_f.y)>5,"alternating foot lift %s"%key)
			check(f.hp==original.hp and Fighter.hurtbox(f).size==Fighter.hurtbox(original).size,"presentation preserves health/hitbox %s"%key)
			f.y=570;rig.update(f,.016);f.y=590;rig.update(f,.016)
			check(rig.states[0].landing>0,"landing reaction %s"%key)
			var snapshot=f.duplicate(true)
			rig.sample(f,"idle",1,.5);rig.transition(f,"idle0","idle")
			check(f==snapshot,"render sampling read-only %s"%key)
	check(rig.topology.size()<=Motion.CACHE_LIMIT,"mesh topology cache bounded")
	rig.reset();check(rig.states.is_empty(),"fight reset clears blend state")
	for name in ["lorenzo","cristian","fernando"]:
		check(arena.sprite_data[name].frames.walk0[1]==0,"intact walking source restored "+name)
	print("ANIMATION050: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
