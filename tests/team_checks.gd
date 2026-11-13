extends RefCounted
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run(g: SakuraBlitzMain) -> bool:
	var saved := g.profile.data.duplicate(true)
	for stage in SakuraWorld.COMBAT_STAGE_DEFS.size():
		for kind in [CombatMatch.FFA, CombatMatch.TEAMS, CombatMatch.CTF]:
			var count := CombatMatch.population(stage, kind)
			check(count >= 5 and count <= 18, "Default population fits each arena")
			if kind != CombatMatch.FFA:
				check((count + 1) % 2 == 0, "Every team population includes the player and has equal sides")
	for population in [12, 18, 24]:
		g.profile.data.match_kind = CombatMatch.TEAMS
		g.profile.data.large_population = population
		g._start_from_hub(0, 10)
		g.set_physics_process(false)
		var w := g.world
		w.enemies_paused = true
		await g.get_tree().physics_frame
		await g.get_tree().physics_frame
		check(w.enemies.size() == population - 1, "Large team population applies selected intensity")
		var counts: Array[int] = [1, 0]
		var names := {}
		for bot in w.enemies:
			counts[bot.team_id] += 1
			names[bot.bot_name] = true
			check(bot.team_id == w.team_for(bot.bot_name), "Spawned bot retains its team identity")
			check(bot.global_position.z > 0 if bot.team_id == 0 else bot.global_position.z < 0, "Teams initially spawn on their own half")
		check(counts[0] == population / 2 and counts[1] == population / 2 and names.size() == population - 1, "Team rosters are equal and every bot name is unique")
		var ally: EnemyBot = w.enemies[1]
		var enemy: EnemyBot = w.enemies[0]
		var hp := ally.hp
		ally.apply_hit(1000, ally.global_position + Vector3.UP, Vector3.ZERO)
		check(ally.hp == hp, "Player cannot damage an ally")
		var my_hp := g.hp
		g._on_player_damaged(1000, ally.global_position, ally.bot_name)
		check(g.hp == my_hp, "An allied source cannot damage the player")
		ally._choose_target()
		check(not ally._target_player and (ally._target_bot == null or ally._target_bot.team_id != ally.team_id), "Allied AI never acquires a teammate")
		var score := w.team_scores[0]
		enemy.apply_hit(1000, enemy.global_position + Vector3.UP, Vector3.ZERO)
		check(w.team_scores[0] == score + 1, "Actual enemy elimination increments the team score once")
		check(w.bots_per_round <= EnemyBot.BOT_NAMES.size(), "Population cannot exceed the available unique roster")
	g.profile.data.match_kind = CombatMatch.CTF
	g.profile.data.large_population = 0
	for stage in SakuraWorld.COMBAT_STAGE_DEFS.size():
		g._start_from_hub(0, stage)
		g.set_physics_process(false)
		var w := g.world
		w.enemies_paused = true
		for bot in w.enemies:
			bot.set_physics_process(false)
		await g.get_tree().physics_frame
		await g.get_tree().physics_frame
		var flags := w.match_controller
		check(flags != null and flags.flags.size() == 2 and w.combat_kill_limit == 3, "CTF initializes two physical flags and a three-capture goal")
		for flag in flags.flags:
			check(SpawnDirector.grounded(w, flag.home) != null, "Flag base has physical ground and access")
			check(not w.arena_navigation.path(w._current_pvp_spawn, flag.home).is_empty(), "Both bases connect through navigation")
		flags.interact("PLAYER", flags.flags[1].home)
		check(flags.flags[1].carrier == "PLAYER", "Touching enemy flag picks it up")
		flags.flags[0].carrier = w.enemies[0].bot_name
		flags.interact("PLAYER", flags.flags[0].home)
		check(w.team_scores[0] == 0, "Cannot capture while own flag is stolen")
		flags.reset_flag(0)
		flags.interact("PLAYER", flags.flags[0].home)
		check(w.team_scores[0] == 1 and flags.flags[1].carrier == "" and flags.captures.get("PLAYER", 0) == 1, "Returning enemy flag scores once and resets it")
		flags.interact("PLAYER", flags.flags[1].home)
		var drop := (flags.flags[0].home as Vector3).lerp(flags.flags[1].home, 0.5)
		flags.drop_carrier("PLAYER", drop)
		check(flags.flags[1].dropped and flags.flags[1].carrier == "", "Carrier death drops the flag at the defeat position")
		flags.interact(w.enemies[0].bot_name, drop)
		check(not flags.flags[1].dropped and flags.flags[1].at == flags.flags[1].home, "Owner can recover its dropped flag")
		flags.interact("PLAYER", flags.flags[1].home)
		flags.drop_carrier("PLAYER", drop)
		flags._interaction_cd = 100
		flags.tick(25.1)
		check(not flags.flags[1].dropped, "Abandoned flag returns automatically after twenty-five seconds")
		var bot: EnemyBot = w.enemies[0]
		flags.interact(bot.bot_name, flags.flags[0].home)
		check(flags.bot_goal(bot) == flags.flags[1].home, "Bot carrying enemy flag routes to its own base")
		flags.interact(bot.bot_name, flags.flags[1].home)
		check(w.team_scores[1] == 1, "Bot can complete an actual flag capture")
		var before := w.team_scores.duplicate()
		w.record_team_elimination("PLAYER", bot.bot_name, bot.global_position)
		check(w.team_scores == before, "Kills do not replace capture scoring in CTF")
		flags.reset_flag(0)
		flags.reset_flag(1)
		flags.interact(bot.bot_name, flags.flags[0].home)
		bot.global_position = flags.flags[0].home
		bot.velocity = Vector3.ZERO
		bot._spawn_check_pending = false
		bot._has_target = false
		bot._target_player = false
		bot._target_bot = null
		bot._sense_cd = 10000
		bot._route_cd = 0
		bot._route.clear()
		bot.set_physics_process(true)
		w.enemies_paused = false
		w.player_spawn_guard = 1000
		flags._interaction_cd = 0
		var captures_before: int = w.team_scores[1]
		for frame in 4800:
			await g.get_tree().physics_frame
			if w.team_scores[1] > captures_before:
				break
		check(w.team_scores[1] == captures_before + 1, "Flag carrier physically follows the map route and captures through proximity detection")
		w.enemies_paused = true
		bot.set_physics_process(false)
		w.team_scores[0] = 3
		w._physics_process(0)
		check(w.combat_is_finished, "Reaching the capture goal ends the match")
		await g.get_tree().process_frame
	g.profile.data.match_kind = CombatMatch.FFA
	g._start_from_hub(0, 1)
	check(g.world.match_controller == null and g.world.team_scores == [0, 0], "Starting FFA removes objectives and team scores")
	g.profile.data = saved
	g.set_physics_process(true)
	print("TEAMS: %d checks, %d failures" % [checks, failures])
	return failures == 0
