extends SceneTree
## Asset and lifecycle regression: Vitor's summon never borrows Maria's art.
const Art=preload("res://scripts/ally_art.gd")
const Arena=preload("res://scripts/arena_view.gd")
const Kart=preload("res://scripts/kart.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(value:bool,label:String):
	checks+=1
	if not value:failures+=1;printerr("ALLY FAIL: "+label)
func run():
	var arena=Arena.new();root.add_child(arena);arena.set_process(false)
	check(arena.ally_texture!=null,"Exclusive summon texture loads")
	check(arena.sprite_atlas.has("maria") and arena.ally_texture!=arena.sprite_atlas.maria,"Maria remains playable with her own unmodified art")
	var image=arena.ally_texture.get_image()
	check(image.get_width()==1536 and image.get_height()==1024,"Original full resolution asset is present")
	check(image.get_pixel(0,0).a<.01 and image.get_pixel(1535,1023).a<.01,"Atlas uses real transparency")
	for frame in Art.FRAMES:
		var region:Rect2=Art.FRAMES[frame]
		check(Rect2(Vector2.ZERO,Vector2(image.get_size())).encloses(region),"Pose lies inside atlas: "+frame)
		check(region.size.x>Art.ANCHORS[frame].x and region.size.y>Art.ANCHORS[frame].y,"Foot anchor remains inside pose: "+frame)
	var game=Kart.new();root.add_child(game);game.setup(null);game.race_mode="time_trial"
	game.start([9],[0],4,1);game.set_process(false);game.set_physics_process(false)
	check(game.IDS.size()==14 and not game.IDS.has(Art.ID),"Ally adds no selectable character")
	var racer=game.racers[0]
	var effect=racer.node.get_node("SignatureDisplay")
	check(effect.has_node("BlondeAlly") and not effect.visible,"Kart summon starts inactive")
	racer.signature=2.0;game._sync_kart(racer,.016)
	check(effect.visible and effect.get_node("BlondeAlly").texture.atlas.resource_path==Art.TEXTURE_PATH,"Active kart ability shows exclusive blonde ally")
	racer.signature=0.0;game._sync_kart(racer,.016)
	check(not effect.visible,"Expired ability hides ally")
	game.stop();await process_frame;await process_frame
	check(not is_instance_valid(effect),"Race cleanup frees summon")
	game.queue_free();arena.queue_free();await process_frame
	print("ALLY 0.5.0: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
