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
	var window_size := g.get_window().size
	var old_emulation := Input.is_emulating_touch_from_mouse()
	var menus = load("res://tests/menu_checks.gd").new()
	var path := "user://manual_fire_migration.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("player", "auto_fire", true)
	cfg.set_value("player", "coins", 4321)
	cfg.set_value("player", "selected_weapon", 4)
	cfg.save(path)
	var profile := PlayerProfile.new(path)
	profile.read_save()
	check(not profile.data.auto_fire and profile.data.coins == 4321 and profile.data.selected_weapon == 4, "Legacy auto-fire is disabled without losing wallet or loadout")
	check(not PlayerProfile.defaults().auto_fire, "New profiles require manual firing")
	DirAccess.remove_absolute(path)
	g.get_window().size = Vector2i(844, 390)
	Input.set_emulate_touch_from_mouse(true)
	g.profile.data.hud_layout = {}
	g.profile.data.hud_left_handed = false
	g._start_from_hub(0, 5)
	g._mobile_hud_enabled = true
	g._mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	g.world.enemies_paused = true
	for enemy in g.world.enemies:
		enemy.set_physics_process(false)
	# A visible real collider inside the aim cone reproduces the former auto-trigger.
	g.world.box(g.world, 70, -0.5, -10, 12, 0.5, 16, Color.WHITE, true)
	var bot: EnemyBot = g.world.enemies[0]
	bot.global_position = Vector3(75, 0.05, -5)
	bot.hp = 10000
	g._body.global_position = Vector3(75, 0.05, 3)
	g._body.velocity = Vector3.ZERO
	g._yaw = 0
	g._pitch = -0.035
	g._clear_touch_state()
	g.weapons.select_weapon(0, true)
	g.weapons.refill_all_ammo()
	g.weapons.fire_cd = 0
	g.set_physics_process(true)
	var initial_ammo: int = g.weapons.ammo[0]
	var yaw := g._yaw
	var pitch := g._pitch
	await frames(g, 45)
	check(g.weapons.ammo[0] == initial_ammo and bot.hp == 10000, "Aiming at an enemy without touching fire cannot shoot")
	check(g._yaw == yaw and g._pitch == pitch, "Idle mobile camera is not pulled toward enemies")
	check(g._atelier.pieces.fire_hint.visible and g._atelier.pieces.fire_hint.text == "ATIRAR", "Mobile firing button is explicitly labeled")
	var fire: Vector2 = g._action_rects().fire.get_center()
	var joy := g._mobile_rect("joystick").get_center()
	menus.touch(g, joy, true, 1)
	menus.touch(g, fire, true, 2)
	await frames(g, 20)
	check(initial_ammo - int(g.weapons.ammo[0]) >= 2, "Holding the native fire touch sustains an automatic weapon")
	yaw = g._yaw
	menus.drag(g, fire, fire + Vector2(25, 0), 2)
	check(g._yaw != yaw and g._mobile_fire_held and g._look_touch_idx == 2, "The same firing finger drags the camera")
	menus.touch(g, joy, false, 1)
	check(g._mobile_fire_held and g._look_touch_idx == 2, "Releasing movement cannot cancel the firing finger")
	menus.touch(g, Vector2(20, 20), false, 2)
	var stopped: int = g.weapons.ammo[0]
	await frames(g, 20)
	check(g.weapons.ammo[0] == stopped and not g._mobile_fire_held, "Releasing fire outside the button stops shooting immediately")
	for idx in [1, 2, 5]:
		g._clear_touch_state()
		g.weapons.select_weapon(idx, true)
		g.weapons.refill_all_ammo()
		g.weapons.fire_cd = 0
		var ammo: int = g.weapons.ammo[idx]
		menus.touch(g, fire, true, 2)
		await frames(g, int(float(WeaponCatalog.DEFINITIONS[idx].rate) * 60) + 20)
		check(g.weapons.ammo[idx] == ammo - 1, "Semi-auto weapon %d fires once per press, even after its cooldown" % idx)
		menus.touch(g, fire, false, 2)
		await frames(g, 2)
		g.weapons.fire_cd = 0
		ammo = g.weapons.ammo[idx]
		# Complete tap between physics frames must be remembered as player intent.
		menus.touch(g, fire, true, 2)
		menus.touch(g, fire, false, 2)
		await frames(g, 2)
		check(g.weapons.ammo[idx] == ammo - 1, "Fast tap between frames fires semi-auto weapon %d exactly once" % idx)
	g.weapons.select_weapon(0, true)
	g.weapons.refill_all_ammo()
	g.weapons.fire_cd = 0
	menus.touch(g, fire, true, 2)
	menus.touch(g, fire, false, 2)
	g._open_hub()
	g._resume_from_hub()
	await frames(g, 3)
	check(g.weapons.ammo[0] == g.weapons.max_mag_for(0) and not g._fire_press_pending, "Pause discards pending taps instead of firing on resume")
	g._fire_press_pending = true
	g._killcam_active = true
	g._tick_weapon_trigger(0)
	check(g.weapons.ammo[0] == g.weapons.max_mag_for(0) and not g._fire_press_pending, "Killcam cannot consume ammunition or retain a pending trigger")
	g._killcam_active = false
	g._fire_press_pending = true
	g._toggle_mobile_hud()
	check(not g._fire_press_pending and g._touch_actions.is_empty(), "Changing control mode cannot keep a queued shot or a held finger")
	g._start_from_hub(1, 0)
	g._fire_press_pending = true
	var knife_ammo: int = g.weapons.ammo[3]
	g._tick_weapon_trigger(0)
	check(g.weapons.ammo[3] == knife_ammo and not g._fire_press_pending, "Parkour cannot execute a pending combat trigger")
	g.profile.data = saved
	g._apply_profile_settings()
	g._clear_touch_state()
	g.get_window().size = window_size
	Input.set_emulate_touch_from_mouse(old_emulation)
	print("MANUAL FIRE: %d checks, %d failures" % [checks, failures])
	return failures == 0
