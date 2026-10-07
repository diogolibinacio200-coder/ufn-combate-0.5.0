extends Node3D
## Supplied kart turnarounds translated into seated, articulated 3D pilots.
## Hips/pedals stay fixed; hands are solved in wheel space after body reactions.
const Appearance = preload("res://scripts/kart_appearance.gd")
var upper: Node3D
var head: Node3D
var wheel: Node3D
var arms: Array = []
var kart
var look: Dictionary
var body_width = 1.0
var lean = 0.0
var pitch = 0.0
var previous_speed = 0.0
var elapsed = 0.0
var skin_color = Color("dbab88")
var knee_points: Array[Vector3] = []

static func appearance(character: int, skin: int = 0) -> Dictionary:
	return Appearance.get_appearance(character,skin)

static func add_crown(host, parent: Node3D, position: Vector3, size: float, color: Color) -> Node3D:
	# Filled crown in XZ plane, tips towards the driver (+Z), upright from front.
	var badge=Node3D.new();badge.name="CrownBadge";badge.position=position;parent.add_child(badge)
	var polygon=PackedVector2Array([Vector2(-.46,-.35),Vector2(-.20,-.07),Vector2(0,-.48),Vector2(.20,-.07),Vector2(.46,-.35),Vector2(.35,.22),Vector2(-.35,.22)])
	var indices=Geometry2D.triangulate_polygon(polygon)
	var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for idx in indices:
		var point=polygon[idx]*size
		mesh.set_normal(Vector3.UP);mesh.add_vertex(Vector3(-point.x,0,-point.y))
	var node=MeshInstance3D.new();node.mesh=mesh.commit()
	var mat: StandardMaterial3D=host.material(color).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=mat;badge.add_child(node)
	host.cube(badge,Vector3(0,0,-.32*size),Vector3(.71*size,.008,.065*size),color)
	return badge

func build(host, character: int, skin: int, steering: Node3D) -> void:
	kart=host;wheel=steering;look=appearance(character,skin)
	name="Driver";set_meta("character",character);set_meta("skin",skin);set_meta("reference",look.reference)
	skin_color=look.skin;body_width=look.width
	_build_legs()
	upper=Node3D.new();upper.name="UpperBody";upper.position=Vector3(0,.89,.10);add_child(upper)
	_build_clothing()
	head=Node3D.new();head.name="Head";head.position=Vector3(0,.91,-.04);upper.add_child(head)
	_build_face();_build_hair()
	kart.batch_meshes(head);kart.batch_meshes(upper)
	for side in [-1.0,1.0]:
		var sleeve=link(self,Vector3.ZERO,Vector3.UP,.12*body_width,look.shirt)
		var bare=look.style in ["tee","shorts_tee"]
		var forearm=link(self,Vector3.ZERO,Vector3.UP,.105 if look.style=="puffer" else .080,skin_color if bare else look.shirt)
		var cuff=kart.ball(self,Vector3.ZERO,.084,look.shirt.darkened(.10),Vector3(1,.7,1))
		var hand=kart.ball(self,Vector3.ZERO,.077,skin_color,Vector3(.91,.85,1.1))
		var elbow=kart.ball(self,Vector3.ZERO,.104,skin_color if bare else look.shirt)
		if look.style=="tracksuit":
			for n in [-1.0,1.0]:kart.cube(forearm,Vector3(side*.075,0,n*.036),Vector3(.013,.95,.020),Color("e6e5df"))
		if look.detail=="tattoos":
			for n in 6:
				var tattoo=kart.cube(forearm,Vector3(side*.065,-.34+n*.125,-.027),Vector3(.022,.08,.07),Color("514138"));tattoo.rotation.y=n*.65
		arms.append({"side":side,"upper":sleeve,"forearm":forearm,"hand":hand,"elbow":elbow,"cuff":cuff,"bare":bare})
	animate({"steer":0.0,"speed":0.0,"boost":0.0,"stun":0.0,"jump":0.0,"signature":0.0},1.0)

func _build_legs() -> void:
	var lower=Node3D.new();lower.name="SeatedLegs";add_child(lower)
	var shorts=look.style=="shorts_tee"
	kart.ball(lower,Vector3(0,.84,.12),.30,look.pants,Vector3(1.05,.53,.9))
	for side in [-1.0,1.0]:
		var hip=Vector3(side*.18,.87,.09)
		var knee=Vector3(side*.235,.86,-.43);knee_points.append(knee)
		var ankle=Vector3(side*.235,.63,-.81)
		link(lower,hip,knee,.132,look.pants);link(lower,knee,ankle,.103,skin_color if shorts else look.pants)
		kart.ball(lower,knee,.137,skin_color if shorts else look.pants,Vector3(1,.86,1))
		kart.ball(lower,Vector3(side*.235,.60,-.89),.153,look.shoes,Vector3(.82,.50,1.48))
		kart.cube(lower,Vector3(side*.235,.55,-.90),Vector3(.23,.028,.38),Color("e3e2d9"))
		for lace in 3:kart.cube(lower,Vector3(side*.235,.657,-.87-float(lace)*.045),Vector3(.13,.010,.012),Color("e0e0da"))
		if look.style=="tracksuit":
			for stripe in [-1.0,1.0]:
				link(lower,hip+Vector3(side*.116,0,stripe*.030),knee+Vector3(side*.116,0,stripe*.030),.010,Color("e9e8df"))
				link(lower,knee+Vector3(side*.093,0,stripe*.030),ankle+Vector3(side*.093,0,stripe*.030),.010,Color("e9e8df"))
		if shorts:
			for n in 3:kart.cube(lower,Vector3(side*.305,.91-n*.044,-.21),Vector3(.025,.028,.19),Color("e3e1d9"))
	kart.batch_meshes(lower)

func _build_clothing() -> void:
	var shirt: Color=look.shirt
	kart.ball(upper,Vector3(0,.35,-.04),.34,shirt,Vector3(.97*body_width,1.20,.67))
	kart.cube(upper,Vector3(0,.16,-.194),Vector3(.43*body_width,.23,.05),shirt.darkened(.10))
	kart.cylinder(upper,Vector3(0,.72,-.04),.107,.16,skin_color)
	if look.style in ["hoodie","open_hoodie","puffer"]:
		kart.ball(upper,Vector3(0,.64,.125),.215,shirt.darkened(.14),Vector3(1.16,.74,.68))
		for side in [-1.0,1.0]:
			link(upper,Vector3(side*.13,.67,-.13),Vector3(side*.17,.44,-.248),.016,shirt.lightened(.26))
			kart.ball(upper,Vector3(side*.17,.44,-.248),.022,shirt.darkened(.26))
	if look.style=="puffer":
		for row in 4:kart.ball(upper,Vector3(0,.18+row*.12,-.043),.34,shirt.lightened(.055 if row%2 else 0),Vector3(body_width,.20,.76))
		link(upper,Vector3(0,.13,-.265),Vector3(0,.67,-.221),.011,Color("747776"))
	if look.style=="blazer":
		kart.cube(upper,Vector3(0,.37,-.248),Vector3(.16,.40,.04),Color("1a2638"))
		for side in [-1.0,1.0]:
			var lapel=kart.cube(upper,Vector3(side*.112,.49,-.25),Vector3(.075,.27,.035),shirt.lightened(.10));lapel.rotation.z=side*-.32
			link(upper,Vector3(side*.065,.65,-.22),Vector3(side*.035,.34,-.287),.016,Color("ddac4c"))
		kart.cube(upper,Vector3(0,.30,-.29),Vector3(.105,.145,.02),Color("2868a1"))
		kart.cube(upper,Vector3(0,.315,-.304),Vector3(.07,.03,.008),Color("d1d6cb"))
	if look.style=="open_hoodie":
		kart.cube(upper,Vector3(0,.45,-.25),Vector3(.14,.36,.025),skin_color)
		for side in [-1.0,1.0]:link(upper,Vector3(side*.095,.69,-.15),Vector3(side*.13,.27,-.25),.025,shirt.darkened(.28))
	if look.detail=="collar":
		for side in [-1.0,1.0]:
			var collar=kart.cube(upper,Vector3(side*.072,.65,-.173),Vector3(.09,.105,.027),Color("b9cad5"));collar.rotation.z=side*.42
	if look.style=="tracksuit":
		kart.cube(upper,Vector3(0,.50,-.25),Vector3(.15,.27,.035),look.inner)
		for side in [-1.0,1.0]:
			for n in 2:link(upper,Vector3(side*(.15+n*.038),.65,-.12),Vector3(side*(.29+n*.026),.53,-.08),.012,Color("e6e5df"))
	if look.detail in ["chain","tattoos"]:
		for n in 11:
			var t=float(n)/10
			kart.ball(upper,Vector3((t-.5)*.28,.67-sin(t*PI)*.115,-.17-sin(t*PI)*.075),.014,Color("d4d1bb"))
	if look.detail=="splatter":
		for n in 17:
			var xx=sin(n*8.17)*.175
			kart.cube(upper,Vector3(xx,.14+float(n%5)*.058,-.262+absf(xx)*.18),Vector3(.029+float(n%3)*.011,.032+float(n%2)*.04,.013),Color("232326"))
	if look.detail=="straps":
		for side in [-1.0,1.0]:
			link(upper,Vector3(side*.195,.66,-.12),Vector3(side*.23,.27,-.228),.034,Color("33373a"))
			kart.cube(upper,Vector3(side*.21,.53,-.212),Vector3(.074,.059,.025),Color("717477"))
	if look.detail=="chest_mark":
		for n in 6:kart.cube(upper,Vector3((n-2.5)*.038,.49,-.269),Vector3(.024,.011,.008),Color("b0b2ad"))
	if look.detail=="zip":link(upper,Vector3(0,.24,-.264),Vector3(0,.65,-.209),.010,Color("8e9293"))

func _build_face() -> void:
	kart.ball(head,Vector3.ZERO,.260,skin_color,Vector3(.88,1.05,.83))
	for side in [-1.0,1.0]:
		kart.ball(head,Vector3(side*.225,.015,.012),.050,skin_color,Vector3(.65,1,1))
		kart.cube(head,Vector3(side*.088,.045,-.210),Vector3(.061,.030,.018),Color("f0e6d9"))
		kart.cube(head,Vector3(side*.091,.046,-.222),Vector3(.025,.026,.012),Color("28272a"))
		var brow=kart.cube(head,Vector3(side*.095,.089,-.208),Vector3(.082,.021,.024),look.hair.darkened(.2));brow.rotation.z=side*.08
	kart.ball(head,Vector3(0,.002,-.222),.053,skin_color,Vector3(.64,.88,.8))
	kart.cube(head,Vector3(0,-.081,-.204),Vector3(.084,.014,.02),skin_color.darkened(.35))
	if look.beard!="none":
		var beard: Color=Color("929495") if look.beard=="gray" else look.hair.darkened(.12)
		if look.beard=="stubble":beard=beard.lerp(skin_color,.28)
		kart.ball(head,Vector3(0,-.122,-.08),.169,beard,Vector3(.93,.51,.77))
		for side in [-1.0,1.0]:
			if look.beard!="goatee":link(head,Vector3(side*.187,.003,-.074),Vector3(side*.118,-.12,-.177),.045,beard)
			kart.cube(head,Vector3(side*.038,-.047,-.214),Vector3(.057,.023,.020),beard)
		kart.cube(head,Vector3(0,-.079,-.223),Vector3(.068,.012,.014),skin_color.darkened(.34))
	if look.glasses!="none":
		for side in [-1.0,1.0]:
			var center=Vector3(side*.102,.050,-.239)
			for edge in [-1.0,1.0]:
				kart.cube(head,center+Vector3(0,edge*.044,0),Vector3(.169,.017,.022),Color("12191f"))
				kart.cube(head,center+Vector3(edge*.078,0,0),Vector3(.017,.091,.022),Color("12191f"))
			if look.glasses=="dark":
				kart.cube(head,center,Vector3(.137,.067,.014),Color("1d252b"))
				kart.cube(head,center+Vector3(-.03,.014,-.012),Vector3(.04,.011,.006),Color("667886"))
			link(head,center+Vector3(side*.083,.009,.004),Vector3(side*.238,.056,.03),.011,Color("16191e"))
		kart.cube(head,Vector3(0,.057,-.242),Vector3(.049,.019,.020),Color("12191f"))

func _build_hair() -> void:
	var hair: Color=look.hair
	match look.hair_style:
		"bald":pass
		"buzz":kart.ball(head,Vector3(0,.143,.025),.246,hair,Vector3(.97,.47,.91))
		"long":
			kart.ball(head,Vector3(0,.18,.045),.258,hair,Vector3(1.04,.52,.94))
			_long_hair_curtain(hair)
			for side in [-1.0,1.0]:link(head,Vector3(side*.12,.2,-.15),Vector3(side*.239,-.20,-.06),.062,hair)
		_:
			var faded=look.hair_style in ["fade","short","receding"]
			kart.ball(head,Vector3(0,.178,.029),.253,hair,Vector3(.97,.44,.89))
			for side in [-1.0,1.0]:kart.ball(head,Vector3(side*.204,.107,.056),.104,hair.lerp(skin_color,.35 if faded else 0),Vector3(.51,.87,1.02))
			if look.hair_style=="receding":
				for side in [-1.0,1.0]:kart.ball(head,Vector3(side*.184,.135,.012),.067,Color("9e8980"),Vector3(.5,1.05,1))
			else:
				var count=19 if look.hair_style=="curls" else 11
				for n in count:
					var angle=n*2.39996;var radius=.18*sqrt(float(n+1)/count)
					var pos=Vector3(cos(angle)*radius,.20+(.036 if n%2 else .011),sin(angle)*radius-.025)
					var lock=kart.ball(head,pos,.073,hair.lightened(float(n%3)*.045),Vector3(1,.89 if look.hair_style=="curls" else 1.12,1))
					if look.hair_style=="swept":lock.rotation.z=.55;lock.scale=Vector3(.75,.78,1.5)
					if look.hair_style in ["spiky","fade"]:lock.scale=Vector3(.7,1.23,.8)

func _long_hair_point(row: int, column: int) -> Vector3:
	var theta=float(column)/12*PI
	var radii=[.225,.254,.273,.297]
	var heights=[.18,.00,-.28,-.54]
	return Vector3(cos(theta)*radii[row],heights[row]+sin(column*2.4)*.023*row,sin(theta)*(.16+row*.015)+.053+sin(column*2.3+row)*.014)

func _long_hair_curtain(color: Color) -> void:
	# Connected volume behind Maria's head keeps long hair legible from chase view.
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 3:
		for column in 12:
			var a=_long_hair_point(row,column);var b=_long_hair_point(row,column+1)
			var c=_long_hair_point(row+1,column);var d=_long_hair_point(row+1,column+1)
			for vertex in [a,b,c,b,d,c]:surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh=MeshInstance3D.new();mesh.mesh=surface.commit()
	var mat: StandardMaterial3D=kart.material(color).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=mat;head.add_child(mesh)
	for column in range(0,13,2):
		for row in 3:link(head,_long_hair_point(row,column),_long_hair_point(row+1,column),.017,color.lightened(.085))

func link(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node=kart.cylinder(parent,Vector3.ZERO,radius,1.0,color);pose_link(node,a,b);return node

func pose_link(node: Node3D, a: Vector3, b: Vector3) -> void:
	var delta=b-a
	node.position=(a+b)*.5;node.quaternion=Quaternion(Vector3.UP,delta.normalized());node.scale=Vector3(1,maxf(.001,delta.length()),1)

func animate(r: Dictionary, dt: float) -> void:
	var amount=1.0-exp(-12.0*dt)
	var speed=float(r.get("speed",0));var steer=float(r.get("steer",0))
	var acceleration=clampf((speed-previous_speed)/maxf(dt,.001),-30.0,30.0)
	previous_speed=speed;elapsed+=dt
	lean=lerpf(lean,-steer*.095*minf(absf(speed)/20.0,1.0),amount)
	pitch=lerpf(pitch,acceleration*.0016+(.08 if float(r.get("boost",0))>0 else 0.0)+sin(float(r.get("stun",0))*24.0)*.11+sin(float(r.get("jump",0))*PI)*.055-sin(minf(float(r.get("signature",0)),1.0)*PI)*.045,amount)
	upper.rotation=Vector3(pitch+sin(elapsed*2.3)*.006,0,lean)
	head.rotation.y=lerpf(head.rotation.y,-steer*.14,amount);head.rotation.z=-lean*.30
	wheel.rotation.y=-steer*.48
	for arm in arms:
		var side=float(arm.side)
		var shoulder=upper.transform*Vector3(side*.276*body_width,.55,-.07)
		var elbow=upper.transform*Vector3(side*.365*body_width,.28,-.26)
		var hand=global_transform.affine_inverse()*(wheel.global_transform*Vector3(side*.263,0,0))
		pose_link(arm.upper,shoulder,elbow);pose_link(arm.forearm,elbow,hand)
		arm.hand.position=hand;arm.hand.rotation.z=-steer*.15;arm.elbow.position=elbow
		arm.cuff.position=elbow.lerp(hand,.87);arm.cuff.visible=not arm.bare
