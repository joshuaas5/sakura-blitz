class_name AtelierHud
extends Control
## Persistent native controls with painted frames, scalable glyphs and live game data.
const ART := "res://assets/ui/blossom/"
const INK := Color("fff0d4")
const GOLD := Color("d8bb80")
var game: SakuraBlitzMain
var pieces: Dictionary = {}
var map_stage_id := 0
var map_boxes: Array[Rect2] = []
var map_canvas: Control
var reticle: Control
var font: FontVariation

func setup(g: SakuraBlitzMain) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	font = FontVariation.new()
	font.base_font = preload("res://assets/ui/blossom/nunito_sans.ttf")
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 850}
	font.variation_embolden = 0.4
	for key in ["score", "clock", "hp", "armor", "ammo", "hint", "feed"]:
		frame(key, false)
	for key in ["pause", "map", "jump", "fire", "ads", "reload", "weapon", "checkpoint", "joystick"]:
		frame(key, true)
	for action in ["pause", "jump", "fire", "ads", "reload", "weapon", "checkpoint"]:
		glyph(action + "_icon", action)
	glyph("health_icon", "health")
	glyph("shield_icon", "shield")
	glyph("ammo_icon", "fire")
	glyph("knob", "knob")
	for key in ["score_text", "clock_text", "hp_text", "armor_text", "ammo_text", "hint_text", "map_name", "mode_text", "weapon_name", "countdown", "leaderboard", "feed_text", "guard_text"]:
		label(key)
	map_canvas = Control.new()
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas.draw.connect(_draw_map)
	add_child(map_canvas)
	reticle = Control.new()
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(_draw_reticle)
	add_child(reticle)

func frame(key: String, round_button: bool) -> void:
	var control: Control
	if round_button:
		var texture := TextureRect.new()
		texture.texture = preload("res://assets/ui/blossom/action_frame.png")
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		control = texture
	else:
		var texture := NinePatchRect.new()
		texture.texture = preload("res://assets/ui/blossom/panel_frame.png")
		texture.region_rect = Rect2(0, 80, 2172, 560)
		texture.patch_margin_left = 180
		texture.patch_margin_right = 180
		texture.patch_margin_top = 70
		texture.patch_margin_bottom = 70
		control = texture
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pieces[key] = control
	add_child(control)

func glyph(key: String, icon_name: String) -> void:
	var control := TextureRect.new()
	control.texture = load(ART + "icons/" + icon_name + ".svg")
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pieces[key] = control
	add_child(control)

func label(key: String) -> void:
	var control := Label.new()
	control.add_theme_font_override("font", font)
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	control.add_theme_constant_override("shadow_offset_y", 1)
	control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pieces[key] = control
	add_child(control)

func place(key: String, rect: Rect2) -> void:
	var control: Control = pieces[key]
	control.position = rect.position
	if control is NinePatchRect:
		control.scale = Vector2.ONE * 0.08
		control.size = rect.size / 0.08
	else:
		control.size = rect.size

func words(key: String, value: String, rect: Rect2, points: int = 22, color: Color = INK) -> void:
	var control: Label = pieces[key]
	control.text = value
	control.add_theme_font_size_override("font_size", points)
	control.add_theme_color_override("font_color", color)
	place(key, rect)

static func pause_rect(g: SakuraBlitzMain) -> Rect2:
	return g._mobile_rect("pause") if g._mobile_hud_enabled else Rect2(g.size.x - 68, 14, 50, 50)

static func checkpoint_rect(g: SakuraBlitzMain) -> Rect2:
	return g._mobile_rect("checkpoint")

func sync() -> void:
	var g := game
	visible = not g._hub_open and not g._paused and not g._shop_open
	if not visible:
		return
	var w := g.size.x
	var h := g.size.y
	var mobile := g._mobile_hud_enabled
	var left_handed: bool = mobile and g.profile.data.hud_left_handed
	var race := g.current_mode == 1
	for key in pieces:
		pieces[key].visible = true
	place("pause", pause_rect(g))
	place("pause_icon", pause_rect(g).grow(-14))
	place("score", Rect2(w * 0.5 - 105, 12, 210, 46))
	place("clock", Rect2(w * 0.5 - 55, 57, 110, 30))
	var time: float = g.world.kz_time if race else g.world.combat_time_left
	words("clock_text", "%02d:%02d" % [int(time) / 60, int(time) % 60], Rect2(w * 0.5 - 52, 57, 104, 29), 19)
	var place_number := 1
	if race:
		for runner in g.world.parkour_runners:
			if is_instance_valid(runner) and (runner.finish_placed or runner.global_position.z < g._body.global_position.z):
				place_number += 1
		if g.world.player_race_place > 0:
			place_number = g.world.player_race_place
	words("score_text", ("— / 8" if g.world.race_countdown > 0 else "%dº / 8" % place_number) if race else "%02d  /  15" % g.kills, Rect2(w * 0.5 - 100, 13, 200, 43), 29)
	words("mode_text", "CHECKPOINT %d / 8" % g.world.kz_active_stage if race else "CADA UM POR SI", Rect2(w * 0.5 - 110, 90, 220, 20), 11)
	words("guard_text", "PROTEÇÃO AO NASCER • %.1fs" % g.world.player_spawn_guard, Rect2(w * 0.5 - 150, 112, 300, 22), 12, Color("a4e4c4"))
	pieces.guard_text.visible = not race and g.world.player_spawn_guard > 0
	place("map", Rect2(16, 14, 124, 124))
	pieces.map.visible = not race
	map_canvas.visible = not race
	map_canvas.position = Vector2(28, 26)
	map_canvas.size = Vector2(100, 100)
	map_canvas.queue_redraw()
	words("map_name", SakuraHub.MAPS[g.current_mode][g.current_stage], Rect2(18, 139 if not race else 18, 200, 24), 13)
	pieces.map_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in 2:
		var key := "hp" if i == 0 else "armor"
		var y := h - 72 + i * 31
		var vital_x := w - 130 if left_handed else 18.0
		place(key, Rect2(vital_x, y, 112, 30))
		place("health_icon" if i == 0 else "shield_icon", Rect2(vital_x + 9, y + 3, 24, 24))
		words(key + "_text", str(int(g.hp if i == 0 else g.armor)), Rect2(vital_x + 39, y, 60, 29), 22)
		pieces[key].visible = not race
		pieces[key + "_text"].visible = not race
	pieces.health_icon.visible = not race
	pieces.shield_icon.visible = not race
	var ammo_rect := Rect2(25 if left_handed else w - 211, h - 225 if mobile else h - 64, 186, 38)
	if mobile:
		for action_rect in g._action_rects().values():
			ammo_rect.position.y = minf(ammo_rect.position.y, action_rect.position.y - 52)
	place("ammo", ammo_rect)
	place("ammo_icon", Rect2(ammo_rect.position + Vector2(145, 7), Vector2(25, 25)))
	words("ammo_text", "RECARGA" if g._reloading_cached else "%d / %d" % [g._cur_ammo_cached, g._cur_res_cached], Rect2(ammo_rect.position + Vector2(9, 0), Vector2(132, 37)), 23)
	words("weapon_name", WeaponCatalog.label_for(g.weapons.current_idx), Rect2(ammo_rect.position.x, ammo_rect.position.y - 22, 184, 20), 11)
	for key in ["ammo", "ammo_icon", "ammo_text", "weapon_name"]:
		pieces[key].visible = not race
	for action in ["jump", "fire", "ads", "reload", "weapon"]:
		var enabled: bool = mobile and (not race or action == "jump")
		pieces[action].visible = enabled
		pieces[action + "_icon"].visible = enabled
		if enabled:
			var r: Rect2 = g._action_rects()[action]
			place(action, r)
			place(action + "_icon", r.grow(-r.size.x * 0.27))
			pieces[action].self_modulate = Color("d7b47d") if g._touch_actions.values().has(action) else Color.WHITE
			pieces[action].modulate.a = MobileLayout.opacity(g.profile.data, action)
			pieces[action + "_icon"].modulate.a = MobileLayout.opacity(g.profile.data, action)
	place("checkpoint", checkpoint_rect(g))
	place("checkpoint_icon", checkpoint_rect(g).grow(-18))
	pieces.checkpoint.visible = race
	pieces.checkpoint_icon.visible = race
	var joy_rect := g._mobile_rect("joystick")
	if g._joy_touch_idx < 0:
		g._joy_radius = joy_rect.size.x / 2
	var center := joy_rect.get_center() if g._joy_touch_idx < 0 else g._joy_center
	place("joystick", Rect2(center - Vector2.ONE * g._joy_radius, Vector2.ONE * g._joy_radius * 2))
	pieces.joystick.self_modulate.a = 0.65
	place("knob", Rect2((center if g._joy_touch_idx < 0 else g._joy_knob) - Vector2(25, 25), Vector2(50, 50)))
	pieces.joystick.visible = mobile
	pieces.knob.visible = mobile
	place("hint", Rect2(w * 0.5 - 170, h - 42, 340, 28))
	words("hint_text", "ESPAÇO  Pular     G  Checkpoint" if race else "R  Recarregar     F  Inspecionar", Rect2(w * 0.5 - 165, h - 42, 330, 27), 13)
	pieces.hint.visible = not mobile
	pieces.hint_text.visible = not mobile
	words("countdown", str(int(ceil(g.world.race_countdown))), Rect2(w * 0.5 - 50, h * 0.4, 100, 90), 68)
	pieces.countdown.visible = race and g.world.race_countdown > 0
	var leaders := ""
	if not mobile and not race:
		var standings := g.world.get_combat_standings(g.kills, g.deaths)
		for i in mini(3, standings.size()):
			leaders += "%d   %s   %d\n" % [i + 1, standings[i].name, standings[i].kills]
	words("leaderboard", leaders, Rect2(w - 250, 79, 225, 80), 13)
	pieces.leaderboard.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var feed := ""
	for i in mini(2, g.killfeed.size()):
		feed += str(g.killfeed[i].text) + ("\n" if i == 0 else "")
	var feed_at := Rect2(w - 310, 76 if mobile else 170, 286, 48)
	place("feed", feed_at)
	words("feed_text", feed, feed_at.grow(-8), 11)
	pieces.feed_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pieces.feed.visible = not feed.is_empty()
	pieces.feed_text.visible = not feed.is_empty()
	var safe := g._safe_ui_rect()
	for control in get_children():
		if control is Control and control != reticle and control.visible:
			var extent: Vector2 = control.size * control.scale
			control.position = control.position.clamp(safe.position, (safe.end - extent).max(safe.position))
	reticle.size = g.size
	reticle.queue_redraw()

func _draw_map() -> void:
	var stage := game.world._stage_root
	if not is_instance_valid(stage):
		return
	if map_stage_id != stage.get_instance_id():
		map_stage_id = stage.get_instance_id()
		map_boxes.clear()
		for body in stage.get_children():
			if not body is StaticBody3D:
				continue
			for collider in body.get_children():
				if collider is CollisionShape3D and collider.shape is BoxShape3D:
					var extent: Vector3 = collider.shape.size
					var pos: Vector3 = collider.global_position
					if extent.y >= 0.4 and extent.x < 60 and extent.z < 60 and pos.y + extent.y * 0.5 > 0.15:
						map_boxes.append(Rect2(Vector2(pos.x, pos.z) - Vector2(extent.x, extent.z) * 0.5, Vector2(extent.x, extent.z)))
	var circle := PackedVector2Array()
	for i in 32:
		circle.append(Vector2(50, 50) + Vector2.from_angle(i * TAU / 32) * 46)
	for box in map_boxes:
		var r := Rect2(Vector2(50, 50) + box.position * 1.25, box.size * 1.25)
		var clipped := Geometry2D.intersect_polygons(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), circle)
		for polygon in clipped:
			map_canvas.draw_colored_polygon(polygon, Color("7e837a"))
	var p := game._body.position
	var dot := (Vector2(p.x, p.z) * 1.25).limit_length(43) + Vector2(50, 50)
	var dir := Vector2(-sin(game._yaw), -cos(game._yaw))
	map_canvas.draw_colored_polygon(PackedVector2Array([dot + dir * 7, dot + dir.rotated(2.4) * 5, dot + dir.rotated(-2.4) * 5]), GOLD)

func _draw_reticle() -> void:
	var g := game
	if g.current_mode == 1:
		return
	var center := g.size * 0.5
	var spread := 5 + g._crosshair_spread * 7
	var color := Color("eb9cad") if g._hitmarker_timer > 0 else INK
	reticle.draw_circle(center, 1.4, color)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		reticle.draw_line(center + direction * spread, center + direction * (spread + 5), color, 1.6, true)
	if g.weapons.is_scoped_in():
		reticle.draw_line(center - Vector2(0, g.size.y * 0.3), center + Vector2(0, g.size.y * 0.3), Color("192e30"), 1)
		reticle.draw_line(center - Vector2(g.size.x * 0.2, 0), center + Vector2(g.size.x * 0.2, 0), Color("192e30"), 1)
	if g._mobile_hud_enabled and g._reloading_cached:
		var r: Rect2 = g._action_rects().reload
		var progress := clampf(1.0 - g.weapons.reload_timer / maxf(0.01, g.weapons.reload_duration), 0, 1)
		reticle.draw_arc(r.get_center(), r.size.x * 0.46, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color("9dd8b5"), 2.5, true)
