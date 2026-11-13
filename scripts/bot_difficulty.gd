class_name BotDifficulty
extends RefCounted
## Equal health/damage across difficulties. Skill changes perception and execution.
const PRESETS := [
	{"name": "Fácil", "hint": "Aprenda os mapas • mira tolerante • reação lenta", "reaction": 0.95, "interval": 1.15, "spread": 1.25, "speed": 3.2, "race_speed": 5.2, "strafe": 0.38, "think": 0.65, "memory": 1.5, "hearing": 12.0, "fov": 160.0},
	{"name": "Médio", "hint": "Disputa equilibrada • flancos • mira consistente", "reaction": 0.52, "interval": 0.72, "spread": 0.60, "speed": 4.1, "race_speed": 6.0, "strafe": 0.68, "think": 0.40, "memory": 3.0, "hearing": 20.0, "fov": 150.0},
	{"name": "Difícil", "hint": "Reação rápida • pressão e cobertura • precisão alta", "reaction": 0.24, "interval": 0.42, "spread": 0.23, "speed": 4.9, "race_speed": 6.7, "strafe": 0.92, "think": 0.25, "memory": 4.5, "hearing": 28.0, "fov": 160.0}
]

static func get_preset(index: int) -> Dictionary:
	return PRESETS[clampi(index, 0, PRESETS.size() - 1)]
