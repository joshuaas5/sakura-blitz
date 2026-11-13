extends RefCounted
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func blocked(g: SakuraBlitzMain, a: Vector3, b: Vector3) -> bool:
	return not g.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1)).is_empty()

func run(g: SakuraBlitzMain) -> bool:
	var quality := g._res_idx
	g._start_from_hub(0, 1)
	g.set_physics_process(false)
	g.world.enemies_paused = true
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	var stage := g.world._stage_root
	check(stage.get_meta("harbor_playable_containers", 0) == 7, "Harbor keeps seven combat containers")
	check(stage.get_meta("harbor_factory_instances", 0) >= 20, "Harbor uses the authored industrial scenery")
	check(not blocked(g, Vector3(-8.5, 1.3, -12.1), Vector3(-8.5, 1.3, -4.9)), "Open container interior has a clear shooting corridor")
	check(blocked(g, Vector3(-13, 1.3, 0), Vector3(-18, 1.3, 0)), "Closed cargo remains solid cover")
	check(not blocked(g, Vector3(0, 1.3, -5), Vector3(0, 1.3, 5)), "Lower central lane stays clear beneath catwalk")
	check(blocked(g, Vector3(-5, 4.2, 1), Vector3(-5, 4.2, 2.8)), "Visible catwalk guardrail stops physical rays")
	check(blocked(g, Vector3(0, 2, 18), Vector3(0, 2, 23)), "Open-looking fence retains the arena boundary")
	var exterior_solids := 0
	for body in stage.find_children("*", "StaticBody3D", true, false):
		if absf(body.global_position.x) > 20 or absf(body.global_position.z) > 20:
			exterior_solids += 1
	check(exterior_solids == 0, "Backdrop has no invisible collision outside the combat bounds")
	var palette_batches := 0
	for mesh in stage.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh != null and mesh.get_active_material(0) == HarborAtelier.palette_material:
			palette_batches += 1
	check(palette_batches > 0 and palette_batches <= 12, "Container paint shares a small set of spatial vertex-color batches")
	check(stage.find_children("*", "OmniLight3D", true, false).is_empty(), "Industrial lamps add no real-time point lights")
	check(g.world.sky_mat.ground_horizon_color == g.world.sky_mat.sky_horizon_color, "Sea horizon has no inherited brown band")
	var ambience := stage.find_children("*", "AudioStreamPlayer3D", true, false).filter(func(source): return source.bus == "Ambience")
	check(ambience.size() == 1 and ambience[0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Harbor owns a looping spatial surf source on the ambience bus")
	g.world.combat_audio.footstep(Vector3(0, 3.3, 0))
	check(g.world.combat_audio.last_requested == "step_metal", "Raised steel surfaces use metal footsteps")
	g.world.combat_audio.footstep(Vector3(0, 0.01, 16))
	check(g.world.combat_audio.last_requested == "step_stone", "Concrete apron keeps hard-ground footsteps")
	for preset in [0, 2]:
		g._res_idx = preset
		g._apply_graphics_preset()
		check(g.world.sun.shadow_enabled == (preset > 0), "Harbor shadows follow the selected quality preset")
	g._start_from_hub(0, 5)
	await g.get_tree().process_frame
	await g.get_tree().process_frame
	check(not is_instance_valid(stage), "Changing maps frees harbor meshes, colliders and imported instances")
	check(not g.world._stage_root.has_meta("harbor_art_revision"), "Harbor decoration does not leak into another arena")
	check(g.world._stage_root.find_child("harbor_surf", true, false) == null, "Harbor surf ends when leaving the map")
	g._res_idx = quality
	g._apply_graphics_preset()
	g.set_physics_process(true)
	print("HARBOR: %d checks, %d failures" % [checks, failures])
	return failures == 0
