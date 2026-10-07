extends RefCounted
## Versioned local profile. A failed write leaves the last good profile intact.

const PROFILE: String = "user://profile.json"
const TEMP: String = "user://profile.json.tmp"
const BACKUP: String = "user://profile.json.bak"
var data: Dictionary = {}
var last_error: String = ""
var _profile_path: String = PROFILE
var _temp_path: String = TEMP
var _backup_path: String = BACKUP

func _init(profile_path: String = PROFILE) -> void:
	_profile_path = profile_path
	_temp_path = profile_path + ".tmp"
	_backup_path = profile_path + ".bak"
	data = defaults()

func defaults() -> Dictionary:
	return {
		"version": 2,
		"settings": {"music": 0.5, "sfx": 0.7, "shake": 0.6, "flashes": 0.5, "rounds": 3, "difficulty": 1, "fullscreen": true, "resolution": 0, "arcade_mode": false,"master":0.8,"voice":0.7,"quality":1,"particles":0.7,"subtitles":true,"text_size":0,"auto_accelerate":false,"split_horizontal":false},
		"stats": {"matches": 0, "p1_wins": 0, "p2_wins": 0, "most_played": {}, "biggest_combo": 0, "perfect_blocks": 0, "guard_breaks": 0, "supers": 0},
		"progress":{"tower":{},"championship":{},"records":{},"achievements":[]},
		"bindings": {}
	}

func load_profile() -> Dictionary:
	data = defaults()
	last_error = ""
	var parsed: Variant = _read(_profile_path)
	if not parsed is Dictionary:
		parsed = _read(_backup_path)
	if parsed is Dictionary:
		for section: String in ["settings", "stats", "bindings", "progress"]:
			var incoming: Variant = parsed.get(section, {})
			if incoming is Dictionary:
				data[section].merge(incoming, true)
	_sanitize()
	return data

func save_profile() -> bool:
	last_error = ""
	_sanitize()
	var file: FileAccess = FileAccess.open(_temp_path, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível gravar o perfil: " + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Falha ao gravar o perfil: " + error_string(write_error)
		return false
	# Backup is secondary recovery; rename of a fully flushed temporary is the commit.
	if FileAccess.file_exists(_profile_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(_profile_path), ProjectSettings.globalize_path(_backup_path))
	var commit_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(_temp_path), ProjectSettings.globalize_path(_profile_path))
	if commit_error != OK:
		last_error = "Falha ao confirmar o perfil: " + error_string(commit_error)
		return false
	return true

func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return parser.data

func _sanitize() -> void:
	var baseline: Dictionary = defaults()
	for section: String in ["settings", "stats", "bindings", "progress"]:
		if not data.get(section) is Dictionary:
			data[section] = baseline[section].duplicate(true)
		else:
			data[section].merge(baseline[section], false)
	var settings: Dictionary = data["settings"]
	for setting: String in ["music", "sfx", "shake", "flashes","master","voice","particles"]:
		var value: Variant = settings[setting]
		settings[setting] = clampf(float(value), 0.0, 1.0) if value is float or value is int else baseline["settings"][setting]
	if not settings["rounds"] in [1, 3, 5]:
		settings["rounds"] = 3
	for setting: String in ["difficulty", "resolution", "quality", "text_size"]:
		var value: Variant = settings[setting]
		var upper_bound: int = 3 if setting == "difficulty" else 1
		settings[setting] = clampi(int(value), 0, upper_bound) if value is float or value is int else baseline["settings"][setting]
	for setting: String in ["fullscreen", "arcade_mode", "subtitles", "auto_accelerate", "split_horizontal"]:
		if not settings[setting] is bool:
			settings[setting] = baseline["settings"][setting]
	var stats: Dictionary = data["stats"]
	for stat: String in baseline["stats"]:
		if stat == "most_played":
			if not stats[stat] is Dictionary:
				stats[stat] = {}
		else:
			var value: Variant = stats[stat]
			stats[stat] = maxi(0, int(value)) if value is float or value is int else 0
	var progress:Dictionary=data.progress
	for key in ["tower","championship","records"]:
		if not progress.get(key) is Dictionary:progress[key]={}
	if not progress.get("achievements") is Array:progress.achievements=[]
	var tower:Dictionary=progress.tower
	if not tower.is_empty():
		if not _valid_tower(tower):progress.tower={}
		else:
			tower.order=tower.order.map(func(id):return int(id))
			tower.character=int(tower.character)
			tower.step=int(tower.step)
			tower.count=tower.order.size()-2
			tower.difficulty=clampi(int(tower.get("difficulty",1)),0,2) if tower.get("difficulty",1) is int or tower.get("difficulty",1) is float else 1
			tower.skin=clampi(int(tower.get("skin",0)),0,1) if int(tower.character)==3 and (tower.get("skin",0) is int or tower.get("skin",0) is float) else 0

	var championship:Dictionary=progress.championship
	if not championship.is_empty():
		if not championship.get("choices") is Array or championship.get("choices",[]).size()!=2 or not championship.get("skins") is Array or not championship.get("points") is Dictionary or int(championship.get("track",-1)) not in range(4):progress.championship={}
	data["version"] = 2

func _valid_tower(tower: Dictionary) -> bool:
	if not tower.get("order") is Array:return false
	var order:Array=tower.order
	if order.size() not in [5,7,10,12]:return false
	for field in ["character","step"]:
		var value=tower.get(field)
		if not (value is int or value is float):return false
		if not is_finite(float(value)) or float(value)!=float(int(value)):return false
	if int(tower.character) not in range(14) or int(tower.step) not in range(order.size()):return false
	var seen=[]
	for i in order.size():
		var id=order[i]
		if not (id is int or id is float):return false
		if not is_finite(float(id)) or float(id)!=float(int(id)):return false
		if i>=order.size()-2:
			if int(id)!=(14 if i==order.size()-2 else 15):return false
		elif int(id) not in range(14) or int(id)==int(tower.character):return false
		if int(id) in seen:return false
		seen.append(int(id))
	return true
