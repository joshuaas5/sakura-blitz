class_name MobileAim
extends RefCounted
## Input intent only. Aiming never requests a shot.
const TAP := 0
const HOLD := 1
const HYBRID := 2
const HOLD_SECONDS := 0.22
const DRAG_DISTANCE := 10.0
var latched := false
var touches: Dictionary = {}

func press(index: int, mode: int) -> void:
	touches[index] = {"mode": mode, "elapsed": 0.0, "travel": 0.0, "previous": latched}
	if mode == TAP:
		latched = not latched

func tick(delta: float) -> void:
	for touch in touches.values():
		touch.elapsed += delta

func drag(index: int, relative: Vector2) -> void:
	if touches.has(index):
		touches[index].travel += relative.length()

func release(index: int, canceled: bool = false) -> void:
	if not touches.has(index):
		return
	var touch: Dictionary = touches[index]
	if canceled:
		latched = bool(touch.previous)
	elif touch.mode == HYBRID:
		var tap: bool = touch.elapsed < HOLD_SECONDS and touch.travel < DRAG_DISTANCE
		latched = not bool(touch.previous) if tap else false
	touches.erase(index)

func desired(mode: int) -> bool:
	return latched if mode == TAP else latched or not touches.is_empty()

func reset() -> void:
	latched = false
	touches.clear()
