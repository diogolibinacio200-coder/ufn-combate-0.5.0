extends RefCounted
## Supporting summon, never a roster ID or a skin of Maria.
const ID = "vitor_ally_blonde"
const TEXTURE_PATH = "res://assets/sprites/vitor_ally_blonde/atlas.png"
const FRAMES = {
	"guard":Rect2(0,0,360,512), "run0":Rect2(376,0,392,512),
	"run1":Rect2(770,0,394,512), "windup":Rect2(1176,0,360,512),
	"punch0":Rect2(0,512,422,512), "punch1":Rect2(420,512,350,512),
	"kick":Rect2(750,512,490,512)
}
const ANCHORS = {
	"guard":Vector2(175,499),"run0":Vector2(181,495),"run1":Vector2(222,494),
	"windup":Vector2(183,499),"punch0":Vector2(189,487),
	"punch1":Vector2(180,487),"kick":Vector2(194,487)
}
# The generated atlas has overlapping cell extents. UV contours exclude pixels
# belonging to neighbouring poses, while preserving both shoes and flying hair.
const CONTOURS = {
	"punch1":[Vector2(0,0),Vector2(331,0),Vector2(331,150),Vector2(350,200),Vector2(350,512),Vector2(0,512)],
	"kick":[Vector2(0,0),Vector2(490,0),Vector2(490,225),Vector2(270,285),Vector2(270,512),Vector2(115,512),Vector2(100,320),Vector2(0,210)]
}
static func pose(time: float, variant: int) -> String:
	return ["run0","run1","windup","punch0","punch1","guard"][posmod(int(time*12)+variant,6)]
