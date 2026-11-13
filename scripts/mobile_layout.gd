class_name MobileLayout
extends RefCounted
## Shared geometry for rendering, touch hit testing, preview and saved layouts.
const ACTIONS := ["jump", "fire", "ads", "reload", "weapon", "joystick", "checkpoint", "pause"]
const LABELS := {"jump": "Pular", "fire": "Atirar", "ads": "Mirar", "reload": "Recarregar", "weapon": "Trocar arma", "joystick": "Mover", "checkpoint": "Checkpoint", "pause": "Pausa"}

static func safe_rect(view: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, view)
	if not OS.has_feature("mobile"):
		return full
	var window := Vector2(DisplayServer.window_get_size())
	var pixels := Rect2(DisplayServer.get_display_safe_area())
	if window.x < 1 or window.y < 1 or not pixels.has_area():
		return full
	# The Android game is fullscreen; convert display pixels to logical UI units.
	var ratio := view / window
	return full.intersection(Rect2(pixels.position * ratio, pixels.size * ratio))

static func defaults(area: Rect2, left_handed: bool = false) -> Dictionary:
	var scale := clampf(minf(area.size.x / 844, area.size.y / 390), 0.65, 1.35)
	var specs := {"jump": Vector3(74, 74, 96), "fire": Vector3(198, 94, 112), "ads": Vector3(300, 160, 62), "reload": Vector3(300, 70, 56), "weapon": Vector3(62, 164, 56), "checkpoint": Vector3(187, 64, 60)}
	var result := {}
	for action in specs:
		var spec: Vector3 = specs[action]
		var center := area.end - Vector2(spec.x, spec.y) * scale
		if left_handed:
			center.x = area.position.x + spec.x * scale
		result[action] = Rect2(center - Vector2.ONE * spec.z * scale / 2, Vector2.ONE * spec.z * scale)
	var joy := area.position + Vector2(100 * scale, area.size.y - 145 * scale)
	if left_handed:
		joy.x = area.end.x - 100 * scale
	result.joystick = Rect2(joy - Vector2.ONE * 66 * scale, Vector2.ONE * 132 * scale)
	result.pause = Rect2(Vector2(area.end.x - 60 * scale, area.position.y + 12 * scale), Vector2.ONE * 44 * scale)
	return result

static func sanitize(raw: Dictionary) -> Dictionary:
	var clean := {}
	for action in ACTIONS:
		var value: Variant = raw.get(action)
		if not value is Vector4 or not is_finite(value.x) or not is_finite(value.y) or not is_finite(value.z) or not is_finite(value.w):
			continue
		clean[action] = Vector4(clampf(value.x, 0, 1), clampf(value.y, 0, 1), clampf(value.z, 0.7, 1.35), clampf(value.w, 0.3, 1))
	return clean

static func rects(area: Rect2, settings: Dictionary, race: bool = false) -> Dictionary:
	var base := defaults(area, settings.get("hud_left_handed", false))
	var custom := sanitize(settings.get("hud_layout", {}))
	var result := {}
	for action in ACTIONS:
		if race and action in ["fire", "ads", "reload", "weapon"]:
			continue
		if not race and action == "checkpoint":
			continue
		var rect: Rect2 = base[action]
		if custom.has(action):
			var value: Vector4 = custom[action]
			rect.size *= value.z
			rect.position = area.position + area.size * Vector2(value.x, value.y) - rect.size / 2
		rect.size = rect.size.min(area.size)
		rect.position = rect.position.clamp(area.position, area.end - rect.size)
		result[action] = rect
	return result

static func valid(rectangles: Dictionary, area: Rect2) -> bool:
	for action in rectangles:
		if not area.grow(0.1).encloses(rectangles[action]):
			return false
		for other in rectangles:
			if action != other and (rectangles[action] as Rect2).intersects(rectangles[other]):
				return false
	return true

static func opacity(settings: Dictionary, action: String) -> float:
	var custom := sanitize(settings.get("hud_layout", {}))
	return custom[action].w if custom.has(action) else 0.85
