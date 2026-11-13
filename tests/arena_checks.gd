extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run(game: SakuraBlitzMain) -> bool:
	game.set_physics_process(false)
	game._mobile_autofire = false
	for arena in [5, 6, 7, 8]:
		game._start_from_hub(0, arena)
		game.world.enemies_paused = true
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		var world := game.world
		var nav := world.arena_navigation
		check(nav != null, "Authored arena supplies navigation")
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.35
		capsule.height = 1.8
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		var spawns: Array = world.tr_spawns.duplicate()
		spawns.append(world._current_pvp_spawn)
		for spawn in spawns:
			query.transform = Transform3D(Basis.IDENTITY, spawn + Vector3.UP)
			check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Arena %d spawn has physical clearance" % arena)
			for other in spawns:
				var route := nav.path(spawn, other)
				check(not route.is_empty(), "Arena %d connects every spawn pair" % arena)
				var clear := true
				for point in route:
					query.transform.origin = point + Vector3.UP
					if not world.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
						clear = false
						break
				check(clear, "Arena %d navigation agrees with physical cover" % arena)
		# Exercise the real movement loop along a route around solid buildings.
		var bot: EnemyBot = world.enemies[0]
		for other_bot in world.enemies:
			other_bot.set_physics_process(false)
		bot.set_physics_process(true)
		bot.global_position = Vector3(-21, 0.2, -23)
		bot._ensure_clear_spawn()
		bot._spawn_check_pending = false
		bot._has_target = false
		bot._target_player = false
		bot._target_bot = null
		bot._target_memory = Vector3(21, 0.2, 23)
		bot._sense_cd = 100
		var start := bot.global_position
		world.enemies_paused = false
		for frame in 1800:
			await game.get_tree().physics_frame
		print("ROUTE arena=", arena, " from=", start, " to=", bot.global_position, " target_distance=", bot.global_position.distance_to(Vector3(21, 0.2, 23)))
		check(bot.global_position.distance_to(start) > 4, "Arena %d bot follows a route through actual physics" % arena)
		check(bot.global_position.distance_to(Vector3(21, 0.2, 23)) < 3, "Arena %d bot crosses the complete arena around cover" % arena)
		check(bot.global_position.y > -0.5, "Arena %d bot stays on the floor" % arena)
		check(not bot._route.is_empty(), "Arena %d combat AI consumes the route" % arena)
		world.enemies_paused = true
	game._start_from_hub(1, 0)
	check(game.world.arena_navigation == null, "Navigation is cleared when leaving an authored arena")
	game.set_physics_process(true)
	print("ARENAS: %d checks, %d failures" % [checks, failures])
	return failures == 0
