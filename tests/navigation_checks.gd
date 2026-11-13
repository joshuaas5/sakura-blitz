extends RefCounted
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run(g: SakuraBlitzMain) -> bool:
	g.set_physics_process(false)
	for stage in 5:
		g._start_from_hub(0, stage)
		g.world.enemies_paused = true
		await g.get_tree().physics_frame
		await g.get_tree().physics_frame
		var nav: SurfaceNavigation = g.world.arena_navigation
		print("NAV stage=", stage, " nodes=", nav.graph.get_point_count(), " bake_ms=", nav.build_ms)
		var spawns: Array = g.world.tr_spawns.duplicate()
		spawns.append(g.world._current_pvp_spawn)
		for i in spawns.size():
			check(SpawnDirector.grounded(g.world, spawns[i]) != null, "Arena %d spawn %d is physically usable" % [stage, i])
			for j in spawns.size():
				var route := nav.path(spawns[i], spawns[j])
				check(not route.is_empty(), "Arena %d route %d -> %d exists" % [stage, i, j])
		var cases: Array = [
			[[Vector3(-2, 0.05, -15), Vector3(0, 0.05, 15)], [Vector3(12, 0.05, -3), Vector3(9.5, 3.73, 5.5)], [Vector3(-12, 0.05, 3), Vector3(-9.5, 3.73, -5.5)]],
			[[Vector3(-8.5, 0.05, 18), Vector3(0, 3.35, 0)], [Vector3(0, 3.35, 0), Vector3(8.5, 0.05, 18)]],
			[[Vector3(0, 0.05, -10), Vector3(0, 4.05, 26.5)], [Vector3(0, 0.05, 10), Vector3(-18.5, 2.65, -14)]],
			[[Vector3(0, 0.05, 6), Vector3(0, 7.3, 0)], [Vector3(0, 7.3, 0), Vector3(0, 0.05, 6)]],
			[[Vector3(-19, 0.05, -12), Vector3(0, 2.9, -12)]]
		][stage]
		for points in cases:
			await _walk(g, stage, points[0], points[1])
	await _step_limits(g)
	await _isolation(g)
	var cached: SurfaceNavigation = SurfaceNavigation._cache[0]
	g._start_from_hub(0, 0)
	check(g.world.arena_navigation == cached and SurfaceNavigation._cache.size() == 5, "Arena reload reuses a bounded cache of node-free graphs")
	g.set_physics_process(true)
	print("NAVIGATION: %d checks, %d failures" % [checks, failures])
	return failures == 0

func _walk(g: SakuraBlitzMain, stage: int, from: Vector3, goal: Vector3) -> void:
	var w := g.world
	w.enemies_paused = true
	for actor in w.enemies:
		actor.set_physics_process(false)
	var bot: EnemyBot = w.enemies[0]
	bot.global_position = from
	bot.velocity = Vector3.ZERO
	bot._spawn_check_pending = false
	bot._has_target = false
	bot._target_player = false
	bot._target_bot = null
	bot._target_memory = goal
	bot._sense_cd = 10000
	bot._tactical_cd = 10000
	bot._tactical_until = 0
	bot._route_cd = 0
	bot._route.clear()
	bot._steer_cd = 0
	bot.navigation_steps = 0
	bot.set_physics_process(true)
	w.enemies_paused = false
	var maximum_jump := 0.0
	var maximum_motion := 0.0
	var last := from
	for frame in 2400:
		await g.get_tree().physics_frame
		maximum_jump = maxf(maximum_jump, bot.global_position.y - last.y)
		maximum_motion = maxf(maximum_motion, Vector2(bot.global_position.x - last.x, bot.global_position.z - last.z).length())
		last = bot.global_position
		if bot.global_position.distance_to(goal) < 0.8:
			break
	print("WALK arena=", stage, " start=", from, " goal=", goal, " actual=", bot.global_position, " steps=", bot.navigation_steps, " next=", bot._route[bot._route_cursor] if bot._route_cursor < bot._route.size() else Vector3.ZERO)
	check(bot.global_position.distance_to(goal) < 0.8, "Arena %d bot physically reaches destination across floors" % stage)
	check(maximum_jump <= 0.5 and maximum_motion < 0.4, "Arena %d movement does not teleport or climb tall walls" % stage)
	if goal.y > from.y + 2:
		check(bot.navigation_steps > 0, "Arena %d ascent uses collision-tested steps" % stage)
	w.enemies_paused = true

func _isolation(g: SakuraBlitzMain) -> void:
	# Overlapping floors must remain disconnected without a real access route.
	var root := Node3D.new()
	g.world._stage_root.add_child(root)
	g.world.box(root, 60, -0.5, 60, 12, 0.5, 12, Color.WHITE, true)
	g.world.box(root, 63, 4, 63, 6, 0.25, 6, Color.WHITE, true)
	g.world.box(root, 65.2, 0, 60, 0.12, 3, 12, Color.WHITE, true)
	var nav := SurfaceNavigation.new()
	nav.bake(root, Rect2(60, 60, 12, 12))
	check(nav.path(Vector3(63, 0.05, 61), Vector3(68, 0.05, 61)).is_empty(), "Thin solid wall cannot be crossed between grid samples")
	check(nav.path(Vector3(64, 0.05, 64), Vector3(64, 4.3, 64)).is_empty(), "Overlapping floors cannot connect through the ceiling")
	g._start_from_hub(1, 0)
	check(g.world.arena_navigation == null, "Leaving combat clears the active layered graph")

func _step_limits(g: SakuraBlitzMain) -> void:
	var root := Node3D.new()
	g.world._stage_root.add_child(root)
	g.world.box(root, 70, -0.5, 70, 10, 0.5, 10, Color.WHITE, true)
	g.world.box(root, 74, 0, 72, 0.6, 0.4, 2, Color.WHITE, true)
	g.world.box(root, 72, 1.95, 71, 5, 0.3, 4, Color.WHITE, true)
	var bot: EnemyBot = g.world.enemies[0]
	bot.global_position = Vector3(73.55, 0.05, 73)
	bot.velocity = Vector3.ZERO
	bot._has_target = false
	bot._target_memory = bot.global_position
	bot._route.clear()
	bot._sense_cd = 10000
	bot._tactical_cd = 10000
	bot._tactical_until = 0
	bot.set_physics_process(true)
	g.world.enemies_paused = false
	for frame in 12:
		await g.get_tree().physics_frame
	bot.set_physics_process(false)
	var before := bot.global_position
	bot.velocity = Vector3(4.8, 0, 0)
	var steps := bot.navigation_steps
	bot._try_combat_step(1.0 / 60)
	check(bot.global_position == before and bot.navigation_steps == steps, "Step assist refuses to lift the capsule into a low ceiling")
	g.world.enemies_paused = true
