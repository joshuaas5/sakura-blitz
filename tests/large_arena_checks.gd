extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run(g: SakuraBlitzMain) -> bool:
	var saved_kind: int = g.profile.data.match_kind
	var saved_population: int = g.profile.data.large_population
	g.profile.data.match_kind = CombatMatch.FFA
	g.profile.data.large_population = 0
	g.set_physics_process(false)
	for stage in [9, 10]:
		g._start_from_hub(0, stage)
		g.set_physics_process(false)
		var w := g.world
		w.enemies_paused = true
		await g.get_tree().physics_frame
		await g.get_tree().physics_frame
		var spec: Dictionary = w._stage_root.get_meta("large_arena", {})
		check(float(spec.get("port_area_ratio", 0)) >= 5.5 and float(spec.get("port_area_ratio", 0)) <= 6.1, "Large arena %d has approximately six Porto combat footprints" % stage)
		check(w.enemies.size() == 18 and w.bot_scoreboard.size() == 18, "Large arena spawns eighteen uniquely scored competitors")
		check(w.combat_time_left > 299.8 and w.combat_time_left <= 300 and w.combat_kill_limit == 20, "Large match has five minutes or twenty eliminations")
		check(w.combat_sectors.size() >= 6 and w.combat_patrol_points.size() >= 6, "Large arena supplies named sectors and patrol routes")
		var nav := w.arena_navigation
		check(nav.grid.region.size.x > 90 and nav.grid.region.size.y > 70, "Navigation spans the full large footprint")
		var spawns: Array = w.tr_spawns.duplicate()
		spawns.append(w._current_pvp_spawn)
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.46
		capsule.height = 1.82
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		for at: Vector3 in spawns:
			check(SpawnDirector.grounded(w, at) != null, "Large arena %d spawn %s has floor and body clearance" % [stage, at])
			for to: Vector3 in spawns:
				var route := nav.path(at, to)
				check(not route.is_empty() and Vector2(route[-1].x, route[-1].z).distance_to(Vector2(to.x, to.z)) < 2 if not route.is_empty() else false, "Large arena routes to the destination without clipping it to old bounds")
				var clear := true
				for point in route:
					query.transform.origin = point + Vector3.UP * 0.91
					if not w.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
						clear = false
						break
				check(clear, "Large arena %d path agrees with the real capsule and cover" % stage)
		for point in w.combat_patrol_points:
			check(not nav.path(w._current_pvp_spawn, point).is_empty() and SpawnDirector.grounded(w, point) != null, "Sector patrol destination is physically reachable")
		for point in [w.combat_bounds.position, w.combat_bounds.end, Vector2(w.combat_bounds.end.x, w.combat_bounds.position.y)]:
			check(g._atelier.map_point(point).distance_to(Vector2(50, 50)) <= 43.01, "Full-map corners fit inside the minimap circle")
		check(g._atelier.map_point(Vector2(-30, 0)).distance_to(g._atelier.map_point(Vector2(30, 0))) > 30, "Minimap preserves distinct positions outside the old small arena")
		g._atelier.sync()
		check(g._atelier.pieces.score_text.text.ends_with("20"), "HUD displays the actual map kill limit")
		check(not w.combat_sector(w._current_pvp_spawn).is_empty(), "Entry spawn has a named sector")
		var npc := w.enemies[0]
		for other in w.enemies:
			other.set_physics_process(false)
		var saved := w.enemies.duplicate()
		w.enemies.assign([npc])
		w.player_spawn_guard = 1000
		npc._target_bot = null
		npc._has_target = false
		npc._memory_until = 0
		npc._patrol_cd = 0
		npc._choose_target()
		check(npc._patrol_cd >= npc.global_position.distance_to(npc._target_memory) / npc.move_speed, "Bot retains a distant patrol goal long enough to reach its sector")
		w.enemies.assign(saved)
		var half := w.combat_bounds.size / 2 - Vector2.ONE * 5
		await walk(g, Vector3(-half.x, 0.05, -half.y), Vector3(half.x, 0.05, half.y), "district crossing")
		if stage == 9:
			await walk(g, Vector3(35, 0.05, -22), Vector3(35, 0.05, -2), "greenhouse corridor")
			await walk(g, Vector3(-22, 0.05, 0), Vector3(-12, 0.05, 0), "walk-through tea house")
		else:
			await walk(g, Vector3(-40, 0.05, 10), Vector3(-40, 0.05, 30), "workshop corridor")
			await walk(g, Vector3(-51, 0.05, 0), Vector3(51, 0.05, 0), "tram crossing")
		w.enemies_paused = true
		w.player_spawn_guard = 0
		var selected := w.spawn_director.choose(w, true)
		check(SpawnDirector.grounded(w, selected) != null, "Large-map respawn selects a usable physical candidate")
		check(w._stage_root.find_children("*", "OmniLight3D", true, false).is_empty(), "Large districts add no dynamic point lights")
	g._start_from_hub(0, 1)
	check(g.world.bots_per_round == 6 and g.world.enemies.size() == 6 and g.world.combat_kill_limit == 15 and g.world.combat_time_left == 180, "Compact arena restores its original population and match rules")
	check(g.world.combat_sectors.is_empty() and g.world.combat_patrol_points.is_empty(), "Large-map sector and patrol data do not leak into compact arenas")
	g.profile.data.match_kind = saved_kind
	g.profile.data.large_population = saved_population
	g.set_physics_process(true)
	print("LARGE ARENAS: %d checks, %d failures" % [checks, failures])
	return failures == 0

func walk(g: SakuraBlitzMain, from: Vector3, to: Vector3, label: String) -> void:
	var w := g.world
	var bot := w.enemies[0]
	bot.global_position = from
	bot.velocity = Vector3.ZERO
	bot._spawn_check_pending = false
	bot._has_target = false
	bot._target_player = false
	bot._target_bot = null
	bot._target_memory = to
	bot._sense_cd = 10000
	bot._tactical_cd = 10000
	bot._tactical_until = 0
	bot._route_cd = 0
	bot._route.clear()
	bot._steer_cd = 0
	bot.set_physics_process(true)
	w.enemies_paused = false
	var max_motion := 0.0
	var last := from
	for frame in 4200:
		await g.get_tree().physics_frame
		max_motion = maxf(max_motion, bot.global_position.distance_to(last))
		last = bot.global_position
		if last.distance_to(to) < 1:
			break
	print("LARGE WALK arena=", w.current_stage_idx, " ", label, " from=", from, " actual=", last, " goal=", to)
	check(last.distance_to(to) < 1, "Bot physically completes " + label)
	check(max_motion < 0.5 and last.y > -0.1, "Large arena crossing stays grounded without teleporting")
	w.enemies_paused = true
	bot.set_physics_process(false)
