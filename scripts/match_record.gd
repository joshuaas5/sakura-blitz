class_name MatchRecord
extends RefCounted
## Session totals are independent of purchases and persistent wallet balances.
var shots := 0
var hits := 0
var coins := 0
var xp := 0
var best_streak := 0
var last_hit_shot := -1
var mastery_start: Array = []

func reset(mastery: Array) -> void:
	shots = 0
	hits = 0
	coins = 0
	xp = 0
	best_streak = 0
	last_hit_shot = -1
	mastery_start = mastery.duplicate()

func fired(weapon: int) -> void:
	if weapon in WeaponCatalog.FIREARMS:
		shots += 1

func hit(weapon: int) -> void:
	# One successful cartridge, even if a shotgun volley hits several bodies.
	if weapon in WeaponCatalog.FIREARMS and shots > 0 and shots != last_hit_shot:
		hits += 1
		last_hit_shot = shots

func accuracy() -> int:
	return roundi(100.0 * hits / shots) if shots > 0 else 0
