extends RefCounted
var checks := 0
var failures := 0
var hits: Array[Dictionary] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func capture_hit(result: Dictionary, _idx: int) -> void:
	hits.append(result)

func run(g: SakuraBlitzMain) -> bool:
	var saved := g.profile.data.duplicate(true)
	_test_migration()
	check(WeaponCatalog.DEFINITIONS.size() == 6, "Six distinct weapons are available")
	check(WeaponCatalog.damage_at_distance(5, 3) == 14 and WeaponCatalog.damage_at_distance(5, 25) == 3, "Shotgun loses damage at distance")
	check(WeaponCatalog.damage_at_distance(4, 8) == 24 and WeaponCatalog.damage_at_distance(4, 40) == 12, "SMG has a bounded close-range role")
	g._start_from_hub(0, 5)
	g.world.enemies_paused = true
	g.set_physics_process(false)
	var camera_transform := g._cam.transform
	var rig := g.weapons
	for idx in [4, 5]:
		rig.select_weapon(idx, true)
		check(is_instance_valid(rig._mag_nodes[idx]) and rig._mag_nodes[idx].get_child_count() > 0, "New weapon has an articulated magazine")
		check(is_instance_valid(rig._bolt_nodes[idx]) and rig._bolt_nodes[idx].get_child_count() > 0, "New weapon has an articulated bolt")
		rig.ammo[idx] = 1
		rig.reserve[idx] = 30
		rig.start_reload()
		check(rig.is_reloading and rig.reload_duration == float(WeaponCatalog.DEFINITIONS[idx].reload), "Each new weapon has its own reload timing")
		rig.tick_viewmodel(rig.reload_duration * 0.42, 0, true, false, false)
		rig.select_weapon(0, true)
		check(not rig.is_reloading and rig.ammo[idx] == 1 and rig.reserve[idx] == 30, "Switching cancels reload without creating ammo")
		check(rig._mag_nodes[idx].position == rig._mag_rest_pos[idx], "Cancelled reload restores magazine geometry")
		rig.select_weapon(idx, true)
		rig.start_reload()
		rig.tick_viewmodel(rig.reload_duration + 0.01, 0, true, false, false)
		check(rig.ammo[idx] == rig.max_mag_for(idx) and rig.ammo[idx] + rig.reserve[idx] == 31, "Reload conserves total ammunition")
		rig.set_suppressor(idx, true)
		check(rig._suppressor_meshes[idx].visible, "New firearm supports its mastery suppressor")
		rig.set_suppressor(idx, false)
		rig.apply_weapon_skin(2, false)
		check(WeaponRig.WEAPON_SKINS[2].dmg_mult == 1 and WeaponRig.WEAPON_SKINS[2].rate_mult == 1, "Cosmetic finish preserves weapon stats")
	# A real collision target outside the arena isolates pellet accounting and occlusion.
	g.world.box(g.world, 65, -0.5, -15, 25, 0.5, 25, Color.WHITE, true)
	for other in g.world.enemies:
		other.set_physics_process(false)
	var bot: EnemyBot = g.world.enemies[0]
	bot.global_position = Vector3(75, 0.05, 0)
	bot.hp = 1000
	g._cam.global_position = Vector3(75, 0.9, 3)
	g._cam.look_at(Vector3(75, 0.9, 0))
	rig.select_weapon(5, true)
	rig.apply_weapon_skin(0, false)
	rig.weapon_levels[5] = 1
	rig.ads_alpha = 1
	rig.ammo[5] = 8
	rig.fire_cd = 0
	rig.hit_registered.connect(capture_hit)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	check(rig.try_fire(0), "Shotgun fires against physical target")
	check(rig.ammo[5] == 7, "Eight pellets consume exactly one shell")
	check(hits.size() == 1 and hits[0].dmg == 112, "Eight body pellets aggregate to one 112-damage event")
	check(not rig.try_fire(0) and rig.ammo[5] == 7, "Cooldown rejects duplicate trigger without consuming ammo")
	g._cam.global_position = Vector3(75, 1.45, 1)
	g._cam.look_at(Vector3(75, 1.45, 0))
	hits.clear()
	rig.fire_cd = 0
	rig.try_fire(0)
	check(hits.size() == 1 and hits[0].dmg == 146 and hits[0].headshot, "Head pellets receive exactly one multiplier each")
	bot.hp = 888
	g._cam.global_position = Vector3(75, 0.9, 3)
	g._cam.look_at(Vector3(75, 0.9, 0))
	g.world.box(g.world, 74, 0, 1.3, 2, 3, 0.2, Color.WHITE, true)
	var wall_collision := g.world._stage_root.get_child(g.world._stage_root.get_child_count() - 1)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	hits.clear()
	rig.fire_cd = 0
	rig.try_fire(0)
	check(hits.is_empty() and bot.hp == 888, "Solid cover blocks every pellet")
	wall_collision.queue_free()
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	bot.hp = 100
	var before_kills := g.kills
	var before_mastery: int = g.profile.data.weapon_kills[5]
	hits.clear()
	rig.fire_cd = 0
	rig.try_fire(0)
	check(hits.size() == 1 and hits[0].killed, "A close-range shotgun hit kills once")
	check(g.kills == before_kills + 1 and g.profile.data.weapon_kills[5] == before_mastery + 1, "Pellets award one frag and one mastery increment")
	rig.hit_registered.disconnect(capture_hit)
	g._cam.transform = camera_transform
	g.profile.data.selected_weapon = 4
	g._start_from_hub(1, 0)
	check(rig.current_idx == 3 and g.profile.data.selected_weapon == 4, "Parkour knife preserves selected combat weapon")
	g._apply_profile_settings()
	check(rig.current_idx == 3 and g.profile.data.selected_weapon == 4, "Settings and arsenal preserve race knife without replacing combat loadout")
	g._start_from_hub(0, 5)
	check(rig.current_idx == 4, "Returning to combat restores preferred firearm")
	await _test_touch(g)
	g.profile.data = saved
	g._apply_profile_settings()
	g.set_physics_process(true)
	print("ARSENAL: %d checks, %d failures" % [checks, failures])
	return failures == 0

func _test_migration() -> void:
	var path := "user://arsenal_migration_test.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("player", "coins", 12345)
	cfg.set_value("player", "weapon_kills", [100, 50, 12, 7])
	cfg.set_value("player", "weapon_skins", [1, 1, 0, 0])
	cfg.set_value("player", "weapon_levels", [4, 2, 1, 3])
	cfg.set_value("player", "suppressors", [true, false, false, true])
	cfg.save(path)
	var profile := PlayerProfile.new(path)
	profile.read_save()
	check(profile.data.weapon_kills == [100, 50, 12, 7, 0, 0], "Legacy mastery migrates without reordering knife")
	check(profile.data.weapon_levels == [4, 2, 1, 3, 1, 1] and profile.data.coins == 12345, "Legacy upgrades and wallet survive migration")
	check(profile.data.suppressors == [true, false, false, false, false, false], "Legacy suppressors validate all six slots")
	profile.data.selected_weapon = 5
	profile.data.weapon_kills[5] = 100
	profile.data.weapon_skins[5] = 1
	profile.data.suppressors[5] = true
	profile.write_save()
	var reopened := PlayerProfile.new(path)
	reopened.read_save()
	check(reopened.data.selected_weapon == 5 and reopened.data.weapon_skins[5] == 1 and reopened.data.suppressors[5], "New loadout, gold and suppressor persist after reopening")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func _test_touch(g: SakuraBlitzMain) -> void:
	var menus = load("res://tests/menu_checks.gd").new()
	var old_window := g.get_window().size
	var old_emulation := Input.is_emulating_touch_from_mouse()
	Input.set_emulate_touch_from_mouse(true)
	g.get_window().size = Vector2i(844, 390)
	g._hub.page = 0
	g._open_hub()
	await menus.wait_frames(g)
	await menus.tap(g, menus.button(g._hub._fixed_header, "Arsenal"))
	check(g._hub.page == 3 and g._hub._grid.get_child_count() == 6, "Native touch opens six-weapon arsenal")
	var scroll := g._hub._scroll
	var equip: Button = menus.button(g._hub._grid.get_child(5), "EQUIPAR")
	scroll.ensure_control_visible(equip)
	await menus.wait_frames(g)
	await menus.tap(g, equip)
	check(g.profile.data.selected_weapon == 5, "Native mobile touch equips shotgun from scrolling arsenal")
	await menus.tap(g, menus.button(g._hub._fixed_header, "Jogar"))
	g._hub.mode = 0
	g._hub.refresh()
	scroll.scroll_vertical = 0
	await menus.wait_frames(g)
	await menus.tap(g, menus.button(g._hub._grid.get_child(0), "JOGAR"))
	check(not g._hub_open and g.weapons.current_idx == 5, "Play starts an arena with selected shotgun")
	g.get_window().size = old_window
	Input.set_emulate_touch_from_mouse(old_emulation)
