extends RefCounted
## Presentation-only connected sprite mesh. Source pixels, fighter stats and
## collision boxes are never edited. One continuous surface keeps joints closed.

const CELL = Vector2(384,320)
const ANCHOR = Vector2(192,304)
const COLS = 12
const ROWS = 16
const CACHE_LIMIT = 96
var states: Dictionary = {}
var topology: Dictionary = {}

func reset() -> void:
	states.clear()

func update(f: Dictionary, delta: float) -> void:
	var player = int(f.get("player",0))
	var identity = str(f.id)+":"+str(f.get("skin",0))
	var state = str(f.state)
	var p = Vector2(float(f.x),float(f.y))
	if not states.has(player) or states[player].identity != identity:
		states[player] = {"identity":identity,"position":p,"phase":0.0,"clock":0.0,"state":state,"state_age":0.0,"landing":0.0,"frame":"","previous":"","blend_age":1.0,"pose":""}
	var s: Dictionary = states[player]
	s.clock += delta
	s.state_age += delta
	s.blend_age += delta
	s.landing = maxf(0.0,float(s.landing)-delta)
	if s.position.y < 585 and p.y >= 589:
		s.landing = .15
	if s.state != state:
		s.state = state
		s.state_age = 0.0
	var distance = minf(absf(p.x-s.position.x),24.0)
	if state in ["walk","dash","evade"]:
		# Cadence follows travelled distance, so changing speed does not skate.
		s.phase = fposmod(float(s.phase)+distance/(126.0 if state=="walk" else 168.0),1.0)
	s.position = p

func sample(f: Dictionary, pose: String, t: float, progress: float) -> Dictionary:
	var cinematic = bool(f.get("_cinematic",false))
	var s: Dictionary = states.get(int(f.get("player",0)),{}) if not cinematic else {}
	var phase = float(s.get("phase",fposmod(t*2.0,1.0)))
	var state = str(f.get("state","idle"))
	var velocity: Vector2 = f.get("vel",Vector2.ZERO)
	var backward = velocity.x*float(f.get("face",1)) < -.1
	var moving = state in ["walk","dash","evade"] and not cinematic
	var running = state in ["dash","evade"]
	var gait = phase*TAU*(-1.0 if backward else 1.0)
	return {"gait":gait,"stride":(24.0 if running else (13.0 if backward else 19.0)) if moving else 0.0,"lift":(15.0 if running else (6.0 if backward else 10.0)) if moving else 0.0,"bob":absf(sin(gait))*3.5 if moving else sin(t*3.6+int(f.id)*.7)*1.1,"breath":sin(t*3.6+int(f.id)*.7)*.005 if state in ["idle","block","crouch_block","intro","entry","victory"] else 0.0,"recoil":sin(progress*PI)*4.5 if state=="attack" and not cinematic else 0.0,"landing":sin(float(s.get("landing",0.0))/.15*PI)*.055,"moving":moving,"backward":backward,"phase":phase,"pose":pose}

func transition(f: Dictionary, frame: String, pose: String) -> Dictionary:
	if bool(f.get("_cinematic",false)) or not states.has(int(f.get("player",0))):
		return {"previous":frame,"mix":1.0}
	var s: Dictionary = states[int(f.player)]
	if s.frame != frame:
		s.previous = s.frame if not str(s.frame).is_empty() else frame
		s.frame = frame
		s.blend_age = 0.0
		s.pose = pose
	# Attack contacts remain readable; locomotion/crouch use a longer dissolve.
	var duration = .035 if str(f.state) in ["attack","hitstun","super_victim"] else .09
	return {"previous":str(s.previous),"mix":smoothstep(0.0,duration,float(s.blend_age))}

static func deform(point: Vector2, motion: Dictionary) -> Vector2:
	var local = point-ANCHOR
	var lower = smoothstep(177.0,300.0,point.y)
	var side = smoothstep(174.0,215.0,point.x)*2.0-1.0
	var gait = float(motion.get("gait",0.0))
	var stride = float(motion.get("stride",0.0))
	var step_wave = sin(gait)*side
	local.x += step_wave*stride*lower
	# The sole in support stays on y=0; only the swinging leg lifts.
	local.y -= maxf(0.0,step_wave)*float(motion.get("lift",0.0))*lower
	local.y -= float(motion.get("bob",0.0))*(1.0-lower)
	local.x += sin(gait+PI)*stride*.11*(1.0-lower)*smoothstep(55.0,150.0,point.y)
	local.y *= 1.0+float(motion.get("breath",0.0))-float(motion.get("landing",0.0))
	# A planted pivot accompanies punches; it is continuous at the pelvis.
	local.x += float(motion.get("recoil",0.0))*sin(lower*PI)
	return local

func make_mesh(key: String, frame: String, data: Dictionary, texture: Texture2D, motion: Dictionary) -> ArrayMesh:
	var cache_key = key+":"+frame
	if not topology.has(cache_key):
		if topology.size() >= CACHE_LIMIT:
			topology.erase(topology.keys()[0])
		topology[cache_key] = _build_topology(frame,data,texture)
	var source: Dictionary = topology[cache_key]
	var vertices = PackedVector3Array()
	for point in source.points:
		var p = deform(point,motion)
		vertices.append(Vector3(p.x,p.y,0))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = source.uvs
	arrays[Mesh.ARRAY_INDEX] = source.indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _build_topology(frame: String, data: Dictionary, texture: Texture2D) -> Dictionary:
	var r: Array = data.frames.get(frame,data.frames.idle0)
	var source = Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
	var clip = PackedVector2Array()
	for vertex in data.get("frame_clips",{}).get(frame,[]):
		clip.append(Vector2(float(vertex[0]),float(vertex[1])))
	var points = PackedVector2Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	for row in ROWS:
		for col in COLS:
			var p = Vector2(col*CELL.x/COLS,row*CELL.y/ROWS)
			var size = CELL/Vector2(COLS,ROWS)
			var quad = PackedVector2Array([p,p+Vector2(size.x,0),p+size,p+Vector2(0,size.y)])
			var pieces: Array = Geometry2D.intersect_polygons(quad,clip) if clip.size()>2 else [quad]
			for polygon in pieces:
				var triangles = Geometry2D.triangulate_polygon(polygon)
				var offset = points.size()
				for point in polygon:
					points.append(point)
					uvs.append((source.position+point/CELL*source.size)/texture.get_size())
				for index in triangles:
					indices.append(offset+index)
	return {"points":points,"uvs":uvs,"indices":indices}
