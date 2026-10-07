extends RefCounted
## Original city geometry. Geographic references are documented in docs/PISTA-UFN.md.
## X follows Andradas eastward; -Z follows Serafim toward Silva Jardim.
const NAME = "UFN / ANDRADAS"
const STREETS = ["RUA DOS ANDRADAS", "R. SERAFIM VALANDRO", "RUA SILVA JARDIM", "R. DUQUE DE CAXIAS"]

static func anchors() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-52,66),Vector2(32,66),Vector2(70,63),Vector2(86,47),Vector2(86,-40),Vector2(78,-60),Vector2(58,-66),Vector2(-61,-66),Vector2(-84,-54),Vector2(-90,-34),Vector2(-90,42),Vector2(-77,61)])

static func build(game) -> void:
	var world: Node3D = game.world
	# Dense university block with a courtyard, glazed galleries and a recessed entry.
	_building(game,Vector3(-20,0,-39),Vector3(69,14,17),Color("e6e0cd"),"UFN  •  CONJUNTO II",true)
	_building(game,Vector3(-47,0,-10),Vector3(15,11,38),Color("dad8cc"),"ENGENHARIAS",true)
	_building(game,Vector3(17,0,-20),Vector3(17,17,28),Color("d5d9d4"),"ITEC / UFN",true)
	game.cube(world,Vector3(-16,.09,-9),Vector3(44,.16,31),Color("c5c2af"))
	for x in [-34,-22,-10,2]:
		game.cube(world,Vector3(x,.19,-8),Vector3(.22,.06,24),Color("ebe7d8"))
	for p in [Vector2(-28,-7),Vector2(-4,-7)]:game._tree(p,.9)
	_building(game,Vector3(-32,0,36),Vector3(42,12,16),Color("e7d5b6"),"UNIVERSIDADE FRANCISCANA",true)
	_building(game,Vector3(44,0,29),Vector3(25,9,25),Color("d1b7a1"),"SANTA MARIA",false)
	# Block edges: small commercial fronts, apartments, gates and awnings.
	for n in 9:
		var x=-93.0+n*22.0
		var color=[Color("e0ccaf"),Color("c0cecb"),Color("d5b7ad"),Color("d3d0be")][n%4]
		_building(game,Vector3(x,0,98),Vector3(19,8+(n%3)*4,18),color,["LIVRARIA","CAFÉ ANDRADAS","CENTRO","PAPELARIA"][n%4],false)
		_building(game,Vector3(x,0,-100),Vector3(19,10+(n%4)*3,18),color,"",false)
	for side in [-1,1]:
		for n in 5:
			_building(game,Vector3(side*121,0,-52+n*26),Vector3(22,8+(n%3)*5,23),Color("cbbca9") if n%2 else Color("b9cace"),"",false)
	# Side streets terminate at visible barriers; they do not form shortcuts.
	for s in [game.sample_road(game.total_length*.23),game.sample_road(game.total_length*.52),game.sample_road(game.total_length*.78)]:
		var n=Vector2(-s.dir.y,s.dir.x)
		for side in [-1,1]:
			var p=Vector2(s.pos)+n*side*23
			var street=game.cube(world,Vector3(p.x,.03,p.y),Vector3(27,.025,13),Color("3e4246"))
			street.rotation.y=-Vector2(n).angle()
	# Crossing markings, lamps, street names and parked vehicles at regular safe setbacks.
	for i in 20:
		var s=game.sample_road(game.total_length*float(i)/20)
		var normal=Vector2(-s.dir.y,s.dir.x)
		for side in [-1,1]:
			var p=Vector2(s.pos)+normal*side*11.9
			game.cylinder(world,Vector3(p.x,3.4,p.y),.11,6.8,Color("52616b"))
			game.cube(world,Vector3(p.x,6.8,p.y),Vector3(1.3,.18,.55),Color("fff0bb"),true)
			if i%3==1:
				var tree=Vector2(s.pos)+normal*side*15.0
				if game.nearest_road(tree).offset>12:game._tree(tree,.6)
		if i in [3,8,13,18]:
			for j in 10:
				var p=Vector2(s.pos)+normal*(-6.2+j*1.38)
				var stripe=game.cube(world,Vector3(p.x,.052,p.y),Vector3(3,.015,.62),Color("eee7d1"))
				stripe.rotation.y=-Vector2(s.dir).angle()
		if i in [0,5,10,15]:
			var p=Vector2(s.pos)+normal*11.9
			var node=Node3D.new();world.add_child(node);node.position=Vector3(p.x,0,p.y)
			node.rotation.y=-Vector2(s.dir).angle()-PI/2
			game.cube(node,Vector3(0,4.6,0),Vector3(8.4,.8,.15),Color("183e62"))
			game.sign3d(node,STREETS[i/5],Vector3(0,4.6,.1),32,Color.WHITE)
			game.sign3d(node,STREETS[i/5],Vector3(0,4.6,-.1),32,Color.WHITE,PI)
		if i in [2,7,12,17]:
			var p=Vector2(s.pos)+normal*12.1
			_parked_car(game,p,-Vector2(s.dir).angle()-PI/2,i)
	# Cone chicane before the final corner; the CPU sees the same obstacles.
	for i in 3:
		var s=game.sample_road(game.total_length*.91+i*2.1)
		var p=Vector2(s.pos)+Vector2(-s.dir.y,s.dir.x)*5.8
		game.cube(world,Vector3(p.x,.10,p.y),Vector3(.85,.20,.85),Color("2b3238"))
		game.cylinder(world,Vector3(p.x,.6,p.y),.27,.9,Color("ef782d"))
		game.cylinder(world,Vector3(p.x,.67,p.y),.28,.18,Color("fff0d5"))
		game.track_obstacles.append({"pos":p,"radius":.55,"kind":"cone"})
	for n in 9:game.ball(world,Vector3(-210+n*57,-8,-235),43,Color("668384"),Vector3(1.4,.8,1))

static func _building(game, pos: Vector3, size: Vector3, color: Color, title: String, campus: bool) -> void:
	game._building(pos,size,color,title)
	game.scenery_bounds.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	var world: Node3D=game.world
	if campus:
		for side in [-1,1]:
			game.cube(world,pos+Vector3(0,size.y*.46,side*(size.z/2+.12)),Vector3(size.x,.45,.35),Color("f4f0df"))
		game.cube(world,pos+Vector3(0,2.1,size.z/2+.13),Vector3(5,4.2,.15),Color("234859"))
		game.cube(world,pos+Vector3(0,4.4,size.z/2+1.6),Vector3(10,.25,3.5),Color("ddd9cb"))
	else:
		game.cube(world,pos+Vector3(0,1.65,size.z/2+.1),Vector3(size.x*.7,2.7,.15),Color("455e64"))
		game.cube(world,pos+Vector3(0,3.3,size.z/2+.55),Vector3(size.x*.82,.18,1.1),Color("995953"))

static func _parked_car(game, pos: Vector2, angle: float, index: int) -> void:
	var node=Node3D.new();game.world.add_child(node);node.position=Vector3(pos.x,0,pos.y);node.rotation.y=angle
	var color=[Color("9d5147"),Color("9fa8ad"),Color("536979"),Color("c9c2ac")][index%4]
	game.cube(node,Vector3(0,.7,0),Vector3(1.9,.8,4.2),color)
	game.cube(node,Vector3(0,1.25,.1),Vector3(1.65,.7,2.1),color)
	game.cube(node,Vector3(0,1.38,-.98),Vector3(1.4,.45,.07),Color("32576a"))
	for side in [-1,1]:
		for z in [-1.25,1.25]:
			var tire=game.cylinder(node,Vector3(side*.95,.4,z),.36,.16,Color("25292d"));tire.rotation.z=PI/2
	game.track_obstacles.append({"pos":pos,"radius":2.3,"kind":"parked_car"})
