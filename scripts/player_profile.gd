class_name PlayerProfile
extends RefCounted
## Local prototype progression. Never an authority for real-money purchases.
const SAVE_PATH := "user://profile_v1.cfg"
var data: Dictionary = {}
var path := SAVE_PATH
var loaded_from_backup := false

func _init(save_path: String = SAVE_PATH) -> void:
	path = save_path
	data = defaults()

static func defaults() -> Dictionary:
	var zeros: Array = []
	var levels: Array = []
	var suppressors: Array = []
	for i in WeaponCatalog.DEFINITIONS.size():
		zeros.append(0)
		levels.append(1)
		suppressors.append(false)
	return {
		"coins": 650, "gems": 75, "rp": 0,
		"weapon_kills": zeros.duplicate(), "weapon_skins": zeros.duplicate(), "selected_weapon": 0,
		"weapon_levels": levels, "suppressors": suppressors,
		"owned_weapons": [true, false, false, false, false],
		"owned_characters": [true, false, false, false],
		"owned_tags": [true, false, false, false, false],
		"character": 0, "tag": 0, "best_times": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"daily_day": "", "daily_kills": 0, "daily_races": 0, "daily_claimed": false,
		"sensitivity": 1.0, "ads_sensitivity": 0.55, "auto_fire": true,
		"haptics": true, "quality": 0, "bot_difficulty": 1, "music_volume": 0.35, "music_enabled": true,
		"hud_left_handed": false, "hud_layout": {}, "tutorial_complete": false, "show_performance": false, "effects_volume": 1.0, "ambience_volume": 0.6
	}

func read_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		err = cfg.load(path + ".bak")
		loaded_from_backup = err == OK
	if err != OK:
		return
	# Validate the shape and types; old/malformed keys cannot break the menu.
	for key in data:
		var value: Variant = cfg.get_value("player", key, data[key])
		var expected: Variant = data[key]
		if expected is Array:
			if value is Array and (value.size() == expected.size() or (key in ["best_times", "weapon_kills", "weapon_skins", "weapon_levels", "suppressors"] and value.size() == 4)):
				for i in mini(value.size(), expected.size()):
					if typeof(value[i]) == typeof(expected[i]):
						data[key][i] = value[i]
		elif key == "hud_layout" and value is Dictionary:
			data[key] = MobileLayout.sanitize(value)
		elif typeof(value) == typeof(expected):
			data[key] = value
	for key in ["coins", "gems", "rp", "daily_kills", "daily_races"]:
		data[key] = clampi(data[key], 0, 99999999)
	for i in WeaponCatalog.DEFINITIONS.size():
		data.weapon_kills[i] = clampi(data.weapon_kills[i], 0, 9999999)
		data.weapon_levels[i] = clampi(data.weapon_levels[i], 1, 4)
		data.weapon_skins[i] = clampi(data.weapon_skins[i], 0, 4)
		if data.weapon_skins[i] == 1 and data.weapon_kills[i] < 50:
			data.weapon_skins[i] = 0
		elif data.weapon_skins[i] > 1 and not data.owned_weapons[data.weapon_skins[i]]:
			data.weapon_skins[i] = 0
		data.suppressors[i] = bool(data.suppressors[i]) and data.weapon_kills[i] >= 100 and i in WeaponCatalog.FIREARMS
	for i in data.best_times.size():
		data.best_times[i] = maxf(0.0, data.best_times[i]) if is_finite(data.best_times[i]) else 0.0
	data.selected_weapon = clampi(data.selected_weapon, 0, WeaponCatalog.DEFINITIONS.size() - 1)
	data.character = clampi(data.character, 0, 3)
	data.tag = clampi(data.tag, 0, 4)
	if not data.owned_characters[data.character]:
		data.character = 0
	if not data.owned_tags[data.tag]:
		data.tag = 0
	data.sensitivity = clampf(data.sensitivity, 0.4, 2.0) if is_finite(data.sensitivity) else 1.0
	data.ads_sensitivity = clampf(data.ads_sensitivity, 0.25, 1.0) if is_finite(data.ads_sensitivity) else 0.55
	data.quality = clampi(data.quality, 0, 3)
	data.bot_difficulty = clampi(data.bot_difficulty, 0, 2)
	data.music_volume = clampf(data.music_volume, 0.0, 1.0) if is_finite(data.music_volume) else 0.35
	for key in ["effects_volume", "ambience_volume"]:
		data[key] = clampf(data[key], 0, 1) if is_finite(data[key]) else 0.6
	data.owned_weapons[0] = true
	data.owned_characters[0] = true
	data.owned_tags[0] = true

func write_save() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 2)
	for key in data:
		cfg.set_value("player", key, data[key])
	var err := cfg.save(path + ".tmp")
	if err != OK:
		return err
	# Keep the last valid snapshot if the application is interrupted during a write.
	if FileAccess.file_exists(path) and not loaded_from_backup:
		err = DirAccess.copy_absolute(path, path + ".bak")
		if err != OK:
			return err
	err = DirAccess.rename_absolute(path + ".tmp", path)
	if err == OK:
		loaded_from_backup = false
	return err

func refresh_day(day: String = Time.get_date_string_from_system(true)) -> void:
	if data.daily_day != day:
		data.daily_day = day
		data.daily_kills = 0
		data.daily_races = 0
		data.daily_claimed = false

func record_kill(weapon: int) -> int:
	refresh_day()
	data.weapon_kills[weapon] += 1
	data.daily_kills += 1
	return int(data.weapon_kills[weapon])

func record_finish(stage: int, seconds: float) -> void:
	refresh_day()
	data.daily_races += 1
	if data.best_times[stage] <= 0.0 or seconds < data.best_times[stage]:
		data.best_times[stage] = seconds

func claim_daily() -> bool:
	refresh_day()
	if data.daily_claimed or (data.daily_kills < 10 and data.daily_races < 1):
		return false
	data.daily_claimed = true
	data.coins += 300
	return true
