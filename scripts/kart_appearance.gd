extends RefCounted
## Supplied kart turnarounds, in MoveDB.IDS order. Skin 1 belongs to Diogo.
const REFERENCES = ["arthur","vitorbem","maria","diogo","mirkos","felipe","murilo","gabriel","fabiano","vitormal","lorenzo","leonardo","cristian","fernando"]
const LOOKS = [
	{"kart_color":"202127","accent":"e7e8e5","rim":"bdc0c5","shirt":"181a1e","pants":"202126","shoes":"dedfdc","hair":"442d26","style":"hoodie","hair_style":"curls","detail":"straps"},
	{"kart_color":"123c70","accent":"078cda","rim":"168acd","shirt":"1c304b","pants":"87a8c0","shoes":"e0dfd9","hair":"493026","style":"puffer","hair_style":"curls","inner":"60656b"},
	{"kart_color":"125be9","accent":"f0f1e9","rim":"1a64e8","shirt":"10294d","pants":"8cabc9","shoes":"191c23","hair":"241a23","style":"tee","hair_style":"long","width":0.87},
	{"kart_color":"edece7","accent":"c91426","rim":"d81a27","shirt":"ede9e1","pants":"252428","shoes":"ca1525","hair":"4a3027","style":"tee","hair_style":"messy","detail":"splatter"},
	{"kart_color":"173f72","accent":"097bd4","rim":"197ac9","shirt":"243a60","pants":"181f2d","shoes":"24272c","hair":"32262b","style":"blazer","hair_style":"short","glasses":"clear","beard":"goatee","detail":"lanyard","skin":"cb946e"},
	{"kart_color":"c61722","accent":"ebe8dd","rim":"be1420","shirt":"66636a","pants":"d6ccba","shoes":"c8242d","hair":"613b27","style":"open_hoodie","hair_style":"messy","detail":"chain"},
	{"kart_color":"ea88b2","accent":"f8e6ef","rim":"ed87b8","shirt":"e7a7c6","pants":"aaa99e","shoes":"e2e2dc","hair":"261e22","style":"hoodie","hair_style":"spiky","glasses":"clear","detail":"cords"},
	{"kart_color":"232326","accent":"c9a044","rim":"ceac5d","shirt":"181c22","pants":"202227","shoes":"e5e5df","hair":"392b25","style":"hoodie","hair_style":"swept","detail":"chest_mark"},
	{"kart_color":"68273e","accent":"af4766","rim":"8c3a53","shirt":"6e2d40","pants":"284760","shoes":"5c463a","hair":"664b3f","style":"sweater","hair_style":"receding","beard":"stubble","detail":"collar","skin":"dbab86"},
	{"kart_color":"151d31","accent":"075ce3","rim":"0c75ea","shirt":"22242a","pants":"88a7c6","shoes":"d8dbdb","hair":"37251f","style":"hoodie","hair_style":"curls","detail":"zip"},
	{"kart_color":"0759d4","accent":"e9e9e3","rim":"196ee2","shirt":"1c2027","pants":"20242b","shoes":"161e24","hair":"51392b","style":"tracksuit","hair_style":"buzz","glasses":"dark","beard":"full","detail":"double_stripe","inner":"16446b","skin":"c28f6b","width":1.08},
	{"kart_color":"304b86","accent":"e1e5e6","rim":"6d85bf","shirt":"246447","pants":"335582","shoes":"bfc3c3","hair":"7f8384","style":"sweater","hair_style":"bald","glasses":"clear","beard":"gray","skin":"d6a17b","width":1.18},
	{"kart_color":"075ec9","accent":"e8e8e2","rim":"1978df","shirt":"252629","pants":"d2cab8","shoes":"23272d","hair":"241d20","style":"puffer","hair_style":"fade","glasses":"clear","beard":"full","skin":"c99572"},
	{"kart_color":"20252e","accent":"2f80db","rim":"4277b5","shirt":"a1a1a0","pants":"294b70","shoes":"20272d","hair":"29201d","style":"hoodie","hair_style":"swept","beard":"stubble","detail":"cords","skin":"d3a07c"}
]

static func get_appearance(character: int, skin: int = 0) -> Dictionary:
	var index = clampi(character,0,LOOKS.size()-1)
	var result: Dictionary = LOOKS[index].duplicate(true)
	result.reference = REFERENCES[index]
	result.skin = result.get("skin","e0af89")
	result.width = result.get("width",1.0)
	result.glasses = result.get("glasses","none")
	result.beard = result.get("beard","none")
	result.detail = result.get("detail","none")
	if index == 3 and skin > 0:
		result.merge({"reference":"diogo_alt","kart_color":"cc1724","accent":"eeebe3","rim":"cf1c27","shirt":"1d1e21","pants":"202225","shoes":"191d22","hair":"865742","skin":"c58967","style":"shorts_tee","hair_style":"bald","glasses":"dark","beard":"none","detail":"tattoos","width":1.14},true)
	for key in ["kart_color","accent","rim","shirt","pants","shoes","hair","skin"]:result[key] = Color(result[key])
	result.inner = Color(result.get("inner","222832"))
	return result
