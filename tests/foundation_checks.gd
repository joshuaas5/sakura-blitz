extends RefCounted
## Integration regressions, called by the game's --test entry point.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run(game: SakuraBlitzMain) -> bool:
	_test_profile()
	game._start_from_hub(0, 0)
	game._mobile_hud_enabled = true
	var jump: Rect2 = game._action_rects().jump
	var joystick: Vector2 = game._mobile_rect("joystick").get_center()
	game._handle_touch(2, joystick, true)
	game._handle_touch(7, jump.get_center(), true)
	game._handle_touch_drag(2, joystick + Vector2(20, -50), Vector2(20, -50))
	check(game._mobile_move_vec.length() > 0, "Joystick receives its own finger")
	var yaw: float = game._yaw
	game._handle_touch_drag(18, Vector2(800, 500), Vector2(100, 0))
	check(game._yaw == yaw, "Unowned finger drag must not rotate camera")
	game._handle_touch_drag(7, jump.get_center(), Vector2(30, 0))
	check(game._yaw != yaw, "Jump finger can look while held")
	game._handle_touch(2, Vector2(500, 500), false)
	check(game._mobile_jump_held and game._mobile_move_vec == Vector2.ZERO, "Joystick release must preserve another finger's jump")
	game._handle_touch(7, Vector2(20, 20), false)
	check(not game._mobile_jump_held and game._look_touch_idx == -1, "Off-button release clears the owning finger")
	game._handle_touch(4, game._action_rects().fire.get_center(), true)
	game._open_hub()
	check(not game._mobile_fire_held and game._touch_actions.is_empty(), "Opening hub clears held input")
	var before: Vector3 = game.world.enemies[0].position
	for i in 8:
		await game.get_tree().physics_frame
	check(game.world.enemies[0].position == before, "Hub freezes combat simulation")
	game._resume_from_hub()
	check(game.world.process_mode == Node.PROCESS_MODE_INHERIT, "Resume restores world processing")
	game._toggle_shop(1)
	check(game._paused and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Shop freezes simulation too")
	game._toggle_shop(0)
	check(not game._paused, "Shop closes back into gameplay")
	var base_mag := game.weapons.max_mag_for(0)
	game.weapons.weapon_levels[0] = 4
	check(game.weapons.max_mag_for(0) == base_mag, "Upgrade cannot increase magazine capacity")
	for skin in WeaponRig.WEAPON_SKINS:
		check(skin.dmg_mult == 1.0 and skin.rate_mult == 1.0, "Skins cannot stack hidden combat bonuses")
	for skin in WeaponRig.CHAR_SKINS:
		check(skin.speed_bonus == 0, "Operator cosmetics cannot change race speed")
	game.weapons.weapon_levels[0] = 1
	var owned_weapons := game.unlocked_weapon_skins.duplicate()
	var owned_characters := game.unlocked_char_skins.duplicate()
	var shortcut_coins := game.coins
	for shortcut in [KEY_5, KEY_7]:
		var key := InputEventKey.new()
		key.keycode = shortcut
		key.pressed = true
		game._input(key)
	check(game.unlocked_weapon_skins == owned_weapons and game.unlocked_char_skins == owned_characters, "Cosmetic shortcuts must not unlock unearned items")
	check(game.coins == shortcut_coins, "Cycling owned cosmetics must not spend coins")
	var root_count := game.world.get_child_count()
	for cycle in 2:
		for mode in 2:
			for stage in SakuraHub.MAPS[mode].size():
				game._start_from_hub(mode, stage)
				await game.get_tree().physics_frame
				check(game.world.get_child_count() == root_count, "Map switching cannot retain previous props (%d/%d/%d)" % [cycle, mode, stage])
				check(game.world._glb_cache.values().all(func(v): return v is PackedScene), "Model cache owns resources, not orphan nodes")
	for stage in 6:
		game._start_from_hub(1, stage)
		game.set_physics_process(false)
		game.world.enemies_paused = true
		game.world._start_gate_node.position.y = -14
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		# Every safe-route waypoint has a real static landing, not just a visual.
		var space := game.world.get_world_3d().direct_space_state
		for waypoint in game.world.race_waypoints:
			var ray := PhysicsRayQueryParameters3D.create(waypoint + Vector3.UP * 1.0, waypoint - Vector3.UP * 1.0, 1)
			check(not space.intersect_ray(ray).is_empty(), "Course %d safe waypoint has collision: %s" % [stage, waypoint])
		# Play each side lane using the actual CharacterBody controller and jump physics.
		for sector in 8:
			var z := 8.0 - sector * 26.0
			var x := 8.0 if sector % 2 == 0 else -8.0
			game._body.position = Vector3(x, 0.2, z + 1.0)
			game._body.velocity = Vector3.ZERO
			game._jump_grace = 0
			game._sprinting = true
			game._crouching = false
			for frame in 360:
				await game.get_tree().physics_frame
				game._jump_grace = maxf(0, game._jump_grace - 1.0 / 60.0)
				game._mantle_cooldown = maxf(0, game._mantle_cooldown - 1.0 / 60.0)
				game._process_crisp_ground_and_parkour(1.0 / 60.0, Vector3.FORWARD, true)
				if game._body.position.y < -1 or game._body.position.z < z - 23:
					break
			check(game._body.position.y > -1 and game._body.position.z < z - 23, "Course %d sector %d safe route traversable with hold-jump" % [stage, sector])
		# Rings are claimed once even after standing still / returning later.
		game.world.kz_running = true
		game.world.player_pos = game.world.kz_rings[0].pos - Vector3(0, 0.9, 0)
		var coins_before := game.coins
		for frame in 8:
			await game.get_tree().physics_frame
		check(game.coins == coins_before + 10, "Course %d ring rewarded once" % stage)
		check(game.world.kz_rings[0].collected and not game.world.kz_rings[0].node.visible, "Collected ring disappears")
		# Cannot skip the course by teleporting directly to the finish.
		game.world.player_pos = game.world.kz_finish_pad
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		check(game.world.player_race_place == 0, "Finish requires all checkpoints")
		for cp in game.world.kz_checkpoints:
			game.world.player_pos = cp.pos
			await game.get_tree().physics_frame
			await game.get_tree().physics_frame
		check(game.world.kz_active_stage == 8, "Checkpoints advance in sequence")
		game.world.player_pos = game.world.kz_finish_pad
		for frame in 4:
			await game.get_tree().physics_frame
		check(game.world.player_race_place > 0 and not game.world.kz_running, "Finishing after all checkpoints completes the race")
		check(is_instance_valid(game._result_panel) and game._result_panel.visible, "Race completion opens result actions")
		var reward_total := game.coins
		for frame in 4:
			await game.get_tree().physics_frame
		check(game.coins == reward_total, "Finish reward cannot repeat while on finish pad")
	game.set_physics_process(true)
	await _test_mantle(game)
	await _test_art_integration(game)
	print("FOUNDATION: %d checks, %d failures" % [checks, failures.size()])
	return failures.is_empty()

func _test_profile() -> void:
	var path := "user://foundation_test_profile.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var profile := PlayerProfile.new(path)
	for i in 50:
		profile.record_kill(0)
	check(profile.data.weapon_kills == [50, 0, 0, 0, 0, 0], "Mastery attributed to the firing weapon")
	profile.data.weapon_skins[0] = 1
	profile.data.suppressors[0] = true
	profile.record_finish(2, 65.5)
	profile.record_finish(2, 70.0)
	check(profile.data.best_times[2] == 65.5, "A slower finish cannot overwrite a record")
	check(profile.claim_daily(), "Daily challenge can be claimed when completed")
	var coins: int = profile.data.coins
	check(not profile.claim_daily() and profile.data.coins == coins, "Daily claim is idempotent")
	check(profile.write_save() == OK, "Profile saves successfully")
	var restored := PlayerProfile.new(path)
	restored.read_save()
	check(restored.data.weapon_skins[0] == 1 and restored.data.weapon_kills[0] == 50, "Gold and kills survive reopening")
	check(not restored.data.suppressors[0], "Suppressor cannot equip before 100 kills")
	check(not restored.claim_daily(), "Restart cannot reset the daily claim")
	check(restored.data.best_times[2] == 65.5, "Course record survives reopening")
	for i in 50:
		restored.record_kill(0)
	restored.data.suppressors[0] = true
	check(restored.write_save() == OK, "Second profile save creates backup")
	var equipped := PlayerProfile.new(path)
	equipped.read_save()
	check(equipped.data.suppressors[0], "100-kill cosmetic persists")
	print("EXPECTED DIAGNOSTIC: deliberately corrupting a test save to verify backup recovery")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[broken config")
	file.close()
	var backup := PlayerProfile.new(path)
	backup.read_save()
	check(backup.loaded_from_backup and backup.data.weapon_kills[0] == 50, "Corrupt save recovers previous valid backup")
	check(backup.write_save() == OK, "Recovered profile can be saved again")
	backup.refresh_day("2000-01-01")
	check(not backup.data.daily_claimed and backup.data.daily_kills == 0, "Day rollover resets challenge")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func _test_mantle(game: SakuraBlitzMain) -> void:
	game._start_from_hub(1, 0)
	game.set_physics_process(false)
	game.world.enemies_paused = true
	# Isolated block outside the course: a reachable lip and an obstructed variant.
	game.world.box(game.world, 39, 0, -2, 2, 0.9, 2, Color.WHITE, true)
	game._body.position = Vector3(40, 0, 0.45)
	game._body.velocity = Vector3.ZERO
	game._mantle_cooldown = 0
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	check(game._try_mantle(Vector3.FORWARD), "Mantle lifts onto a reachable ledge")
	check(game._body.position.y > 0.9, "Mantle places feet above the top face")
	game.world.box(game.world, 39, 2.0, -2, 2, 0.3, 3, Color.WHITE, true)
	game._body.position = Vector3(40, 0, 0.45)
	game._mantle_cooldown = 0
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	check(not game._try_mantle(Vector3.FORWARD), "Mantle rejects low ceilings")
	game.set_physics_process(true)


func _test_art_integration(game: SakuraBlitzMain) -> void:
	game._start_from_hub(0, 5)
	game.set_physics_process(false)
	game.world.enemies_paused = true
	await game.get_tree().physics_frame
	var rig := game.weapons
	var camera_pose := game._cam.transform
	game._cam.look_at(game._cam.global_position + Vector3.UP, Vector3.FORWARD)
	for i in 3:
		rig.select_weapon(i, true)
		check(rig._mag_nodes[i].get_child_count() > 0, "Imported weapon %d has a moving magazine" % i)
		check(rig._bolt_nodes[i].get_child_count() > 0, "Imported weapon %d has a moving action" % i)
		rig.ammo[i] = rig.max_mag_for(i) - 2
		rig.start_reload()
		rig.tick_viewmodel(0.5, 0, true, false, false)
		check(rig._mag_nodes[i].position.y < -0.05, "Imported magazine visibly leaves the receiver during reload")
		rig.tick_viewmodel(0.8, 0, true, false, false)
		check(not rig.is_reloading and rig.ammo[i] == rig.max_mag_for(i), "Imported weapon reload replenishes ammunition")
		check(rig._mag_nodes[i].position.is_equal_approx(rig._mag_rest_pos[i]), "Reload restores imported magazine position")
		rig.fire_cd = 0
		check(rig.try_fire(0), "Imported weapon can shoot")
		check(rig.ammo[i] == rig.max_mag_for(i) - 1, "Imported weapon shot consumes exactly one round")
		check(absf(rig._muzzle_flash.position.z - [-0.57, -0.80, -0.28][i]) < 0.01, "Muzzle effect follows the imported barrel")
		rig.set_suppressor(i, true)
		check(rig._suppressor_meshes[i].visible, "Imported suppressor can be equipped")
		rig.set_suppressor(i, false)
	game._cam.transform = camera_pose
	var space := game.world.get_world_3d().direct_space_state
	for spawn in [game.world._current_pvp_spawn] + game.world.tr_spawns:
		var ground := PhysicsRayQueryParameters3D.create(spawn + Vector3.UP, spawn - Vector3.UP, 1)
		check(not space.intersect_ray(ground).is_empty(), "Every village spawn has real ground")
	var fountain := PhysicsRayQueryParameters3D.create(Vector3(0, 0.4, -3), Vector3(0, 0.4, -10), 1)
	check(not space.intersect_ray(fountain).is_empty(), "Village fountain is solid cover")
	var quality := game._res_idx
	game._res_idx = 0
	game._apply_graphics_preset()
	check(not game.world.sun.shadow_enabled, "Lightest graphics preset disables village shadows")
	game._res_idx = 2
	game._apply_graphics_preset()
	check(game.world.sun.shadow_enabled, "High graphics preset enables village shadows")
	game._res_idx = quality
	game._apply_graphics_preset()
	var old_size := game.size
	for dimensions in [Vector2(854, 480), Vector2(1280, 720), Vector2(1040, 480)]:
		game.size = dimensions
		var rects := game._action_rects()
		for action in rects:
			check(Rect2(Vector2.ZERO, dimensions).encloses(rects[action]), "Touch action stays inside landscape viewport")
			for other in rects:
				if action != other:
					check(not rects[action].intersects(rects[other]), "Touch actions cannot overlap")
	game.size = old_size
	game._atelier.sync()
	check(game._atelier.pieces.ammo_text.text.contains(str(game._cur_ammo_cached)), "Native HUD displays live ammunition")
	check(game._handle_hud_tap_or_click(AtelierHud.pause_rect(game).get_center(), true), "New pause icon opens hub")
	check(game._hub_open, "Pause icon actually pauses the match")
	game._resume_from_hub()
	game.set_physics_process(true)
