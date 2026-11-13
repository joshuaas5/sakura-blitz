extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run(g: SakuraBlitzMain) -> bool:
	g._start_from_hub(0, 5)
	g.set_physics_process(false)
	g.world.enemies_paused = true
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	var route := g.world.arena_navigation.path(Vector3(-15, 0.2, 10), Vector3(-5, 0.2, 10))
	check(route.has(Vector3(-10, 0.15, 10)), "Bots can route straight through the tea house")
	g._body.position = Vector3(-14, 0.2, 10)
	for frame in 240:
		g._body.velocity = Vector3(2.5, g._body.velocity.y - 20.0 / 60, 0)
		g._body.move_and_slide()
		await g.get_tree().physics_frame
	check(g._body.position.x > -6.5, "Player physically traverses both tea-house doorways")
	check(g._body.position.y > -0.1 and g._body.position.y < 0.4, "Interior floor does not drop or launch the player")
	var audio := g.world._stage_root.find_children("*", "AudioStreamPlayer3D", true, false).filter(func(source): return source.bus == "Ambience")
	check(audio.size() == 2, "Village owns two spatial ambience sources")
	for source in audio:
		check(source.bus == "Ambience" and source.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and source.max_distance > 0, "Ambience loops with spatial attenuation on independent bus")
	Sfx.configure_effects(0.25, 0)
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")), linear_to_db(0.25)), "Effects volume uses independent mixer bus")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")), "Zero ambience volume mutes the environment")
	g._start_from_hub(1, 0)
	check(g.world._stage_root.find_children("*", "AudioStreamPlayer3D", true, false).filter(func(source): return source.bus == "Ambience").is_empty(), "Switching maps removes old ambience emitters")
	g._apply_profile_settings()
	g.set_physics_process(true)
	print("VILLAGE: %d checks, %d failures" % [checks, failures])
	return failures == 0
