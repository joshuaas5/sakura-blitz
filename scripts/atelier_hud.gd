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
	glyph("ammo_icon", "ammo")
	glyph("knob", "knob")
	for key in ["score_text", "clock_text", "hp_text", "armor_text", "ammo_text", "hint_text", "map_name", "sector_text", "mode_text", "objective_text", "weapon_name", "countdown", "leaderboard", "feed_text", "guard_text", "fire_hint", "aim_label", "aim_mode_label"]:
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
	words("score_text", ("— / 8" if g.world.race_countdown > 0 else "%dº / 8" % place_number) if race else "%02d  /  %d" % [g.kills, g.world.combat_kill_limit], Rect2(w * 0.5 - 100, 13, 200, 43), 29)
	if not race and g.world.match_kind != CombatMatch.FFA:
		pieces.score_text.text = "%02d  ×  %02d" % [g.world.team_scores[0], g.world.team_scores[1]]
	words("mode_text", "CHECKPOINT %d / 8" % g.world.kz_active_stage if race else "CADA UM POR SI", Rect2(w * 0.5 - 110, 90, 220, 20), 11)
	if not race and g.world.match_kind != CombatMatch.FFA:
		pieces.mode_text.text = "MENTA × CORAL • %s / %d" % ["BANDEIRAS" if g.world.match_kind == CombatMatch.CTF else "ABATES", g.world.combat_kill_limit]
	var objective := "PEGUE A CORAL • VOLTE À BASE MENTA"
	if is_instance_valid(g.world.match_controller) and g.world.match_controller.flags[1].carrier == "PLAYER":
		objective = "VOCÊ TEM A BANDEIRA • VOLTE À BASE"
		if g.world.match_controller.flags[0].carrier != "" or g.world.match_controller.flags[0].dropped:
			objective = "RECUPERE SUA BANDEIRA PARA CAPTURAR"
	words("objective_text", objective, Rect2(w * 0.5 - 175, 112, 350, 22), 11, Color("a4e4c4"))
	pieces.objective_text.visible = not race and g.world.match_kind == CombatMatch.CTF and g.world.player_spawn_guard <= 0
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
	words("sector_text", g.world.combat_sector(g._body.position), Rect2(18, 161, 200, 20), 11, Color("a4e4c4"))
	pieces.sector_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pieces.sector_text.visible = not race and not g.world.combat_sectors.is_empty()
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
			pieces[action].self_modulate = Color("93e7c3") if action == "ads" and g.weapons.want_ads else (Color("d7b47d") if g._touch_actions.values().has(action) else Color.WHITE)
			pieces[action].modulate.a = MobileLayout.opacity(g.profile.data, action)
			pieces[action + "_icon"].modulate.a = MobileLayout.opacity(g.profile.data, action)
	pieces.aim_label.visible = mobile and not race
	pieces.aim_mode_label.visible = mobile and not race
	if mobile and not race:
		var aim: Rect2 = g._action_rects().ads
		place("ads_icon", Rect2(aim.position + Vector2(aim.size.x * 0.30, aim.size.y * 0.12), aim.size * 0.40))
		var label_size := clampi(roundi(aim.size.x * 0.145), 9, 13)
		words("aim_label", "MIRANDO" if g.weapons.want_ads else "MIRAR", Rect2(aim.position.x, aim.position.y + aim.size.y * 0.56, aim.size.x, aim.size.y * 0.21), label_size, Color("b1f0cc") if g.weapons.want_ads else INK)
		var mode_text: String = ["TOQUE", "SEGURE", "TOQUE / SEGURE"][g.profile.data.aim_mode]
		if g.weapons.want_ads:
			mode_text = "TOQUE P/ SAIR" if g._mobile_aim.latched else "ARRASTE"
		words("aim_mode_label", mode_text, Rect2(aim.position.x, aim.position.y + aim.size.y * 0.78, aim.size.x, aim.size.y * 0.16), 8)
	pieces.fire_hint.visible = mobile and not race
	if mobile and not race:
		var fire: Rect2 = g._action_rects().fire
		words("fire_hint", "ATIRAR", Rect2(fire.position.x, fire.end.y - fire.size.y * 0.27, fire.size.x, fire.size.y * 0.18), 10)
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
	if mobile and not race and not g.profile.data.aim_tip_seen:
		var coach_width := minf(300, w * 0.36)
		var coach := Rect2(w * 0.5 - coach_width * 0.5, h - 31, coach_width, 24)
		var clear := true
		for action_rect: Rect2 in g._action_rects().values():
			if coach.intersects(action_rect):
				clear = false
		place("hint", coach)
		words("hint_text", ("SEGURE MIRAR" if g.profile.data.aim_mode == MobileAim.HOLD else "TOQUE EM MIRAR") + " • ARRASTE PARA AJUSTAR", coach.grow(-3), 10)
		pieces.hint.visible = clear
		pieces.hint_text.visible = clear
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
		var r := Rect2(map_point(box.position), box.size * map_scale())
		var clipped := Geometry2D.intersect_polygons(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), circle)
		for polygon in clipped:
			map_canvas.draw_colored_polygon(polygon, Color("7e837a"))
	if is_instance_valid(game.world.match_controller):
		for team in 2:
			var at: Vector3 = game.world.match_controller.flags[team].at
			map_canvas.draw_circle(map_point(Vector2(at.x, at.z)), 3, CombatMatch.COLORS[team])
	var p := game._body.position
	var dot := Vector2(50, 50) + (map_point(Vector2(p.x, p.z)) - Vector2(50, 50)).limit_length(43)
	var dir := Vector2(-sin(game._yaw), -cos(game._yaw))
	map_canvas.draw_colored_polygon(PackedVector2Array([dot + dir * 7, dot + dir.rotated(2.4) * 5, dot + dir.rotated(-2.4) * 5]), GOLD)

func map_scale() -> float:
	if game.world.combat_sectors.is_empty():
		return 1.25
	# Fit the full rectangular footprint inside the circular frame, including corners.
	return 86.0 / game.world.combat_bounds.size.length()

func map_point(at: Vector2) -> Vector2:
	var center := Vector2.ZERO if game.world.combat_sectors.is_empty() else game.world.combat_bounds.get_center()
	return Vector2(50, 50) + (at - center) * map_scale()

func _draw_reticle() -> void:
	var g := game
	if g.current_mode == 1:
		return
	_draw_objective_marker()
	var center := g.size * 0.5
	if g._damage_alpha > 0 and g._last_damage_from.distance_squared_to(g._body.position) > 0.5:
		var from := g._last_damage_from - g._body.position
		var right := Vector3(cos(g._yaw), 0, -sin(g._yaw))
		var forward := Vector3(-sin(g._yaw), 0, -cos(g._yaw))
		var angle := atan2(from.dot(right), from.dot(forward)) - PI / 2
		reticle.draw_arc(center, 72, angle - 0.25, angle + 0.25, 16, Color(0.96, 0.38, 0.39, minf(1, g._damage_alpha * 2.5)), 4, true)
	var spread := 5 + g._crosshair_spread * 7
	var color := Color("eb9cad") if g._hitmarker_timer > 0 else INK
	reticle.draw_circle(center, 1.4, color)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		reticle.draw_line(center + direction * spread, center + direction * (spread + 5), color, 1.6, true)
	if g._mobile_hud_enabled and g.weapons.ads_alpha > 0.01:
		var aim: Rect2 = g._action_rects().ads
		reticle.draw_arc(aim.get_center(), aim.size.x * 0.46, -PI * 0.5, -PI * 0.5 + TAU * g.weapons.ads_alpha, 48, Color("93e7c3"), 3, true)
	if g.weapons.is_scoped_in():
		reticle.draw_line(center - Vector2(0, g.size.y * 0.3), center + Vector2(0, g.size.y * 0.3), Color("192e30"), 1)
		reticle.draw_line(center - Vector2(g.size.x * 0.2, 0), center + Vector2(g.size.x * 0.2, 0), Color("192e30"), 1)
	if g._mobile_hud_enabled and g._reloading_cached:
		var r: Rect2 = g._action_rects().reload
		var progress := clampf(1.0 - g.weapons.reload_timer / maxf(0.01, g.weapons.reload_duration), 0, 1)
		reticle.draw_arc(r.get_center(), r.size.x * 0.46, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color("9dd8b5"), 2.5, true)

func _draw_objective_marker() -> void:
	var g := game
	if not is_instance_valid(g.world.match_controller):
		return
	var own: Dictionary = g.world.match_controller.flags[0]
	var enemy: Dictionary = g.world.match_controller.flags[1]
	var target: Vector3 = enemy.at
	var title := "BANDEIRA CORAL"
	var color: Color = CombatMatch.COLORS[1]
	if enemy.carrier == "PLAYER":
		target = own.home
		title = "BASE MENTA"
		color = CombatMatch.COLORS[0]
		if own.dropped or own.carrier != "":
			target = own.at
			title = "RECUPERAR MENTA"
	elif enemy.carrier != "":
		title = "ESCOLTAR"
	var meters := g._body.position.distance_to(target)
	if meters < 3:
		return
	var point := g._cam.unproject_position(target + Vector3.UP * 2.8) * (g.size / Vector2(g._vp.size))
	var safe := Rect2(24, 144, g.size.x - 48, maxf(40, g.size.y - 240))
	if g._cam.is_position_behind(target):
		var delta := target - g._body.position
		var right := Vector3(cos(g._yaw), 0, -sin(g._yaw))
		point = Vector2(safe.end.x if delta.dot(right) > 0 else safe.position.x, safe.get_center().y)
	point = point.clamp(safe.position, safe.end)
	var diamond := PackedVector2Array([point + Vector2(0, -9), point + Vector2(9, 0), point + Vector2(0, 9), point + Vector2(-9, 0)])
	reticle.draw_colored_polygon(diamond, Color("173b37"))
	reticle.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 2, true)
	reticle.draw_line(point + Vector2(-2, 4), point + Vector2(-2, -4), color, 2)
	reticle.draw_colored_polygon(PackedVector2Array([point + Vector2(-1, -4), point + Vector2(5, -2), point + Vector2(-1, 0)]), color)
	var text := "%s / %dm" % [title, int(meters)]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var at := Vector2(clampf(point.x - width * 0.5, 12, g.size.x - width - 12), point.y + 23)
	reticle.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color("173b37"))
	reticle.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
