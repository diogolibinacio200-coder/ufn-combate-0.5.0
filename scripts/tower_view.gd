extends RefCounted
## Stacked stone towers with the existing UFN cast. Presentation is read-only;
## completion/progress are committed by main.gd before the bounded animation.
const ICE=Color("9ddcfa")
const AMBER=Color("edbd72")
const LIGHT=Color("edf5fa")
const MUTED=Color("89a7bf")
const STONE=Color("24384c")
const COUNTS=[3,5,8,10]

static func card_rect(index: int) -> Rect2:return Rect2(52+298*index,179,282,431)
static func level_rect(index: int) -> Rect2:return Rect2(767+149*index,108,141,39)
static func start_rect() -> Rect2:return Rect2(945,620,281,39)
static func resume_rect() -> Rect2:return Rect2(674,620,253,39)

func draw(u, screen: String) -> void:
	_environment(u)
	if screen=="tower_select":_selection(u)
	else:_progress(u,screen=="tower_complete")

func _environment(u) -> void:
	var area=Rect2(-u.position,u.get_viewport_rect().size)
	var texture=u.app.arena.backgrounds[3]
	var factor=maxf(area.size.x/texture.get_width(),area.size.y/texture.get_height())
	var extent=texture.get_size()*factor
	u.draw_texture_rect(texture,Rect2(area.get_center()-extent*.5,extent),false,Color(.35,.46,.55))
	u.draw_rect(area,Color(.014,.035,.063,.84))
	u.draw_colored_polygon(PackedVector2Array([Vector2(-100,720),Vector2(670,80),Vector2(1050,80),Vector2(400,720)]),Color(.18,.48,.65,.065))
	for i in 17:
		u.line(Vector2(640,531),Vector2((i-8)*130+640,720),Color(.30,.57,.69,.07))
	u.line(Vector2(0,611),Vector2(1280,611),Color(.32,.64,.76,.18))
	u.topbar("TORRES DOS DESAFIOS · UFN")

func _selection(u) -> void:
	var app=u.app
	u.tx("ESCOLHA SUA TORRE",53,126,43,LIGHT)
	u.tx("3, 5, 8 OU 10 OPONENTES · DOIS CHEFES EM TODAS AS TORRES",56,155,18,MUTED)
	u.tx("DIFICULDADE  /  ↑ ↓ ESCOLHE A LINHA · ← → ALTERA",767,96,15,MUTED)
	for i in 3:
		var r=level_rect(i)
		var selected=i==app.tower_difficulty
		u.panel(r,Color("256887") if selected else Color("0b2337"),ICE if selected else Color("28475d"))
		u.center(app.TOWER_LEVELS[i],r.position.y+27,21,LIGHT if selected else MUTED,r.position.x,r.size.x)
		if selected and app.tower_focus==1:u.draw_rect(Rect2(r.position+Vector2(0,36),Vector2(r.size.x,3)),AMBER)
	for column in 4:
		var r=card_rect(column)
		var count=COUNTS[column]
		var chosen=count==app.tower_count
		u.panel(r,Color(.035,.085,.127,.88),ICE if chosen else Color("284456"))
		if chosen:u.draw_rect(Rect2(r.position,Vector2(r.size.x,4)),ICE)
		u.tx(str(count).pad_zeros(2)+" OPONENTES",r.position.x+20,213,26,LIGHT if chosen else MUTED)
		var record="torre_%d_%d"%[count,app.tower_difficulty]
		if int(app.profile.data.progress.records.get(record,0))>0:u.tx("✓",r.end.x-38,213,24,AMBER)
		var order:Array=app.tower_previews[column] if app.tower_previews.size()==4 else _preview(count)
		_stack(u,order,Vector2(r.position.x+42,582),194,30, -1,0.0,chosen)
		u.center("SELECIONADA" if chosen else "ESCOLHER TORRE",601,14,ICE if chosen else MUTED,r.position.x,r.size.x)
	u.tx("Rivais sorteados ao escolher seu lutador. André CSTH e Kelvin guardam o topo.",56,636,16,MUTED)
	u.tx("Dificuldade e número de lutas são escolhas independentes.",56,655,15,MUTED)
	var r=start_rect()
	u.panel(r,Color("a0d7ef"),ICE);u.center("ESCOLHER LUTADOR  →",r.position.y+27,22,Color("102638"),r.position.x,r.size.x)
	if not app.profile.data.progress.tower.is_empty():
		r=resume_rect()
		var saved:Dictionary=app.profile.data.progress.tower
		u.panel(r,Color("183d4d"),AMBER if app.tower_focus==2 else Color("548395"))
		u.center("RETOMAR  ·  %d / %d"%[int(saved.step)+1,saved.order.size()],r.position.y+27,20,AMBER,r.position.x,r.size.x)
	_footer(u,"ESC  MENU","↑ ↓  TORRE / DIFICULDADE   ·   ← →  ALTERAR","ENTER / A1  CONFIRMAR")

func _preview(count: int) -> Array:
	var order=[]
	for n in count:order.append((n*3+1)%14)
	order.append_array([14,15]);return order

func _progress(u, complete: bool) -> void:
	var app=u.app
	var total=app.arcade_order.size()
	var regular_count=maxi(1,int(app.tower_count))
	if total==0:return
	u.tx("TORRE CONQUISTADA" if complete else "CONQUISTE O CAMPUS",53,130,43,AMBER if complete else LIGHT)
	u.tx("%d OPONENTES + 2 CHEFES  ·  %s"%[regular_count,app.TOWER_LEVELS[app.tower_difficulty]],56,160,21,MUTED)
	u.app.arena.draw_portrait(u,app.chosen[0],Rect2(49,241,312,321),1 if complete else 0,false,app.skins[0])
	u.tx("CAMPEÃO" if complete else "SEU LUTADOR",63,210,17,AMBER if complete else ICE)
	u.center(u.info(app.chosen[0]).name,589,30,LIGHT,42,333)
	var age=app.screen_time if complete else 0.0
	var floor_height=clampf(405.0/float(total)-4.0,27.0,96.0)
	_stack(u,app.arcade_order,Vector2(466,607),262,floor_height,app.arcade_index,age,true)
	if complete:
		u.tx("O TOPO É SEU.",833,251,42,AMBER)
		u.wrap_text("Você venceu todos os desafios e derrubou a Torre UFN.",836,297,379,26,LIGHT,32)
		u.tx("%d OPONENTES + 2 CHEFES DERROTADOS"%[regular_count],837,402,22,ICE)
		u.tx("ANDRÉ CSTH  ✓    KELVIN  ✓",837,439,19,AMBER)
		u.wrap_text("Conquista salva. Seu final vem a seguir.",837,496,356,21,MUTED,28)
		_footer(u,"UFN COMBATE","A TORRE CAIU. O CAMPUS LEMBRA.","ENTER / ESC  CONTINUAR")
	else:
		var next_id=int(app.arcade_order[mini(app.arcade_index,total-1)])
		u.panel(Rect2(832,184,380,343),Color(.024,.066,.106,.92),Color("34566d"))
		u.tx("PRÓXIMO CONFRONTO",852,219,19,AMBER if next_id>=14 else ICE)
		u.tx("%02d / %02d"%[app.arcade_index+1,total],1093,219,23,MUTED)
		u.app.arena.draw_portrait(u,next_id,Rect2(921,237,198,196),0,true)
		u.center(u.info(next_id).name,463,29,LIGHT,846,350)
		u.center("CHEFE FINAL" if next_id==15 else ("CHEFE" if next_id==14 else "DESAFIANTE"),495,17,AMBER if next_id>=14 else MUTED,846,350)
		u.tx("%d VENCIDOS · %d RESTANTES"%[app.arcade_index,total-app.arcade_index],856,552,20,MUTED)
		u.panel(Rect2(888,567,326,59),Color("9ddcfa"),ICE)
		u.center("LUTAR  →",605,30,Color("102638"),888,326)
		_footer(u,"ESC  SALVAR E VOLTAR","DO PRIMEIRO ANDAR ATÉ OS CHEFES","ENTER / A1  LUTAR")

func _footer(u, left: String, middle: String, right: String) -> void:
	u.draw_rect(Rect2(-u.position.x,664,1280+u.position.x*2,56),Color(.012,.032,.054,.97))
	u.line(Vector2(40,664),Vector2(1240,664),Color("355970"))
	u.tx(left,43,699,18,MUTED)
	u.center(middle,699,16,MUTED,288,610)
	u.tx(right,931,699,18,ICE,310,HORIZONTAL_ALIGNMENT_RIGHT)

func _stack(u, order: Array, base: Vector2, width: float, height: float, step: int, age: float, selected: bool) -> void:
	var stride=height+4
	var top=base.y-order.size()*stride
	# Beveled base and UFN cap make the slabs read as a single tower.
	u.draw_colored_polygon(PackedVector2Array([base+Vector2(-17,5),base+Vector2(width+22,5),base+Vector2(width+34,19),base+Vector2(-27,19)]),Color("111f2b"))
	u.draw_rect(Rect2(base+Vector2(-19,0),Vector2(width+41,7)),Color("46677b"))
	if age<1.3:
		var alpha=1.0-smoothstep(.3,1.3,age)
		u.draw_rect(Rect2(base.x+12,top-26,width-4,21),Color(.10,.26,.36,alpha))
		u.center("U F N",top-10,15,Color(ICE,alpha),base.x+12,width-4)
	for i in order.size():
		var origin=Vector2(base.x,base.y-(i+1)*stride)
		var delay=.32+i*.095
		if age>delay:_crumble(u,int(order[i]),origin,width,height,age-delay,i)
		else:
			if age>0:origin.x+=sin(age*93+i)*3*float(u.app.profile.data.settings.shake)
			_block(u,int(order[i]),i,origin,width,height,step,selected)
	u.draw_set_transform(Vector2.ZERO)

func _block(u, id: int, index: int, origin: Vector2, width: float, height: float, step: int, selected: bool) -> void:
	var active=index==step
	var done=step>=0 and index<step
	var edge=AMBER if id>=14 else (ICE if active else Color("527087"))
	var fill=Color("16465d") if active else (Color("1b343b") if done else STONE)
	u.draw_set_transform(origin)
	u.draw_rect(Rect2(3,4,width+15,height+2),Color(0,0,0,.46))
	u.draw_colored_polygon(PackedVector2Array([Vector2(width,0),Vector2(width+15,-5),Vector2(width+15,height-5),Vector2(width,height)]),Color("142739"))
	u.draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(15,-5),Vector2(width+15,-5),Vector2(width,0)]),Color("466174"))
	u.draw_rect(Rect2(0,0,width,height),fill)
	u.draw_rect(Rect2(0,0,width,height),edge if selected else edge.darkened(.3),false,1.2)
	# Deterministic stone grain and seams, with no allocated scene objects.
	for n in 7:
		var x=fposmod(index*31+n*37,width-9)
		var y=4+fposmod(index*11+n*7,height-9)
		u.draw_line(Vector2(x,y),Vector2(x+5+n%4,y-1),Color(.58,.73,.80,.11),1)
	u.draw_line(Vector2(width*.46,0),Vector2(width*.42,height*.22),Color(0,0,0,.23),1)
	u.tx("✓" if done else str(index+1).pad_zeros(2),8,height*.5+5,13,Color("7dbfac") if done else edge)
	u.tx(u.info(id).name,34,height*.5+5,17 if height>64 else (15 if height>34 else 13),LIGHT if not done else MUTED,width-height-44)
	_face(u,id,Rect2(width-height+2,3,height-6,height-6),.55 if done else 1.0)
	if active:
		var pulse=.65+sin(u.app.clock_time*4)*.25
		u.draw_rect(Rect2(-4,-2,3,height+4),Color(ICE,pulse))
	u.draw_set_transform(Vector2.ZERO)

func _face(u, id: int, rect: Rect2, alpha: float = 1.0) -> void:
	var texture=u.app.arena.portrait_art[u.app.arena.NAMES[id]]
	var source=Rect2(texture.get_width()*.20,0,texture.get_width()*.60,texture.get_width()*.60)
	u.draw_rect(rect,Color(.008,.026,.044,alpha))
	u.draw_texture_rect_region(texture,rect,source,Color(1,1,1,alpha))
	u.draw_rect(rect,Color(AMBER if id>=14 else ICE,alpha*.5),false,1)

func _crumble(u, id: int, origin: Vector2, width: float, height: float, age: float, index: int) -> void:
	var alpha=1.0-smoothstep(1.3,2.15,age)
	if alpha<=0:return
	for piece in 6:
		var column=piece%3
		var row=int(piece/3)
		var size=Vector2(width/3-2,height/2-1)
		var direction=(column-1)*97+sin(index*3+piece)*44
		var position=origin+Vector2((column+.5)*width/3,(row+.5)*height/2)+Vector2(direction*age,-70*age+295*age*age)
		u.draw_set_transform(position,sin(index+piece*2.1)*age*2.4)
		u.draw_rect(Rect2(-size*.5,size),Color(STONE.lightened(.025*piece),alpha))
		u.draw_line(-size*.5,Vector2(size.x*.5,-size.y*.5),Color(.36,.51,.60,alpha),2)
		u.draw_line(Vector2(-size.x*.5,size.y*.5),size*.5,Color(.025,.065,.09,alpha),2)
	var position=origin+Vector2(width-20,height*.5)+Vector2(45*age,-95*age+275*age*age)
	u.draw_set_transform(position,age*(.8 if index%2 else -.8))
	_face(u,id,Rect2(-16,-16,32,32),alpha)
	u.draw_set_transform(Vector2.ZERO)
	for n in 5:
		var dust=origin+Vector2(width*.5+sin(index+n*2)*age*120,height+20*age+190*age*age)
		u.draw_circle(dust,3+age*5,Color(.55,.66,.69,alpha*.13))
