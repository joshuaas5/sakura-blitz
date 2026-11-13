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
var _scoreboard: MatchScoreboard
var _last_damage_from := Vector3.ZERO
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
var rp := 0
var rank_idx := 0

var unlocked_weapon_skins := [true, false, false, false, false]
var unlocked_char_skins := [true, false, false, false]
var unlocked_dogtags := [true, false, false, false, false]
var unlocked_icons := [true, false, false, false, false, false]
var active_dogtag_idx := 0
var active_icon_idx := 0

var killfeed: Array[Dictionary] = []

# HUD elements
var _atelier: AtelierHud
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
var _fire_press_pending := false
var _mobile_aim_assist := true
var _mobile_aim := MobileAim.new()
var _mobile_move_vec := Vector2.ZERO
var _mobile_fire_held := false
var _mobile_jump_held := false
var _joy_touch_idx := -1
var _joy_center := Vector2(155.0, 540.0)
var _joy_knob := Vector2(155.0, 540.0)
var _joy_radius := 76.0
var _look_touch_idx := -1
var _startup_grace := 0.25
var profile := PlayerProfile.new()
var _hub: SakuraHub
var _hub_open := false
var _result_panel: PanelContainer
var _touch_actions: Dictionary = {}
var _save_delay := -1.0
var _automation := false
var _mantle_cooldown := 0.0
var _session_started := false
var _hud_editor: HudEditor
var _diagnostics: FrameDiagnostics
var _training: TrainingGuide
var _safe_area_override := Rect2()

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

	_automation = OS.get_cmdline_user_args().has("--test") or OS.get_cmdline_user_args().has("--shot") or OS.get_cmdline_user_args().has("--qa")
	if not _automation:
		profile.read_save()
		_restore_profile()
	# Auto-detect Mobile / Touchscreen (iOS, Android, Mobile Web Browser)
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available():
		_mobile_hud_enabled = true

	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.audio_listener_enable_3d = true
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
	world.combat_finished.connect(_on_combat_finished)
	world.objective_notice.connect(func(message): _show_banner(message, 2.5); Sfx.play("pickup"))
	world.objective_scored.connect(func(actor):
		if actor == "PLAYER":
			_award_progression(35, 20)
			_haptic(25)
	)
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
	_hub = SakuraHub.new()
	add_child(_hub)
	_hub.setup(profile)
	_hub.play_requested.connect(_start_from_hub)
	_hub.resume_requested.connect(_resume_from_hub)
	_hub.profile_changed.connect(_profile_menu_changed)
	_diagnostics = FrameDiagnostics.new()
	add_child(_diagnostics)
	_diagnostics.setup(self)
	_hub.diagnostics_requested.connect(func():
		var report := _diagnostics.report()
		DisplayServer.clipboard_set(report)
		if not _automation:
			var file := FileAccess.open("user://diagnostico_sakura.txt", FileAccess.WRITE)
			if file != null:
				file.store_string(report)
		_show_banner("Diagnóstico copiado. Cole aqui para avaliarmos o desempenho.", 4)
	)
	_hub.hud_editor_requested.connect(_open_hud_editor)
	_hub.training_requested.connect(_start_training)
	_hub.shop_requested.connect(func(): _toggle_shop(1))
	_hub.hide()
	_apply_profile_settings()
	get_viewport().size_changed.connect(_resize_layout)
	_resize_layout.call_deferred()

	var args := OS.get_cmdline_user_args()
	if args.has("--test"):
		_run_automated_test.call_deferred()
		return
	if args.has("--shot"):
		_run_screenshot_suite.call_deferred()
		return

	if args.has("--qa"):
		_run_foundation_qa.call_deferred()
		return
	_select_mode_and_stage(SakuraWorld.MODE_COMBAT, 1)
	_session_started = false
	_open_hub()


func _capture_mouse() -> void:
	if DisplayServer.get_name().contains("headless"):
		return
	if _shop_open or _hub_open or _paused or _mobile_hud_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
		return
	DisplayServer.window_move_to_foreground()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true
	_paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_profile()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(_hud_editor):
			_hud_editor.finished.emit(false)
		elif _shop_open:
			_toggle_shop(0)
		elif is_instance_valid(_hub):
			_open_hub()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_clear_touch_state()
		if is_instance_valid(_hub) and not _automation:
			_pause_for_interruption()
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and not _paused and not _hub_open and not _shop_open and not _mobile_hud_enabled and not DisplayServer.get_name().contains("headless"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true

func _pause_for_interruption() -> void:
	_clear_touch_state()
	if is_instance_valid(_hud_editor):
		_hud_editor.dragging = -2
	_open_hub()


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
	if is_instance_valid(world) and is_instance_valid(world.sun):
		world.sun.shadow_enabled = current_mode == 0 and (current_stage == 1 or current_stage >= 5) and _res_idx > 0


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
	_hud_font = ThemeDB.fallback_font

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
	_atelier = AtelierHud.new()
	_hud.add_child(_atelier)
	_atelier.setup(self)

	_banner_label = _make_label("", 15, Color("f5e6c8"))
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_label.position = Vector2(-340, 130)
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
	_shop_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shop_panel.offset_left = 24
	_shop_panel.offset_right = -24
	_shop_panel.offset_top = 16
	_shop_panel.offset_bottom = -16
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c29")
	style.set_corner_radius_all(16)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_shop_panel.add_theme_stylebox_override("panel", style)
	add_child(_shop_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_shop_panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := _make_label("ARSENAL / SEU ESTILO", 24, Color("f0a5b7"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_styled_btn("VOLTAR", Vector2(120, 48), Color("416772"), func(): _toggle_shop(0)))
	_shop_status_lbl = _make_label("", 16, Color("aec7cb"))
	_shop_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_shop_status_lbl)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 8)
	content.add_child(tabs)
	for i in 2:
		tabs.add_child(_make_styled_btn(["SKINS E UPGRADE", "OPERADORES E TAGS"][i], Vector2(210, 48), Color("416772"), func():
			_shop_tab_idx = i
			_populate_shop_cards()
		))
	for i in WeaponRig.WEAPONS.size():
		tabs.add_child(_make_styled_btn(WeaponCatalog.label_for(i), Vector2(90, 48), Color("416772"), func():
			weapons.select_weapon(i)
			_populate_shop_cards()
		))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_shop_grid = GridContainer.new()
	_shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_grid.add_theme_constant_override("h_separation", 14)
	_shop_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_shop_grid)
	var layout := func(): _shop_grid.columns = 3 if size.x >= 1000 else (2 if size.x >= 680 else 1)
	resized.connect(layout)
	layout.call()
	_shop_panel.hide()
	_populate_shop_cards()


func _populate_shop_cards() -> void:
	if not is_instance_valid(_shop_grid):
		return
	for ch in _shop_grid.get_children():
		_shop_grid.remove_child(ch)
		ch.queue_free()

	if _shop_tab_idx == 0:
		for i in WeaponRig.WEAPON_SKINS.size():
			var sk: Dictionary = WeaponRig.WEAPON_SKINS[i]
			var owned: bool = profile.data.weapon_kills[weapons.current_idx] >= 50 if i == 1 else bool(unlocked_weapon_skins[i])
			var equipped: bool = (weapons.active_skin_idx == i) if is_instance_valid(weapons) else (i == 0)
			var sub := "Visual cosmético • sem bônus de atributos"
			if i == 1:
				sub = "Maestria desta arma: %d/50 abates" % profile.data.weapon_kills[weapons.current_idx]
			var act_txt := "EQUIPADA" if equipped else ("EQUIPAR" if owned else ("50 ABATES NESTA ARMA" if i == 1 else "COMPRAR (%d MOEDAS)" % int(sk.cost)))
			_shop_grid.add_child(_make_product_card(
				"res://assets/ui/skin_%d.png" % i,
				str(sk.name).to_upper(),
				sub,
				act_txt,
				Color("52b788") if equipped else (Color("daa854") if owned else Color("697c68")),
				func():
					_buy_or_equip_weapon_skin(i)
					_populate_shop_cards()
			))

		var cur_w := weapons.current_idx if is_instance_valid(weapons) else 0
		var cur_lvl := int(weapons.weapon_levels[cur_w]) if is_instance_valid(weapons) else 1
		var wname := str(WeaponRig.WEAPONS[cur_w].name).split(" ")[0]
		_shop_grid.add_child(_make_product_card(
			"res://assets/ui/upgrade_gun.png",
			"UPGRADE %s [NV.%d/4]" % [wname, cur_lvl],
			"+1% dano por nível • limite total +3%",
			"NIVEL MAXIMO" if cur_lvl >= 4 else "EVOLUIR (180 MOEDAS)",
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
			var sub := "Visual cosmético • mesma velocidade para todos"
			var act_txt := "EQUIPADO" if equipped else ("EQUIPAR" if owned else ("COMPRAR (%d MOEDAS)" % int(cs.cost)))
			_shop_grid.add_child(_make_product_card(
				"res://assets/ui/char_%d.png" % i,
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
				"Identidade cosmética do perfil",
				act_txt,
				Color("52b788") if equipped else Color("697c68"),
				func():
					_buy_or_equip_dogtag(d_i)
					_populate_shop_cards()
			))


func _make_product_card(img_path: String, title: String, sub: String, btn_txt: String, accent: Color, on_click: Callable) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	pc.custom_minimum_size = Vector2(240, 250)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("203b38")
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

	if img_path.begins_with("res://assets/ui/char_"):
		var portrait := CozyPortrait.new()
		portrait.outfit = int(img_path.get_file().trim_prefix("char_").get_basename())
		vb.add_child(portrait)
	elif img_path.begins_with("res://assets/ui/skin_") or img_path.ends_with("upgrade_gun.png"):
		var portrait := WeaponPortrait.new()
		portrait.weapon_index = weapons.current_idx
		portrait.skin_index = int(img_path.get_file().trim_prefix("skin_").get_basename()) if "skin_" in img_path else weapons.active_skin_idx
		vb.add_child(portrait)
	else:
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.custom_minimum_size = Vector2(180, 110)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = _load_ui_tex(img_path)
		vb.add_child(tr)

	var tl := _make_label(title, 17, Color("fff4d2"))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)

	var sl := _make_label(sub, 15, Color("d8c7ae"))
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sl)

	var btn := _make_styled_btn(btn_txt, Vector2(180, 48), accent, on_click)
	vb.add_child(btn)
	return pc


func _make_styled_btn(txt: String, min_sz: Vector2, accent: Color, on_click: Callable) -> Button:
	var b := Button.new()
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.text = txt
	b.custom_minimum_size = min_sz
	if _hud_font != null:
		b.add_theme_font_override("font", _hud_font)
	b.add_theme_font_size_override("font_size", 14)
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
	_shop_open = not _shop_open if force_state == -1 else force_state == 1
	_shop_panel.visible = _shop_open
	Sfx.set_music_context("lobby" if _shop_open or _hub_open else ("race" if current_mode == 1 else "combat"))
	_clear_touch_state()
	if _shop_open:
		_paused = true
		world.process_mode = Node.PROCESS_MODE_DISABLED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
		move_child(_shop_panel, get_child_count() - 1)
		_populate_shop_cards()
		_refresh_shop_ui("Skins cosméticas. Upgrades com moedas de jogo: até +3% dano.")
	else:
		_save_profile()
		if _hub_open:
			_hub.refresh()
		else:
			_paused = false
			world.process_mode = Node.PROCESS_MODE_INHERIT
			_capture_mouse()


func _refresh_shop_ui(msg: String = "") -> void:
	if is_instance_valid(_shop_status_lbl):
		_shop_status_lbl.text = "SALDO: %d MOEDAS   |   %d DIAMANTES   |   %s" % [coins, gems, msg]


func _buy_or_equip_weapon_skin(idx: int) -> void:
	if idx == 1:
		if profile.data.weapon_kills[weapons.current_idx] < 50:
			_refresh_shop_ui("Ouro: alcance 50 abates com esta arma.")
			return
		unlocked_weapon_skins[1] = true
	var sk: Dictionary = WeaponRig.WEAPON_SKINS[idx]
	var cost := int(sk.cost)
	if not bool(unlocked_weapon_skins[idx]):
		if coins < cost:
			Sfx.play("hurt")
			_refresh_shop_ui("Moedas insuficientes! Jogue partidas e resgate o desafio no hub.")
			return
		coins -= cost
		unlocked_weapon_skins[idx] = true
		Sfx.play("cash_buy")
	else:
		Sfx.play("pickup")
	weapons.apply_weapon_skin(idx)
	profile.data.weapon_skins[weapons.current_idx] = idx
	_queue_save()
	_refresh_shop_ui("Skin de Arma [%s] EQUIPADA!" % str(sk.name))
	_show_banner("SKIN 3D EQUIPADA: %s!" % str(sk.name).to_upper(), 2.4)


func _buy_weapon_upgrade() -> void:
	var cur_lvl := int(weapons.weapon_levels[weapons.current_idx])
	if cur_lvl >= 4:
		_refresh_shop_ui("Esta arma ja esta no NIVEL MAXIMO (+3% dano)!")
		return
	var cost := 180
	if coins < cost:
		Sfx.play("hurt")
		_refresh_shop_ui("Precisa de 180 Moedas para fazer Upgrade!")
		return
	coins -= cost
	var new_lvl := weapons.upgrade_current_weapon()
	_queue_save()
	Sfx.play("rank_up", 1.1)
	var wname := str(WeaponRig.WEAPONS[weapons.current_idx].name)
	_refresh_shop_ui("%s evoluida para NIVEL %d!" % [wname, new_lvl])
	_show_banner("UPGRADE COMPLETO: %s NIVEL %d (+1%% dano; limite +3%%)!" % [wname, new_lvl], 2.5)


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
	_queue_save()
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
	_queue_save()
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
	if is_instance_valid(_atelier):
		_atelier.sync()


func _safe_ui_rect() -> Rect2:
	return _safe_area_override if _safe_area_override.has_area() else MobileLayout.safe_rect(size)

func _action_rects() -> Dictionary:
	var rectangles := MobileLayout.rects(_safe_ui_rect(), profile.data, current_mode == 1)
	# Invalid layouts from a different screen aspect fall back as a whole.
	if not MobileLayout.valid(rectangles, _safe_ui_rect()):
		rectangles = MobileLayout.rects(_safe_ui_rect(), {"hud_left_handed": profile.data.hud_left_handed}, current_mode == 1)
	for key in ["joystick", "pause", "checkpoint"]:
		rectangles.erase(key)
	return rectangles

func _mobile_rect(action: String) -> Rect2:
	var rectangles := MobileLayout.rects(_safe_ui_rect(), profile.data, current_mode == 1)
	if not MobileLayout.valid(rectangles, _safe_ui_rect()):
		rectangles = MobileLayout.rects(_safe_ui_rect(), {"hud_left_handed": profile.data.hud_left_handed}, current_mode == 1)
	return rectangles.get(action, MobileLayout.defaults(_safe_ui_rect(), profile.data.hud_left_handed)[action])

func _open_hud_editor() -> void:
	if is_instance_valid(_hud_editor):
		return
	_open_hub()
	_hub.hide()
	_hud_editor = HudEditor.new()
	add_child(_hud_editor)
	_hud_editor.open(self)
	_hud_editor.finished.connect(func(_saved):
		_hud_editor.queue_free()
		_hud_editor = null
		_clear_touch_state()
		_hub.show()
		_hub.refresh()
	)

func _start_training() -> void:
	if size.y > size.x and not _automation:
		return
	_start_from_hub(0, 5)
	if not is_instance_valid(_training):
		_training = TrainingGuide.new()
		add_child(_training)
		_training.setup(self)
		weapons.hit_registered.connect(_training.hit)
	_training.start()


# ---------------------------------------------------------------- Unified Input: Desktop + Multi-Touch Mobile-First Engine

func _handle_hud_tap_or_click(pos: Vector2, pressed: bool) -> bool:
	if not pressed:
		return false
	if AtelierHud.pause_rect(self).has_point(pos):
		_open_hub()
		return true
	if current_mode == 0 and Rect2(size.x * 0.5 - 105, 12, 210, 75).has_point(pos):
		_toggle_scoreboard()
		return true
	if current_mode == 1 and AtelierHud.checkpoint_rect(self).has_point(pos):
		_teleport_kz_checkpoint()
		return true
	return false


func _input(event: InputEvent) -> void:
	# Native GUI controls consume the emulated pointer; gameplay uses each real finger.
	# Ignoring this duplicate here prevents the same touch firing or moving twice.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if is_instance_valid(_hud_editor):
		return
	if is_instance_valid(_training) and _training.visible and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton) and _training.get_global_rect().has_point(event.position):
		return
	if _hub_open and not _shop_open:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and _hub.can_resume:
			_resume_from_hub()
		return
	if is_instance_valid(_result_panel) and _result_panel.visible:
		return
	if _shop_open:
		if event is InputEventKey and event.pressed and not event.echo:
			var k_s := (event as InputEventKey).keycode
			if k_s == KEY_ESCAPE or k_s == KEY_L:
				_toggle_shop(0)
		return
	if is_instance_valid(_scoreboard) and _scoreboard.visible:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_TAB, KEY_ESCAPE]:
			_toggle_scoreboard()
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_handle_touch(st.index, st.position, st.pressed and not st.canceled, st.canceled)
		return
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_handle_touch_drag(sd.index, sd.position, sd.relative)
		return

	if event is InputEventMouseMotion:
		if not _paused:
			if _mobile_hud_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_handle_touch_drag(99, event.position, event.relative)
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
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not _mobile_hud_enabled and _mouse_captured and not _paused and not _killcam_active:
			_fire_press_pending = true
		if mb.button_index == MOUSE_BUTTON_LEFT and _mobile_hud_enabled:
			_handle_touch(99, mb.position, mb.pressed)
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT and not _mobile_hud_enabled and current_mode == 0:
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
				_open_hub()
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
				weapons.select_weapon(4)
			KEY_6:
				weapons.select_weapon(5)
			KEY_H:
				for step in range(1, WeaponRig.WEAPON_SKINS.size() + 1):
					var next_sk := (weapons.active_skin_idx + step) % WeaponRig.WEAPON_SKINS.size()
					var owned: bool = profile.data.weapon_kills[weapons.current_idx] >= 50 if next_sk == 1 else bool(unlocked_weapon_skins[next_sk])
					if owned:
						_buy_or_equip_weapon_skin(next_sk)
						break
			KEY_7:
				for step in range(1, WeaponRig.CHAR_SKINS.size() + 1):
					var next_cs := (weapons.active_char_skin_idx + step) % WeaponRig.CHAR_SKINS.size()
					if unlocked_char_skins[next_cs]:
						_buy_or_equip_char_skin(next_cs)
						break
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
				_toggle_scoreboard()
			KEY_N:
				_select_mode_and_stage(current_mode, (current_stage + 1) % SakuraHub.MAPS[current_mode].size())
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
				profile.data.music_enabled = not profile.data.music_enabled
				Sfx.configure_music(profile.data.music_enabled, profile.data.music_volume)
				_queue_save()
				_show_banner("MÚSICA: %s" % ("LIGADA" if profile.data.music_enabled else "DESLIGADA"), 2.0)
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
	_queue_save()


func _cycle_atmosphere_preset() -> void:
	var atmo_name := world.cycle_atmosphere_preset()
	_show_banner("ILUMINACAO & CLIMA [U / F6]: %s" % atmo_name, 2.5)


func _toggle_mobile_hud() -> void:
	_mobile_hud_enabled = not _mobile_hud_enabled
	_clear_touch_state()
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
	if is_instance_valid(_scoreboard):
		_scoreboard.queue_free()
		_scoreboard = null
	_clear_touch_state()
	_coyote_timer = 0
	_jump_buffer = 0
	_jump_grace = 0
	_mantle_cooldown = 0
	_cp_count = 0
	_crouching = false
	_killcam_active = false
	_cleanup_killcam_actors()
	_cam.current = true
	_killcam_card.hide()
	_session_started = true
	world.enemies_paused = false
	world.bot_difficulty = profile.data.bot_difficulty
	world.large_population = profile.data.large_population
	world.match_kind = profile.data.match_kind
	kills = 0
	deaths = 0
	headshots = 0
	streak = 0
	_pf_score_stack.clear()
	killfeed.clear()
	current_mode = clampi(mode_idx, 0, 1)
	current_stage = clampi(stage_idx, 0, SakuraHub.MAPS[current_mode].size() - 1)
	var sp := world.load_mode_and_stage(current_mode, current_stage)

	_body.global_position = sp[0]
	_body.velocity = Vector3.ZERO
	_yaw = float(sp[1])
	_pitch = float(sp[2])
	_has_saved_cp = false

	if current_mode == SakuraWorld.MODE_COMBAT:
		server_mode = ServerMode.FY_ICEWORLD_PVP
		world.enemies_paused = false
		Sfx.set_panadero_radio(false)
		weapons.select_weapon(profile.data.selected_weapon)
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

	weapons.visible = current_mode == 0
	_apply_graphics_preset()
	_show_banner("Rota verde: segura. Centro: atalho. Boa corrida!" if current_mode == 1 else "Treino com bots • abates rendem moedas e maestria", 4.0)


func _save_kz_checkpoint() -> void:
	if current_mode == 1:
		_show_banner("Checkpoints automáticos nos portais de cada setor.", 2.0)
		return
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
	if _save_delay >= 0:
		_save_delay -= delta
		if _save_delay < 0:
			_save_profile()
	if _paused or _hub_open or _shop_open:
		return
	_mantle_cooldown = maxf(0, _mantle_cooldown - delta)
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

	if _mobile_hud_enabled and current_mode == SakuraWorld.MODE_COMBAT:
		_mobile_aim.tick(delta)
		_sync_touch_aim(false)

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
	_sprinting = (Input.is_key_pressed(KEY_SHIFT) or joy_sprint or current_mode == SakuraWorld.MODE_PARKOUR) and in_z < -0.1 and not _crouching and (current_mode == 1 or (not weapons.want_ads and weapons.ads_alpha < 0.1))
	var jump_held := Input.is_key_pressed(KEY_SPACE) or _mobile_jump_held
	if jump_held:
		_jump_buffer = 0.15
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

	# Aim assistance never requests a shot.
	if current_mode == SakuraWorld.MODE_COMBAT and _mobile_aim_assist:
		_apply_mobile_aim_assist(delta)

	var target_eye := EYE_CROUCH if _crouching else EYE_STAND
	_eye_y = lerpf(_eye_y, target_eye, minf(1.0, delta * 16.0))
	_cam_pivot.position.y = _eye_y

	var target_roll := -input_vec.x * 0.015 + (0.05 if _surfing else 0.0)
	_cam_roll = lerpf(_cam_roll, target_roll, minf(1.0, delta * 14.0))
	_body.rotation.y = _yaw
	_cam_pivot.rotation = Vector3(_pitch, 0.0, _cam_roll)

	var w_def: Dictionary = WeaponRig.WEAPONS[weapons.current_idx]
	var target_fov := 76.0 if current_mode == 1 else lerpf(76.0, float(w_def.ads_fov), weapons.ads_alpha)
	if _sprinting and _body.is_on_floor():
		target_fov = 82.0
	_cam.fov = lerpf(_cam.fov, target_fov, minf(1.0, delta * 14.0))

	var h_speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	world.player_pos = _body.global_position
	world.player_grounded = _body.is_on_floor()
	weapons.tick_viewmodel(delta, h_speed, _body.is_on_floor(), _sprinting, _crouching)

	_tick_weapon_trigger(h_speed)

	_update_hud(delta, h_speed)


func _tick_weapon_trigger(h_speed: float) -> void:
	var pressed := _fire_press_pending
	_fire_press_pending = false
	if current_mode != SakuraWorld.MODE_COMBAT or _shop_open or _paused or _hub_open or _killcam_active:
		_body.set_meta("fire_was", false)
		return
	var held := (_mouse_captured and not _mobile_hud_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) or _mobile_fire_held
	var w: Dictionary = WeaponRig.WEAPONS[weapons.current_idx]
	if _mobile_hud_enabled and _cur_ammo_cached == 0 and not _reloading_cached:
		weapons.start_reload()
	if (held or pressed) and (bool(w.auto) or pressed or not bool(_body.get_meta("fire_was", false))):
		if weapons.try_fire(h_speed):
			_crosshair_spread = minf(1.0, _crosshair_spread + (0.14 if weapons.ads_alpha > 0.5 else 0.28))
	_body.set_meta("fire_was", held)


func _apply_mobile_aim_assist(delta: float) -> bool:
	if not _mobile_hud_enabled or (_look_touch_idx < 0 and not _mobile_fire_held and not weapons.want_ads) or not is_instance_valid(_cam) or world.enemies.is_empty():
		return false
	var cam_pos := _cam.global_position
	var cam_fwd := -_cam.global_transform.basis.z
	var best_dot := 0.965
	var best_aim_dir := Vector3.ZERO
	var on_target := false

	for b in world.enemies:
		if not is_instance_valid(b) or world.same_team("PLAYER", b.bot_name):
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
		_coyote_timer = 0.15
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

	var w_mult := 1.0 if current_mode == 1 else weapons.speed_multiplier() + (0.12 if _adrenaline_t > 0.0 else 0.0)
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
	_try_mantle(wish_dir)


# ---------------------------------------------------------------- Phantom Forces Combat Dopamine, Progression & Callbacks

func _push_pf_score_popup(txt: String, col: Color = Color("ffd166"), fsize: int = 15) -> void:
	_pf_score_stack.push_front({"text": txt, "col": col, "size": fsize, "life": 2.1})
	if _pf_score_stack.size() > 5:
		_pf_score_stack.resize(5)


func _award_progression(add_coins: int, add_rp: int, reason: String = "") -> void:
	_queue_save()
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
	if is_instance_valid(weapons):
		if current_mode == SakuraWorld.MODE_COMBAT:
			profile.data.selected_weapon = _idx
			_queue_save()
		weapons.apply_weapon_skin(profile.data.weapon_skins[_idx])
		weapons.inspect_timer = 0
	_on_ammo_updated(cur_ammo, cur_res, false)


func _on_ammo_updated(cur_ammo: int, cur_res: int, reloading: bool) -> void:
	_cur_ammo_cached = cur_ammo
	_cur_res_cached = cur_res
	_reloading_cached = reloading
	if is_instance_valid(_hud):
		_hud.queue_redraw()


func _on_shot_fired(_weapon_idx: int, kick_pitch: float, kick_yaw: float) -> void:
	world.player_spawn_guard = 0
	if _weapon_idx == 3 and world.combat_audio != null:
		world.combat_audio.noise(world.player_pos, null, 0.25)
	_pitch = clampf(_pitch + kick_pitch, -1.45, 1.45)
	_yaw += kick_yaw


func _on_hit_registered(result: Dictionary, _weapon_idx: int) -> void:
	_hitmarker_timer = 0.18
	_hitmarker_crit = bool(result.get("headshot", false)) or bool(result.get("killed", false))


func _on_enemy_killed(was_headshot: bool, bot_name: String, hit_pos: Vector3) -> void:
	kills += 1
	var mastery := profile.record_kill(weapons.current_idx)
	if mastery == 50 or (mastery == 100 and weapons.current_idx in WeaponCatalog.FIREARMS):
		_push_pf_score_popup("MAESTRIA: %s DESBLOQUEADO!" % ("OURO" if mastery == 50 else "SILENCIADOR"), Color("f4d593"), 18)
	_haptic(25)
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

	var c_gain := (18 if was_headshot else 12) + mini(streak, 5) * 2
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
	_push_pf_score_popup("+10 MOEDAS / ANEL COLETADO", Color("00f5d4"), 15)
	_award_progression(10, 10, "ANEL DOURADO DE PARKOUR COLETADO")


func _on_kz_stage_reached(stage_idx: int, stage_name: String, ctime: float, cp_pos: Vector3) -> void:
	_saved_cp_pos = cp_pos
	_saved_cp_yaw = 0.0
	_has_saved_cp = true
	_cp_count = stage_idx
	_award_progression(15, 15, "CHECKPOINT SALVO: %s (%.1fs)" % [stage_name, ctime])


func _on_kz_course_finished(ctime: float, best_t: float, place: int) -> void:
	profile.record_finish(current_stage, ctime)
	var coin_reward := 180 if place == 1 else (120 if place <= 3 else 80)
	var gem_reward := 50 if place == 1 else (30 if place <= 3 else 15)
	gems += gem_reward
	var place_tag := "1º LUGAR CAMPEAO FALL GUYS!" if place == 1 else ("%dº LUGAR NA CORRIDA!" % place)
	_push_pf_score_popup("%s (+%d MOEDAS / +%d DIAMANTES)" % [place_tag, coin_reward, gem_reward], Color("ffd166"), 18)
	_award_progression(coin_reward, 350, "%s // TEMPO %.2fs (Recorde: %.2fs) // [K] Nova Corrida" % [place_tag, ctime, best_t])
	_show_race_result.call_deferred(ctime, best_t, place, coin_reward)


func _on_player_damaged(amount: float, _from_pos: Vector3, attacker_name: String) -> void:
	if world.same_team(attacker_name, "PLAYER"):
		return
	if current_mode == SakuraWorld.MODE_PARKOUR or _paused or _hub_open or _shop_open or world.combat_is_finished:
		return # Zero PvP shooting damage in Parkour Mode!
	_out_of_combat_t = 0.0
	_last_damage_from = _from_pos
	var absorbed := minf(armor, amount * 0.55)
	armor = maxf(0.0, armor - absorbed)
	hp = maxf(0.0, hp - (amount - absorbed))
	_haptic(18)
	_damage_alpha = 0.36
	Sfx.play("hurt")
	if hp <= 0.0:
		world.record_team_elimination(attacker_name, "PLAYER", _body.global_position)
		_clear_touch_state()
		deaths += 1
		world.player_spawn_guard = 1.5
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
		world.player_pos = sp[0]
		_yaw = sp[1]
		_pitch = 0
		_body.velocity = Vector3.ZERO
		_push_killfeed("%s  //  AK-47  //  VOCE" % attacker_name)
		_show_banner("%s eliminou você • novo ponto de entrada" % attacker_name, 2.4)


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
	_clear_touch_state()
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
	if OS.get_cmdline_user_args().has("--teams"):
		var teams = load("res://tests/team_checks.gd").new()
		get_tree().quit(0 if await teams.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--large"):
		var large_checks = load("res://tests/large_arena_checks.gd").new()
		get_tree().quit(0 if await large_checks.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--harbor"):
		var harbor = load("res://tests/harbor_checks.gd").new()
		get_tree().quit(0 if await harbor.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--aim"):
		var aim = load("res://tests/aim_checks.gd").new()
		get_tree().quit(0 if await aim.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--manual-fire"):
		var manual_fire = load("res://tests/manual_fire_checks.gd").new()
		get_tree().quit(0 if await manual_fire.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--navigation"):
		var navigation = load("res://tests/navigation_checks.gd").new()
		get_tree().quit(0 if await navigation.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--arsenal"):
		var arsenal = load("res://tests/arsenal_checks.gd").new()
		get_tree().quit(0 if await arsenal.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--quality"):
		var quality = load("res://tests/quality_checks.gd").new()
		get_tree().quit(0 if await quality.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--combat"):
		var combat = load("res://tests/combat_checks.gd").new()
		get_tree().quit(0 if await combat.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--menus"):
		var menus = load("res://tests/menu_checks.gd").new()
		get_tree().quit(0 if await menus.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--mobile"):
		var mobile = load("res://tests/mobile_checks.gd").new()
		get_tree().quit(0 if await mobile.run(self) else 1)
		return
	if OS.get_cmdline_user_args().has("--arenas"):
		var focused_checks = load("res://tests/arena_checks.gd").new()
		get_tree().quit(0 if await focused_checks.run(self) else 1)
		return

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

	for st_i in SakuraWorld.COMBAT_STAGE_DEFS.size():
		_select_mode_and_stage(SakuraWorld.MODE_COMBAT, st_i)
		assert(current_mode == SakuraWorld.MODE_COMBAT and current_stage == st_i, "Must switch to Combat Arena %d" % st_i)

	# 2. Verify Parkour Race Mode (4 Long 8-Sector Marathons + 7 Runner Bots + Zero PvP Damage!)
	for pk_i in SakuraWorld.PARKOUR_STAGE_DEFS.size():
		_select_mode_and_stage(SakuraWorld.MODE_PARKOUR, pk_i)
		await get_tree().process_frame
		assert(current_mode == SakuraWorld.MODE_PARKOUR and current_stage == pk_i, "Must switch to Parkour Marathon %d" % pk_i)
		assert(world.parkour_runners.size() == 7, "Parkour Race must spawn 7 competing Runner Bots")
		assert(world.kz_checkpoints.size() == 8, "Each Parkour Marathon must have 8 Sectors")
		var total_len := world.kz_start_pad.z - world.kz_finish_pad.z
		assert(total_len >= 200.0 and total_len <= 230.0, "Mobile course length must be 200–230m (got %.1fm)" % total_len)

	# 3. Verify Mobile-First Touch HUD Toggle
	_toggle_mobile_hud()
	assert(_mobile_hud_enabled, "Mobile Touch HUD should toggle on")
	_toggle_mobile_hud()

	var checks = load("res://tests/foundation_checks.gd").new()
	if not await checks.run(self):
		get_tree().quit(1)
		return
	var bot_checks = load("res://tests/bot_checks.gd").new()
	if not await bot_checks.run(self):
		get_tree().quit(1)
		return
	var arena_checks = load("res://tests/arena_checks.gd").new()
	if not await arena_checks.run(self):
		get_tree().quit(1)
		return
	var mobile_checks = load("res://tests/mobile_checks.gd").new()
	if not await mobile_checks.run(self):
		get_tree().quit(1)
		return
	var village_checks = load("res://tests/village_checks.gd").new()
	if not await village_checks.run(self):
		get_tree().quit(1)
		return
	var menu_checks = load("res://tests/menu_checks.gd").new()
	if not await menu_checks.run(self):
		get_tree().quit(1)
		return
	var combat_checks = load("res://tests/combat_checks.gd").new()
	if not await combat_checks.run(self):
		get_tree().quit(1)
		return
	var quality_checks = load("res://tests/quality_checks.gd").new()
	if not await quality_checks.run(self):
		get_tree().quit(1)
		return
	var arsenal_checks = load("res://tests/arsenal_checks.gd").new()
	if not await arsenal_checks.run(self):
		get_tree().quit(1)
		return
	var navigation_checks = load("res://tests/navigation_checks.gd").new()
	if not await navigation_checks.run(self):
		get_tree().quit(1)
		return
	var manual_fire_checks = load("res://tests/manual_fire_checks.gd").new()
	if not await manual_fire_checks.run(self):
		get_tree().quit(1)
		return
	var aim_checks = load("res://tests/aim_checks.gd").new()
	if not await aim_checks.run(self):
		get_tree().quit(1)
		return
	var harbor_checks = load("res://tests/harbor_checks.gd").new()
	if not await harbor_checks.run(self):
		get_tree().quit(1)
		return
	var large_checks = load("res://tests/large_arena_checks.gd").new()
	if not await large_checks.run(self):
		get_tree().quit(1)
		return
	var team_checks = load("res://tests/team_checks.gd").new()
	if not await team_checks.run(self):
		get_tree().quit(1)
		return
	print("2 GAME MODES (11 COMBAT ARENAS + 6 MOBILE PARKOUR COURSES) + 7 RUNNER BOTS + MOBILE-FIRST HUD automated test PASSED!")
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
	print("RENDER ", fname, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " memory_MiB=", snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1))


func _handle_touch(index: int, pos: Vector2, pressed: bool, canceled: bool = false) -> void:
	# Release by finger identity before hit testing. A release can be anywhere.
	if not pressed:
		_mobile_aim.release(index, canceled)
		_touch_actions.erase(index)
		if index == _joy_touch_idx:
			_joy_touch_idx = -1
			_mobile_move_vec = Vector2.ZERO
		if index == _look_touch_idx:
			_look_touch_idx = -1
		_mobile_fire_held = _touch_actions.values().has("fire")
		_mobile_jump_held = _touch_actions.values().has("jump")
		if _look_touch_idx < 0:
			for action in ["fire", "ads", "jump"]:
				for finger in _touch_actions:
					if _touch_actions[finger] == action and _look_touch_idx < 0:
						_look_touch_idx = finger
		_sync_touch_aim()
		return
	if _killcam_active:
		_stop_killcam()
		return
	if _handle_hud_tap_or_click(pos, true):
		return
	_mobile_hud_enabled = true
	var rects := _action_rects()
	for action in rects:
		if not (rects[action] as Rect2).has_point(pos):
			continue
		_touch_actions[index] = action
		match action:
			"jump":
				_mobile_jump_held = true
				_jump_buffer = 0.15
			"fire":
				_mobile_fire_held = true
				_fire_press_pending = true
			"ads":
				_mobile_aim.press(index, profile.data.aim_mode)
				if not profile.data.aim_tip_seen:
					profile.data.aim_tip_seen = true
					_queue_save()
				_sync_touch_aim()
			"reload":
				weapons.start_reload()
			"weapon":
				weapons.select_weapon((weapons.current_idx + 1) % WeaponRig.WEAPONS.size())
		# Looking while jumping/firing is essential for two-thumb play.
		if action in ["jump", "fire", "ads"] and _look_touch_idx < 0:
			_look_touch_idx = index
		return
	if _mobile_rect("joystick").grow(12).has_point(pos) and _joy_touch_idx < 0:
		_joy_touch_idx = index
		_joy_radius = _mobile_rect("joystick").size.x / 2
		_joy_center = pos
		_joy_knob = pos
		_mobile_move_vec = Vector2.ZERO
	elif _look_touch_idx < 0:
		_look_touch_idx = index


func _handle_touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	_mobile_aim.drag(index, relative)
	if index == _joy_touch_idx:
		var motion := (pos - _joy_center).limit_length(_joy_radius)
		_joy_knob = _joy_center + motion
		_mobile_move_vec = motion / _joy_radius
	elif index == _look_touch_idx:
		var sensitivity := 0.0035 * float(profile.data.sensitivity)
		var fov := float(WeaponCatalog.DEFINITIONS[weapons.current_idx].ads_fov)
		var zoom_ratio := tan(deg_to_rad(fov) * 0.5) / tan(deg_to_rad(76.0) * 0.5)
		sensitivity *= lerpf(1.0, float(profile.data.ads_sensitivity) * sqrt(zoom_ratio), weapons.ads_alpha)
		_yaw -= relative.x * sensitivity
		_pitch = clampf(_pitch - relative.y * sensitivity, -1.45, 1.45)
		weapons.add_look_sway(relative)


func _sync_touch_aim(feedback: bool = true) -> void:
	if not _mobile_hud_enabled or not is_instance_valid(weapons):
		return
	var allowed := current_mode == SakuraWorld.MODE_COMBAT and not _paused and not _hub_open and not _shop_open and not _killcam_active and not weapons.is_reloading and not bool(WeaponCatalog.DEFINITIONS[weapons.current_idx].melee)
	var desired: bool = allowed and _mobile_aim.desired(profile.data.aim_mode)
	if desired != weapons.want_ads:
		weapons.want_ads = desired
		if feedback:
			_haptic(10 if desired else 5)


func _clear_touch_state() -> void:
	_mobile_aim.reset()
	_fire_press_pending = false
	_touch_actions.clear()
	_joy_touch_idx = -1
	_look_touch_idx = -1
	_mobile_move_vec = Vector2.ZERO
	_mobile_fire_held = false
	_mobile_jump_held = false
	_jump_buffer = 0
	_sprinting = false
	if is_instance_valid(weapons):
		weapons.want_ads = false
	if is_instance_valid(_body):
		_body.velocity.x = 0
		_body.velocity.z = 0
		_body.set_meta("fire_was", false)
	_jump_buffer = 0
	if is_instance_valid(weapons):
		weapons.want_ads = false


func _try_mantle(wish_dir: Vector3) -> bool:
	if current_mode != 1 or _body.is_on_floor() or _mantle_cooldown > 0 or wish_dir.length() < 0.5 or _body.velocity.y > 2.0:
		return false
	var foot := _body.global_position
	var space := world.get_world_3d().direct_space_state
	var ahead := foot + wish_dir * 0.8
	var wall := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 0.55, ahead + Vector3.UP * 0.55, 1)
	if space.intersect_ray(wall).is_empty():
		return false
	var ray := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 1.45, ahead + Vector3.UP * 0.2, 1)
	var top := space.intersect_ray(ray)
	if top.is_empty() or (top.normal as Vector3).y < 0.8:
		return false
	var rise := float(top.position.y) - foot.y + 0.04
	if rise < 0.25 or rise > 1.25:
		return false
	# Sweep both segments of the lift; no teleport through ceilings or walls.
	if _body.test_move(_body.global_transform, Vector3.UP * rise):
		return false
	var raised := _body.global_transform
	raised.origin += Vector3.UP * rise
	if _body.test_move(raised, wish_dir * 0.8):
		return false
	_body.global_position = raised.origin + wish_dir * 0.8
	_body.velocity.y = 0
	_mantle_cooldown = 0.4
	_coyote_timer = 0
	_haptic(12)
	return true


func _restore_profile() -> void:
	coins = profile.data.coins
	gems = profile.data.gems
	rp = profile.data.rp
	unlocked_weapon_skins = profile.data.owned_weapons.duplicate()
	unlocked_char_skins = profile.data.owned_characters.duplicate()
	unlocked_dogtags = profile.data.owned_tags.duplicate()
	active_dogtag_idx = profile.data.tag
	_res_idx = profile.data.quality
	for i in RANK_TIERS.size():
		if rp >= RANK_TIERS[i].min_rp:
			rank_idx = i


func _sync_profile() -> void:
	profile.data.coins = coins
	profile.data.gems = gems
	profile.data.rp = rp
	profile.data.owned_weapons = unlocked_weapon_skins.duplicate()
	profile.data.owned_characters = unlocked_char_skins.duplicate()
	profile.data.owned_tags = unlocked_dogtags.duplicate()
	profile.data.tag = active_dogtag_idx
	profile.data.quality = _res_idx
	if is_instance_valid(weapons):
		profile.data.weapon_levels = weapons.weapon_levels.duplicate()
		profile.data.character = weapons.active_char_skin_idx


func _apply_profile_settings() -> void:
	Sfx.configure_music(profile.data.music_enabled, profile.data.music_volume)
	Sfx.configure_effects(profile.data.effects_volume, profile.data.ambience_volume)
	_res_idx = profile.data.quality
	_apply_graphics_preset()
	world.kz_best_times = profile.data.best_times.duplicate()
	weapons.weapon_levels = profile.data.weapon_levels.duplicate()
	weapons.select_weapon(profile.data.selected_weapon if current_mode == SakuraWorld.MODE_COMBAT else 3)
	weapons.apply_char_skin(profile.data.character)
	weapons.apply_weapon_skin(profile.data.weapon_skins[weapons.current_idx])
	weapons.inspect_timer = 0
	for i in WeaponCatalog.FIREARMS:
		weapons.set_suppressor(i, profile.data.suppressors[i])


func _profile_menu_changed() -> void:
	coins = profile.data.coins
	_apply_profile_settings()
	_queue_save()


func _queue_save() -> void:
	_save_delay = 0.4


func _save_profile() -> Error:
	if _automation:
		return OK
	_sync_profile()
	var err := profile.write_save()
	if err != OK:
		_show_banner("Não foi possível salvar o perfil neste dispositivo.", 4)
		push_warning("Profile save failed: %s" % error_string(err))
	_save_delay = -1
	return err


func _open_hub() -> void:
	if is_instance_valid(_scoreboard):
		_scoreboard.hide()
	# A transition to the lobby owns the screen; never leave a shop modal above it.
	_shop_open = false
	if is_instance_valid(_shop_panel):
		_shop_panel.hide()
	Sfx.set_music_context("lobby")
	if _killcam_active:
		_stop_killcam()
	_clear_touch_state()
	_sync_profile()
	_hub_open = true
	_paused = true
	_mouse_captured = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.hide()
	_damage_flash.hide()
	if is_instance_valid(_result_panel):
		_result_panel.hide()
	_hub.can_resume = _session_started and world.player_race_place == 0 and not world.combat_is_finished
	_hub.show()
	_hub.refresh()
	_save_profile()


func _resume_from_hub() -> void:
	if size.y > size.x and not _automation:
		return
	Sfx.set_music_context("race" if current_mode == 1 else "combat")
	_hub.hide()
	_hub_open = false
	_paused = false
	_hud.show()
	_damage_flash.show()
	world.process_mode = Node.PROCESS_MODE_INHERIT
	_clear_touch_state()
	_capture_mouse()


func _start_from_hub(mode: int, stage: int) -> void:
	if is_instance_valid(_training) and _training.active:
		_training.stop()
	if size.y > size.x and not _automation:
		return
	if is_instance_valid(_result_panel):
		_result_panel.hide()
	_resume_from_hub()
	_select_mode_and_stage(mode, stage)
	_capture_mouse()


func _result_contents() -> VBoxContainer:
	_result_panel = PanelContainer.new()
	_result_panel.add_theme_stylebox_override("panel", _hub._style(Color("203b38")))
	add_child(_result_panel)
	var safe := _safe_ui_rect().grow(-16)
	_result_panel.size = safe.size.min(Vector2(560, 480))
	_result_panel.position = safe.get_center() - _result_panel.size / 2
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_result_panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	return content

func _show_race_result(seconds: float, best: float, place: int, reward: int) -> void:
	_save_profile()
	_clear_touch_state()
	_paused = true
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false
	if is_instance_valid(_result_panel):
		_result_panel.queue_free()
	var v := _result_contents()
	v.add_child(_hub._label("CHEGOU! / %dº LUGAR" % place, 30, Color("93e7c3")))
	v.add_child(_hub._label("%.2fs   •   Recorde %.2fs" % [seconds, best], 22))
	v.add_child(_hub._label("+%d moedas • 8 setores concluídos" % reward, 17))
	v.add_child(_hub._button("Jogar novamente", func(): _start_from_hub(1, current_stage), true))
	v.add_child(_hub._button("Próxima pista", func(): _start_from_hub(1, (current_stage + 1) % SakuraHub.MAPS[current_mode].size())))
	v.add_child(_hub._button("Voltar ao hub", _open_hub))


func _haptic(duration: int) -> void:
	if _mobile_hud_enabled and profile.data.haptics and not _automation:
		Input.vibrate_handheld(duration)


func _run_foundation_qa() -> void:
	if OS.get_cmdline_user_args().has("--teams"):
		await _run_team_qa()
		return
	if OS.get_cmdline_user_args().has("--large"):
		await _run_large_qa()
		return
	if OS.get_cmdline_user_args().has("--harbor"):
		await _run_harbor_qa()
		return
	if OS.get_cmdline_user_args().has("--aim"):
		await _run_aim_qa()
		return
	if OS.get_cmdline_user_args().has("--manual-fire"):
		await _run_manual_fire_qa()
		return
	if OS.get_cmdline_user_args().has("--color"):
		await _run_color_qa()
		return
	if OS.get_cmdline_user_args().has("--navigation"):
		await _run_navigation_qa()
		return
	if OS.get_cmdline_user_args().has("--arsenal"):
		await _run_arsenal_qa()
		return
	if OS.get_cmdline_user_args().has("--combat"):
		await _run_combat_qa()
		return
	if OS.get_cmdline_user_args().has("--phase2"):
		await _run_phase2_qa()
		return
	if OS.get_cmdline_user_args().has("--mobile"):
		await _run_mobile_qa()
		return
	if OS.get_cmdline_user_args().has("--arena-lobby"):
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_hub.mode = 0
		_open_hub()
		for frame in 15:
			await get_tree().process_frame
		await _save_shot("arenas_lobby.png")
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--arenas"):
		await _run_arena_qa()
		return
	if OS.get_cmdline_user_args().has("--art"):
		await _run_art_qa()
		return
	await get_tree().process_frame
	_open_hub()
	await _save_shot("foundation_hub.png")
	for i in SakuraWorld.PARKOUR_STAGE_DEFS.size():
		_start_from_hub(1, i)
		_res_idx = 2
		_apply_graphics_preset()
		_mobile_hud_enabled = true
		world.race_countdown = 0
		world._start_gate_node.position.y = -14
		_body.position = Vector3(0, 0.2, 17)
		_pitch = -0.03
		for frame in 12:
			await get_tree().process_frame
		await _save_shot("foundation_course_%d.png" % i)
	for arena in [0, 4, 5]:
		_start_from_hub(0, arena)
		for frame in 12:
			await get_tree().process_frame
		await _save_shot("foundation_combat_%d.png" % arena)
	world.enemies_paused = true
	weapons.apply_weapon_skin(1)
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("foundation_gold.png")
	weapons.apply_weapon_skin(2)
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("foundation_neon.png")
	_open_hub()
	_hub.page = 1
	_hub.refresh()
	await _save_shot("foundation_mastery.png")
	_toggle_shop(1)
	await _save_shot("foundation_shop.png")
	_shop_tab_idx = 1
	_populate_shop_cards()
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_costume_shop.png")
	_toggle_shop(0)
	_hub.hide()
	_hub_open = false
	_show_race_result(87.45, 87.45, 2, 120)
	await _save_shot("foundation_result.png")
	_result_panel.hide()
	_open_hub()
	_hub.page = 0
	_hub.refresh()
	DisplayServer.window_set_size(Vector2i(540, 960))
	for frame in 8:
		await get_tree().process_frame
	await _save_shot("foundation_portrait.png")
	DisplayServer.window_set_size(Vector2i(844, 390))
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_phone_lobby.png")
	_start_from_hub(1, 4)
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_phone_race.png")
	_start_from_hub(0, 5)
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_phone_combat.png")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_mobile_hud_enabled = false
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_pc_hud.png")
	_start_from_hub(1, 4)
	world.enemies_paused = true
	world.race_countdown = 0
	world._start_gate_node.position.y = -14
	_body.position = Vector3(0, 0.2, 20)
	_pitch = -0.08
	for i in world.parkour_runners.size():
		var runner = world.parkour_runners[i]
		runner.position = Vector3((i - 1) * 1.3, 0.2, 16.5 if i < 3 else -30)
		runner._root.rotation.y = 0
	_banner_label.text = ""
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("foundation_avatar_lineup.png")
	get_tree().quit()


func _resize_layout() -> void:
	var physical := get_window().size
	var design := Vector2i(480, 854) if physical.y > physical.x else (Vector2i(854, 480) if physical.y < 600 else Vector2i(1280, 720))
	if get_window().content_scale_size != design:
		get_window().content_scale_size = design
		if is_instance_valid(_hub):
			_hub.refresh.call_deferred()
	_vp.size = _calc_vp_size()
	_clear_touch_state()
	if physical.y > physical.x and _session_started and not _hub_open and not _automation:
		_open_hub()


func _on_combat_finished(standings: Array) -> void:
	var place := 1
	for row in standings:
		if row.is_player:
			place = row.rank
	if world.match_kind != CombatMatch.FFA:
		place = 1 if world.team_scores[0] > world.team_scores[1] else (2 if world.team_scores[0] < world.team_scores[1] else 0)
	var participated := kills > 0 or (is_instance_valid(world.match_controller) and int(world.match_controller.captures.get("PLAYER", 0)) > 0)
	var reward := (150 if place == 1 else 60) if participated else 0
	_award_progression(reward, 40 if participated else 0)
	_save_profile()
	_show_combat_result.call_deferred(standings, place, reward)


func _show_combat_result(standings: Array, place: int, reward: int) -> void:
	if is_instance_valid(_scoreboard):
		_scoreboard.hide()
	_clear_touch_state()
	_paused = true
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false
	if is_instance_valid(_result_panel):
		_result_panel.queue_free()
	var v := _result_contents()
	var title := "VITÓRIA!" if place == 1 else ("EMPATE" if place == 0 else "PARTIDA CONCLUÍDA / %dº" % place)
	if world.match_kind != CombatMatch.FFA and place == 2:
		title = "EQUIPE CORAL VENCEU"
	v.add_child(_hub._label(title, 28, Color("93e7c3")))
	if world.match_kind != CombatMatch.FFA:
		v.add_child(_hub._label("MENTA %d × %d CORAL • %s" % [world.team_scores[0], world.team_scores[1], CombatMatch.LABELS[world.match_kind]], 18))
	v.add_child(_hub._label("Bots %s • +%d moedas" % [BotDifficulty.get_preset(world.bot_difficulty).name, reward], 18))
	for row in standings:
		var team_label: String = " / " + CombatMatch.TEAM_NAMES[int(row.get("team_id", 0))] if world.match_kind != CombatMatch.FFA else ""
		v.add_child(_hub._label("%d. %s%s    %d abates / %d mortes" % [row.rank, row.name, team_label, row.kills, row.deaths], 16, Color("93e7c3") if row.is_player else Color("c3d3da")))
	v.add_child(_hub._button("Revanche", func(): _start_from_hub(0, current_stage), true))
	v.add_child(_hub._button("Próxima arena", func(): _start_from_hub(0, (current_stage + 1) % SakuraWorld.COMBAT_STAGE_DEFS.size())))
	v.add_child(_hub._button("Voltar ao lobby", _open_hub))

func _toggle_scoreboard() -> void:
	if current_mode != SakuraWorld.MODE_COMBAT or _hub_open or _paused:
		return
	if is_instance_valid(_scoreboard) and _scoreboard.visible:
		_scoreboard.hide()
		_capture_mouse()
		return
	if not is_instance_valid(_scoreboard):
		_scoreboard = MatchScoreboard.new()
		add_child(_scoreboard)
		_scoreboard.setup(self)
	_clear_touch_state()
	_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_scoreboard.show()
	_scoreboard.refresh()


func _run_combat_qa() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	_mobile_hud_enabled = true
	profile.data.bot_difficulty = 2
	_res_idx = 2
	_start_from_hub(0, 5)
	_apply_graphics_preset()
	_banner_timer = 0
	_banner_label.text = ""
	for frame in 8:
		await get_tree().process_frame
	await _save_shot("combat_spawn_protection.png")
	_body.position = Vector3(-4, 0.1, 10)
	_yaw = PI / 2
	_pitch = 0
	for frame in 600:
		await get_tree().physics_frame
	world.enemies_paused = true
	var frags := 0
	for stats in world.bot_scoreboard.values():
		frags += int(stats.kills)
	print("LIVE COMBAT QA: bot_frags=", frags, " player_deaths=", deaths, " active_bots=", world.enemies.size())
	for frame in 8:
		await get_tree().process_frame
	await _save_shot("combat_live_mobile.png")
	_open_hub()
	_hub.page = 2
	_hub.refresh()
	for frame in 8:
		await get_tree().process_frame
	await _save_shot("combat_audio_settings.png")
	get_tree().quit()

func _run_phase2_qa() -> void:
	var menu_checks = load("res://tests/menu_checks.gd").new()
	if not await menu_checks.run(self):
		get_tree().quit(1)
		return
	Input.set_emulate_touch_from_mouse(true)
	_session_started = false
	DisplayServer.window_set_size(Vector2i(844, 390))
	_hub.mode = 0
	_hub.page = 0
	_hub._scroll.scroll_vertical = 0
	_open_hub()
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("phase2_lobby_mobile.png")
	var origin: Vector2 = _hub._grid.get_child(0).get_global_rect().position + Vector2(50, 25)
	await menu_checks.swipe(self, origin)
	await _save_shot("phase2_lobby_scrolled.png")
	Input.set_emulate_touch_from_mouse(false)
	_start_from_hub(0, 5)
	_mobile_hud_enabled = true
	_res_idx = 2
	_apply_graphics_preset()
	world.enemies_paused = true
	_banner_timer = 0
	_banner_label.text = ""
	_body.position = Vector3(-4, 0.2, 10)
	_yaw = PI / 2
	_pitch = 0
	for frame in 16:
		await get_tree().process_frame
	await _save_shot("phase2_tea_house_mobile.png")
	_body.position = Vector3(-8.2, 0.2, 9.3)
	_yaw = PI / 2
	_pitch = -0.08
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("phase2_tea_room_mobile.png")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_mobile_hud_enabled = false
	_body.position = Vector3(-3, 3, 20)
	_yaw = 0.35
	_pitch = -0.1
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("phase2_village_pc.png")
	get_tree().quit()

func _run_mobile_qa() -> void:
	DisplayServer.window_set_size(Vector2i(844, 390))
	_mobile_hud_enabled = true
	_res_idx = 2
	_start_from_hub(0, 6)
	_apply_graphics_preset()
	world.enemies_paused = true
	_banner_timer = 0
	for frame in 20:
		await get_tree().process_frame
	await _save_shot("mobile_controls_right.png")
	profile.data.hud_left_handed = true
	_safe_area_override = Rect2(Vector2(38, 12), size - Vector2(64, 24))
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("mobile_controls_left_safe.png")
	_open_hud_editor()
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("mobile_hud_editor.png")
	_hud_editor.finished.emit(false)
	_safe_area_override = Rect2()
	profile.data.hud_left_handed = false
	_start_training()
	_res_idx = 2
	_apply_graphics_preset()
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("mobile_training.png")
	_training.stop()
	_hub.page = 2
	_hub.refresh()
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("mobile_settings.png")
	get_tree().quit()

func _run_arena_qa() -> void:
	_res_idx = 2
	for arena in [6, 7, 8]:
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_start_from_hub(0, arena)
		_apply_graphics_preset()
		world.enemies_paused = true
		_mobile_hud_enabled = false
		_banner_timer = 0
		_banner_label.text = ""
		weapons.apply_weapon_skin(2)
		weapons.inspect_timer = 0
		for frame in 20:
			await get_tree().process_frame
		await _save_shot("arena_%d_pc.png" % arena)
		DisplayServer.window_set_size(Vector2i(844, 390))
		_mobile_hud_enabled = true
		for frame in 12:
			await get_tree().process_frame
		await _save_shot("arena_%d_mobile.png" % arena)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_hud.hide()
		weapons.hide()
		set_physics_process(false)
		_body.position = Vector3(-19, 20, 31)
		_yaw = -0.45
		_pitch = -0.52
		_body.rotation.y = _yaw
		_cam_pivot.rotation = Vector3(_pitch, 0, 0)
		for frame in 16:
			await get_tree().process_frame
		await _save_shot("arena_%d_hero.png" % arena)
		set_physics_process(true)
		_hud.show()
		weapons.show()
	get_tree().quit()

func _run_art_qa() -> void:
	_start_from_hub(0, 5)
	_res_idx = 2
	_apply_graphics_preset()
	world.enemies_paused = true
	_mobile_hud_enabled = false
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_banner_timer = 0
	_banner_label.text = ""
	for idx in 3:
		weapons.select_weapon(idx, true)
		weapons.apply_weapon_skin(2)
		weapons.inspect_timer = 0
		for frame in 24:
			await get_tree().process_frame
		await _save_shot("atelier_weapon_%d.png" % idx)
	weapons.select_weapon(0, true)
	weapons.apply_weapon_skin(2)
	weapons.inspect_timer = 0
	for frame in 20:
		await get_tree().process_frame
	await _save_shot("atelier_pc.png")
	weapons.trigger_inspect()
	for frame in 16:
		await get_tree().process_frame
	await _save_shot("atelier_inspect.png")
	weapons.apply_weapon_skin(4)
	weapons.inspect_timer = 0
	for frame in 18:
		await get_tree().process_frame
	await _save_shot("atelier_porcelain.png")
	weapons.want_ads = true
	for frame in 18:
		await get_tree().process_frame
	await _save_shot("atelier_ads.png")
	weapons.want_ads = false
	weapons.apply_weapon_skin(2)
	weapons.inspect_timer = 0
	DisplayServer.window_set_size(Vector2i(844, 390))
	_mobile_hud_enabled = true
	for frame in 20:
		await get_tree().process_frame
	await _save_shot("atelier_mobile.png")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_toggle_shop(1)
	_shop_tab_idx = 0
	_populate_shop_cards()
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("atelier_shop.png")
	_toggle_shop(0)
	_hud.hide()
	weapons.hide()
	_body.position = Vector3(-5, 4, 21)
	_yaw = -0.18
	_pitch = -0.1
	for frame in 10:
		await get_tree().process_frame
	await _save_shot("atelier_village.png")
	get_tree().quit()

func _run_arsenal_qa() -> void:
	var arsenal = load("res://tests/arsenal_checks.gd").new()
	if not await arsenal.run(self):
		get_tree().quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_hub.page = 3
	_hub._scroll.scroll_vertical = 0
	_open_hub()
	for frame in 20:
		await get_tree().process_frame
	await _save_shot("arsenal_lobby_pc.png")
	DisplayServer.window_set_size(Vector2i(844, 390))
	for frame in 20:
		await get_tree().process_frame
	_hub._scroll.ensure_control_visible(_hub._grid.get_child(4))
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("arsenal_lobby_mobile.png")
	_start_from_hub(0, 5)
	_res_idx = 2
	_apply_graphics_preset()
	world.enemies_paused = true
	_banner_label.text = ""
	_banner_timer = 0
	_body.position = Vector3(-5, 0.1, 17)
	_yaw = -0.2
	_pitch = -0.03
	for idx in [4, 5]:
		weapons.select_weapon(idx, true)
		weapons.apply_weapon_skin(2 if idx == 4 else 4)
		weapons.inspect_timer = 0
		_mobile_hud_enabled = true
		DisplayServer.window_set_size(Vector2i(844, 390))
		for frame in 25:
			await get_tree().process_frame
		await _save_shot("arsenal_weapon_%d_mobile.png" % idx)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		_mobile_hud_enabled = false
		weapons.want_ads = true
		for frame in 25:
			await get_tree().process_frame
		await _save_shot("arsenal_weapon_%d_ads.png" % idx)
		weapons.want_ads = false
		weapons.trigger_inspect()
		for frame in 28:
			await get_tree().process_frame
		await _save_shot("arsenal_weapon_%d_inspect.png" % idx)
		_toggle_shop(1)
		_populate_shop_cards()
		for frame in 18:
			await get_tree().process_frame
		await _save_shot("arsenal_weapon_%d_shop.png" % idx)
		_toggle_shop(0)
	get_tree().quit()

func _run_navigation_qa() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for stage in [1, 3]:
		_start_from_hub(0, stage)
		_res_idx = 2
		_apply_graphics_preset()
		set_physics_process(false)
		_hud.hide()
		weapons.hide()
		_banner_label.text = ""
		_banner_timer = 0
		for actor in world.enemies:
			actor.set_physics_process(false)
		var bot: EnemyBot = world.enemies[0]
		bot.global_position = Vector3(-8.5, 0.05, 18) if stage == 1 else Vector3(0, 0.05, 6)
		bot.velocity = Vector3.ZERO
		bot._spawn_check_pending = false
		bot._has_target = false
		bot._target_player = false
		bot._target_bot = null
		bot._target_memory = Vector3(0, 3.35, 0) if stage == 1 else Vector3(0, 7.3, 0)
		bot._sense_cd = 10000
		bot._tactical_cd = 10000
		bot._tactical_until = 0
		bot._route_cd = 0
		bot._route.clear()
		bot.set_physics_process(true)
		world.enemies_paused = false
		_cam.fov = 66
		_cam.global_position = Vector3(-15, 8, 21) if stage == 1 else Vector3(5.5, 5.7, 6.8)
		_cam.look_at(Vector3(-8.5, 1.8, 13) if stage == 1 else Vector3(0, 2, 10))
		var captured := false
		for frame in 1800:
			await get_tree().physics_frame
			if not captured and bot.global_position.y > 1.4:
				await _save_shot("navigation_%d_stairs.png" % stage)
				captured = true
			if bot.global_position.distance_to(bot._target_memory) < 0.8:
				break
		print("NATIVE ROUTE stage=", stage, " bot=", bot.global_position, " steps=", bot.navigation_steps)
		world.enemies_paused = true
		_cam.global_position = Vector3(24, 22, 29)
		_cam.look_at(Vector3(0, 1.5, 0) if stage == 1 else Vector3(0, 3.5, 0))
		for frame in 12:
			await get_tree().process_frame
		await _save_shot("navigation_%d_overview.png" % stage)
	get_tree().quit()

func _run_color_qa() -> void:
	var prefix := "color_before" if OS.get_cmdline_user_args().has("--before") else "color_after"
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scenes := [
		[0, 5, Vector3(-4, 2.3, 19), Vector3(0, 1.4, 0)],
		[0, 3, Vector3(18, 10, 21), Vector3(0, 2, 2)],
		[0, 7, Vector3(-11, 3, 21), Vector3(0, 2, -4)],
		[1, 0, Vector3(7, 5, 14), Vector3(0, 1, -25)]
	]
	for spec in scenes:
		_start_from_hub(spec[0], spec[1])
		_res_idx = 0
		_apply_graphics_preset()
		set_physics_process(false)
		world.enemies_paused = true
		for actor in world.enemies + world.parkour_runners:
			actor.set_physics_process(false)
		_hud.hide()
		weapons.hide()
		_banner_timer = 0
		_banner_label.text = ""
		_cam.global_position = spec[2]
		_cam.look_at(spec[3])
		_cam.fov = 70
		for frame in 16:
			await get_tree().process_frame
		await _save_shot("%s_%d_%d.png" % [prefix, spec[0], spec[1]])
	get_tree().quit()

func _run_manual_fire_qa() -> void:
	var checks = load("res://tests/manual_fire_checks.gd").new()
	if not await checks.run(self):
		get_tree().quit(1)
		return
	DisplayServer.window_set_size(Vector2i(844, 390))
	_mobile_hud_enabled = true
	_start_from_hub(0, 5)
	_res_idx = 0
	_apply_graphics_preset()
	world.enemies_paused = true
	_cam.transform = Transform3D.IDENTITY
	_body.position = Vector3(-4, 0.1, 19)
	_yaw = -0.12
	_pitch = -0.02
	weapons.select_weapon(0, true)
	weapons.refill_all_ammo()
	weapons.fire_cd = 0
	weapons.inspect_timer = 0
	_banner_timer = 0
	_banner_label.text = ""
	for frame in 24:
		await get_tree().process_frame
	await _save_shot("color_manual_mobile_ready.png")
	var menus = load("res://tests/menu_checks.gd").new()
	Input.set_emulate_touch_from_mouse(true)
	menus.touch(self, _action_rects().fire.get_center(), true, 2)
	for frame in 5:
		await get_tree().physics_frame
	await _save_shot("color_manual_mobile_firing.png")
	menus.touch(self, _action_rects().fire.get_center(), false, 2)
	get_tree().quit()

func _run_aim_qa() -> void:
	var checks = load("res://tests/aim_checks.gd").new()
	if not await checks.run(self):
		get_tree().quit(1)
		return
	DisplayServer.window_set_size(Vector2i(844, 390))
	_mobile_hud_enabled = true
	profile.data.aim_mode = MobileAim.HYBRID
	profile.data.aim_tip_seen = false
	profile.data.hud_layout = {}
	profile.data.hud_layout_revision = 2
	_start_from_hub(0, 5)
	_res_idx = 0
	_apply_graphics_preset()
	world.enemies_paused = true
	_cam.transform = Transform3D.IDENTITY
	_body.position = Vector3(-4, 0.1, 19)
	_yaw = -0.12
	_pitch = -0.02
	weapons.select_weapon(0, true)
	weapons.refill_all_ammo()
	weapons.inspect_timer = 0
	_banner_timer = 0
	_banner_label.text = ""
	for frame in 24:
		await get_tree().process_frame
	await _save_shot("aim_mobile_ready.png")
	var menus = load("res://tests/menu_checks.gd").new()
	Input.set_emulate_touch_from_mouse(true)
	var aim: Vector2 = _action_rects().ads.get_center()
	menus.touch(self, aim, true, 2)
	menus.touch(self, aim, false, 2)
	for frame in 16:
		await get_tree().physics_frame
	await _save_shot("aim_mobile_aimed.png")
	_open_hub()
	_hub.page = 2
	_hub.refresh()
	for frame in 8:
		await get_tree().process_frame
	for child in _hub._body.get_children():
		if child is OptionButton and child.get_item_text(0).begins_with("MIRA /"):
			_hub._scroll.ensure_control_visible(child)
	for frame in 8:
		await get_tree().process_frame
	await _save_shot("aim_mobile_settings.png")
	get_tree().quit()

func _run_harbor_qa() -> void:
	var prefix := "harbor_before" if OS.get_cmdline_user_args().has("--before") else "harbor_after"
	_start_from_hub(0, 1)
	world.enemies_paused = true
	_banner_timer = 0
	_banner_label.text = ""
	for quality in [0, 2]:
		DisplayServer.window_set_size(Vector2i(844, 390))
		_mobile_hud_enabled = true
		_res_idx = quality
		_apply_graphics_preset()
		_body.position = Vector3(-11, 0.1, 17)
		_yaw = -0.32
		_pitch = -0.025
		_cam.transform = Transform3D.IDENTITY
		weapons.select_weapon(4, true)
		weapons.inspect_timer = 0
		for frame in 24:
			await get_tree().process_frame
		await _save_shot("%s_mobile_%d.png" % [prefix, quality])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_mobile_hud_enabled = false
	_body.position = Vector3(-1, 0.1, 17)
	_yaw = 0.0
	_pitch = -0.025
	_cam.transform = Transform3D.IDENTITY
	for frame in 24:
		await get_tree().process_frame
	await _save_shot(prefix + "_desktop.png")
	set_physics_process(false)
	_hud.hide()
	weapons.hide()
	_cam.global_position = Vector3(24, 22, 29)
	_cam.look_at(Vector3(0, 2, 0))
	for frame in 16:
		await get_tree().process_frame
	await _save_shot(prefix + "_overview.png")
	get_tree().quit()

func _run_large_qa() -> void:
	if OS.get_cmdline_user_args().has("--verify"):
		var checks = load("res://tests/large_arena_checks.gd").new()
		if not await checks.run(self):
			get_tree().quit(1)
			return
	for stage in [9, 10]:
		_start_from_hub(0, stage)
		world.enemies_paused = true
		profile.data.aim_tip_seen = true
		_banner_timer = 0
		_banner_label.text = ""
		for quality in [0, 2]:
			DisplayServer.window_set_size(Vector2i(844, 390))
			_mobile_hud_enabled = true
			_hud.show()
			weapons.show()
			_res_idx = quality
			_apply_graphics_preset()
			set_physics_process(true)
			_body.position = Vector3(0, 0.1, 29 if stage == 9 else 31)
			_yaw = 0.1
			_pitch = -0.025
			_cam.transform = Transform3D.IDENTITY
			weapons.select_weapon(4, true)
			for frame in 24:
				await get_tree().process_frame
			await _save_shot("large_%d_mobile_%d.png" % [stage, quality])
		DisplayServer.window_set_size(Vector2i(1280, 720))
		set_physics_process(false)
		_hud.hide()
		weapons.hide()
		_cam.fov = 56
		_cam.global_position = Vector3(62, 66, 78)
		_cam.look_at(Vector3(0, 0, 0))
		for frame in 16:
			await get_tree().process_frame
		await _save_shot("large_%d_overview.png" % stage)
	if OS.get_cmdline_user_args().has("--production"):
		await _run_team_qa()
		return
	get_tree().quit()

func _run_team_qa() -> void:
	if OS.get_cmdline_user_args().has("--verify"):
		var tests = load("res://tests/team_checks.gd").new()
		if not await tests.run(self):
			get_tree().quit(1)
			return
	DisplayServer.window_set_size(Vector2i(844, 390))
	profile.data.match_kind = CombatMatch.CTF
	profile.data.large_population = 24
	profile.data.aim_tip_seen = true
	_hub.mode = 0
	_hub.page = 0
	_open_hub()
	for frame in 12:
		await get_tree().process_frame
	await _save_shot("teams_mobile_lobby.png")
	for stage in [1, 9, 10]:
		_start_from_hub(0, stage)
		set_physics_process(true)
		_cam.transform = Transform3D.IDENTITY
		world.enemies_paused = true
		_mobile_hud_enabled = true
		_res_idx = 0
		_apply_graphics_preset()
		_banner_timer = 0
		_banner_label.text = ""
		world.player_spawn_guard = 0
		weapons.select_weapon(4, true)
		for frame in 20:
			await get_tree().process_frame
		await _save_shot("teams_%d_ctf.png" % stage)
		if stage == 10:
			world.enemies_paused = false
			for frame in 900:
				await get_tree().physics_frame
			await _save_shot("teams_10_live.png")
			_toggle_scoreboard()
			for frame in 12:
				await get_tree().process_frame
			await _save_shot("teams_10_scoreboard.png")
	get_tree().quit()
