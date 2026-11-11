class_name SakuraBlitzMain
extends Control
## Main Controller for SAKURA BLITZ (Mobile-First iOS / Play Store / Web + PC Crossplay):
## - 2 Distinct Competitive Game Modes ([M] or Tap Mode Tabs):
##   * MODO 0 — MODO TIRO (PHANTOM BLITZ): 4 Complex Combat Arenas (Vila BO2, Shipment CQC, Sniper Canyon, Cyber-Vertigo 3-Floor),
##     Phantom Forces Kill Satisfaction (Kill Siphon +35 HP/+25 Armor/+8 Ammo, Auto-Regen, Ragdoll Launch, Center Score Stack),
##     and Live Match Kill Leaderboard (#1 Matador)!
##   * MODO 1 — MODO PARKOUR (FALL GUYS RACE): 4 Long & Hard 8-Sector Marathons (335m-380m), Zero PvP Shooting Deaths,
##     5-4-3-2-1 VAI! Starting Gate Countdown, and 7 Runner Bots racing you for 1st Place!
## - Mobile-First Pro Touch HUD ([V] or Auto on Touch): Virtual 360° Analog Thumbstick with Auto-Sprint Rim,
##   Right-Screen Swipe Look with Mobile Aim-Assist Magnetism, Optional Auto-Fire, Claw Fire Button, and Direct HUD Tap Zones!

const EYE_STAND := 1.58
const EYE_CROUCH := 1.02
const GRAVITY := 22.5
const WALK_SPEED := 5.6
const SPRINT_SPEED := 7.25
const CROUCH_SPEED := 3.2
const JUMP_VEL := 8.45
const GROUND_ACCEL := 66.0
const GROUND_BRAKE := 90.0
const AIR_ACCEL := 36.0
const AIR_BRAKE := 16.0

const RES_PRESETS := [
	{"h": 360, "short": "360p PS1", "label": "360p PS1 Retro (Nearest / Ultra-Leve)", "linear": false, "msaa": Viewport.MSAA_DISABLED},
	{"h": 540, "short": "540p RETRO", "label": "540p HD-Retro PS1 (MSAA 2X)", "linear": false, "msaa": Viewport.MSAA_2X},
	{"h": 720, "short": "720p HD", "label": "720p HD Nativo (Linear / MSAA 4X)", "linear": true, "msaa": Viewport.MSAA_4X},
	{"h": 1080, "short": "1080p FHD", "label": "1080p Full HD Ultra Nítido (MSAA 4X)", "linear": true, "msaa": Viewport.MSAA_4X}
]

const RANK_TIERS := [
	{"name": "BRONZE I", "min_rp": 0, "col": Color("cd7f32")},
	{"name": "PRATA ELITE", "min_rp": 200, "col": Color("dce4f0")},
	{"name": "OURO BO2", "min_rp": 450, "col": Color("f5c242")},
	{"name": "PLATINA VIP", "min_rp": 800, "col": Color("48cae4")},
	{"name": "DIAMANTE MESTRE", "min_rp": 1250, "col": Color("00bbf9")},
	{"name": "LENDA TOP #1", "min_rp": 1800, "col": Color("e63946")}
]

const DOGTAGS := [
	{"name": "CACADOR", "cost": 0, "icon_path": "res://assets/ui/dogtag_1.png"},
	{"name": "1-TAP GOD", "cost": 150, "icon_path": "res://assets/ui/dogtag_1.png"},
	{"name": "EL PANADERO", "cost": 300, "icon_path": "res://assets/ui/dogtag_2.png"},
	{"name": "REI DO PARKOUR", "cost": 500, "icon_path": "res://assets/ui/dogtag_3.png"},
	{"name": "TOP 1 GLOBAL", "cost": 900, "icon_path": "res://assets/ui/dogtag_4.png"}
]

const PROFILE_ICONS := [
	{"icon": "[I]", "name": "Atirador", "cost": 0},
	{"icon": "[II]", "name": "Raio Neon", "cost": 100},
	{"icon": "[III]", "name": "Chama BO2", "cost": 200},
	{"icon": "[IV]", "name": "Panadero Ouro", "cost": 300},
	{"icon": "[V]", "name": "Diamante VIP", "cost": 500},
	{"icon": "[#1]", "name": "Coroa Top #1", "cost": 800}
]

enum ServerMode { FY_ICEWORLD_PVP, KZ_BHOP_SURF }

var _res_idx := 0 # Default to 360p PS1 Retro for Ultra-Fast Mobile & Classic PS1 Look!
var server_mode: ServerMode = ServerMode.FY_ICEWORLD_PVP
var current_mode := SakuraWorld.MODE_COMBAT
var current_stage := 0

var _vp: SubViewport
var _vp_tex: TextureRect
var world: SakuraWorld
var _body: CharacterBody3D
var _cam_pivot: Node3D
var _cam: Camera3D
var weapons: WeaponRig

# Camera & Crisp Movement state
var _yaw := 0.0
var _pitch := 0.0
var _cam_roll := 0.0
var _eye_y := EYE_STAND
var _fov := 76.0

var _crouching := false
var _sprinting := false
var _on_ladder := false
var _surfing := false
var _bhop_chain := 0
var _coyote_timer := 0.0
var _jump_buffer := 0.0
var _jump_grace := 0.0
var _hud_anim_t := 0.0
var _hp_lag := 100.0
var _cur_ammo_cached := 32
var _cur_res_cached := 160
var _reloading_cached := false

# Phantom Forces Survivability & Dopamine Loop State
var _out_of_combat_t := 5.0
var _adrenaline_t := 0.0
var _pf_score_stack: Array[Dictionary] = [] # Center-bottom Phantom Forces stacked kill bonuses!
var _was_leader := false

# KZ Checkpoint System ([E] Checkpoint / [G] Teleport)
var _saved_cp_pos := Vector3.ZERO
var _saved_cp_yaw := 0.0
var _has_saved_cp := false
var _cp_count := 0

# Player PvP, Ranked & F2P Shop Progression State
var hp := 100.0
var max_hp := 100.0
var armor := 100.0
var kills := 0
var deaths := 0
var headshots := 0
var streak := 0
var coins := 650
var gems := 75
var rp := 180
var rank_idx := 0

var unlocked_weapon_skins := [true, false, false, false, false]
var unlocked_char_skins := [true, false, false, false]
var unlocked_dogtags := [true, false, false, false, false]
var unlocked_icons := [true, false, false, false, false, false]
var active_dogtag_idx := 0
var active_icon_idx := 0

var killfeed: Array[Dictionary] = []

# HUD elements
var _hud: Control
var _hud_font: Font
var _banner_label: Label
var _banner_timer := 0.0
var _damage_flash: ColorRect
var _damage_alpha := 0.0
var _hitmarker_timer := 0.0
var _hitmarker_crit := false
var _crosshair_spread := 0.0
var _h_speed_cached := 0.0
var _mouse_captured := true
var _paused := false
var _shop_open := false
var _shop_panel: PanelContainer
var _shop_status_lbl: Label
var _shop_tab_idx := 0
var _shop_grid: GridContainer
var _ui_tex_cache := {}

# Mobile-First Pro Touch & Aim-Assist System
var _mobile_hud_enabled := false
var _mobile_autofire := true
var _mobile_aim_assist := true
var _mobile_move_vec := Vector2.ZERO
var _mobile_fire_held := false
var _mobile_jump_held := false
var _joy_touch_idx := -1
var _joy_center := Vector2(155.0, 540.0)
var _joy_knob := Vector2(155.0, 540.0)
var _joy_radius := 76.0
var _look_touch_idx := -1
var _startup_grace := 0.25

# Call of Duty: Black Ops 2 KillCam System
var _killcam: Camera3D
var _killcam_active := false
var _killcam_mode := "FINAL"
var _killcam_timer := 0.0
var _killcam_dur := 2.45
var _killcam_impact_played := false
var _killcam_data := {}
var _last_kill_data := {}
var _killcam_dummy: Node3D
var _killcam_bullet: Node3D
var _killcam_card: PanelContainer
var _kc_header_lbl: Label
var _kc_title_lbl: Label
var _kc_sub_lbl: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Auto-detect Mobile / Touchscreen (iOS, Android, Mobile Web Browser)
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available():
		_mobile_hud_enabled = true

	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)

	_vp_tex = TextureRect.new()
	_vp_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vp_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_vp_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp_tex.texture = _vp.get_texture()
	add_child(_vp_tex)
	_apply_graphics_preset()

	world = SakuraWorld.new()
	_vp.add_child(world)
	world.build()
	world.enemy_killed.connect(_on_enemy_killed)
	world.round_won.connect(_on_round_won)
	world.kz_stage_reached.connect(_on_kz_stage_reached)
	world.kz_course_finished.connect(_on_kz_course_finished)
	world.kz_ring_collected.connect(_on_kz_ring_collected)
	world.player_damaged.connect(_on_player_damaged)
	world.pickup_collected.connect(_on_pickup_collected)
	world.runner_crossed_finish.connect(_on_runner_crossed_finish)
	world.bot_frag_feed.connect(_on_bot_frag_feed)

	_build_player()
	_build_hud()
	_build_shop_modal()
	get_viewport().size_changed.connect(func(): _vp.size = _calc_vp_size())

	var args := OS.get_cmdline_user_args()
	if args.has("--test"):
		_run_automated_test.call_deferred()
		return
	if args.has("--shot"):
		_run_screenshot_suite.call_deferred()
		return

	_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 0)
	if not DisplayServer.get_name().contains("headless"):
		_capture_mouse.call_deferred()


func _capture_mouse() -> void:
	if DisplayServer.get_name().contains("headless"):
		return
	if _shop_open or _mobile_hud_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
		return
	DisplayServer.window_move_to_foreground()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true
	_paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and not _paused and not _shop_open and not _mobile_hud_enabled and not DisplayServer.get_name().contains("headless"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true


func _calc_vp_size() -> Vector2i:
	var win := get_viewport_rect().size
	if win.x <= 10 or win.y <= 10:
		win = Vector2(1280, 720)
	var rh := int(RES_PRESETS[_res_idx].h)
	var rw := maxi(320, int(round(rh * (win.x / maxf(1.0, win.y)))))
	return Vector2i(rw, rh)


func _apply_graphics_preset() -> void:
	if not is_instance_valid(_vp) or not is_instance_valid(_vp_tex):
		return
	var p: Dictionary = RES_PRESETS[_res_idx]
	_vp.size = _calc_vp_size()
	_vp.msaa_3d = p.msaa
	_vp_tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if bool(p.linear) else CanvasItem.TEXTURE_FILTER_NEAREST


func _build_player() -> void:
	_body = CharacterBody3D.new()
	_body.collision_layer = 2
	_body.collision_mask = 1
	_body.floor_max_angle = deg_to_rad(50.0)
	_body.floor_snap_length = 0.26
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.72
	cs.shape = cap
	cs.position.y = 0.86
	_body.add_child(cs)

	_cam_pivot = Node3D.new()
	_cam_pivot.position.y = EYE_STAND
	_body.add_child(_cam_pivot)

	_cam = Camera3D.new()
	_cam.fov = _fov
	_cam.near = 0.05
	_cam.far = 220.0
	_cam.current = true
	_cam_pivot.add_child(_cam)

	weapons = WeaponRig.new()
	_cam.add_child(weapons)
	weapons.setup(world, _cam)
	weapons.weapon_changed.connect(_on_weapon_changed)
	weapons.ammo_updated.connect(_on_ammo_updated)
	weapons.shot_fired.connect(_on_shot_fired)
	weapons.hit_registered.connect(_on_hit_registered)

	_vp.add_child(_body)

	_killcam = Camera3D.new()
	_killcam.fov = 62.0
	_killcam.near = 0.05
	_killcam.far = 220.0
	_killcam.current = false
	_vp.add_child(_killcam)


# ---------------------------------------------------------------- Handcrafted Tactile HUD + Mobile Touch Overlay

func _build_hud() -> void:
	var font_abs := ProjectSettings.globalize_path("res://assets/ui/hud_font.ttf")
	if FileAccess.file_exists(font_abs):
		var ff := FontFile.new()
		if ff.load_dynamic_font(font_abs) == OK:
			_hud_font = ff

	_damage_flash = ColorRect.new()
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.color = Color(0.9, 0.1, 0.15, 0.0)
	add_child(_damage_flash)

	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.draw.connect(_draw_hud_canvas)
	add_child(_hud)

	_banner_label = _make_label("", 15, Color("f5e6c8"))
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_label.position = Vector2(-340, 114)
	_banner_label.custom_minimum_size = Vector2(680, 36)
	_hud.add_child(_banner_label)

	_killcam_card = PanelContainer.new()
	_killcam_card.visible = false
	_killcam_card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_killcam_card.custom_minimum_size = Vector2(650, 108)
	_killcam_card.position = Vector2(-325, -148)
	_killcam_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kc_sb := StyleBoxFlat.new()
	kc_sb.bg_color = Color(0.14, 0.10, 0.08, 0.96)
	kc_sb.border_color = Color("daa854")
	kc_sb.set_border_width_all(3)
	kc_sb.set_corner_radius_all(8)
	kc_sb.content_margin_left = 16
	kc_sb.content_margin_right = 16
	kc_sb.content_margin_top = 8
	kc_sb.content_margin_bottom = 8
	_killcam_card.add_theme_stylebox_override("panel", kc_sb)
	_hud.add_child(_killcam_card)

	var kc_vb := VBoxContainer.new()
	kc_vb.add_theme_constant_override("separation", 4)
	_killcam_card.add_child(kc_vb)
	_kc_header_lbl = _make_label("REC // CAMERA DO ABATE FINAL (CALL OF DUTY KILLCAM) // 0.35x SLOW-MO", 13, Color("e85d4a"))
	_kc_header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kc_vb.add_child(_kc_header_lbl)
	_kc_title_lbl = _make_label("VOCE [1-TAP GOD]   //   OURO BO2 (#1 DA PARTIDA)", 18, Color("f5c242"))
	_kc_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kc_vb.add_child(_kc_title_lbl)
	_kc_sub_lbl = _make_label("AK-47 COMMANDO  |  Skin: Ouro Imperial [Nv.2]  |  HEADSHOT FATAL  |  [ESPACO] Pular", 13, Color("f2e6cf"))
	_kc_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kc_vb.add_child(_kc_sub_lbl)

	_on_weapon_changed(0, str(WeaponRig.WEAPONS[0].name), 32, 160)


func _load_ui_tex(res_path: String) -> Texture2D:
	if _ui_tex_cache.has(res_path):
		return _ui_tex_cache[res_path]
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_ui_tex_cache[res_path] = tex
			return tex
	if ResourceLoader.exists(res_path):
		var t := load(res_path) as Texture2D
		if t != null:
			_ui_tex_cache[res_path] = t
			return t
	return null


func _build_shop_modal() -> void:
	_shop_panel = PanelContainer.new()
	_shop_panel.visible = false
	_shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	_shop_panel.custom_minimum_size = Vector2(960, 560)
	_shop_panel.position = Vector2(-480, -280)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.08, 0.98)
	sb.border_color = Color("daa854")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_shop_panel.add_theme_stylebox_override("panel", sb)
	add_child(_shop_panel)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 10)
	_shop_panel.add_child(root_vb)

	var header := _make_label("ARSENAL & MERCADO SAKURA VIP  //  SKINS 3D, UPGRADES, OPERADORES & DOGTAGS", 18, Color("f5c242"))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vb.add_child(header)

	_shop_status_lbl = _make_label("SALDO: 650 MOEDAS   |   75 DIAMANTES   |   Toque em um card ilustrado para Comprar ou Equipar", 13, Color("f2e6cf"))
	_shop_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vb.add_child(_shop_status_lbl)

	var tab_hb := HBoxContainer.new()
	tab_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hb.add_theme_constant_override("separation", 10)
	root_vb.add_child(tab_hb)

	var tab_defs := [
		{"title": "SKINS DE ARMA & UPGRADE", "col": Color("daa854")},
		{"title": "OPERADORES & DOGTAGS VIP", "col": Color("52b788")}
	]
	for ti in tab_defs.size():
		var td: Dictionary = tab_defs[ti]
		var tb := _make_styled_btn(str(td.title), Vector2(260, 34), td.col, func():
			_shop_tab_idx = ti
			_populate_shop_cards()
		)
		tab_hb.add_child(tb)

	var bonus_btn := _make_styled_btn("BONUS DIARIO (+500 MOEDAS)", Vector2(215, 34), Color("c92a35"), func():
		coins += 500
		gems += 25
		Sfx.play("cash_buy", 1.15)
		_refresh_shop_ui("+500 MOEDAS & +25 DIAMANTES RESGATADOS!")
		_populate_shop_cards()
	)
	tab_hb.add_child(bonus_btn)

	var close_btn := _make_styled_btn("FECHAR LOJA [L]", Vector2(165, 34), Color("a67332"), func(): _toggle_shop(0))
	tab_hb.add_child(close_btn)

	_shop_grid = GridContainer.new()
	_shop_grid.columns = 3
	_shop_grid.add_theme_constant_override("h_separation", 14)
	_shop_grid.add_theme_constant_override("v_separation", 12)
	root_vb.add_child(_shop_grid)

	_populate_shop_cards()


func _populate_shop_cards() -> void:
	if not is_instance_valid(_shop_grid):
		return
	for ch in _shop_grid.get_children():
		ch.queue_free()

	if _shop_tab_idx == 0:
		for i in WeaponRig.WEAPON_SKINS.size():
			var sk: Dictionary = WeaponRig.WEAPON_SKINS[i]
			var owned: bool = bool(unlocked_weapon_skins[i])
			var equipped: bool = (weapons.active_skin_idx == i) if is_instance_valid(weapons) else (i == 0)
			var sub := "+%d%% Dano  |  +%d%% Cadencia" % [
				int(round((float(sk.dmg_mult) - 1.0) * 100.0)),
				int(round((1.0 - float(sk.rate_mult)) * 100.0))
			]
			var act_txt := "EQUIPADA" if equipped else ("EQUIPAR" if owned else ("COMPRAR (%d MOEDAS)" % int(sk.cost)))
			_shop_grid.add_child(_make_product_card(
				"res://assets/ui/skin_weapon_%d.png" % i,
				str(sk.name).to_upper(),
				sub,
				act_txt,
				Color("52b788") if equipped else (Color("daa854") if owned else Color("c92a35")),
				func():
					_buy_or_equip_weapon_skin(i)
					_populate_shop_cards()
			))

		var cur_w := weapons.current_idx if is_instance_valid(weapons) else 0
		var cur_lvl := int(weapons.weapon_levels[cur_w]) if is_instance_valid(weapons) else 1
		var wname := str(WeaponRig.WEAPONS[cur_w].name).split(" ")[0]
		_shop_grid.add_child(_make_product_card(
			"res://assets/ui/upgrade_weapon.png",
			"UPGRADE %s [NV.%d/5]" % [wname, cur_lvl],
			"+Pente, +Dano, -Recuo e Recarga Turbo",
			"NIVEL MAXIMO" if cur_lvl >= 5 else "EVOLUIR (180 MOEDAS)",
			Color("daa854"),
			func():
				_buy_weapon_upgrade()
				_populate_shop_cards()
		))
	else:
		for i in WeaponRig.CHAR_SKINS.size():
			var cs: Dictionary = WeaponRig.CHAR_SKINS[i]
			var owned: bool = bool(unlocked_char_skins[i])
			var equipped: bool = (weapons.active_char_skin_idx == i) if is_instance_valid(weapons) else (i == 0)
			var sub := "Velocidade Parkour +%d%%" % int(round(float(cs.speed_bonus) * 100.0))
			var act_txt := "EQUIPADO" if equipped else ("EQUIPAR" if owned else ("COMPRAR (%d MOEDAS)" % int(cs.cost)))
			_shop_grid.add_child(_make_product_card(
				"res://assets/ui/skin_char_%d.png" % i,
				str(cs.name).to_upper(),
				sub,
				act_txt,
				Color("52b788") if equipped else Color("daa854"),
				func():
					_buy_or_equip_char_skin(i)
					_populate_shop_cards()
			))
		for d_i in [1, 4]:
			var dt: Dictionary = DOGTAGS[d_i]
			var owned: bool = bool(unlocked_dogtags[d_i])
			var equipped: bool = (active_dogtag_idx == d_i)
			var act_txt := "EQUIPADA" if equipped else ("EQUIPAR" if owned else ("COMPRAR (%d MOEDAS)" % int(dt.cost)))
			_shop_grid.add_child(_make_product_card(
				str(dt.icon_path),
				"DOGTAG: %s" % str(dt.name),
				"Exibida no seu Card e no Killfeed",
				act_txt,
				Color("52b788") if equipped else Color("c92a35"),
				func():
					_buy_or_equip_dogtag(d_i)
					_populate_shop_cards()
			))


func _make_product_card(img_path: String, title: String, sub: String, btn_txt: String, accent: Color, on_click: Callable) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(292, 198)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.21, 0.15, 0.11, 0.98)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	pc.add_child(vb)

	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(268, 98)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = _load_ui_tex(img_path)
	vb.add_child(tr)

	var tl := _make_label(title, 13, Color("fff4d2"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)

	var sl := _make_label(sub, 11, Color("d8c7ae"))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sl)

	var btn := _make_styled_btn(btn_txt, Vector2(268, 30), accent, on_click)
	vb.add_child(btn)
	return pc


func _make_styled_btn(txt: String, min_sz: Vector2, accent: Color, on_click: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_sz
	if _hud_font != null:
		b.add_theme_font_override("font", _hud_font)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color("fff8ea"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent.darkened(0.35)
	sb.border_color = accent.lightened(0.22)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = accent.darkened(0.15)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_h)
	b.pressed.connect(on_click)
	return b


func _toggle_shop(force_state: int = -1) -> void:
	if force_state == 0:
		_shop_open = false
	elif force_state == 1:
		_shop_open = true
	else:
		_shop_open = not _shop_open
	_shop_panel.visible = _shop_open
	if _shop_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
		_populate_shop_cards()
		_refresh_shop_ui("Toque nas figuras para comprar ou equipar Skins 3D, Upgrades, Operadores e Dogtags")
	else:
		_capture_mouse()


func _refresh_shop_ui(msg: String = "") -> void:
	if is_instance_valid(_shop_status_lbl):
		_shop_status_lbl.text = "SALDO: %d MOEDAS   |   %d DIAMANTES   |   %s" % [coins, gems, msg]


func _buy_or_equip_weapon_skin(idx: int) -> void:
	var sk: Dictionary = WeaponRig.WEAPON_SKINS[idx]
	var cost := int(sk.cost)
	if not bool(unlocked_weapon_skins[idx]):
		if coins < cost:
			Sfx.play("hurt")
			_refresh_shop_ui("Moedas insuficientes! Faca Kills, Parkour ou toque em Bonus Diario!")
			return
		coins -= cost
		unlocked_weapon_skins[idx] = true
		Sfx.play("cash_buy")
	else:
		Sfx.play("pickup")
	weapons.apply_weapon_skin(idx)
	_refresh_shop_ui("Skin de Arma [%s] EQUIPADA!" % str(sk.name))
	_show_banner("SKIN 3D EQUIPADA: %s!" % str(sk.name).to_upper(), 2.4)


func _buy_weapon_upgrade() -> void:
	var cur_lvl := int(weapons.weapon_levels[weapons.current_idx])
	if cur_lvl >= 5:
		_refresh_shop_ui("Esta arma ja esta no NIVEL MAXIMO (Nv.5)!")
		return
	var cost := 180
	if coins < cost:
		Sfx.play("hurt")
		_refresh_shop_ui("Precisa de 180 Moedas para fazer Upgrade!")
		return
	coins -= cost
	var new_lvl := weapons.upgrade_current_weapon()
	Sfx.play("rank_up", 1.1)
	var wname := str(WeaponRig.WEAPONS[weapons.current_idx].name)
	_refresh_shop_ui("%s evoluida para NIVEL %d!" % [wname, new_lvl])
	_show_banner("UPGRADE COMPLETO: %s NIVEL %d (+Pente, +Dano, -Recuo)!" % [wname, new_lvl], 2.5)


func _buy_or_equip_char_skin(idx: int) -> void:
	var cs: Dictionary = WeaponRig.CHAR_SKINS[idx]
	var cost := int(cs.cost)
	if not bool(unlocked_char_skins[idx]):
		if coins < cost:
			Sfx.play("hurt")
			_refresh_shop_ui("Moedas insuficientes para %s!" % str(cs.name))
			return
		coins -= cost
		unlocked_char_skins[idx] = true
		Sfx.play("cash_buy")
	else:
		Sfx.play("pickup")
	weapons.apply_char_skin(idx)
	_refresh_shop_ui("Operador [%s] EQUIPADO!" % str(cs.name))
	_show_banner("SKIN DE PERSONAGEM: %s!" % str(cs.name).to_upper(), 2.2)


func _buy_or_equip_dogtag(idx: int) -> void:
	var dt: Dictionary = DOGTAGS[idx]
	var cost := int(dt.cost)
	if not bool(unlocked_dogtags[idx]):
		if coins < cost:
			Sfx.play("hurt")
			_refresh_shop_ui("Moedas insuficientes para a Dogtag [%s]!" % str(dt.name))
			return
		coins -= cost
		unlocked_dogtags[idx] = true
		Sfx.play("cash_buy")
	active_dogtag_idx = idx
	_refresh_shop_ui("Dogtag [%s] EQUIPADA no seu perfil e Killfeed!" % str(dt.name))


func _make_label(txt: String, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	if _hud_font != null:
		l.add_theme_font_override("font", _hud_font)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.03, 0.95))
	l.add_theme_constant_override("outline_size", 5)
	return l


# ---------------------------------------------------------------- Handcrafted Tactile HUD + Live Leaderboards + Mobile Overlay

func _draw_hud_text(pos: Vector2, txt: String, fsize: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, outline_sz: int = 4, outline_col: Color = Color(0.08, 0.05, 0.04, 0.94)) -> void:
	var font: Font = _hud_font if _hud_font != null else ThemeDB.fallback_font
	if font == null:
		return
	if outline_sz > 0:
		_hud.draw_string_outline(font, pos, txt, align, width, fsize, outline_sz, outline_col)
	_hud.draw_string(font, pos, txt, align, width, fsize, col)


func _draw_hud_canvas() -> void:
	var center := size * 0.5
	var W := size.x
	var H := size.y

	# 0. Call of Duty: Black Ops 2 KillCam Letterbox + Telemetry Frame
	if _killcam_active:
		var bar_h := 54.0
		var bar_col := Color(0.05, 0.04, 0.04, 0.90)
		_hud.draw_rect(Rect2(0, 0, W, bar_h), bar_col)
		_hud.draw_rect(Rect2(0, H - bar_h, W, bar_h), bar_col)
		var accent := Color("daa854") if _killcam_mode == "FINAL" else Color("c42a30")
		_hud.draw_line(Vector2(0, bar_h), Vector2(W, bar_h), accent, 2.5)
		_hud.draw_line(Vector2(0, H - bar_h), Vector2(W, H - bar_h), accent, 2.5)
		return

	# 1. Crosshair / AWP Sniper Scope + Phantom Forces Double Hitmarker
	if is_instance_valid(weapons) and weapons.is_scoped_in():
		var rad := minf(W, H) * 0.43
		var dark := Color(0.02, 0.03, 0.05, 0.94)
		_hud.draw_rect(Rect2(0, 0, center.x - rad, H), dark)
		_hud.draw_rect(Rect2(center.x + rad, 0, W - (center.x + rad), H), dark)
		_hud.draw_rect(Rect2(center.x - rad, 0, rad * 2.0, center.y - rad), dark)
		_hud.draw_rect(Rect2(center.x - rad, center.y + rad, rad * 2.0, H - (center.y + rad)), dark)
		_hud.draw_arc(center, rad, 0.0, TAU, 64, Color(0.08, 0.06, 0.05), 28.0)
		_hud.draw_arc(center, rad - 12.0, 0.0, TAU, 64, Color("daa854"), 2.0)
		_hud.draw_line(Vector2(center.x - rad, center.y), Vector2(center.x + rad, center.y), Color(0, 0, 0, 0.9), 1.6)
		_hud.draw_line(Vector2(center.x, center.y - rad), Vector2(center.x, center.y + rad), Color(0, 0, 0, 0.9), 1.6)
		_hud.draw_circle(center, 2.5, Color("e63946"))
	else:
		var ads_fade := 1.0 - (weapons.ads_alpha if is_instance_valid(weapons) else 0.0)
		if ads_fade > 0.05:
			var gap := 4.5 + _crosshair_spread * 16.0
			var len_px := 7.5
			var ch_col := Color(0.98, 0.92, 0.72, ads_fade * 0.95)
			for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				_hud.draw_line(center + d * gap, center + d * (gap + len_px), Color(0, 0, 0, ads_fade * 0.75), 4.0)
				_hud.draw_line(center + d * gap, center + d * (gap + len_px), ch_col, 2.0)
			_hud.draw_circle(center, 1.8, Color(0.92, 0.25, 0.28, ads_fade))
		else:
			_hud.draw_circle(center, 2.2, Color("e63946"))

	if _hitmarker_timer > 0.0:
		var hm_col := Color("ff2a55") if _hitmarker_crit else Color("fff5dc")
		for dir in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_hud.draw_line(center + dir * 5.0, center + dir * 15.0, hm_col, 2.8)
			if _hitmarker_crit:
				_hud.draw_line(center + dir * 9.0, center + dir * 20.0, Color("ffd166"), 1.8)

	# =========================================================================
	# 2. TOP-CENTER TORII-ARCH SCOREBOARD + 2-MODE SWITCHER ([M]) + 4 STAGE TABS
	# =========================================================================
	var cx := center.x
	var tc_pos := Vector2(cx - 240.0, 4.0)
	var tc_tex := _load_ui_tex("res://assets/ui/hud_top_scoreboard.png")
	if tc_tex != null:
		_hud.draw_texture_rect(tc_tex, Rect2(tc_pos, Vector2(480, 82)), false)

	var stage_defs := world.get_stage_defs_for_mode()
	var cur_def: Dictionary = world.get_active_stage_def()

	if current_mode == SakuraWorld.MODE_COMBAT:
		var standings := world.get_combat_standings(kills, deaths)
		var my_rank := 1
		for r_item in standings:
			if bool(r_item.is_player):
				my_rank = int(r_item.rank)
				break
		_draw_hud_text(tc_pos + Vector2(48, 37), "KILLS", 11, Color("a8e0f0"), HORIZONTAL_ALIGNMENT_CENTER, 42)
		_draw_hud_text(tc_pos + Vector2(92, 41), "%d" % kills, 24, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, 56)
		_draw_hud_text(tc_pos + Vector2(332, 41), "#%d" % my_rank, 22, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER, 56)
		_draw_hud_text(tc_pos + Vector2(394, 37), "RANK", 11, Color("ffadb0"), HORIZONTAL_ALIGNMENT_CENTER, 42)

		_draw_hud_text(tc_pos + Vector2(168, 29), "MODO TIRO // %s" % str(cur_def.short), 11, Color("f5c862"), HORIZONTAL_ALIGNMENT_CENTER, 144)
		_draw_hud_text(tc_pos + Vector2(168, 43), "STREAK x%d  |  %d ALVOS" % [streak, world.enemies.size()], 12, Color("fff6e5"), HORIZONTAL_ALIGNMENT_CENTER, 144)
	else:
		var r_standings := world.get_race_standings()
		var my_pos := 1
		var my_pct := 0
		for r_item in r_standings:
			if bool(r_item.is_player):
				my_pos = int(r_item.rank)
				my_pct = int(round(float(r_item.pct)))
				break
		_draw_hud_text(tc_pos + Vector2(46, 37), "POS", 12, Color("a8e0f0"), HORIZONTAL_ALIGNMENT_CENTER, 40)
		_draw_hud_text(tc_pos + Vector2(92, 41), "%d/8" % my_pos, 22, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER, 56)
		_draw_hud_text(tc_pos + Vector2(332, 41), "%d%%" % my_pct, 20, Color("8ce8d8"), HORIZONTAL_ALIGNMENT_CENTER, 56)
		_draw_hud_text(tc_pos + Vector2(394, 37), "SET %d/8" % world.kz_active_stage, 10, Color("ffadb0"), HORIZONTAL_ALIGNMENT_CENTER, 44)

		_draw_hud_text(tc_pos + Vector2(168, 29), "CORRIDA // %s" % str(cur_def.short), 11, Color("00f5d4"), HORIZONTAL_ALIGNMENT_CENTER, 144)
		_draw_hud_text(tc_pos + Vector2(168, 43), "TEMPO %.1fs  |  SEM PVP" % world.kz_time, 12, Color("fff6e5"), HORIZONTAL_ALIGNMENT_CENTER, 144)

	# 4 Hanging Wooden Stage Tabs ([F1] [F2] [F3] [F4])
	for i in 4:
		var tx := tc_pos.x + 70.0 + i * 86.0
		var ty := tc_pos.y + 54.5
		var is_act := (i == current_stage)
		if is_act:
			_hud.draw_rect(Rect2(tx + 2, ty + 2, 77, 18), Color(0.76, 0.20, 0.24, 0.88))
		var tab_lbl := str(stage_defs[i].short)
		_draw_hud_text(Vector2(tx + 2, ty + 15), tab_lbl, 10, Color("fff2c2") if is_act else Color("c4b49a"), HORIZONTAL_ALIGNMENT_CENTER, 77)

	# Prominent Top Controls: 2-Mode Switcher, Touch HUD, Graphics Presets [O], and Weather [U]
	var m0_rect := Rect2(cx - 325.0, 86.0, 118.0, 24.0)
	var m1_rect := Rect2(cx - 201.0, 86.0, 138.0, 24.0)
	var mob_rect := Rect2(cx - 57.0, 86.0, 96.0, 24.0)
	var gfx_rect := Rect2(cx + 45.0, 86.0, 168.0, 24.0)
	var atmo_rect := Rect2(cx + 219.0, 86.0, 106.0, 24.0)

	_hud.draw_rect(m0_rect, Color("c92a42") if current_mode == 0 else Color(0.14, 0.11, 0.09, 0.88))
	_hud.draw_rect(m0_rect, Color("ffd166") if current_mode == 0 else Color("6e5a44"), false, 1.8)
	_draw_hud_text(m0_rect.position + Vector2(0, 16), "[M] 1: TIRO", 10, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, m0_rect.size.x)

	_hud.draw_rect(m1_rect, Color("0096c7") if current_mode == 1 else Color(0.14, 0.11, 0.09, 0.88))
	_hud.draw_rect(m1_rect, Color("00f5d4") if current_mode == 1 else Color("6e5a44"), false, 1.8)
	_draw_hud_text(m1_rect.position + Vector2(0, 16), "[M] 2: PARKOUR", 10, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, m1_rect.size.x)

	_hud.draw_rect(mob_rect, Color("2a9d8f") if _mobile_hud_enabled else Color(0.14, 0.11, 0.09, 0.88))
	_hud.draw_rect(mob_rect, Color("ffd166"), false, 1.5)
	_draw_hud_text(mob_rect.position + Vector2(0, 16), "[V] TOUCH: %s" % ("ON" if _mobile_hud_enabled else "OFF"), 10, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, mob_rect.size.x)

	var cur_gfx: Dictionary = RES_PRESETS[_res_idx]
	_hud.draw_rect(gfx_rect, Color(0.28, 0.16, 0.42, 0.92))
	_hud.draw_rect(gfx_rect, Color("c77dff"), false, 1.6)
	_draw_hud_text(gfx_rect.position + Vector2(0, 16), "[O] GFX: %s" % str(cur_gfx.get("short", cur_gfx.label)), 10, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, gfx_rect.size.x)

	_hud.draw_rect(atmo_rect, Color(0.38, 0.25, 0.10, 0.92))
	_hud.draw_rect(atmo_rect, Color("ffd166"), false, 1.5)
	_draw_hud_text(atmo_rect.position + Vector2(0, 16), "[U] CLIMA", 10, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, atmo_rect.size.x)

	# =========================================================================
	# 2B. GIANT FALL GUYS 5-4-3-2-1 VAI! STARTING GATE COUNTDOWN OVERLAY
	# =========================================================================
	if current_mode == SakuraWorld.MODE_PARKOUR and world.race_countdown > 0.0:
		var cd_num := int(ceil(world.race_countdown))
		var pulse := 1.0 + sin(_hud_anim_t * 14.0) * 0.08
		var box_w := 440.0 * pulse
		var box_h := 118.0
		var c_rect := Rect2(cx - box_w * 0.5, center.y - 125.0, box_w, box_h)
		_hud.draw_rect(c_rect, Color(0.10, 0.07, 0.16, 0.92))
		_hud.draw_rect(c_rect, Color("ff2a85"), false, 4.0)
		_draw_hud_text(Vector2(cx - 210.0, center.y - 92.0), "CORRIDA FALL GUYS // QUEM CHEGA PRIMEIRO!", 14, Color("00f5d4"), HORIZONTAL_ALIGNMENT_CENTER, 420.0)
		_draw_hud_text(Vector2(cx - 210.0, center.y - 34.0), "LARGADA EM %d..." % cd_num, 42, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER, 420.0)
		_draw_hud_text(Vector2(cx - 210.0, center.y - 12.0), "7 BOTS NA LINHA DE LARGADA — SEM DANO DE TIRO PVP!", 11, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, 420.0)

	# =========================================================================
	# 3. TOP-LEFT TACTICAL WALLET & RANK SHIELD STRIP (Tap to open VIP Shop!)
	# =========================================================================
	var tl_pos := Vector2(12.0, 8.0)
	var tl_tex := _load_ui_tex("res://assets/ui/hud_wallet_badge.png")
	if tl_tex != null:
		_hud.draw_texture_rect(tl_tex, Rect2(tl_pos, Vector2(290, 54)), false)
	var r_name := str(RANK_TIERS[rank_idx].name)
	var my_tag := str(DOGTAGS[active_dogtag_idx].name)
	_draw_hud_text(tl_pos + Vector2(44, 24), r_name, 12, Color("f5c862"))
	_draw_hud_text(tl_pos + Vector2(44, 39), "TAG: %s [LOJA]" % my_tag, 10, Color("d8cab4"))
	_draw_hud_text(tl_pos + Vector2(170, 32), "%d" % coins, 14, Color("ffe082"))
	_draw_hud_text(tl_pos + Vector2(235, 32), "%d" % gems, 14, Color("90e8f8"))

	# =========================================================================
	# 4. TOP-RIGHT KILLFEED + LIVE COMPETITIVE LEADERBOARD (Matadores / Corredores)
	# =========================================================================
	var tape_tex := _load_ui_tex("res://assets/ui/hud_kill_tape.png")
	var kf_y := 8.0
	var max_kf := mini(2, killfeed.size())
	for k_i in max_kf:
		var kf := killfeed[k_i]
		var kpos := Vector2(W - 318.0, kf_y)
		if tape_tex != null:
			_hud.draw_texture_rect(tape_tex, Rect2(kpos, Vector2(306, 26)), false)
		_draw_hud_text(kpos + Vector2(38, 18), str(kf.text), 10, Color("2b1e16"), HORIZONTAL_ALIGNMENT_LEFT, 256.0, 0)
		kf_y += 28.0

	# Live Competitive Leaderboard Panel (Top 5 Players/Bots in Real Time!)
	var lb_pos := Vector2(W - 252.0, maxf(68.0, kf_y + 4.0))
	var lb_rect := Rect2(lb_pos, Vector2(240.0, 128.0))
	_hud.draw_rect(lb_rect, Color(0.11, 0.08, 0.07, 0.88))
	_hud.draw_rect(lb_rect, Color("daa854") if current_mode == 0 else Color("00f5d4"), false, 2.0)

	if current_mode == SakuraWorld.MODE_COMBAT:
		_draw_hud_text(lb_pos + Vector2(8, 17), "PLACAR DE MATADORES (TOP 5)", 11, Color("ffd166"))
		var c_rows := world.get_combat_standings(kills, deaths)
		for r_i in mini(5, c_rows.size()):
			var row: Dictionary = c_rows[r_i]
			var ry := lb_pos.y + 35.0 + r_i * 19.0
			var is_me := bool(row.is_player)
			if is_me:
				_hud.draw_rect(Rect2(lb_pos.x + 3, ry - 12, 234, 17), Color(0.85, 0.22, 0.28, 0.55))
			var col_r := Color("ffd166") if r_i == 0 else (Color("00f5d4") if is_me else Color("f2e6cf"))
			_draw_hud_text(Vector2(lb_pos.x + 8, ry), "#%d %s" % [int(row.rank), str(row.name)], 11, col_r)
			_draw_hud_text(Vector2(lb_pos.x + 150, ry), "%d K  (%d PTS)" % [int(row.kills), int(row.pts)], 10, col_r, HORIZONTAL_ALIGNMENT_RIGHT, 82.0)
	else:
		_draw_hud_text(lb_pos + Vector2(8, 17), "CORRIDA FALL GUYS (TOP 5)", 11, Color("00f5d4"))
		var p_rows := world.get_race_standings()
		for r_i in mini(5, p_rows.size()):
			var row: Dictionary = p_rows[r_i]
			var ry := lb_pos.y + 35.0 + r_i * 19.0
			var is_me := bool(row.is_player)
			if is_me:
				_hud.draw_rect(Rect2(lb_pos.x + 3, ry - 12, 234, 17), Color(0.0, 0.65, 0.85, 0.50))
			var col_r := Color("ffd166") if r_i == 0 else (Color("00f5d4") if is_me else Color("f2e6cf"))
			_draw_hud_text(Vector2(lb_pos.x + 8, ry), "%dº %s" % [int(row.rank), str(row.name)], 11, col_r)
			var st_s := "CHEGOU!" if bool(row.finished) else ("%dm (%d%%)" % [int(round(float(row.dist))), int(round(float(row.pct)))])
			_draw_hud_text(Vector2(lb_pos.x + 140, ry), st_s, 10, col_r, HORIZONTAL_ALIGNMENT_RIGHT, 92.0)

	# =========================================================================
	# 4B. PHANTOM FORCES CENTER-SCREEN DOPAMINE SCORE FEED STACK!
	# =========================================================================
	if not _pf_score_stack.is_empty():
		var pf_y := center.y + 52.0
		for pf_item in _pf_score_stack:
			var alpha := clampf(float(pf_item.life) / 1.2, 0.0, 1.0)
			var c: Color = pf_item.col
			c.a = alpha
			_draw_hud_text(Vector2(cx - 190.0, pf_y), str(pf_item.text), int(pf_item.size), c, HORIZONTAL_ALIGNMENT_CENTER, 380.0, 4, Color(0, 0, 0, alpha * 0.9))
			pf_y += 20.0

	# =========================================================================
	# 5. BOTTOM-LEFT TACTICAL VITALITY & MECHANICAL TACHOMETER (hud_vitality_frame.png)
	# =========================================================================
	var bl_pos := Vector2(10.0, H - 140.0)
	var vit_tex := _load_ui_tex("res://assets/ui/hud_vitality_frame.png")
	if vit_tex != null:
		_hud.draw_texture_rect(vit_tex, Rect2(bl_pos, Vector2(380, 132)), false)

	var hp_ratio := clampf(hp / max_hp, 0.0, 1.0)
	var lag_ratio := clampf(_hp_lag / max_hp, 0.0, 1.0)
	var ar_ratio := clampf(armor / 100.0, 0.0, 1.0)

	_draw_hud_text(bl_pos + Vector2(68, 49), "HP %d" % int(ceil(hp)), 16, Color("fff4dc"))
	_draw_hud_text(bl_pos + Vector2(158, 49), "COLETE %d%%" % int(ceil(armor)), 12, Color("82c8f8"))

	if ar_ratio > 0.005:
		var ar_w := 176.0 * ar_ratio
		_hud.draw_rect(Rect2(bl_pos.x + 69.0, bl_pos.y + 58.0, ar_w, 7.0), Color("3a86ff"))
		_hud.draw_rect(Rect2(bl_pos.x + 69.0, bl_pos.y + 58.0, ar_w, 2.0), Color("90caf9"))

	if lag_ratio > hp_ratio:
		_hud.draw_rect(Rect2(bl_pos.x + 69.0, bl_pos.y + 73.5, 176.0 * lag_ratio, 16.5), Color("f4a261"))
	if hp_ratio > 0.005:
		var hp_w := 176.0 * hp_ratio
		var bar_c := Color("2ec4b6") if hp_ratio > 0.5 else (Color("f4a261") if hp_ratio > 0.25 else Color("e63946"))
		_hud.draw_rect(Rect2(bl_pos.x + 69.0, bl_pos.y + 73.5, hp_w, 16.5), bar_c)
		_hud.draw_rect(Rect2(bl_pos.x + 69.0, bl_pos.y + 73.5, hp_w, 4.0), bar_c.lightened(0.32))
		for seg in range(1, 10):
			var sx := bl_pos.x + 69.0 + seg * 17.6
			if sx < bl_pos.x + 69.0 + hp_w:
				_hud.draw_line(Vector2(sx, bl_pos.y + 73.5), Vector2(sx, bl_pos.y + 90.0), Color(0, 0, 0, 0.32), 1.2)

	var st_txt := "EM PE // PRONTO"
	if _adrenaline_t > 0.0:
		st_txt = "ADRENALINA // +VEL & CURA"
	elif _surfing:
		st_txt = "SURF // DESFILADEIRO"
	elif _on_ladder:
		st_txt = "ESCADA // VERTICAL"
	elif is_instance_valid(weapons) and weapons.ads_alpha > 0.5:
		st_txt = "MIRA SIGHT // ATIVA"
	elif _crouching:
		st_txt = "AGACHADO // SLIDE"
	elif _sprinting:
		st_txt = "SPRINT TATICO BO2"
	_draw_hud_text(bl_pos + Vector2(74, 109), st_txt, 11, Color("2e1f14"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 0)

	var dial_c := bl_pos + Vector2(309.0, 69.0)
	var cs_units := int(round(_h_speed_cached * 48.0))
	var spd_ratio := clampf(float(cs_units) / 400.0, 0.0, 1.0)
	var needle_ang := deg_to_rad(135.0 + 270.0 * spd_ratio)
	var needle_tip := dial_c + Vector2(cos(needle_ang), sin(needle_ang)) * 31.0
	var needle_tail := dial_c - Vector2(cos(needle_ang), sin(needle_ang)) * 7.0
	_hud.draw_line(needle_tail, needle_tip, Color("e63946"), 2.8)
	_hud.draw_circle(dial_c, 4.5, Color("daa854"))
	_hud.draw_circle(dial_c, 2.2, Color("22201d"))
	_draw_hud_text(dial_c + Vector2(-32, 27), "%d u/s" % cs_units, 11, Color("f5c862") if _bhop_chain > 1 else Color("fff4dc"), HORIZONTAL_ALIGNMENT_CENTER, 64)

	# =========================================================================
	# 6. BOTTOM-RIGHT TACTILE ARSENAL CASE & ILLUSTRATED WEAPON BAY (hud_weapon_frame.png)
	# =========================================================================
	var br_pos := Vector2(W - 410.0, H - 140.0)
	var wep_tex := _load_ui_tex("res://assets/ui/hud_weapon_frame.png")
	if wep_tex != null:
		_hud.draw_texture_rect(wep_tex, Rect2(br_pos, Vector2(400, 132)), false)

	var w_idx := weapons.current_idx if is_instance_valid(weapons) else 0
	var sk_dict: Dictionary = WeaponRig.WEAPON_SKINS[weapons.active_skin_idx] if is_instance_valid(weapons) else WeaponRig.WEAPON_SKINS[0]
	var w_lvl := int(weapons.weapon_levels[w_idx]) if is_instance_valid(weapons) else 1

	var gun_tex := _load_ui_tex("res://assets/ui/hud_gun_%d.png" % w_idx)
	if gun_tex != null:
		_hud.draw_texture_rect(gun_tex, Rect2(br_pos + Vector2(35, 33), Vector2(148, 54)), false)

	var w_short := str(WeaponRig.WEAPONS[w_idx].name).split(" ")[0] if is_instance_valid(weapons) else "AK-47"
	var sk_short := str(sk_dict.name).split(" (")[0].split(" /")[0].replace(" Cyber Roblox", " Cyber").to_upper()
	_draw_hud_text(
		br_pos + Vector2(198, 46),
		"%s // %s [NV.%d]" % [w_short, sk_short, w_lvl],
		10, Color("2b1e16"), HORIZONTAL_ALIGNMENT_LEFT, 168.0, 0
	)

	if w_idx == 3:
		_draw_hud_text(br_pos + Vector2(196, 81), "LAMINA TATICA (+18% VEL)", 16, Color("f5c862"))
	elif _reloading_cached:
		_draw_hud_text(br_pos + Vector2(196, 81), "RECARREGANDO PENTE...", 16, Color("f4a261"))
	else:
		_draw_hud_text(br_pos + Vector2(196, 84), "%02d" % _cur_ammo_cached, 28, Color("fff6e5"))
		_draw_hud_text(br_pos + Vector2(236, 82), "/ %d" % _cur_res_cached, 14, Color("c4b49a"))
		for p_i in 15:
			var px := br_pos.x + 282.0 + p_i * 6.4
			var py := br_pos.y + 64.0
			var has_bullet := (p_i < _cur_ammo_cached)
			if has_bullet:
				_hud.draw_rect(Rect2(px + 0.8, py, 3.0, 5.0), Color("d97842"))
				_hud.draw_rect(Rect2(px, py + 5.0, 4.6, 13.0), Color("e5b84b"))
				_hud.draw_rect(Rect2(px - 0.3, py + 18.5, 5.2, 2.0), Color("b08428"))
			else:
				_hud.draw_rect(Rect2(px, py + 4.0, 4.4, 16.0), Color(0.14, 0.15, 0.19, 0.85))

	var key_names := ["1 AK-47", "2 AWP", "3 DEAGLE", "4 FACAO"]
	for s_i in 4:
		var kx := br_pos.x + 30.0 + s_i * 88.0
		var ky := br_pos.y + 94.0
		var s_act := (s_i == w_idx)
		if s_act:
			_hud.draw_rect(Rect2(kx + 2, ky + 2, 79, 15), Color(0.76, 0.20, 0.24, 0.88))
		_draw_hud_text(Vector2(kx + 2, ky + 14), key_names[s_i], 11, Color("fff2c2") if s_act else Color("b4a690"), HORIZONTAL_ALIGNMENT_CENTER, 79)

	# =========================================================================
	# 7. MOBILE-FIRST PRO MULTI-TOUCH HUD (iOS / Play Store / Web Touchscreen)
	# =========================================================================
	if _mobile_hud_enabled and not _shop_open:
		_draw_mobile_touch_overlay(W, H)


func _draw_mobile_touch_overlay(W: float, H: float) -> void:
	# 1. Left Virtual 360° Thumbstick with Auto-Sprint Outer Ring!
	var jc := Vector2(138.0, H - 255.0) if _joy_touch_idx < 0 else _joy_center
	var jk := jc if _joy_touch_idx < 0 else _joy_knob
	_hud.draw_circle(jc, _joy_radius, Color(0.08, 0.10, 0.14, 0.52))
	_hud.draw_arc(jc, _joy_radius, 0.0, TAU, 40, Color(0.0, 0.96, 0.83, 0.78), 2.5)
	_hud.draw_arc(jc, _joy_radius * 0.72, 0.0, TAU, 32, Color(1.0, 0.82, 0.4, 0.35), 1.5)
	_hud.draw_circle(jk, 28.0, Color(1.0, 0.82, 0.40, 0.88))
	_hud.draw_arc(jk, 28.0, 0.0, TAU, 24, Color("ffffff"), 2.0)
	_draw_hud_text(jc + Vector2(-60, -_joy_radius - 10), "ANALOGICO + SPRINT", 10, Color("00f5d4"), HORIZONTAL_ALIGNMENT_CENTER, 120)

	# 2. Top-Left Claw Fire Button (For 3-Finger / 4-Finger Mobile Pros)
	var claw_r := Rect2(26.0, 82.0, 118.0, 56.0)
	_draw_touch_button_rect(claw_r, "ATIRAR (CLAW)", Color("ff2a55"), _mobile_fire_held)

	# 3. Right-Side Ergonomic Action Cluster (Fire, Jump, Slide/Crouch, ADS, Reload, Inspect, Auto-Fire)
	var fire_r := Rect2(W - 168.0, H - 295.0, 142.0, 74.0)
	var jump_r := Rect2(W - 152.0, H - 382.0, 126.0, 64.0)
	var ads_r := Rect2(W - 302.0, H - 285.0, 120.0, 58.0)
	var crouch_r := Rect2(W - 290.0, H - 365.0, 120.0, 56.0)
	var reload_r := Rect2(W - 425.0, H - 210.0, 96.0, 46.0)
	var insp_r := Rect2(W - 318.0, H - 210.0, 96.0, 46.0)
	var auto_r := Rect2(W - 210.0, H - 210.0, 184.0, 46.0)

	_draw_touch_button_rect(fire_r, "ATIRAR / GOLPE", Color("ff2a55"), _mobile_fire_held)
	_draw_touch_button_rect(jump_r, "PULAR [SPACE]", Color("ffd166"), _mobile_jump_held)
	_draw_touch_button_rect(ads_r, "MIRA (ADS)", Color("00f5d4"), is_instance_valid(weapons) and weapons.want_ads)
	_draw_touch_button_rect(crouch_r, "SLIDE / AGACHAR", Color("3a86ff"), _crouching)
	_draw_touch_button_rect(reload_r, "RECARGA [R]", Color("f4a261"), false)
	_draw_touch_button_rect(insp_r, "GIRAR [F]", Color("9b5de5"), false)
	_draw_touch_button_rect(auto_r, "AUTO-TIRO: %s" % ("ON" if _mobile_autofire else "OFF"), Color("2ec4b6") if _mobile_autofire else Color("6c757d"), _mobile_autofire)


func _draw_touch_button_rect(r: Rect2, label: String, col: Color, active: bool) -> void:
	var bg := col.darkened(0.15) if active else Color(0.09, 0.11, 0.16, 0.68)
	bg.a = 0.86 if active else 0.68
	_hud.draw_rect(r, bg)
	_hud.draw_rect(r, col.lightened(0.25) if active else col, false, 2.4)
	_draw_hud_text(r.position + Vector2(0, r.size.y * 0.5 + 5.0), label, 11, Color("fff8ea"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


# ---------------------------------------------------------------- Unified Input: Desktop + Multi-Touch Mobile-First Engine

func _handle_hud_tap_or_click(pos: Vector2, pressed: bool) -> bool:
	var W := size.x
	var H := size.y
	var cx := W * 0.5
	var tc_pos := Vector2(cx - 240.0, 4.0)

	if pressed:
		# 1. Top-Left Wallet Card -> Opens VIP Shop!
		if Rect2(12.0, 8.0, 290.0, 54.0).has_point(pos):
			_toggle_shop()
			return true
		# 2. Top Mode Switcher Pills (MODO 1: TIRO | MODO 2: PARKOUR | TOUCH | GFX [O] | CLIMA [U])
		if Rect2(cx - 325.0, 84.0, 118.0, 28.0).has_point(pos):
			_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 0)
			return true
		if Rect2(cx - 201.0, 84.0, 138.0, 28.0).has_point(pos):
			_select_mode_and_stage(SakuraWorld.MODE_PARKOUR, 0)
			return true
		if Rect2(cx - 57.0, 84.0, 96.0, 28.0).has_point(pos):
			_toggle_mobile_hud()
			return true
		if Rect2(cx + 45.0, 84.0, 168.0, 28.0).has_point(pos):
			_cycle_graphics_preset()
			return true
		if Rect2(cx + 219.0, 84.0, 106.0, 28.0).has_point(pos):
			_cycle_atmosphere_preset()
			return true
		# 3. 4 Stage Tabs (F1..F4)
		for i in 4:
			var tx := tc_pos.x + 70.0 + i * 86.0
			var ty := tc_pos.y + 52.0
			if Rect2(tx, ty, 82.0, 24.0).has_point(pos):
				_select_mode_and_stage(current_mode, i)
				return true
		# 4. Bottom-Right 4 Weapon Slots (1 AK-47, 2 AWP, 3 DEAGLE, 4 KARAMBIT)
		var br_pos := Vector2(W - 410.0, H - 140.0)
		for s_i in 4:
			var kx := br_pos.x + 28.0 + s_i * 88.0
			var ky := br_pos.y + 90.0
			if Rect2(kx, ky, 84.0, 26.0).has_point(pos):
				weapons.select_weapon(s_i)
				return true

	if not _mobile_hud_enabled:
		return false

	# Mobile Action Buttons
	var claw_r := Rect2(26.0, 82.0, 118.0, 56.0)
	var fire_r := Rect2(W - 168.0, H - 295.0, 142.0, 74.0)
	var jump_r := Rect2(W - 152.0, H - 382.0, 126.0, 64.0)
	var ads_r := Rect2(W - 302.0, H - 285.0, 120.0, 58.0)
	var crouch_r := Rect2(W - 290.0, H - 365.0, 120.0, 56.0)
	var reload_r := Rect2(W - 425.0, H - 210.0, 96.0, 46.0)
	var insp_r := Rect2(W - 318.0, H - 210.0, 96.0, 46.0)
	var auto_r := Rect2(W - 210.0, H - 210.0, 184.0, 46.0)

	if claw_r.has_point(pos) or fire_r.has_point(pos):
		_mobile_fire_held = pressed
		return true
	if jump_r.has_point(pos):
		_mobile_jump_held = pressed
		return true
	if pressed and ads_r.has_point(pos):
		if weapons.current_idx == 3:
			weapons.try_fire(0.0, true)
		else:
			weapons.want_ads = not weapons.want_ads
		return true
	if pressed and crouch_r.has_point(pos):
		_crouching = not _crouching
		return true
	if pressed and reload_r.has_point(pos):
		weapons.start_reload()
		return true
	if pressed and insp_r.has_point(pos):
		weapons.trigger_inspect()
		return true
	if pressed and auto_r.has_point(pos):
		_mobile_autofire = not _mobile_autofire
		_show_banner("AUTO-TIRO MOBILE: %s!" % ("LIGADO" if _mobile_autofire else "DESLIGADO"), 2.0)
		return true

	return false


func _input(event: InputEvent) -> void:
	if _shop_open:
		if event is InputEventKey and event.pressed and not event.echo:
			var k_s := (event as InputEventKey).keycode
			if k_s == KEY_ESCAPE or k_s == KEY_L:
				_toggle_shop(0)
		return

	# Multi-Touch Screen Touch (Mobile iOS / Android / Web Touch)
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if _killcam_active and st.pressed:
			_stop_killcam()
			return
		if _handle_hud_tap_or_click(st.position, st.pressed):
			return
		if st.pressed:
			if st.position.x < size.x * 0.44 and _joy_touch_idx < 0:
				_joy_touch_idx = st.index
				_joy_center = st.position
				_joy_knob = st.position
				_mobile_move_vec = Vector2.ZERO
			elif _look_touch_idx < 0:
				_look_touch_idx = st.index
		else:
			if st.index == _joy_touch_idx:
				_joy_touch_idx = -1
				_mobile_move_vec = Vector2.ZERO
			elif st.index == _look_touch_idx:
				_look_touch_idx = -1
			_mobile_fire_held = false
			_mobile_jump_held = false
		return

	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _joy_touch_idx:
			var delta_v := sd.position - _joy_center
			if delta_v.length() > _joy_radius:
				delta_v = delta_v.normalized() * _joy_radius
			_joy_knob = _joy_center + delta_v
			_mobile_move_vec = delta_v / _joy_radius
		else:
			var sens_m := 0.0022 if (is_instance_valid(weapons) and weapons.is_scoped_in()) else 0.0040
			_yaw -= sd.relative.x * sens_m
			_pitch = clampf(_pitch - sd.relative.y * sens_m * 0.88, -1.45, 1.45)
			if is_instance_valid(weapons):
				weapons.add_look_sway(sd.relative)
		return

	if event is InputEventMouseMotion:
		if not _paused:
			if _mobile_hud_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var mm_m := event as InputEventMouseMotion
				if _joy_touch_idx == 99:
					var dv := mm_m.position - _joy_center
					if dv.length() > _joy_radius:
						dv = dv.normalized() * _joy_radius
					_joy_knob = _joy_center + dv
					_mobile_move_vec = dv / _joy_radius
				else:
					_yaw -= mm_m.relative.x * 0.0035
					_pitch = clampf(_pitch - mm_m.relative.y * 0.0032, -1.45, 1.45)
				return
			if not _mobile_hud_enabled and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not DisplayServer.get_name().contains("headless"):
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				_mouse_captured = true
			if _startup_grace <= 0.0 and (_mouse_captured or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
				var mm := event as InputEventMouseMotion
				var sens := 0.0012 if (is_instance_valid(weapons) and weapons.is_scoped_in()) else (0.0018 if (is_instance_valid(weapons) and weapons.ads_alpha > 0.5) else 0.0026)
				_yaw -= mm.relative.x * sens
				_pitch = clampf(_pitch - mm.relative.y * sens, -1.45, 1.45)
				if is_instance_valid(weapons):
					weapons.add_look_sway(mm.relative)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not _mouse_captured or _mobile_hud_enabled:
				if _handle_hud_tap_or_click(mb.position, mb.pressed):
					return
				if _mobile_hud_enabled:
					if mb.pressed and mb.position.x < size.x * 0.42:
						_joy_touch_idx = 99
						_joy_center = mb.position
						_joy_knob = mb.position
					elif not mb.pressed:
						_joy_touch_idx = -1
						_mobile_move_vec = Vector2.ZERO
						_mobile_fire_held = false
						_mobile_jump_held = false
					return
		if mb.button_index == MOUSE_BUTTON_RIGHT and not _mobile_hud_enabled:
			if mb.pressed:
				if is_instance_valid(weapons) and weapons.current_idx == 3:
					weapons.try_fire(0.0, true)
				else:
					weapons.want_ads = true
			else:
				weapons.want_ads = false
			return
		if mb.pressed and not _mobile_hud_enabled:
			if _paused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				_capture_mouse()
				return
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				weapons.select_weapon(weapons.current_idx - 1)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				weapons.select_weapon(weapons.current_idx + 1)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if _killcam_active and k == KEY_SPACE:
			_stop_killcam()
			return
		match k:
			KEY_X:
				_trigger_instant_killcam()
			KEY_ESCAPE:
				_paused = not _paused
				if _paused:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					_mouse_captured = false
					_show_banner("MOUSE LIBERADO — Clique nas abas ou aperte ESC para voltar!", 4.0)
				else:
					_capture_mouse()
					_show_banner("", 0.0)
			KEY_L:
				_toggle_shop()
			KEY_1:
				weapons.select_weapon(0)
			KEY_2:
				weapons.select_weapon(1)
			KEY_3:
				weapons.select_weapon(2)
			KEY_4:
				weapons.select_weapon(3)
			KEY_5:
				var next_sk := (weapons.active_skin_idx + 1) % WeaponRig.WEAPON_SKINS.size()
				unlocked_weapon_skins[next_sk] = true
				weapons.apply_weapon_skin(next_sk)
				Sfx.play("cash_buy")
				_show_banner("SKIN DE ARMA 3D: %s!" % str(WeaponRig.WEAPON_SKINS[next_sk].name).to_upper(), 2.2)
			KEY_6:
				_buy_weapon_upgrade()
			KEY_7:
				var next_cs := (weapons.active_char_skin_idx + 1) % WeaponRig.CHAR_SKINS.size()
				unlocked_char_skins[next_cs] = true
				weapons.apply_char_skin(next_cs)
				Sfx.play("cash_buy")
				_show_banner("SKIN DE PERSONAGEM: %s!" % str(WeaponRig.CHAR_SKINS[next_cs].name).to_upper(), 2.2)
			KEY_Q:
				weapons.quick_switch()
			KEY_F:
				weapons.trigger_inspect()
			KEY_R:
				weapons.start_reload()
			KEY_M:
				var next_mode := SakuraWorld.MODE_PARKOUR if current_mode == SakuraWorld.MODE_COMBAT else SakuraWorld.MODE_COMBAT
				_select_mode_and_stage(next_mode, 0)
			KEY_TAB:
				_select_mode_and_stage(current_mode, (current_stage + 1) % 4)
			KEY_F1:
				_select_mode_and_stage(current_mode, 0)
			KEY_F2:
				_select_mode_and_stage(current_mode, 1)
			KEY_F3:
				_select_mode_and_stage(current_mode, 2)
			KEY_F4:
				_select_mode_and_stage(current_mode, 3)
			KEY_E:
				_save_kz_checkpoint()
			KEY_G:
				_teleport_kz_checkpoint()
			KEY_P:
				Sfx.set_panadero_radio(not Sfx.panadero_mode)
				_show_banner("RADIO EL PANADERO CON EL PAN: %s!" % ("LIGADA" if Sfx.panadero_mode else "DESLIGADA"), 2.5)
			KEY_B, KEY_K:
				_reset_current_mode()
			KEY_V, KEY_T:
				_toggle_mobile_hud()
			KEY_F5, KEY_O:
				_cycle_graphics_preset()
			KEY_F6, KEY_U:
				_cycle_atmosphere_preset()


func _cycle_graphics_preset() -> void:
	_res_idx = (_res_idx + 1) % RES_PRESETS.size()
	_apply_graphics_preset()
	_show_banner("MODO GRAFICO [O / F5]: %s" % RES_PRESETS[_res_idx].label, 2.5)


func _cycle_atmosphere_preset() -> void:
	var atmo_name := world.cycle_atmosphere_preset()
	_show_banner("ILUMINACAO & CLIMA [U / F6]: %s" % atmo_name, 2.5)


func _toggle_mobile_hud() -> void:
	_mobile_hud_enabled = not _mobile_hud_enabled
	_joy_touch_idx = -1
	_mobile_move_vec = Vector2.ZERO
	_mobile_fire_held = false
	_mobile_jump_held = false
	if _mobile_hud_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
		_show_banner("MODO MOBILE-FIRST (iOS / Play Store Touch + Aim Assist) ATIVADO!", 2.6)
	else:
		_capture_mouse()
		_show_banner("MODO PC DESKTOP (Mouse + Teclado) ATIVADO!", 2.2)


func _select_stage(stage_idx: int) -> void:
	_select_mode_and_stage(current_mode, stage_idx)


func _select_mode_and_stage(mode_idx: int, stage_idx: int) -> void:
	current_mode = clampi(mode_idx, 0, 1)
	current_stage = clampi(stage_idx, 0, 3)
	var sp := world.load_mode_and_stage(current_mode, current_stage)
	var st_def: Dictionary = world.get_active_stage_def()

	_body.global_position = sp[0]
	_body.velocity = Vector3.ZERO
	_yaw = float(sp[1])
	_pitch = float(sp[2])
	_has_saved_cp = false

	if current_mode == SakuraWorld.MODE_COMBAT:
		server_mode = ServerMode.FY_ICEWORLD_PVP
		world.enemies_paused = false
		Sfx.set_panadero_radio(false)
		weapons.select_weapon(0)
		weapons.refill_all_ammo()
		hp = max_hp
		armor = 100.0
	else:
		server_mode = ServerMode.KZ_BHOP_SURF
		world.enemies_paused = false # Keep false so the 7 Parkour Runner Bots run!
		weapons.select_weapon(3) # Equip Karambit (+18% Parkour Speed)
		Sfx.set_panadero_radio(true)
		hp = max_hp
		armor = 100.0

	_show_banner("%s  //  %s" % [str(st_def.title), str(st_def.subtitle)], 4.0)


func _save_kz_checkpoint() -> void:
	if not _body.is_on_floor():
		_show_banner("Voce precisa estar no chao para salvar um Checkpoint!", 2.0)
		return
	_saved_cp_pos = _body.global_position
	_saved_cp_yaw = _yaw
	_has_saved_cp = true
	_cp_count += 1
	Sfx.play("ring_pass", 1.1)
	_show_banner("CHECKPOINT #%d SALVO! (Aperte [G] para voltar aqui)" % _cp_count, 2.2)


func _teleport_kz_checkpoint() -> void:
	if _has_saved_cp:
		_body.global_position = _saved_cp_pos
		_body.velocity = Vector3.ZERO
		_yaw = _saved_cp_yaw
		Sfx.play("pickup", 1.15)
		_show_banner("TELEPORTADO AO CHECKPOINT #%d!" % _cp_count, 1.8)
	elif current_mode == SakuraWorld.MODE_PARKOUR:
		_respawn_kz_stage()


func _respawn_kz_stage() -> void:
	if _has_saved_cp:
		_body.global_position = _saved_cp_pos + Vector3(0, 0.3, 0)
		_body.velocity = Vector3.ZERO
		_yaw = _saved_cp_yaw
		return
	_body.global_position = world.kz_start_pad
	_body.velocity = Vector3.ZERO
	_yaw = 0.0


func _reset_current_mode() -> void:
	_select_mode_and_stage(current_mode, current_stage)


# ---------------------------------------------------------------- Physics, ParkourCountdown Gate, & Mobile Aim-Assist

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return

	if _startup_grace > 0.0:
		_startup_grace -= delta
	if _jump_grace > 0.0:
		_jump_grace -= delta
	if _adrenaline_t > 0.0:
		_adrenaline_t -= delta

	# Phantom Forces Auto-Health Regeneration after 2.8s out of combat!
	_out_of_combat_t += delta
	if _out_of_combat_t >= 2.8 and hp < max_hp:
		hp = minf(max_hp, hp + 26.0 * delta)

	if _killcam_active:
		_tick_killcam(delta)
		_update_hud(delta, 0.0)
		return

	if _body.is_on_floor():
		var mp_delta := world.get_moving_platform_delta(_body.global_position)
		if mp_delta.length_squared() > 0.000001:
			_body.global_position += mp_delta

	if _body.global_position.y < -3.8:
		if current_mode == SakuraWorld.MODE_PARKOUR:
			_respawn_kz_stage()
		else:
			var sp := world.spawn_pvp_transform()
			_body.global_position = sp[0]
			_body.velocity = Vector3.ZERO

	# Optional Arrow-key camera look
	var look_h := (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)
	var look_v := (1.0 if Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_UP) else 0.0)
	if absf(look_h) > 0.01 or absf(look_v) > 0.01:
		_yaw -= look_h * 2.2 * delta
		_pitch = clampf(_pitch - look_v * 1.6 * delta, -1.45, 1.45)

	# Movement inputs (Keyboard + Mobile 360° Virtual Analog Stick)
	var in_x := (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0) + _mobile_move_vec.x
	var in_z := (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0) + _mobile_move_vec.y
	var input_vec := Vector2(in_x, in_z)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var basis_yaw := Basis(Vector3.UP, _yaw)
	var wish_dir := (basis_yaw * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()

	var want_crouch := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C)
	if not _mobile_hud_enabled:
		_crouching = want_crouch

	var joy_sprint := _mobile_move_vec.length() > 0.72 and _mobile_move_vec.y < -0.25
	_sprinting = (Input.is_key_pressed(KEY_SHIFT) or joy_sprint or current_mode == SakuraWorld.MODE_PARKOUR) and in_z < -0.1 and not _crouching and weapons.ads_alpha < 0.1
	var jump_held := Input.is_key_pressed(KEY_SPACE) or _mobile_jump_held
	if jump_held:
		_jump_buffer = 0.11
	elif _jump_buffer > 0.0:
		_jump_buffer -= delta

	# Check Bouncy Awnings & Lily-Leaper Drums!
	if _jump_grace <= 0.0 and world.check_bouncy_awning(_body.global_position):
		_body.velocity.y = 13.0
		_jump_grace = 0.24
		Sfx.play("jumppad", 1.15)
		_show_banner("TAMBOR ELASTICO LILY LEAPER!", 1.4)

	# Check Jump-Pads
	for jp in world.kz_jumppads:
		if _body.global_position.distance_to(jp) < 1.55 and _jump_grace <= 0.0:
			_body.velocity.y = 14.8
			_jump_grace = 0.26
			Sfx.play("jumppad")
			_show_banner("SUPER JUMP-PAD TATICO!", 1.5)

	# Check Fall Guys Interactive Obstacles
	var haz := world.compute_parkour_hazard_impulse(_body.global_position)
	if not haz.is_empty():
		var h_vel: Vector3 = haz.vel
		_body.velocity = h_vel
		_jump_grace = 0.28
		Sfx.play("jumppad", 0.92)
		_show_banner(str(haz.banner), 1.6)

	_on_ladder = false
	for lad in world.kz_ladders:
		if (lad as AABB).has_point(_body.global_position + Vector3(0, 0.9, 0)):
			_on_ladder = true
			break

	_surfing = false
	var surf_data := {}
	if not _body.is_on_floor() and _jump_grace <= 0.0:
		for sr in world.surf_ramps:
			if (sr.aabb as AABB).has_point(_body.global_position):
				_surfing = true
				surf_data = sr
				break

	if _on_ladder:
		var climb_v := -in_z * 6.5
		_body.velocity.y = climb_v
		_body.velocity.x = wish_dir.x * 3.8
		_body.velocity.z = wish_dir.z * 3.8
		if jump_held:
			_body.velocity = (basis_yaw * Vector3(0, 0.65, 1.0)).normalized() * 7.5
			_jump_grace = 0.20
			Sfx.play("jump")
		_body.move_and_slide()
	elif _surfing:
		var c: Vector3 = surf_data.center
		var side := -1.0 if _body.global_position.x < c.x else 1.0
		var pressing_into_ramp := (side < 0.0 and in_x > 0.05) or (side > 0.0 and in_x < -0.05) or in_z < -0.05
		var fwd_z := -basis_yaw.z
		if pressing_into_ramp:
			var cur_spd := maxf(8.8, Vector2(_body.velocity.x, _body.velocity.z).length())
			cur_spd = minf(cur_spd + 3.8 * delta, 12.6)
			_body.velocity.x = move_toward(_body.velocity.x, (c.x + side * 1.45 - _body.global_position.x) * 4.5, delta * 36.0)
			_body.velocity.z = move_toward(_body.velocity.z, fwd_z.z * cur_spd, delta * 32.0)
			_body.velocity.y = move_toward(_body.velocity.y, sin(_pitch) * 6.0 - 0.8, delta * 28.0)
		else:
			_body.velocity.y -= GRAVITY * delta
		_body.move_and_slide()
	else:
		_process_crisp_ground_and_parkour(delta, wish_dir, jump_held)

	# Keep player behind Starting Gate during 5-4-3-2-1 Parkour Race Countdown!
	if current_mode == SakuraWorld.MODE_PARKOUR and world.race_countdown > 0.0:
		if _body.global_position.z < 14.1:
			_body.global_position.z = 14.1
			if _body.velocity.z < 0.0:
				_body.velocity.z = 0.0

	# Mobile-First Aim-Assist Magnetism + Optional Auto-Fire when in Combat Mode!
	var auto_trigger_target := false
	if current_mode == SakuraWorld.MODE_COMBAT and _mobile_aim_assist:
		auto_trigger_target = _apply_mobile_aim_assist(delta)

	var target_eye := EYE_CROUCH if _crouching else EYE_STAND
	_eye_y = lerpf(_eye_y, target_eye, minf(1.0, delta * 16.0))
	_cam_pivot.position.y = _eye_y

	var target_roll := -input_vec.x * 0.015 + (0.05 if _surfing else 0.0)
	_cam_roll = lerpf(_cam_roll, target_roll, minf(1.0, delta * 14.0))
	_body.rotation.y = _yaw
	_cam_pivot.rotation = Vector3(_pitch, 0.0, _cam_roll)

	var w_def: Dictionary = WeaponRig.WEAPONS[weapons.current_idx]
	var target_fov := lerpf(76.0, float(w_def.ads_fov), weapons.ads_alpha)
	if _sprinting and _body.is_on_floor():
		target_fov = 82.0
	_cam.fov = lerpf(_cam.fov, target_fov, minf(1.0, delta * 14.0))

	var h_speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	world.player_pos = _body.global_position
	weapons.tick_viewmodel(delta, h_speed, _body.is_on_floor(), _sprinting, _crouching)

	var want_fire := not _shop_open and not _paused and (
		(_mouse_captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		or _mobile_fire_held
		or (_mobile_hud_enabled and _mobile_autofire and auto_trigger_target)
	)
	if want_fire:
		if bool(w_def.auto) or not bool(_body.get_meta("fire_was", false)) or (_mobile_hud_enabled and _mobile_autofire):
			if weapons.try_fire(h_speed):
				_crosshair_spread = minf(1.0, _crosshair_spread + (0.14 if weapons.ads_alpha > 0.5 else 0.28))
	_body.set_meta("fire_was", want_fire)

	_update_hud(delta, h_speed)


func _apply_mobile_aim_assist(delta: float) -> bool:
	if not is_instance_valid(_cam) or world.enemies.is_empty():
		return false
	var cam_pos := _cam.global_position
	var cam_fwd := -_cam.global_transform.basis.z
	var best_dot := 0.965
	var best_aim_dir := Vector3.ZERO
	var on_target := false

	for b in world.enemies:
		if not is_instance_valid(b):
			continue
		var chest_p := b.global_position + Vector3(0.0, 1.32, 0.0)
		var to_b := chest_p - cam_pos
		var d := to_b.length()
		if d < 0.8 or d > 48.0:
			continue
		var dir_b := to_b / d
		var dot := cam_fwd.dot(dir_b)
		if dot > best_dot:
			var space := world.get_world_3d().direct_space_state
			var q := PhysicsRayQueryParameters3D.create(cam_pos, chest_p, 1)
			if space.intersect_ray(q).is_empty():
				best_dot = dot
				best_aim_dir = dir_b
				if dot > 0.992:
					on_target = true

	if best_aim_dir.length_squared() > 0.1 and (_mobile_hud_enabled or _mobile_fire_held or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		var desired_yaw := atan2(-best_aim_dir.x, -best_aim_dir.z)
		var desired_pitch := asin(clampf(best_aim_dir.y, -0.95, 0.95))
		var pull := 3.6 if _mobile_hud_enabled else 1.4
		_yaw = lerp_angle(_yaw, desired_yaw, minf(1.0, delta * pull))
		_pitch = lerpf(_pitch, desired_pitch, minf(1.0, delta * pull))

	return on_target


func _process_crisp_ground_and_parkour(delta: float, wish_dir: Vector3, jump_held: bool) -> void:
	var on_floor := _body.is_on_floor()
	if on_floor:
		_coyote_timer = 0.12
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

	var w_mult := weapons.speed_multiplier() + (0.12 if _adrenaline_t > 0.0 else 0.0)
	var max_ground_spd := (CROUCH_SPEED if _crouching else (SPRINT_SPEED if _sprinting else WALK_SPEED)) * w_mult

	if (jump_held or _jump_buffer > 0.0) and _coyote_timer > 0.0 and _jump_grace <= 0.0:
		_body.velocity.y = JUMP_VEL
		_coyote_timer = 0.0
		_jump_buffer = 0.0
		_jump_grace = 0.14
		if on_floor and wish_dir.length() > 0.1:
			_bhop_chain = mini(_bhop_chain + 1, 6)
			var boost := minf(max_ground_spd * (1.0 + _bhop_chain * 0.025), 8.2)
			_body.velocity.x = wish_dir.x * boost
			_body.velocity.z = wish_dir.z * boost
		else:
			_bhop_chain = 0
		Sfx.play("jump", 1.0 + _bhop_chain * 0.02, -6.0)
	elif on_floor:
		_bhop_chain = 0
		var conv_v := world.get_conveyor_velocity(_body.global_position)
		if wish_dir.length() > 0.05:
			var target_v := wish_dir * max_ground_spd + conv_v
			_body.velocity.x = move_toward(_body.velocity.x, target_v.x, GROUND_ACCEL * delta)
			_body.velocity.z = move_toward(_body.velocity.z, target_v.z, GROUND_ACCEL * delta)
		else:
			_body.velocity.x = move_toward(_body.velocity.x, conv_v.x, GROUND_BRAKE * delta)
			_body.velocity.z = move_toward(_body.velocity.z, conv_v.z, GROUND_BRAKE * delta)
	else:
		_body.velocity.y -= GRAVITY * delta
		if wish_dir.length() > 0.05:
			var air_target := wish_dir * maxf(max_ground_spd, Vector2(_body.velocity.x, _body.velocity.z).length())
			_body.velocity.x = move_toward(_body.velocity.x, air_target.x, AIR_ACCEL * delta)
			_body.velocity.z = move_toward(_body.velocity.z, air_target.z, AIR_ACCEL * delta)
		else:
			_body.velocity.x = move_toward(_body.velocity.x, 0.0, AIR_BRAKE * delta)
			_body.velocity.z = move_toward(_body.velocity.z, 0.0, AIR_BRAKE * delta)

	_body.move_and_slide()


# ---------------------------------------------------------------- Phantom Forces Combat Dopamine, Progression & Callbacks

func _push_pf_score_popup(txt: String, col: Color = Color("ffd166"), fsize: int = 15) -> void:
	_pf_score_stack.push_front({"text": txt, "col": col, "size": fsize, "life": 2.1})
	if _pf_score_stack.size() > 5:
		_pf_score_stack.resize(5)


func _award_progression(add_coins: int, add_rp: int, reason: String = "") -> void:
	coins += add_coins
	rp += add_rp
	var new_rank := 0
	for i in RANK_TIERS.size():
		if rp >= int(RANK_TIERS[i].min_rp):
			new_rank = i
	if new_rank > rank_idx:
		rank_idx = new_rank
		gems += 20
		Sfx.play("rank_up")
		var rname := str(RANK_TIERS[rank_idx].name)
		_show_banner("PROMOCAO DE PATENTE RANQUEADA: %s! (+20 DIAMANTES)" % rname, 3.5)
	elif not reason.is_empty():
		_show_banner("%s  (+%d MOEDAS  +%d RP)" % [reason, add_coins, add_rp], 2.2)


func _on_weapon_changed(_idx: int, _wname: String, cur_ammo: int, cur_res: int) -> void:
	_on_ammo_updated(cur_ammo, cur_res, false)


func _on_ammo_updated(cur_ammo: int, cur_res: int, reloading: bool) -> void:
	_cur_ammo_cached = cur_ammo
	_cur_res_cached = cur_res
	_reloading_cached = reloading
	if is_instance_valid(_hud):
		_hud.queue_redraw()


func _on_shot_fired(_weapon_idx: int, kick_pitch: float, kick_yaw: float) -> void:
	_pitch = clampf(_pitch + kick_pitch, -1.45, 1.45)
	_yaw += kick_yaw


func _on_hit_registered(result: Dictionary, _weapon_idx: int) -> void:
	_hitmarker_timer = 0.18
	_hitmarker_crit = bool(result.get("headshot", false)) or bool(result.get("killed", false))


func _on_enemy_killed(was_headshot: bool, bot_name: String, hit_pos: Vector3) -> void:
	kills += 1
	streak += 1
	world.ct_score = kills
	if was_headshot:
		headshots += 1

	# PHANTOM FORCES KILL SIPHON: Instant Heal + Armor + Ammo in Mag + Adrenaline Speed!
	hp = minf(max_hp, hp + 35.0)
	armor = minf(100.0, armor + 25.0)
	_adrenaline_t = 2.6
	weapons.grant_kill_ammo_siphon(8)
	Sfx.play("cash_buy", minf(1.45, 1.0 + streak * 0.06))

	var w_full := str(WeaponRig.WEAPONS[weapons.current_idx].name)
	var w_name := w_full.split(" ")[0]
	var hs_icon := " [HS]" if was_headshot else ""
	var my_tag := str(DOGTAGS[active_dogtag_idx].name)
	var my_icon := str(PROFILE_ICONS[active_icon_idx].icon)
	var sk_dict: Dictionary = WeaponRig.WEAPON_SKINS[weapons.active_skin_idx]
	var sk_name := str(sk_dict.name)
	var w_lvl := int(weapons.weapon_levels[weapons.current_idx])

	var shooter_eye := _cam.global_position if is_instance_valid(_cam) else (_body.global_position + Vector3(0, 1.5, 0))
	var dist_m := shooter_eye.distance_to(hit_pos)
	_last_kill_data = {
		"shooter_pos": shooter_eye,
		"hit_pos": hit_pos,
		"foot_pos": Vector3(hit_pos.x, 0.0, hit_pos.z),
		"was_headshot": was_headshot,
		"bot_name": bot_name,
		"weapon_name": w_full,
		"skin_name": sk_name,
		"weapon_lvl": w_lvl,
		"tracer_col": sk_dict.tracer if weapons.active_skin_idx > 0 else Color("ffd166"),
		"dmg": 140 if was_headshot else 58,
		"dist_m": dist_m,
		"killer_icon": my_icon,
		"killer_tag": my_tag,
		"killer_rank": str(RANK_TIERS[rank_idx].name)
	}

	_push_killfeed("VOCE [%s] // %s%s // %s" % [my_tag, w_name, hs_icon, bot_name])

	# Stacked Phantom Forces Score Popups!
	_push_pf_score_popup("+100  ABATE CONFIRMADO  [%s]" % bot_name, Color("fff8ea"), 15)
	if was_headshot:
		_push_pf_score_popup("+50   1-TAP HEADSHOT FATAL!", Color("ff2a55"), 16)
	if dist_m >= 24.0:
		_push_pf_score_popup("+35   TIRO DE LONGA DISTANCIA (%.0fm)!" % dist_m, Color("00f5d4"), 14)
	elif dist_m <= 5.5:
		_push_pf_score_popup("+25   QUEIMA-ROUPA CQC!", Color("ffd166"), 14)
	if not _body.is_on_floor():
		_push_pf_score_popup("+40   ABATE NO AR (MID-AIR)!", Color("00f5d4"), 15)
	if streak >= 2:
		var st_names := ["", "", "DOUBLE KILL!", "TRIPLE KILL!", "QUAD FEED!", "RAMPAGE x5!", "PHANTOM GODLIKE!"]
		var st_lbl: String = st_names[mini(streak, st_names.size() - 1)]
		_push_pf_score_popup("+%d   %s (STREAK x%d)" % [streak * 35, st_lbl, streak], Color("ffd166"), 17)

	# Check if Player just climbed to #1 Leader on the Match Scoreboard!
	var c_rows := world.get_combat_standings(kills, deaths)
	var is_now_leader := (not c_rows.is_empty() and bool(c_rows[0].is_player))
	if is_now_leader and not _was_leader and kills >= 2:
		_push_pf_score_popup("ASSUMIU O #1 LUGAR DO PLACAR!", Color("ffd166"), 18)
	_was_leader = is_now_leader

	var c_gain := (125 if was_headshot else 70) + streak * 18
	var rp_gain := (55 if was_headshot else 30) + streak * 6
	_award_progression(c_gain, rp_gain, ("1-TAP HEADSHOT EM %s (STREAK x%d)" % [bot_name.to_upper(), streak]) if was_headshot else ("ELIMINOU %s (STREAK x%d)" % [bot_name.to_upper(), streak]))


func _on_bot_frag_feed(killer_name: String, victim_name: String, weapon_tag: String) -> void:
	_push_killfeed("%s // %s // %s" % [killer_name, weapon_tag, victim_name])


func _on_runner_crossed_finish(bot_name: String, place: int, f_time: float) -> void:
	_push_killfeed("%dº LUGAR: %s (%.1fs)" % [place, bot_name, f_time])
	if world.player_race_place == 0:
		_show_banner("ALERTA DE CORRIDA: %s CHEGOU EM %dº LUGAR (%.1fs)! ACELERE!" % [bot_name, place, f_time], 2.8)


func _on_round_won(round_num: int, ct_sc: int, tr_sc: int) -> void:
	hp = max_hp
	armor = 100.0
	weapons.refill_all_ammo()
	_award_progression(250, 100, "VITORIA NA RODADA %d  //  CT %d x %d TR" % [round_num, ct_sc, tr_sc])


func _on_kz_ring_collected(_ring_idx: int) -> void:
	_push_pf_score_popup("+85 MOEDAS // ANEL TURBO PARKOUR!", Color("00f5d4"), 15)
	_award_progression(85, 35, "ANEL DOURADO DE PARKOUR COLETADO")


func _on_kz_stage_reached(stage_idx: int, stage_name: String, ctime: float, cp_pos: Vector3) -> void:
	_saved_cp_pos = cp_pos
	_saved_cp_yaw = 0.0
	_has_saved_cp = true
	_cp_count = stage_idx
	_award_progression(180, 75, "CHECKPOINT SALVO: %s (%.1fs)" % [stage_name, ctime])


func _on_kz_course_finished(ctime: float, best_t: float, place: int) -> void:
	var coin_reward := 2500 if place == 1 else (1400 if place == 2 else (900 if place == 3 else 500))
	var gem_reward := 50 if place == 1 else (30 if place <= 3 else 15)
	gems += gem_reward
	var place_tag := "1º LUGAR CAMPEAO FALL GUYS!" if place == 1 else ("%dº LUGAR NA CORRIDA!" % place)
	_push_pf_score_popup("%s (+%d MOEDAS / +%d DIAMANTES)" % [place_tag, coin_reward, gem_reward], Color("ffd166"), 18)
	_award_progression(coin_reward, 350, "%s // TEMPO %.2fs (Recorde: %.2fs) // [K] Nova Corrida" % [place_tag, ctime, best_t])


func _on_player_damaged(amount: float, _from_pos: Vector3, attacker_name: String) -> void:
	if current_mode == SakuraWorld.MODE_PARKOUR:
		return # Zero PvP shooting damage in Parkour Mode!
	_out_of_combat_t = 0.0
	var absorbed := minf(armor, amount * 0.55)
	armor = maxf(0.0, armor - absorbed)
	hp = maxf(0.0, hp - (amount - absorbed))
	_damage_alpha = 0.36
	Sfx.play("hurt")
	if hp <= 0.0:
		deaths += 1
		streak = 0
		world.tr_score += 1
		if world.bot_scoreboard.has(attacker_name):
			world.bot_scoreboard[attacker_name]["kills"] = int(world.bot_scoreboard[attacker_name]["kills"]) + 1
			world.bot_scoreboard[attacker_name]["pts"] = int(world.bot_scoreboard[attacker_name]["kills"]) * 100
		hp = max_hp
		armor = 100.0
		weapons.refill_all_ammo()
		var sp := world.spawn_pvp_transform()
		_body.global_position = sp[0]
		_body.velocity = Vector3.ZERO
		_push_killfeed("%s  //  AK-47  //  VOCE" % attacker_name)
		_show_banner("ELIMINADO POR %s — RESPAWN IMEDIATO (VINGANCA ATIVA!)" % attacker_name, 2.4)


# ---------------------------------------------------------------- Call of Duty: Black Ops 2 KillCam Replay Engine

func _trigger_instant_killcam() -> void:
	if _killcam_active:
		_stop_killcam()
		return
	if _last_kill_data.is_empty():
		var fake_target := Vector3(0.0, 1.5, -2.5)
		if not world.enemies.is_empty() and is_instance_valid(world.enemies[0]):
			fake_target = world.enemies[0].global_position + Vector3(0, 1.5, 0)
		var sk_dict: Dictionary = WeaponRig.WEAPON_SKINS[weapons.active_skin_idx]
		_last_kill_data = {
			"shooter_pos": _cam.global_position,
			"hit_pos": fake_target,
			"foot_pos": Vector3(fake_target.x, 0.0, fake_target.z),
			"was_headshot": true,
			"bot_name": "Bot_S1mple",
			"weapon_name": str(WeaponRig.WEAPONS[weapons.current_idx].name),
			"skin_name": str(sk_dict.name),
			"weapon_lvl": int(weapons.weapon_levels[weapons.current_idx]),
			"tracer_col": sk_dict.tracer if weapons.active_skin_idx > 0 else Color("ffd166"),
			"dmg": 144,
			"dist_m": _cam.global_position.distance_to(fake_target),
			"killer_icon": str(PROFILE_ICONS[active_icon_idx].icon),
			"killer_tag": str(DOGTAGS[active_dogtag_idx].name),
			"killer_rank": str(RANK_TIERS[rank_idx].name)
		}
	_start_killcam("FINAL", _last_kill_data)


func _start_killcam(mode: String, data: Dictionary) -> void:
	_cleanup_killcam_actors()
	_killcam_active = true
	_killcam_mode = mode
	_killcam_data = data.duplicate()
	_killcam_timer = 0.0
	_killcam_dur = 2.45
	_killcam_impact_played = false

	Sfx.play("killcam")

	var shooter_p: Vector3 = data.get("shooter_pos", Vector3(0, 1.6, 12.0))
	var hit_p: Vector3 = data.get("hit_pos", Vector3(0, 1.5, 0.0))
	var foot_p: Vector3 = data.get("foot_pos", Vector3(hit_p.x, 0.0, hit_p.z))
	var t_col: Color = data.get("tracer_col", Color("ffd166"))

	_killcam_dummy = world.spawn_killcam_dummy(foot_p, shooter_p)

	_killcam_bullet = Node3D.new()
	_killcam_bullet.position = shooter_p
	world.add_child(_killcam_bullet)
	world.ball(_killcam_bullet, Vector3.ZERO, 0.11, t_col, 8, 3.0)
	world.ball(_killcam_bullet, Vector3(0, 0, 0.22), 0.06, Color("ffffff"), 6, 3.5)
	world.spawn_tracer(shooter_p, hit_p, t_col, 0.032)

	_killcam_card.visible = true
	if is_instance_valid(_banner_label):
		_banner_label.visible = false
	_kc_header_lbl.text = "REC  //  CAMERA DO ABATE FINAL (CALL OF DUTY KILLCAM)  //  REPLAY 0.35x SLOW-MO"
	_kc_header_lbl.add_theme_color_override("font_color", Color("e85d4a"))
	_kc_title_lbl.text = "VOCE [%s]   ELIMINOU   %s   //   %s" % [
		str(data.get("killer_tag", "1-TAP GOD")),
		str(data.get("bot_name", "Bot_S1mple")),
		str(data.get("killer_rank", "OURO BO2"))
	]

	var hs_txt := "1-TAP HEADSHOT FATAL" if bool(data.get("was_headshot", true)) else "ABATE CONFIRMADO"
	_kc_sub_lbl.text = "%s  |  Skin: %s [Nv.%d]  |  %s (%d Dano / %.1fm)  |  [ESPACO / TOQUE] Pular" % [
		str(data.get("weapon_name", "AK-47")),
		str(data.get("skin_name", "Ouro BO2")),
		int(data.get("weapon_lvl", 2)),
		hs_txt,
		int(data.get("dmg", 144)),
		float(data.get("dist_m", 12.0))
	]

	_cam.current = false
	_killcam.current = true
	_tick_killcam(0.01)


func _tick_killcam(delta: float) -> void:
	_killcam_timer += delta
	var shooter_p: Vector3 = _killcam_data.get("shooter_pos", Vector3(0, 1.6, 12.0))
	var hit_p: Vector3 = _killcam_data.get("hit_pos", Vector3(0, 1.5, 0.0))
	var dir := (hit_p - shooter_p).normalized()
	if dir.length() < 0.01:
		dir = Vector3.FORWARD
	var right := dir.cross(Vector3.UP).normalized()
	if right.length() < 0.01:
		right = Vector3.RIGHT

	var flight_dur := 1.05
	if _killcam_timer <= flight_dur:
		var u := clampf(_killcam_timer / flight_dur, 0.0, 1.0)
		var b_pos := shooter_p.lerp(hit_p, u)
		if is_instance_valid(_killcam_bullet):
			_killcam_bullet.global_position = b_pos
		var cam_offset := -dir * 2.1 + right * 0.55 + Vector3(0, 0.38, 0)
		_killcam.global_position = b_pos + cam_offset
		_killcam.look_at_from_position(_killcam.global_position, hit_p, Vector3.UP)
	else:
		if not _killcam_impact_played:
			_killcam_impact_played = true
			if is_instance_valid(_killcam_bullet):
				_killcam_bullet.visible = false
			Sfx.play("headshot", 0.74)
			world.spawn_voxel_burst(hit_p, Color("ff2a4b"), 14)
			world.spawn_damage_number(hit_p, int(_killcam_data.get("dmg", 144)), bool(_killcam_data.get("was_headshot", true)))

		var post_u := clampf((_killcam_timer - flight_dur) / (_killcam_dur - flight_dur), 0.0, 1.0)
		if is_instance_valid(_killcam_dummy):
			_killcam_dummy.rotation.x = lerpf(0.0, -1.35, minf(1.0, post_u * 1.45))
		var orbit_ang := post_u * 0.85
		var orbit_dir := (-dir).rotated(Vector3.UP, orbit_ang)
		var cam_pos := hit_p + orbit_dir * 2.65 + Vector3(0, 0.55, 0)
		_killcam.global_position = cam_pos
		_killcam.look_at_from_position(cam_pos, hit_p - Vector3(0, 0.25, 0), Vector3.UP)

	if _killcam_timer >= _killcam_dur:
		_stop_killcam()


func _stop_killcam() -> void:
	_killcam_active = false
	if is_instance_valid(_killcam_card):
		_killcam_card.visible = false
	if is_instance_valid(_banner_label):
		_banner_label.visible = true
	_cleanup_killcam_actors()
	if is_instance_valid(_killcam):
		_killcam.current = false
	if is_instance_valid(_cam):
		_cam.current = true


func _cleanup_killcam_actors() -> void:
	if is_instance_valid(_killcam_dummy):
		_killcam_dummy.queue_free()
		_killcam_dummy = null
	if is_instance_valid(_killcam_bullet):
		_killcam_bullet.queue_free()
		_killcam_bullet = null


func _on_pickup_collected(_kind: String, amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	armor = 100.0
	weapons.refill_all_ammo()
	_push_pf_score_popup("+40 HP // +COLETE & MUNICAO!", Color("2ec4b6"), 14)


func _push_killfeed(line: String) -> void:
	killfeed.push_front({"text": line, "life": 6.0})
	if killfeed.size() > 4:
		killfeed.resize(4)


func _show_banner(txt: String, dur: float = 3.0) -> void:
	if is_instance_valid(_banner_label):
		_banner_label.text = txt
		_banner_timer = dur


func _update_hud(delta: float, h_speed: float) -> void:
	_hud_anim_t += delta
	_h_speed_cached = h_speed
	_hp_lag = move_toward(_hp_lag, hp, delta * 35.0)

	var move_sp := clampf(h_speed / 6.0, 0.0, 0.55)
	if not _body.is_on_floor():
		move_sp += 0.35
	_crosshair_spread = move_toward(_crosshair_spread, move_sp, delta * 3.0)

	if _hitmarker_timer > 0.0:
		_hitmarker_timer -= delta
	if _damage_alpha > 0.0:
		_damage_alpha = move_toward(_damage_alpha, 0.0, delta * 1.5)
		_damage_flash.color = Color(0.9, 0.12, 0.18, _damage_alpha)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner_label.text = ""

	for i in range(killfeed.size() - 1, -1, -1):
		killfeed[i].life -= delta
		if float(killfeed[i].life) <= 0.0:
			killfeed.remove_at(i)

	for i in range(_pf_score_stack.size() - 1, -1, -1):
		_pf_score_stack[i].life -= delta
		if float(_pf_score_stack[i].life) <= 0.0:
			_pf_score_stack.remove_at(i)

	_hud.queue_redraw()


# ---------------------------------------------------------------- Automated Tests & QA Screenshots

func _run_automated_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_startup_grace = 0.0

	# 1. Verify Combat Mode (4 Arenas) & Phantom Forces Kill Satisfaction
	_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 0)
	await get_tree().process_frame
	assert(world.enemies.size() == 6, "Combat Mode should spawn 6 active operators")
	var coins0 := coins
	var b0 := world.enemies[0]
	var head_pos := b0.global_position + Vector3(0, 1.55, 0)
	var res := b0.apply_hit(42.0, head_pos, Vector3.ZERO, 3.2)
	assert(bool(res.headshot) and bool(res.killed), "AK-47 headshot must be an instant 1-tap fatal kill!")
	assert(coins > coins0, "Killing an enemy must award coins and Phantom Forces score stack!")

	for st_i in 4:
		_select_mode_and_stage(SakuraWorld.MODE_COMBAT, st_i)
		assert(current_mode == SakuraWorld.MODE_COMBAT and current_stage == st_i, "Must switch to Combat Arena %d" % st_i)

	# 2. Verify Parkour Race Mode (4 Long 8-Sector Marathons + 7 Runner Bots + Zero PvP Damage!)
	for pk_i in 4:
		_select_mode_and_stage(SakuraWorld.MODE_PARKOUR, pk_i)
		await get_tree().process_frame
		assert(current_mode == SakuraWorld.MODE_PARKOUR and current_stage == pk_i, "Must switch to Parkour Marathon %d" % pk_i)
		assert(world.parkour_runners.size() == 7, "Parkour Race must spawn 7 competing Runner Bots")
		assert(world.kz_checkpoints.size() == 8, "Each Parkour Marathon must have 8 Sectors")
		var total_len := world.kz_start_pad.z - world.kz_finish_pad.z
		assert(total_len >= 310.0, "Parkour Marathon must be over 310m long (got %.1fm)" % total_len)

	# 3. Verify Mobile-First Touch HUD Toggle
	_toggle_mobile_hud()
	assert(_mobile_hud_enabled, "Mobile Touch HUD should toggle on")
	_toggle_mobile_hud()

	print("2 GAME MODES (4 COMBAT ARENAS + 4 350m PARKOUR MARATHONS) + 7 RUNNER BOTS + MOBILE-FIRST HUD automated test PASSED!")
	get_tree().quit(0)


func _run_screenshot_suite() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))

	# Shot 1: Combat Mode Arena 2 (Shipment & Killhouse CQC) + Gold AK-47 + Phantom Forces Score Stack & Live Leaderboard!
	_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 1)
	for i in 4:
		await get_tree().process_frame
	_body.global_position = Vector3(-1.5, 0.2, 13.5)
	_yaw = -0.10
	_pitch = -0.02
	weapons.select_weapon(0, true)
	weapons.apply_weapon_skin(1)
	kills = 12
	headshots = 8
	streak = 4
	_push_pf_score_popup("+100  ABATE CONFIRMADO  [Bot_S1mple]", Color("fff8ea"), 15)
	_push_pf_score_popup("+50   1-TAP HEADSHOT FATAL!", Color("ff2a55"), 16)
	_push_pf_score_popup("+140  QUAD FEED! (STREAK x4)", Color("ffd166"), 17)
	_push_killfeed("VOCE [1-TAP GOD] // AK-47 [HS] // Bot_S1mple")
	_push_killfeed("VOCE [1-TAP GOD] // DEAGLE [HS] // Bot_FalleN")
	for i in 4:
		await get_tree().process_frame
	await _save_shot("shot_1_iceworld_pvp.png")

	# Shot 2: Parkour Race Mode (El Panadero Extreme 335m — 7 Runner Bots + Countdown + Curved Karambit!)
	_select_mode_and_stage(SakuraWorld.MODE_PARKOUR, 0)
	world.race_countdown = 3.0
	for i in 4:
		await get_tree().process_frame
	_body.global_position = Vector3(0.0, 0.2, 18.2)
	_yaw = 0.0
	_pitch = -0.02
	weapons.select_weapon(3, true)
	weapons.apply_weapon_skin(2)
	weapons.inspect_timer = 1.25
	for i in 4:
		await get_tree().process_frame
	await _save_shot("shot_2_cozy_rooftops.png")

	# Shot 3: Combat Mode Arena 3 (Crossfire Sniper Canyon) + Mobile-First Touch HUD Overlay Active!
	_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 2)
	_mobile_hud_enabled = true
	for i in 4:
		await get_tree().process_frame
	_body.global_position = Vector3(0.0, 4.2, 23.5)
	_yaw = 0.0
	_pitch = -0.04
	weapons.select_weapon(2, true)
	weapons.apply_weapon_skin(3)
	for i in 4:
		await get_tree().process_frame
	await _save_shot("shot_3_csgo_kz_surf.png")
	_mobile_hud_enabled = false

	print("Saved QA screenshots to shots/!")
	get_tree().quit(0)


func _save_shot(fname: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://shots/" + fname))
