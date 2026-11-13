class_name HarborAtelier
extends RefCounted
## Industrial toy harbor over the original combat footprint.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const STEEL := "294858"
const CREAM := "e7dfbb"
const YELLOW := "edb83f"
static var factory_scenes: Dictionary = {}
static var factory_bounds: Dictionary = {}
static var fence_material: ShaderMaterial
static var palette_material: StandardMaterial3D
static var deck_material: ShaderMaterial

static func deck(w: SakuraWorld, at: Vector3, size: Vector3) -> void:
	if deck_material == null:
		deck_material = ShaderMaterial.new()
		deck_material.shader = preload("res://assets/shaders/harbor_deck.gdshader")
	var shape := BoxMesh.new()
	shape.size = size
	S.mesh(w, shape, at, deck_material)
	CV.collision(w, at, size)

static func bake_palette(root: Node) -> void:
	# Paint is vertex data, so different container colors share one draw material.
	if palette_material == null:
		palette_material = StandardMaterial3D.new()
		palette_material.vertex_color_use_as_albedo = true
		palette_material.roughness = 0.86
	if root is MeshInstance3D and root.mesh is ArrayMesh and root.mesh.get_surface_count() == 1:
		var mat: Material = root.get_active_material(0)
		if mat is StandardMaterial3D and S.mats.values().has(mat) and mat.albedo_texture == null and not mat.emission_enabled:
			var arrays: Array = root.mesh.surface_get_arrays(0)
			var colors := PackedColorArray()
			colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
			colors.fill(mat.albedo_color)
			arrays[Mesh.ARRAY_COLOR] = colors
			var painted := ArrayMesh.new()
			painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			root.mesh = painted
			root.material_override = palette_material
	for child in root.get_children():
		bake_palette(child)

static func block(w: SakuraWorld, at: Vector3, size: Vector3, color: String, solid: bool = false) -> void:
	S.block(w, at, size, color, solid)

static func local_block(w: SakuraWorld, at: Vector3, basis: Basis, p: Vector3, size: Vector3, color: String, solid: bool = false) -> void:
	block(w, at + basis * p, (basis * size).abs(), color, solid)

static func factory(w: SakuraWorld, asset: String, at: Vector3, height: float, yaw: float = 0) -> Node3D:
	var path := "res://assets/third_party/kenney_factory/%s.glb" % asset
	if not factory_scenes.has(path):
		factory_scenes[path] = load(path)
	var model: Node3D = factory_scenes[path].instantiate()
	if not factory_bounds.has(path):
		factory_bounds[path] = S._bounds(model)
	var bounds: AABB = factory_bounds[path]
	var root := Node3D.new()
	w._stage_root.add_child(root)
	root.add_child(model)
	var factor := height / maxf(bounds.size.y, 0.01)
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	root.position = at
	root.rotation.y = yaw
	CV._prepare(model, Color.WHITE)
	w._stage_root.set_meta("harbor_factory_instances", int(w._stage_root.get_meta("harbor_factory_instances", 0)) + 1)
	return root

static func beam(w: SakuraWorld, a: Vector3, b: Vector3, thickness: float, color: String, solid: bool = false) -> void:
	var shape := BoxMesh.new()
	shape.size = Vector3(thickness, a.distance_to(b), thickness)
	var mesh := S.mesh(w, shape, (a + b) * 0.5, S.material(color))
	mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	if solid:
		var body := StaticBody3D.new()
		body.transform = mesh.transform
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = shape.size
		collision.shape = box
		body.add_child(collision)
		w._stage_root.add_child(body)

static func container(w: SakuraWorld, at: Vector3, sx: float, sy: float, sz: float, color: String, opened: bool, id: String, solid: bool = true) -> void:
	var basis := Basis(Vector3.UP, PI / 2 if sx > sz else 0.0)
	var width := minf(sx, sz)
	var length := maxf(sx, sz)
	var light := Color(color).lightened(0.12).to_html(false)
	if opened:
		local_block(w, at, basis, Vector3(0, 0.09, 0), Vector3(width, 0.18, length), STEEL, solid)
		local_block(w, at, basis, Vector3(0, sy - 0.11, 0), Vector3(width, 0.22, length), color, solid)
		for side in [-1.0, 1.0]:
			local_block(w, at, basis, Vector3(side * (width / 2 - 0.12), sy / 2, 0), Vector3(0.24, sy, length), color, solid)
	else:
		local_block(w, at, basis, Vector3(0, sy / 2, 0), Vector3(width, sy, length), color, solid)
	# Corrugated sides, reinforced corners, roof seams and painted lintels.
	for side in [-1.0, 1.0]:
		for rib in range(1, int(length / 0.45)):
			local_block(w, at, basis, Vector3(side * (width / 2 + 0.018), sy / 2, -length / 2 + rib * 0.45), Vector3(0.045, sy - 0.26, 0.065), light)
		for y in [0.07, sy - 0.07]:
			local_block(w, at, basis, Vector3(side * (width / 2 - 0.04), y, 0), Vector3(0.13, 0.14, length + 0.05), STEEL)
		for z in [-length / 2, length / 2]:
			local_block(w, at, basis, Vector3(side * (width / 2 - 0.04), sy / 2, z), Vector3(0.14, sy + 0.04, 0.14), CREAM)
	for end in [-1.0, 1.0]:
		local_block(w, at, basis, Vector3(0, sy - 0.16, end * length / 2), Vector3(width, 0.32, 0.10), CREAM)
		if not opened:
			for side in [-1.0, 1.0]:
				local_block(w, at, basis, Vector3(side * width / 4, sy / 2, end * (length / 2 + 0.02)), Vector3(width / 2 - 0.07, sy - 0.42, 0.045), light)
				local_block(w, at, basis, Vector3(side * width / 4, sy / 2, end * (length / 2 + 0.07)), Vector3(0.045, sy - 0.6, 0.055), STEEL)
				local_block(w, at, basis, Vector3(side * width / 4, 1.2, end * (length / 2 + 0.10)), Vector3(0.30, 0.055, 0.065), CREAM)
	for rib in int(length / 0.65):
		local_block(w, at, basis, Vector3(0, sy + 0.012, -length / 2 + 0.25 + rib * 0.65), Vector3(width - 0.16, 0.025, 0.07), light)
	if solid:
		var sign_at := at + basis * Vector3(width / 2 + 0.055, 1.65, 0)
		S.signpost(w, "CBL / " + id, sign_at, CREAM, (PI / 2 if sx > sz else 0.0) + PI / 2)
	w._stage_root.set_meta("harbor_containers", int(w._stage_root.get_meta("harbor_containers", 0)) + 1)

static func fence(w: SakuraWorld) -> void:
	if fence_material == null:
		fence_material = ShaderMaterial.new()
		fence_material.shader = preload("res://assets/shaders/harbor_fence.gdshader")
	for side in [-1.0, 1.0]:
		for axis in 2:
			var basis := Basis(Vector3.UP, PI / 2 if axis == 1 else 0.0)
			var at := Vector3(side * 19.7, 0, 0) if axis == 1 else Vector3(0, 0, side * 19.7)
			# Same solid perimeter as the old arena; visible mesh has open chain links.
			CV.collision(w, at + Vector3.UP * 2.1, Vector3(0.6, 4.2, 40) if axis == 1 else Vector3(40, 4.2, 0.6))
			local_block(w, at, basis, Vector3(0, 0.325, 0), Vector3(40, 0.65, 0.6), "cbd5cd")
			local_block(w, at, basis, Vector3(0, 0.67, 0), Vector3(40, 0.12, 0.68), STEEL)
			var panel := QuadMesh.new()
			panel.size = Vector2(40, 3.55)
			var mesh := S.mesh(w, panel, at + Vector3.UP * 2.425, fence_material)
			mesh.rotation.y = PI / 2 if axis == 1 else 0.0
			for i in 11:
				local_block(w, at, basis, Vector3(-20 + i * 4, 2.1, 0), Vector3(0.14, 4.2, 0.16), STEEL)
			local_block(w, at, basis, Vector3(0, 4.18, 0), Vector3(40, 0.12, 0.16), STEEL)

static func staircase(w: SakuraWorld, x: float, north: bool) -> void:
	for step in 8:
		var z := -16.7 + step * 0.55 if north else 16.1 - step * 0.55
		block(w, Vector3(x, step * 0.4 + 0.21, z + 0.3), Vector3(2.4, 0.42, 0.6), "6c8792", true)
		block(w, Vector3(x, step * 0.4 + 0.435, z + (0.58 if north else 0.02)), Vector3(2.35, 0.025, 0.08), YELLOW)
	for side in [-1.0, 1.0]:
		var first := Vector3(x + side * 1.12, 1.25, -16.45 if north else 16.45)
		var last := Vector3(x + side * 1.12, 4.05, -12.6 if north else 12.6)
		beam(w, first, last, 0.075, CREAM, true)
		for step in [0, 3, 7]:
			var z: float = -16.4 + step * 0.55 if north else 16.4 - step * 0.55
			block(w, Vector3(x + side * 1.12, step * 0.4 + 0.82, z), Vector3(0.07, 0.82, 0.07), STEEL, true)

static func build(w: SakuraWorld) -> void:
	w._current_pvp_spawn = Vector3(0, 0.2, 16.5)
	w.tr_spawns = [Vector3(-14, 0.2, -14), Vector3(14, 0.2, -14), Vector3(0, 0.2, -18), Vector3(-12.5, 0.2, 0), Vector3(12.5, 0.2, 0), Vector3(-9, 0.2, -6.5), Vector3(9, 0.2, -6.5), Vector3(0, 3.6, 0)]
	var floor_shape := BoxMesh.new()
	floor_shape.size = Vector3(48, 0.5, 48)
	var apron := ShaderMaterial.new()
	apron.shader = preload("res://assets/shaders/harbor_apron.gdshader")
	S.mesh(w, floor_shape, Vector3(0, -0.25, 0), apron)
	CV.collision(w, Vector3(0, -0.25, 0), floor_shape.size)
	var ocean := PlaneMesh.new()
	ocean.size = Vector2(2000, 2000)
	var water := ShaderMaterial.new()
	water.shader = preload("res://assets/shaders/harbor_water.gdshader")
	S.mesh(w, ocean, Vector3(0, -1.8, 0), water)
	fence(w)
	for i in 4:
		var at := Vector3(-8.5 if i % 2 == 0 else 8.5, 0, -8.5 if i < 2 else 8.5)
		container(w, at, 3, 3, 7.6, ["c75d67", "3f8db5", "38a89a", "dca445"][i], true, "0" + str(i + 1))
	container(w, Vector3(-15.5, 0, 0), 3, 3.2, 8.5, "3f8db5", false, "05")
	container(w, Vector3(15.5, 0, 0), 3, 3.2, 8.5, "c75d67", false, "06")
	container(w, Vector3(0, 0, -15.5), 8.5, 3.2, 3, "dca445", false, "07")
	deck(w, Vector3(0, 3.175, 0), Vector3(20, 0.25, 4))
	deck(w, Vector3(0, 3.18, 0), Vector3(4, 0.25, 20))
	for axis in 2:
		var basis := Basis(Vector3.UP, PI / 2 if axis == 1 else 0.0)
		for end in [-1, 1]:
			for side in [-1, 1]:
				local_block(w, Vector3.ZERO, basis, Vector3(side * 1.8, 1.525, end * 9.7), Vector3(0.24, 3.05, 0.24), STEEL, true)
				local_block(w, Vector3.ZERO, basis, Vector3(side * 1.8, 0.07, end * 9.7), Vector3(0.44, 0.14, 0.44), YELLOW, true)
			local_block(w, Vector3.ZERO, basis, Vector3(0, 2.97, end * 9.7), Vector3(3.8, 0.16, 0.28), STEEL, true)
	for x in [-8.5, 8.5]:
		staircase(w, x, false)
		staircase(w, x, true)
		for z in [-3.4, 3.4]:
			deck(w, Vector3(x, 3.175, z), Vector3(2.4, 0.25, 3))
	for axis in 2:
		var basis := Basis(Vector3.UP, PI / 2 if axis == 1 else 0.0)
		for side in [-1.0, 1.0]:
			for start in [-7.2, 2.2]:
				beam(w, basis * Vector3(start, 4.2, side * 1.94), basis * Vector3(start + 5, 4.2, side * 1.94), 0.07, CREAM, true)
				for x in [start, start + 2.5, start + 5]:
					local_block(w, Vector3.ZERO, basis, Vector3(x, 3.75, side * 1.94), Vector3(0.065, 0.9, 0.065), STEEL, true)
	for x in [-4.025, 4.025]:
		block(w, Vector3(x, 1.1, 0), Vector3(0.35, 2.2, 3.6), "5a8792", true)
		for z in [-1.4, 1.4]:
			block(w, Vector3(x, 2.6, z), Vector3(0.16, 0.8, 0.16), STEEL, true)
	for jp in [Vector3(-15.5, 0.1, 15.5), Vector3(15.5, 0.1, -15.5)]:
		ItemArt.jump_pad(w._stage_root, jp)
		w.kz_jumppads.append(jp)
	for p in [Vector3(0, 0.04, 0), Vector3(0, 3.32, 0), Vector3(-12.5, 0.04, 12.5), Vector3(12.5, 0.04, -12.5)]:
		w._add_weapon_pad(p, "SUPRIMENTOS" if p.y < 1 else "PASSARELA", Color("e7c763"))
	for x in [-18.5, 18.5]:
		for z in range(-18, 19, 3):
			block(w, Vector3(x, 0.013, z), Vector3(0.12, 0.02, 1.4), YELLOW)
	# Loading bays and approach lines make the lanes readable at eye level.
	for x in [-8.5, 8.5]:
		for z in [-18.2, 18.2]:
			block(w, Vector3(x, 0.012, z), Vector3(3.6, 0.02, 0.12), CREAM)
			for side in [-1, 1]:
				block(w, Vector3(x + side * 1.8, 0.012, z - signf(z)), Vector3(0.10, 0.02, 2), CREAM)
	for x in [-6, 6]:
		for z in [-18, 18]:
			factory(w, "warning-traffic", Vector3(x, 0, z), 0.65, PI / 2)
	w._stage_root.set_meta("harbor_playable_containers", 7)
	backdrop(w)
	w._stage_root.set_meta("harbor_art_revision", 1)
	bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root)
	VillageAtelier.ambience(w, "harbor_surf", Vector3(0, 1, 0), 65, -7)

static func backdrop(w: SakuraWorld) -> void:
	for side in [-1.0, 1.0]:
		block(w, Vector3(side * 29, -0.5, 0), Vector3(12, 1, 58), "7c9292")
		factory(w, "crane", Vector3(side * 30, 0, -14), 16, side * PI / 2)
		factory(w, "crane-lift", Vector3(side * 25, 10, -14), 5.7)
		warehouse(w, Vector3(side * 29, 0, -34), side)
		for z in [-5, 7, 19]:
			for level in 2:
				container(w, Vector3(side * 30, level * 3.2, z), 3, 3.2, 8, ["3f8db5", "dca445", "38a89a"][posmod(z + level, 3)], false, "CARGA", false)
		factory(w, "robot-arm-a", Vector3(side * 25, 0, 12), 3.2, -side * PI / 2)
		factory(w, "screen-panel-wide", Vector3(side * 25, 0, 16), 1.8, -side * PI / 2)
		for z in [-22, 23]:
			factory(w, "structure-window-wide", Vector3(side * 27, 0, z), 7, -side * PI / 2)
		for z in [-16, 0, 16]:
			beam(w, Vector3(side * 22, 0, z), Vector3(side * 22, 7, z), 0.14, STEEL)
			block(w, Vector3(side * 21.5, 7, z), Vector3(1.3, 0.18, 0.55), CREAM)
	S.signpost(w, "PORTO COBALTO", Vector3(0, 6.5, -23), CREAM)
	S.signpost(w, "TERMINAL / 02", Vector3(0, 5.5, -23), YELLOW)
	for x in [-11, 11]:
		beam(w, Vector3(x, 0, -23), Vector3(x, 8, -23), 0.25, STEEL)
	beam(w, Vector3(-11, 8, -23), Vector3(11, 8, -23), 0.30, STEEL)
	for z in [-35, 35]:
		S.prop(w, "kenney_pirate", "boat-row-large", Vector3(12, -1.4, z), Vector3(2.3, 1.1, 5), 0.35)

static func warehouse(w: SakuraWorld, at: Vector3, side: float) -> void:
	block(w, at + Vector3(0, -0.5, 0), Vector3(18, 1, 14), "7c9292")
	block(w, at + Vector3(0, 4.2, 0), Vector3(16, 8.4, 10), "8da9ac")
	block(w, at + Vector3(0, 8.5, 0), Vector3(16.5, 0.3, 10.5), "355465")
	block(w, at + Vector3(0, 6.8, 5.04), Vector3(16, 0.7, 0.12), "dca445")
	for x in [-5, 0, 5]:
		block(w, at + Vector3(x, 2.65, 5.05), Vector3(4, 5.3, 0.14), STEEL)
		for rib in 10:
			block(w, at + Vector3(x, 0.25 + rib * 0.5, 5.14), Vector3(3.8, 0.05, 0.08), "66848b")
		factory(w, "screen-hanging-wide", at + Vector3(x, 6, 5.1), 0.6)
	S.signpost(w, "ARMAZEM / " + ("NORTE" if side < 0 else "LESTE"), at + Vector3(0, 7.6, 5.15), CREAM)

static func atmosphere(w: SakuraWorld) -> void:
	CV.atmosphere(w)
	w.sun.light_energy = 0.9
	w.sun.rotation_degrees = Vector3(-42, -28, 0)
	w.sky_mat.sky_top_color = Color("338dc5")
	w.sky_mat.sky_horizon_color = Color("c3dfdd")
	w.sky_mat.ground_horizon_color = Color("c3dfdd")
	w.sky_mat.ground_bottom_color = Color("358a99")
	w.env.fog_light_color = Color("95c7cf")
	w.env.fog_density = 0.0008
