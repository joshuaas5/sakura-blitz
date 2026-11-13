extends RefCounted
var failures := 0
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func run(game: SakuraBlitzMain) -> bool:
	# Isolate bot assertions from player input left by earlier touch tests.
	game.set_physics_process(false)
	for difficulty in 3:
		game.profile.data.bot_difficulty = difficulty
		game._start_from_hub(0, 4)
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		var preset := BotDifficulty.get_preset(difficulty)
		check(game.world.bot_difficulty == difficulty, "Lobby difficulty reaches the world")
		for bot in game.world.enemies:
			check(bot.skill.spread == preset.spread and bot.skill.reaction == preset.reaction, "Bot uses selected aim/reaction profile")
			check(bot.max_hp == 100, "Difficulty must not inflate bot health")
		check(game.world.enemies.map(func(bot): return bot.bot_name).size() == 6, "Arena has six competitors")
	check(BotDifficulty.PRESETS[0].reaction > BotDifficulty.PRESETS[1].reaction and BotDifficulty.PRESETS[1].reaction > BotDifficulty.PRESETS[2].reaction, "Reaction improves across difficulty tiers")
	check(BotDifficulty.PRESETS[0].spread > BotDifficulty.PRESETS[1].spread and BotDifficulty.PRESETS[1].spread > BotDifficulty.PRESETS[2].spread, "Aim precision improves across tiers")
	game.set_physics_process(false)
	game.world.enemies_paused = true
	game.world.box(game.world, 35, -0.5, -5, 10, 0.5, 20, Color.WHITE, true)
	var shooter: EnemyBot = game.world.enemies[0]
	var victim: EnemyBot = game.world.enemies[1]
	shooter.position = Vector3(40, 0.1, 8)
	victim.position = Vector3(40, 0.1, 0)
	game.world.player_pos = Vector3(0, 0.2, 20)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var player_coins := game.coins
	var player_kills := game.kills
	var victim_name := victim.bot_name
	game.world.spawn_enemy_orb(shooter.position + Vector3(0, 1.3, -0.6), Vector3.FORWARD, 48, 120, Color.WHITE, shooter)
	for frame in 24:
		await game.get_tree().physics_frame
	check(game.world.bot_scoreboard[shooter.bot_name].kills == 1, "Physical bot projectile credits its actual shooter")
	check(game.world.bot_scoreboard[victim_name].deaths == 1, "Victim death is recorded")
	check(game.coins == player_coins and game.kills == player_kills, "Bot-on-bot kills cannot grant player mastery or currency")
	var shielded: EnemyBot = game.world.enemies[1]
	shielded.position = Vector3(40, 0.1, 0)
	game.world.box(game.world, 38, 0, 3.5, 4, 3, 0.4, Color.WHITE, true)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	game.world.spawn_enemy_orb(shooter.position + Vector3(0, 1.3, -0.6), Vector3.FORWARD, 48, 120, Color.WHITE, shooter)
	for frame in 24:
		await game.get_tree().physics_frame
	check(shielded.hp == 100, "A wall blocks a projectile before it reaches a bot")
	shooter._choose_target()
	check(shooter._target_bot != shielded, "A bot cannot acquire a target through a wall")
	game.world.combat_time_left = 0.02
	for frame in 5:
		await game.get_tree().physics_frame
	check(game.world.combat_is_finished and game._result_panel.visible, "Time limit opens the combat podium")
	var final_coins := game.coins
	for frame in 5:
		await game.get_tree().physics_frame
	check(game.coins == final_coins, "Match payout happens once")
	game._start_from_hub(0, 4)
	check(game.world.combat_time_left == 180 and game.kills == 0 and not game.world.combat_is_finished, "Rematch resets the match state")
	game.kills = game.world.combat_kill_limit
	game.world.ct_score = game.kills
	for frame in 5:
		await game.get_tree().physics_frame
	check(game.world.combat_is_finished, "Reaching the frag limit ends the match")
	check(game.world.get_combat_standings(game.kills, game.deaths)[0].is_player, "Frag-limit winner leads the final standings")
	# Full autonomous races exercise navigation, jumping, hazards and real finishes.
	for stage in 6:
		game.profile.data.bot_difficulty = 2
		game._start_from_hub(1, stage)
		game.world.player_pos = game.world.kz_start_pad
		for frame in 10800:
			await game.get_tree().physics_frame
			if game.world.race_finished_count >= 4:
				break
		print("BOT RACE %d: %d finished, %.1fs" % [stage, game.world.race_finished_count, game.world.kz_time])
		if game.world.race_finished_count < 4:
			for runner in game.world.parkour_runners:
				print("  ", runner.bot_name, " wp=", runner.wp_idx, " pos=", runner.position)
		check(game.world.race_finished_count >= 4, "At least four Hard bots must finish course %d without scripted teleporting" % stage)
	for difficulty in [0, 1]:
		game.profile.data.bot_difficulty = difficulty
		game._start_from_hub(1, 0)
		game.world.player_pos = game.world.kz_start_pad
		for frame in 10800:
			await game.get_tree().physics_frame
			if game.world.race_finished_count >= 4:
				break
		print("BOT DIFFICULTY %s: %d finished, %.1fs" % [BotDifficulty.get_preset(difficulty).name, game.world.race_finished_count, game.world.kz_time])
		check(game.world.race_finished_count >= 4, "Easy and Medium bots must also finish a complete race")
	for track in ["bloom_lobby", "petal_dash", "neon_skirmish"]:
		check(game.get_node("/root/Sfx")._bgm_streams.has(track), "Original music loads: " + track)
		var audio: AudioStreamWAV = game.get_node("/root/Sfx")._bgm_streams[track]
		check(audio.loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.get_length() > 30, "Music is a complete looping track")
	game.set_physics_process(true)
	game.profile.data.bot_difficulty = 1
	print("BOTS: %d checks, %d failures" % [checks, failures])
	return failures == 0
