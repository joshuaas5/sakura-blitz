extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run(g: SakuraBlitzMain) -> bool:
	var previous := g.profile.data.duplicate(true)
	g.set_physics_process(false)
	for stage in SakuraWorld.COMBAT_STAGE_DEFS.size():
		g._start_from_hub(0, stage)
		g.world.enemies_paused = true
		await g.get_tree().physics_frame
		await g.get_tree().physics_frame
		for player in [false, true]:
			var point := g.world.spawn_director.choose(g.world, player)
			check(g.world.spawn_director.last_report.valid_candidates > 0, "Arena %d has physically usable spawn candidates" % stage)
			check(SpawnDirector.grounded(g.world, point) != null, "Arena %d respawn has ground and capsule clearance" % stage)
	g._start_from_hub(0, 8)
	g.world.enemies_paused = true
	var w := g.world
	# Controlled geometry outside the authored arena isolates exposure from map layout.
	w.box(w, 70, -0.5, -12, 30, 0.5, 24, Color.WHITE, true)
	w.box(w, 88, 0, -2, 0.5, 3, 4, Color.WHITE, true)
	for other in w.enemies:
		other.set_physics_process(false)
	var bot: EnemyBot = w.enemies[0]
	w.enemies.assign([bot])
	bot.global_position = Vector3(74, 0.05, 0)
	w.tr_spawns = [Vector3(74, 0.2, 0), Vector3(84, 0.2, 0), Vector3(94, 0.2, 0)]
	w._current_pvp_spawn = Vector3(74, 0.2, 0)
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	w.spawn_director.recent.clear()
	var selected := w.spawn_director.choose(w, true)
	check(selected.x > 90, "Respawn prefers a distant point hidden behind cover")
	w.box(w, 93, 0, -1, 2, 3, 2, Color.WHITE, true)
	await g.get_tree().physics_frame
	selected = w.spawn_director.choose(w, true)
	check(selected.x < 90, "Respawn rejects a point occupied by solid scenery")
	bot.skill = BotDifficulty.get_preset(2)
	bot._root.rotation = Vector3.ZERO
	bot._patrol_cd = 100
	w.player_spawn_guard = 0
	w.player_pos = Vector3(74, 0.05, -8)
	bot._choose_target()
	check(not bot._has_target, "A bot cannot see an opponent behind its field of view")
	w.player_pos = Vector3(74, 0.05, 8)
	bot._choose_target()
	check(bot._has_target and bot._target_player, "An unobstructed opponent in front is acquired")
	bot._has_target = false
	bot._target_player = false
	var heard := Vector3(74, 0.05, -8)
	bot.hear_noise(heard, 1)
	check(bot._target_memory == heard and not bot._has_target and bot.tactical_state == "investigate", "Hearing creates an investigation, never a visible target")
	w.player_pos = Vector3(94, 0.05, -8)
	bot._choose_target()
	check(bot._target_memory == heard and not bot._has_target, "Hidden movement does not update last-known position")
	bot._t = bot._memory_until + 0.1
	bot._patrol_cd = 0
	bot._choose_target()
	check(bot._target_memory != heard, "Expired evidence releases the bot back to patrol")
	bot._target_memory = Vector3(74, 0.05, 0)
	bot.hear_noise(Vector3(74, 0.05, -50), 1)
	check(bot._target_memory == Vector3(74, 0.05, 0), "Distant inaudible shots cannot reveal their location")
	w.arena_navigation = null
	w.combat_cover.assign([AABB(Vector3(88, 0, -2), Vector3(0.5, 3, 4))])
	bot.global_position = Vector3(92, 0.05, 5)
	bot._ensure_clear_spawn()
	bot._spawn_check_pending = false
	bot._target_memory = Vector3(74, 0.05, 0)
	bot.hp = 30
	bot._memory_until = bot._t + 10
	bot._tactical_cd = 0
	bot._tactical_until = 0
	w.bot_difficulty = 2
	var cover: Variant = bot._tactical_destination(false, bot._target_memory)
	check(cover != null and bot.tactical_state == "cover", "Injured Hard bot chooses an actual cover position")
	if cover != null:
		var query := PhysicsRayQueryParameters3D.create(bot._target_memory + Vector3.UP * 1.4, cover + Vector3.UP * 1.2, 1)
		check(not w.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Chosen cover blocks the threat's sight line")
		var before: float = bot.global_position.distance_to(cover)
		bot._sense_cd = 100
		bot._has_target = false
		bot._target_player = false
		bot._target_bot = null
		bot.set_physics_process(true)
		w.enemies_paused = false
		for frame in 70:
			await g.get_tree().physics_frame
		check(bot.global_position.distance_to(cover) < before - 1, "Injured bot physically retreats toward cover")
		w.enemies_paused = true
	bot._tactical_until = 0
	bot._tactical_cd = 0
	w.bot_difficulty = 0
	check(bot._tactical_destination(true, bot._target_memory) == null, "Easy bots do not inherit advanced cover decisions")
	var audio := w.combat_audio
	check(g._vp.audio_listener_enable_3d and audio.pool.size() == 16, "The game listens in 3D with a bounded sixteen-voice pool")
	for voice in audio.pool:
		check(voice.bus == "Effects" and voice.max_distance == 45, "Combat voices use spatial attenuation and effects volume")
	for i in 50:
		audio.play_at("step_stone", Vector3.ZERO)
	check(audio.get_child_count() == 16, "Repeated sounds cannot allocate unbounded audio nodes")
	for name in ["step_stone", "step_wood", "land_soft"]:
		var stream: AudioStreamWAV = audio.streams[name]
		check(stream.mix_rate == 22050 and stream.get_length() >= 0.1 and stream.get_length() < 0.3, "Synthesized movement cue is a short, valid PCM stream")
	# Exercise real playback and occlusion while keeping the effects bus silent.
	var old_mute := Sfx.muted
	var effects_bus := AudioServer.get_bus_index("Effects")
	var bus_was_muted := AudioServer.is_bus_mute(effects_bus)
	AudioServer.set_bus_mute(effects_bus, true)
	Sfx.muted = false
	w.player_pos = Vector3(74, 0.05, 0)
	audio.play_at("smg_shoot", Vector3(94, 1.3, 0), -10)
	check(audio.pool[0].volume_db == -18, "A solid wall reduces the actual 3D shot volume")
	for i in 50:
		audio.play_at("step_stone", Vector3(80, 0.15, 5))
	check(audio.pool.size() == 16 and audio.get_child_count() == 16, "Unmuted playback also reuses the fixed voice pool")
	for voice in audio.pool:
		voice.stop()
	Sfx.muted = old_mute
	AudioServer.set_bus_mute(effects_bus, bus_was_muted)
	audio.footstep(Vector3.ZERO)
	check(audio.last_requested == "step_stone", "Stone surface selects the stone footstep")
	w.current_stage_idx = 7
	audio.footstep(Vector3.ZERO)
	check(audio.last_requested == "step_wood", "Dock surface selects the wood footstep")
	audio.previous_player = Vector3(0, 2, 0)
	w.player_pos = Vector3(0, 1, 0)
	w.player_grounded = false
	audio._physics_process(0.1)
	w.player_pos = Vector3.ZERO
	w.player_grounded = true
	audio._physics_process(0.1)
	check(audio.last_requested == "land_soft", "A real descent ending on the floor requests landing audio")
	g._start_from_hub(0, 5)
	g.world.enemies_paused = true
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	var old_spawn := g.world._current_pvp_spawn
	for opponent in g.world.enemies:
		opponent.global_position = old_spawn
	g.hp = 1
	g.armor = 0
	g.world.player_spawn_guard = 0
	g._on_player_damaged(1000, old_spawn, "Bot_S1mple")
	check(g._body.global_position.distance_to(old_spawn) > 10, "Player death uses scored respawn instead of the camped origin")
	check(g.world.player_pos == g._body.global_position and g.hp == g.max_hp and g.world.player_spawn_guard > 0, "Respawn synchronizes position, health and temporary protection")
	var pose := g._cam.transform
	g._cam.look_at(g._cam.global_position + Vector3.UP, Vector3.FORWARD)
	for index in [0, 3]:
		g.weapons.select_weapon(index, true)
		g.weapons.fire_cd = 0
		g.world.player_spawn_guard = 1.5
		check(g.weapons.try_fire(0) and g.world.player_spawn_guard == 0, "A successful attack ends spawn protection for gun and melee")
		g.world.player_spawn_guard = 1.5
		check(not g.weapons.try_fire(0) and g.world.player_spawn_guard == 1.5, "A rejected trigger does not consume protection")
	g._cam.transform = pose
	g.profile.data.bot_difficulty = 2
	g._start_from_hub(0, 5)
	w = g.world
	w.enemies_paused = true
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	for opponent in w.enemies:
		opponent.set_physics_process(false)
	bot = w.enemies[0]
	bot.global_position = Vector3(0, 0.05, 18)
	bot._ensure_clear_spawn()
	bot._spawn_check_pending = false
	bot._has_target = false
	bot._target_player = false
	bot._target_bot = null
	bot._sense_cd = 100
	bot._target_memory = Vector3(0, 0.05, 4)
	bot._memory_until = bot._t + 10
	bot._tactical_cd = 0
	bot._tactical_until = 0
	bot.hp = 100
	var flank: Variant = bot._tactical_destination(false, bot._target_memory)
	check(flank != null and bot.tactical_state == "flank", "Healthy Hard bot chooses a lateral approach to its last observation")
	if flank != null:
		check(not w.arena_navigation.path(bot.global_position, flank).is_empty(), "Flank is connected to the actual arena navigation")
		var distance_before: float = bot.global_position.distance_to(flank)
		bot.set_physics_process(true)
		w.enemies_paused = false
		for frame in 70:
			await g.get_tree().physics_frame
		check(bot.global_position.distance_to(flank) < distance_before - 1, "Hard bot physically follows its flank route")
	g.profile.data = previous
	g.set_physics_process(true)
	g._start_from_hub(0, 5)
	print("COMBAT: %d checks, %d failures" % [checks, failures])
	return failures == 0
