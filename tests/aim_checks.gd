extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func frames(g: Node, count: int) -> void:
	for frame in count:
		await g.get_tree().physics_frame

func run(g: SakuraBlitzMain) -> bool:
	var saved := g.profile.data.duplicate(true)
	var old_size := g.get_window().size
	var old_emulation := Input.is_emulating_touch_from_mouse()
	var old_assist := g._mobile_aim_assist
	var menus = load("res://tests/menu_checks.gd").new()
	_test_profile()
	g.get_window().size = Vector2i(844, 390)
	Input.set_emulate_touch_from_mouse(true)
	g.profile.data.hud_layout = {}
	g.profile.data.hud_layout_revision = 2
	g.profile.data.hud_left_handed = false
	g.profile.data.aim_mode = MobileAim.HYBRID
	g.profile.data.aim_tip_seen = false
	g._start_from_hub(0, 5)
	g._mobile_hud_enabled = true
	g._mobile_aim_assist = false
	g._mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	g.world.enemies_paused = true
	g.weapons.select_weapon(0, true)
	g.weapons.refill_all_ammo()
	g.weapons.fire_cd = 0
	g._clear_touch_state()
	g.set_physics_process(true)
	await frames(g, 2)
	var aim: Vector2 = g._action_rects().ads.get_center()
	var fire: Vector2 = g._action_rects().fire.get_center()
	var joy := g._mobile_rect("joystick").get_center()
	check(g._action_rects().ads.size.x > g._action_rects().reload.size.x * 1.4, "New aim button has a larger, shared visual and touch footprint")
	g._atelier.sync()
	check(g._atelier.pieces.aim_label.visible and g._atelier.pieces.aim_label.text == "MIRAR", "Aim button explains its purpose before interaction")
	var shots: Array[int] = [0]
	var record_shot := func(_idx: int, _pitch: float, _yaw: float): shots[0] += 1
	g.weapons.shot_fired.connect(record_shot)
	var ammo: int = g.weapons.ammo[0]
	menus.touch(g, joy, true, 1)
	menus.drag(g, joy, joy + Vector2(0, -60), 1)
	menus.touch(g, aim, true, 2)
	check(g.weapons.want_ads and not g._mobile_fire_held and not g._fire_press_pending, "Pressing aim opens sights without requesting a shot")
	await frames(g, 8)
	check(g.weapons.ads_alpha > 0.9 and not g._sprinting, "Aim opens even with the sprint joystick pushed forward")
	check(g.weapons.ammo[0] == ammo, "Aim never spends ammunition")
	menus.touch(g, aim, false, 2)
	check(g.weapons.want_ads and g._mobile_aim.latched, "Short hybrid tap keeps aim open for two-thumb play")
	g._atelier.sync()
	check(g._atelier.pieces.aim_label.text == "MIRANDO" and not g._atelier.pieces.hint.visible, "HUD shows active aim and retires the first-use prompt")
	menus.touch(g, fire, true, 3)
	var yaw := g._yaw
	menus.drag(g, fire, fire + Vector2(12, 0), 3)
	check(g._yaw != yaw and g.weapons.want_ads, "Firing finger can adjust latched aim while the other thumb moves")
	await frames(g, 2)
	check(shots[0] > 0, "Firing while aimed still requires the separate manual trigger")
	menus.touch(g, fire, false, 3)
	menus.touch(g, joy, false, 1)
	menus.touch(g, aim, true, 2)
	menus.touch(g, aim, false, 2)
	check(not g.weapons.want_ads and not g._mobile_aim.latched, "Second hybrid tap closes aim")
	await frames(g, 10)
	menus.touch(g, aim, true, 2)
	await frames(g, 18)
	yaw = g._yaw
	menus.drag(g, aim, aim + Vector2(15, 0), 2)
	check(g._yaw != yaw and g._look_touch_idx == 2, "Holding and dragging aim owns the camera with the same finger")
	menus.touch(g, Vector2(10, 10), false, 2)
	check(not g.weapons.want_ads and not g._mobile_aim.latched, "Long hybrid hold closes on release anywhere")
	menus.touch(g, aim, true, 2)
	menus.drag(g, aim, aim + Vector2(15, 0), 2)
	menus.touch(g, aim, false, 2)
	check(not g.weapons.want_ads, "Short drag is a temporary aim gesture rather than an accidental latch")
	menus.touch(g, aim, true, 2)
	var cancel := InputEventScreenTouch.new()
	cancel.index = 2
	cancel.canceled = true
	cancel.position = g.get_viewport().get_final_transform() * aim
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	check(not g.weapons.want_ads and g._mobile_aim.touches.is_empty(), "Canceled touch cannot latch aim")
	for mode in [MobileAim.TAP, MobileAim.HOLD]:
		g._clear_touch_state()
		g.profile.data.aim_mode = mode
		menus.touch(g, aim, true, 2)
		await frames(g, 18)
		menus.touch(g, aim, false, 2)
		check(g.weapons.want_ads == (mode == MobileAim.TAP), "Explicit tap and hold modes preserve their distinct release behavior")
	g._clear_touch_state()
	g.profile.data.aim_mode = MobileAim.HOLD
	menus.touch(g, aim, true, 2)
	menus.touch(g, fire, true, 3)
	menus.touch(g, aim, false, 2)
	yaw = g._yaw
	menus.drag(g, fire, fire + Vector2(12, 0), 3)
	check(g._look_touch_idx == 3 and g._yaw != yaw and g._mobile_fire_held, "Remaining firing finger takes over camera ownership after aim release")
	menus.touch(g, fire, false, 3)
	# Zoom changes drag sensitivity without changing saved player preferences.
	g.set_physics_process(false)
	var turns: Array[float] = []
	for idx in [0, 1]:
		g.weapons.select_weapon(idx, true)
		g.weapons.ads_alpha = 1
		g._look_touch_idx = 4
		yaw = g._yaw
		g._handle_touch_drag(4, Vector2.ZERO, Vector2(10, 0))
		turns.append(absf(g._yaw - yaw))
	check(turns[1] < turns[0] and turns[1] > 0, "Sniper drag is finer than rifle drag at full zoom")
	g.set_physics_process(true)
	g._clear_touch_state()
	g.profile.data.aim_mode = MobileAim.TAP
	menus.touch(g, aim, true, 2)
	menus.touch(g, aim, false, 2)
	g._open_hub()
	g._resume_from_hub()
	menus.touch(g, aim, false, 2)
	await frames(g, 2)
	check(not g.weapons.want_ads and not g._mobile_aim.latched, "Pause clears latched aim and late releases cannot restore it")
	g.weapons.shot_fired.disconnect(record_shot)
	g.profile.data = saved
	g._clear_touch_state()
	g._apply_profile_settings()
	g._mobile_aim_assist = old_assist
	g.get_window().size = old_size
	Input.set_emulate_touch_from_mouse(old_emulation)
	print("AIM: %d checks, %d failures" % [checks, failures])
	return failures == 0

func _test_profile() -> void:
	var path := "user://aim_layout_migration.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("player", "hud_layout", {"ads": Vector4(0.6, 0.5, 1.2, 0.8)})
	cfg.set_value("player", "coins", 5432)
	cfg.save(path)
	var profile := PlayerProfile.new(path)
	profile.read_save()
	var rectangles := MobileLayout.rects(Rect2(0, 0, 844, 390), profile.data)
	check(profile.data.hud_layout_revision == 1 and is_equal_approx(rectangles.ads.size.x, 62 * 1.2), "Old custom aim controls keep their exact size when upgraded")
	check(profile.data.coins == 5432 and profile.data.aim_mode == MobileAim.HYBRID, "Aim preferences migrate without changing the wallet")
	profile.data.aim_mode = MobileAim.HOLD
	profile.data.aim_tip_seen = true
	profile.write_save()
	var reopened := PlayerProfile.new(path)
	reopened.read_save()
	check(reopened.data.aim_mode == MobileAim.HOLD and reopened.data.aim_tip_seen and reopened.data.hud_layout_revision == 1, "Aim mode and custom-layout revision survive reopening")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
