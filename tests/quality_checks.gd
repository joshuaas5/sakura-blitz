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
	_renderer_checks(g)
	g._mobile_hud_enabled = true
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame
	var joy := g._mobile_rect("joystick").get_center()
	g._handle_touch(31, joy, true)
	g._handle_touch_drag(31, joy + Vector2(20, -40), Vector2(20, -40))
	g._handle_touch(32, g._action_rects().jump.get_center(), true)
	g._handle_touch(33, g._action_rects().fire.get_center(), true)
	g.weapons.want_ads = true
	g._jump_buffer = 0.15
	g._body.set_meta("fire_was", true)
	g.hp = 1
	g.armor = 0
	g.world.player_spawn_guard = 0
	g._on_player_damaged(1000, g._body.position, "Bot_S1mple")
	check(g._touch_actions.is_empty() and g._mobile_move_vec == Vector2.ZERO and not g._mobile_fire_held and not g._mobile_jump_held, "Death releases movement, look, fire and jump ownership")
	check(not g.weapons.want_ads and g._jump_buffer == 0 and not g._body.get_meta("fire_was"), "Respawn cannot inherit aim, buffered jump or previous semi-auto trigger")
	check(g._body.velocity == Vector3.ZERO and g.world.player_spawn_guard > 0, "Respawn begins motionless with protection")
	g._handle_touch(31, joy, false)
	g._handle_touch(32, joy, false)
	g._handle_touch(33, joy, false)
	check(g._touch_actions.is_empty(), "Late releases from a previous life are harmless")
	g.weapons.want_ads = true
	g._jump_buffer = 0.15
	g._body.velocity = Vector3(3, 4, -2)
	g._open_hub()
	check(g._body.velocity.x == 0 and g._body.velocity.z == 0 and g._body.velocity.y == 4, "Pausing stops residual horizontal input and preserves the airborne trajectory")
	g._resume_from_hub()
	check(not g.weapons.want_ads and g._jump_buffer == 0, "Resume cannot unexpectedly aim or jump")
	g._toggle_shop(1)
	g._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not g._shop_open and not g._shop_panel.visible and not g._hub_open and not g._paused, "Android Back closes the current shop and restores its previous gameplay context")
	# Recover old behavior to let every regression report even before the fix.
	if g._shop_open:
		g._toggle_shop(0)
	g._resume_from_hub()
	g._toggle_shop(1)
	g._pause_for_interruption()
	check(g._hub_open and g._paused and not g._shop_open and not g._shop_panel.visible, "Backgrounding a shop returns to one unambiguous paused lobby")
	if g._shop_open:
		g._toggle_shop(0)
	g._resume_from_hub()
	var hp := g.hp
	g._open_hub()
	g._on_player_damaged(10, Vector3.ZERO, "Bot_S1mple")
	check(g.hp == hp, "Late damage cannot change health while paused in a menu")
	g._resume_from_hub()
	var d := g._diagnostics
	d.set_process(false)
	d.stage_key = ""
	d._process(2.1)
	check(d.frames == 0 and d.samples.is_empty(), "The first frame crossing warm-up is excluded from measured FPS")
	d._process(0.016)
	check(d.frames == 1 and d.samples.size() == 1 and is_equal_approx(d.mean_ms(), 16), "Measurement begins with a complete post-warm-up frame")
	g._start_from_hub(0, 5)
	d._process(0.016)
	check(d.frames == 0 and d.samples.is_empty() and d.text.is_empty(), "Rematch on the same map resets diagnostic samples and stale text")
	g._open_hub()
	var elapsed := d.elapsed
	d._process(5)
	check(d.elapsed == elapsed, "Menu time does not count toward match performance")
	g._resume_from_hub()
	d._process(2.1)
	d._process(0.016)
	check(d.frames == 1, "Explicit resume continues the new match measurement")
	g._vp.size += Vector2i(8, 0)
	d._process(0.016)
	check(d.frames == 0 and d.samples.is_empty(), "Changing render dimensions starts a fresh performance sample")
	d.set_process(true)
	g.set_physics_process(true)
	g._start_from_hub(0, 5)
	print("QUALITY: %d checks, %d failures" % [checks, failures])
	return failures == 0

func _renderer_checks(g: SakuraBlitzMain) -> void:
	var sample := Node3D.new()
	g.world._stage_root.add_child(sample)
	for index in 3:
		var cube := BoxMesh.new()
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cube.get_mesh_arrays())
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.position.x = 70 + index * 4
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.RED if index != 1 else Color.BLUE
		material.roughness = 0.2 if index < 2 else 0.9
		material.vertex_color_is_srgb = false
		node.material_override = material
		sample.add_child(node)
	ImportedSceneryBatch.bake(sample, 200)
	var active: Array[MeshInstance3D] = []
	for child in sample.get_children():
		if child is MeshInstance3D and child.visible:
			active.append(child)
	check(active.size() == 2, "Static batching combines color variants and keeps different roughness separate")
	var bounds := AABB()
	var colors := {}
	for node in active:
		var box: AABB = node.transform * node.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
		var arrays: Array = node.mesh.surface_get_arrays(0)
		for color in arrays[Mesh.ARRAY_COLOR]:
			colors[color] = true
	check(bounds.position.distance_to(Vector3(69.5, -0.5, -0.5)) < 0.001 and bounds.size.distance_to(Vector3(9, 1, 1)) < 0.001, "Cell-relative meshes preserve exact world geometry")
	check(colors.has(Color.RED) and colors.has(Color.BLUE), "Merged geometry preserves both material tints")
	sample.queue_free()
	g._atelier.sync()
	var builds := g._atelier.map_builds
	for frame in 20:
		g._atelier.sync()
	check(g._atelier.map_builds == builds and not g._atelier.map_polygons.is_empty(), "HUD updates reuse the static minimap geometry")
	var fx := g.world.combat_fx
	var before := g.world.vfx_items.size()
	for hit in 120:
		g.world.spawn_voxel_burst(Vector3(0, 1, 0), Color("efc987"), 10)
	check(fx.sparks.multimesh.instance_count == 96 and g.world.vfx_items.size() == before, "Repeated hits reuse a fixed spark pool without allocating VFX nodes")
	fx._process(0.5)
	check(not fx.sparks.visible, "All pooled sparks expire and hide")
	g.weapons.select_weapon(0, true)
	g.weapons.select_weapon(2)
	check(not g.weapons.try_fire(0), "A weapon cannot fire before its swap animation reaches readiness")
	g.weapons.tick_viewmodel(0.3, 0, true, false, false)
	check(g.weapons.try_fire(0), "Sidearm becomes available after its short draw window")
	g.weapons.ammo[2] = 1
	g.weapons.start_reload()
	g.weapons.refill_all_ammo()
	check(not g.weapons.is_reloading and g.weapons.fire_cd == 0 and g.weapons.reload_timer == 0, "A fresh life clears stale reload and cooldown state")
