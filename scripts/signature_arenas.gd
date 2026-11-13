class_name SignatureArenas
extends RefCounted
## Original layouts. Every solid decoration shares its footprint with bot navigation.
const CV := preload("res://scripts/curated_village.gd")
static var scenes := {}
static var bounds := {}
static var mats := {}

static func material(color: String, stone: bool = false, glow: bool = false) -> StandardMaterial3D:
	var key := color + str(stone) + str(glow)
	if not mats.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color)
		mat.roughness = 0.86
		if stone:
			mat.albedo_texture = preload("res://assets/third_party/quaternius_village/T_UnevenBrick_BaseColor.png")
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = true
			mat.uv1_scale = Vector3(0.38, 0.38, 0.38)
		if glow:
			mat.emission_enabled = true
			mat.emission = Color(color)
			mat.emission_energy_multiplier = 0.6
		mats[key] = mat
	return mats[key]

static func mesh(w: SakuraWorld, shape: PrimitiveMesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	# ArrayMeshes are merged by material and cell once construction finishes.
	node.mesh = ArrayMesh.new()
	node.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shape.get_mesh_arrays())
	node.material_override = mat
	node.position = at
	w._stage_root.add_child(node)
	return node

static func solid(w: SakuraWorld, at: Vector3, size: Vector3) -> void:
	CV.collision(w, at, size)

static func block(w: SakuraWorld, at: Vector3, size: Vector3, color: String, collide: bool = true, stone: bool = false) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	mesh(w, shape, at, material(color, stone))
	if collide:
		solid(w, at, size)

static func cylinder(w: SakuraWorld, at: Vector3, radius: float, height: float, color: String, top: float = -1) -> void:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 20
	shape.rings = 1
	mesh(w, shape, at, material(color))

static func ring(w: SakuraWorld, at: Vector3, radius: float, thickness: float, color: String, tilt: float = 0) -> void:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 40
	shape.ring_segments = 6
	mesh(w, shape, at, material(color, false, true)).rotation.z = tilt

static func _bounds(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var result := AABB()
	var xf := transform * node.transform
	if node is MeshInstance3D:
		result = xf * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _bounds(child, xf)
			if b.size.length_squared() > 0:
				result = b if result.size.length_squared() == 0 else result.merge(b)
	return result

static func prop(w: SakuraWorld, pack: String, asset: String, at: Vector3, size: Vector3, yaw: float = 0) -> Node3D:
	var path := "res://assets/third_party/%s/%s.%s" % [pack, asset, "glb" if pack == "kenney_pirate" else "gltf"]
	if not scenes.has(path):
		scenes[path] = load(path)
	var node: Node3D = scenes[path].instantiate()
	if not bounds.has(path):
		bounds[path] = _bounds(node)
	var box: AABB = bounds[path]
	var root := Node3D.new()
	w._stage_root.add_child(root)
	root.add_child(node)
	# Some modular floors are truly planar: never divide by a zero AABB axis.
	var scale_vec := size / box.size.max(Vector3.ONE * 0.01)
	node.scale = scale_vec
	node.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * scale_vec
	root.position = at
	root.rotation.y = yaw
	CV._prepare(node, Color.WHITE)
	return root

static func signpost(w: SakuraWorld, text: String, at: Vector3, color: String, yaw: float = 0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = preload("res://assets/ui/blossom/nunito_sans.ttf")
	label.font_size = 64
	label.pixel_size = 0.007
	label.modulate = Color(color)
	label.outline_size = 5
	label.outline_modulate = Color("253746")
	label.position = at
	label.rotation.y = yaw
	w._stage_root.add_child(label)

static func canopy(w: SakuraWorld, at: Vector3, color: String, yaw: float = 0, scale_vec: Vector3 = Vector3.ONE) -> void:
	var root := Node3D.new()
	w._stage_root.add_child(root)
	root.position = at
	root.rotation.y = yaw
	root.scale = scale_vec
	CV.awning(root, Color(color))

static func build(w: SakuraWorld, index: int) -> void:
	w.arena_navigation = ArenaNavigation.new()
	w._current_pvp_spawn = Vector3(0, 0.2, 23)
	w.tr_spawns = [Vector3(-21, 0.2, -23), Vector3(21, 0.2, -23), Vector3(0, 0.2, -23), Vector3(-21, 0.2, 23), Vector3(21, 0.2, 23), Vector3(5, 0.2, 7)]
	CV.collision(w, Vector3(0, -0.3, 0), Vector3(56, 0.6, 60))
	for side in [-1.0, 1.0]:
		solid(w, Vector3(side * 26, 2, 0), Vector3(0.5, 4, 56))
		solid(w, Vector3(0, 2, side * 28), Vector3(52, 4, 0.5))
	match index:
		6: bazaar(w)
		7: docks(w)
		8: observatory(w)
	w.arena_navigation.build()
	ImportedSceneryBatch.bake(w._stage_root)

static func bazaar(w: SakuraWorld) -> void:
	block(w, Vector3(0, -0.09, 0), Vector3(100, 0.16, 110), "d8b887", false, true)
	# Offset courtyard blocks form a dogleg lane, an arcade and a broad garden flank.
	for spec in [Vector4(-12, -12, 8, 8), Vector4(10, -9, 10, 8), Vector4(-9, 8, 8, 7), Vector4(13, 11, 8, 6)]:
		bazaar_house(w, Vector3(spec.x, 0, spec.y), Vector2(spec.z, spec.w), 5.5 if spec.x < 0 else 4.2)
	for side in [-1.0, 1.0]:
		for z in [-24.0, -12.0, 0.0, 12.0, 24.0]:
			bazaar_house(w, Vector3(side * 32, 0, z), Vector2(8, 10), 6 + fmod(z + 24, 3))
	for x in [-20.0, -9.0, 8.0, 20.0]:
		bazaar_house(w, Vector3(x, 0, -34), Vector2(9, 8), 7 if x < 0 else 5)
	# Landmark: octagonal shaded tea pavilion, with passages on every side.
	cylinder(w, Vector3(0, 0.7, -4), 2.7, 1.4, "4b8f8c")
	solid(w, Vector3(0, 0.7, -4), Vector3(5.4, 1.4, 5.4))
	for x in [-2.6, 2.6]:
		for z in [-6.6, -1.4]:
			cylinder(w, Vector3(x, 2.1, z), 0.15, 4.2, "dfbe78")
	cylinder(w, Vector3(0, 4.2, -4), 4, 1.4, "397f85", 0.3)
	cylinder(w, Vector3(0, 5.1, -4), 0.12, 0.8, "e6c47c")
	ring(w, Vector3(0, 4.08, -4), 3.75, 0.08, "e0bd7b")
	for p in [Vector3(-19, 0, 4), Vector3(20, 0, -1), Vector3(-5, 0, -19), Vector3(6, 0, 16)]:
		market(w, p, "ae596d")
	for p in [Vector3(-20, 0, 17), Vector3(20, 0, -18), Vector3(-21, 0, -5), Vector3(3, 0, -16)]:
		planter(w, p, false)
	for z in [-16.0, 4.0, 19.0]:
		bunting(w, Vector3(-22, 6.6, z), Vector3(22, 6.6, z - 3), false)
	signpost(w, "BAZAR SOLAR", Vector3(0, 6.5, -28), "f2d48c")
	signpost(w, "CHÁ & ESPECIARIAS", Vector3(-9, 3.5, 11.6), "ffe5ac")
	# Texture-backed rugs mark crossings, below player collision.
	for p in [Vector3(0, 0.015, 9), Vector3(13, 0.015, -1), Vector3(-13, 0.015, -2)]:
		block(w, p, Vector3(3, 0.02, 5), "954b65", false)
		for x in [-1.3, 1.3]:
			block(w, p + Vector3(x, 0.015, 0), Vector3(0.1, 0.02, 4.7), "e4c18a", false)

static func bazaar_house(w: SakuraWorld, at: Vector3, footprint: Vector2, height: float) -> void:
	block(w, at + Vector3(0, height / 2, 0), Vector3(footprint.x, height, footprint.y), "d4b187" if at.x < 0 else "d6b9a2", true, true)
	# Painted plaster facade, with a stone footing and framed windows.
	if not mats.has("plaster"):
		var plaster_mat: StandardMaterial3D = material("ead1ae").duplicate()
		plaster_mat.albedo_texture = preload("res://assets/third_party/quaternius_village/T_Plaster_BaseColor.png")
		plaster_mat.uv1_triplanar = true
		plaster_mat.uv1_world_triplanar = true
		plaster_mat.uv1_scale = Vector3.ONE * 0.3
		mats["plaster"] = plaster_mat
	var facade := BoxMesh.new()
	facade.size = Vector3(footprint.x + 0.015, height - 1.1, footprint.y + 0.015)
	mesh(w, facade, at + Vector3(0, (height + 1.1) / 2, 0), mats["plaster"])
	block(w, at + Vector3(0, height, 0), Vector3(footprint.x + 0.45, 0.3, footprint.y + 0.45), "eee0b6", false, true)
	for side in [-1.0, 1.0]:
		block(w, at + Vector3(side * (footprint.x / 2 - 0.15), height + 0.45, 0), Vector3(0.3, 0.7, footprint.y), "d8bb8d", false, true)
		block(w, at + Vector3(0, height + 0.45, side * (footprint.y / 2 - 0.15)), Vector3(footprint.x, 0.7, 0.3), "d8bb8d", false, true)
		for x in [-2.4, 0.0, 2.4]:
			var front := at + Vector3(x, 0, side * (footprint.y / 2 + 0.06))
			if x == 0:
				CV.model(w._stage_root, "DoorFrame_Round_Brick", front, 0 if side > 0 else PI, 1, false, Color("dfbf92"))
				CV.model(w._stage_root, "Door_2_Round", front + Vector3(-0.55, 0, 0), 0, 1, false, Color("75a8aa"))
			else:
				CV.model(w._stage_root, "Window_Wide_Round1", front + Vector3(0, 0.2, 0), 0 if side > 0 else PI, 1, false, Color("9bbbbb"))
				CV.model(w._stage_root, "WindowShutters_Wide_Round_Open", front + Vector3(0, 0.2, 0), 0 if side > 0 else PI, 1)
			if height > 5:
				CV.model(w._stage_root, "WindowShutters_Wide_Round_Open", front + Vector3(0, 3.4, 0), 0 if side > 0 else PI, 0.65)
	canopy(w, at + Vector3(0, 0, footprint.y / 2 - 3), "477f83", 0, Vector3(1.2, 1.15, 1))
	if absf(at.x) < 25:
		CV.model(w._stage_root, "Prop_Vine4", at + Vector3(footprint.x / 2 - 0.3, height - 0.2, footprint.y / 2 + 0.12), 0, 0.9)
	if height > 5:
		var dome := SphereMesh.new()
		dome.radius = 2.2
		dome.height = 4.4
		dome.radial_segments = 24
		dome.rings = 12
		mesh(w, dome, at + Vector3(0, height - 0.2, 0), material("528e8d"))
		cylinder(w, at + Vector3(0, height + 2.25, 0), 0.12, 0.7, "e6c47c")

static func market(w: SakuraWorld, at: Vector3, color: String) -> void:
	block(w, at + Vector3(0, 0.7, 0), Vector3(3.4, 1.4, 1.6), "84644f", true, true)
	canopy(w, at + Vector3(0, 0.3, -4), color, 0, Vector3(0.85, 1, 1))
	for side in [-1.0, 1.0]:
		cylinder(w, at + Vector3(side * 1.8, 1.6, 0.8), 0.08, 3.2, "b69769")
	for i in 4:
		prop(w, "kenney_pirate", "crate-bottles" if i % 2 == 0 else "chest", at + Vector3(-1.2 + i * 0.8, 1.4, 0), Vector3(0.65, 0.38, 0.65))

static func planter(w: SakuraWorld, at: Vector3, lunar: bool) -> void:
	block(w, at + Vector3(0, 0.6, 0), Vector3(3.3, 1.2, 2.3), "466175" if lunar else "dcc69d", true, not lunar)
	CV.model(w._stage_root, "Bush_Large_Flowers", at + Vector3(0, 1.1, 0), 0, 1, true)
	if not lunar:
		prop(w, "kenney_pirate", "palm-detailed-bend", at + Vector3(0, 1.1, 0), Vector3(4, 6, 3.8))

static func bunting(w: SakuraWorld, a: Vector3, b: Vector3, lights: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 22:
		var t := (i + 0.5) / 22.0
		var p := a.lerp(b, t) - Vector3.UP * sin(t * PI) * 1.2
		var color := Color(["b95f78", "eacb89", "68aca5"][i % 3])
		for v in [p - Vector3(0.35, 0, 0), p + Vector3(0.35, 0, 0), p - Vector3(0, 0.65, 0)]:
			st.set_color(color)
			st.add_vertex(v)
		if lights and i % 3 == 0:
			cylinder(w, p - Vector3(0, 0.8, 0), 0.13, 0.22, "ffe4a6")
	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	w._stage_root.add_child(node)

static func docks(w: SakuraWorld) -> void:
	var ocean := PlaneMesh.new()
	ocean.size = Vector2(500, 500)
	var water := ShaderMaterial.new()
	water.shader = preload("res://assets/shaders/harbor_water.gdshader")
	mesh(w, ocean, Vector3(0, -1.8, 0), water)
	block(w, Vector3(0, -0.35, 0), Vector3(53, 0.7, 57), "756958", false, true)
	for x in range(-24, 25, 4):
		for z in range(-26, 27, 4):
			prop(w, "quaternius_village", "Floor_WoodDark", Vector3(x, -0.04, z), Vector3(4, 0.045, 4))
	# Long quay, broken loading lane, covered market; ships are outside combat bounds.
	for x in range(-25, 26, 2):
		block(w, Vector3(x, 0.005, 0), Vector3(0.035, 0.015, 55), "504e4a", false)
	for side in [-1.0, 1.0]:
		for z in range(-27, 28, 4):
			cylinder(w, Vector3(side * 25.5, 0.55, z), 0.21, 1.1, "63777c")
		block(w, Vector3(side * 26, 0.5, 0), Vector3(0.35, 1, 56), "abb7ac", false)
	for spec in [Vector3(-13, 0, -8), Vector3(11, 0, 9)]:
		warehouse(w, spec)
	for p in [Vector3(-4, 0, -16), Vector3(6, 0, -6), Vector3(-7, 0, 9), Vector3(16, 0, -16), Vector3(-19, 0, 16), Vector3(-7, 0, 20), Vector3(19, 0, 21), Vector3(-21, 0, -2)]:
		cargo(w, p)
	for p in [Vector3(0, 0, 3), Vector3(19, 0, 0), Vector3(-20, 0, -21)]:
		market(w, p, "518d93")
	prop(w, "kenney_pirate", "ship-large", Vector3(37, -1.6, -5), Vector3(12, 19, 30), -0.12)
	prop(w, "kenney_pirate", "ship-medium", Vector3(-36, -1.6, 12), Vector3(10, 14, 21), 0.3)
	prop(w, "kenney_pirate", "ship-small", Vector3(8, -1.6, -44), Vector3(6, 9, 13), 1.1)
	prop(w, "kenney_pirate", "tower-complete-large", Vector3(-22, -1, -37), Vector3(9, 23, 9))
	for side in [-1.0, 1.0]:
		for z in [-20.0, 3.0, 22.0]:
			prop(w, "kenney_pirate", "boat-row-large", Vector3(side * 29, -1.5, z), Vector3(2.2, 1.1, 5), side * 0.2)
		for z in [-17.0, 15.0]:
			planter(w, Vector3(side * 23, 0, z), false)
		# Merchant tables and mooring equipment make the outer quay a short-range flank.
		for z in [-9.0, 10.0]:
			prop(w, "kenney_pirate", "cannon-mobile", Vector3(side * 23, 0, z), Vector3(2.4, 1.5, 1.5), PI / 2)
			solid(w, Vector3(side * 23, 0.65, z), Vector3(1.5, 1.3, 2.4))
		prop(w, "kenney_pirate", "flag-high-pennant", Vector3(side * 24, 0, -25), Vector3(1.3, 5, 0.2))
		prop(w, "kenney_pirate", "rocks-a", Vector3(side * 65, -2, -70), Vector3(28, 12, 22))
	for z in [-21.0, -2.0, 19.0]:
		bunting(w, Vector3(-24, 7.5, z), Vector3(24, 7.5, z + 4), true)
	# A timber hoist gives the cargo crossing a clear silhouette.
	for x in [-6.0, 2.0]:
		block(w, Vector3(x, 4, -19), Vector3(0.45, 8, 0.45), "ba9870")
	block(w, Vector3(-2, 8, -19), Vector3(9.5, 0.5, 0.6), "ba9870", false)
	cylinder(w, Vector3(-1, 5.6, -19), 0.045, 4.8, "555b5b")
	signpost(w, "DOCAS DO FESTIVAL", Vector3(-2, 8.6, -19), "ffe4af")

static func warehouse(w: SakuraWorld, at: Vector3) -> void:
	# Closed storehouses, explicitly solid; the fight follows their verandas.
	block(w, at + Vector3(0, 2.3, 0), Vector3(8, 4.6, 10), "769b9e", true, true)
	for x in [-4.0, 4.0]:
		for z in [-5.0, 5.0]:
			block(w, at + Vector3(x, 2.4, z), Vector3(0.22, 4.8, 0.22), "d3bc96", false)
	prop(w, "quaternius_village", "Roof_RoundTiles_6x8", at + Vector3(0, 4.6, 0), Vector3(10, 3.5, 12))
	for side in [-1.0, 1.0]:
		for x in [-2.4, 0.0, 2.4]:
			CV.model(w._stage_root, "Window_Wide_Round1", at + Vector3(x, 0.5, side * 5.05), 0 if side > 0 else PI)
	canopy(w, at + Vector3(0, 0.5, 2), "b05d6b", 0, Vector3(1.5, 1, 1))
	signpost(w, "ARMAZÉM  •  CHÁ & MAR", at + Vector3(0, 4, 5.1), "f6dfb3")

static func cargo(w: SakuraWorld, at: Vector3) -> void:
	for x in [-0.9, 0.9]:
		prop(w, "kenney_pirate", "crate", at + Vector3(x, 0, 0), Vector3(1.7, 1.7, 1.7))
	prop(w, "kenney_pirate", "crate", at + Vector3(-0.8, 1.7, 0), Vector3(1.4, 1.4, 1.4), 0.06)
	solid(w, at + Vector3(0, 0.85, 0), Vector3(3.5, 1.7, 1.7))
	solid(w, at + Vector3(-0.8, 2.4, 0), Vector3(1.4, 1.4, 1.4))
	prop(w, "kenney_pirate", "barrel", at + Vector3(2.3, 0, 0), Vector3(0.9, 1.3, 0.9))
	solid(w, at + Vector3(2.3, 0.65, 0), Vector3(0.9, 1.3, 0.9))

static func observatory(w: SakuraWorld) -> void:
	block(w, Vector3(0, -0.12, 0), Vector3(54, 0.24, 58), "384658", false)
	# Two interlinked research wings and an open planetarium ring.
	for x in range(-24, 25, 4):
		for z in range(-26, 27, 4):
			prop(w, "quaternius_scifi", "Platform_Metal", Vector3(x, 0.015, z), Vector3(4, 0.08, 4))
	for side in [-1.0, 1.0]:
		for z in range(-26, 27, 4):
			prop(w, "quaternius_scifi", "WallAstra_Straight_Window", Vector3(side * 26, 0, z), Vector3(0.9, 5, 4))
		for x in range(-24, 25, 4):
			prop(w, "quaternius_scifi", "WallAstra_Straight", Vector3(x, 0, side * 28), Vector3(0.9, 5, 4), PI / 2)
		# Covered perimeter galleries connect the labs without crossing the central ring.
		block(w, Vector3(side * 22, 5, 0), Vector3(6, 0.35, 42), "718a9f", false)
		for z in [-18.0, -6.0, 6.0, 18.0]:
			prop(w, "quaternius_scifi", "Column_MetalSupport", Vector3(side * 19.4, 0, z), Vector3(0.6, 5, 0.6))
			solid(w, Vector3(side * 19.4, 2.5, z), Vector3(0.6, 5, 0.6))
			prop(w, "quaternius_scifi", "Prop_Light_Wide", Vector3(side * 25, 3.8, z), Vector3(0.3, 0.4, 2))
	for p in [Vector3(-13, 0, -10), Vector3(13, 0, 9)]:
		# Opaque labs interrupt cross-map fire; corridors wrap around both ends.
		block(w, p + Vector3(0, 2.25, 0), Vector3(8, 4.5, 10), "657481")
		for side in [-1.0, 1.0]:
			for z in [-4.0, 0.0, 4.0]:
				prop(w, "quaternius_scifi", "WallAstra_Straight", p + Vector3(side * 4, 0, z), Vector3(0.8, 4.6, 4))
			prop(w, "quaternius_scifi", "Door_Frame_A", p + Vector3(0, 0, side * 5.05), Vector3(4.8, 4, 0.7))
			prop(w, "quaternius_scifi", "Prop_AccessPoint", p + Vector3(2.8, 0.5, side * 5.1), Vector3(0.9, 1.5, 0.3), 0 if side > 0 else PI)
		block(w, p + Vector3(0, 4.7, 0), Vector3(9, 0.4, 11), "9aabba", false)
		for z in [-3.0, 3.0]:
			prop(w, "quaternius_scifi", "Prop_Vent_Big", p + Vector3(0, 4.9, z), Vector3(3, 1, 2))
	for p in [Vector3(-12, 0, 9), Vector3(12, 0, -10), Vector3(-5, 0, -20), Vector3(5, 0, 19)]:
		prop(w, "quaternius_scifi", "Prop_Crate3", p, Vector3(3, 2.1, 2))
		solid(w, p + Vector3(0, 1.05, 0), Vector3(3, 2.1, 2))
		prop(w, "quaternius_scifi", "Prop_Barrel_Large", p + Vector3(2.5, 0, 0), Vector3(1.2, 2, 1.2))
		solid(w, p + Vector3(2.5, 1, 0), Vector3(1.2, 2, 1.2))
	cylinder(w, Vector3(0, 1, -2), 3.4, 2, "697d8c")
	solid(w, Vector3(0, 1, -2), Vector3(6.8, 2, 6.8))
	var orb := SphereMesh.new()
	orb.radius = 1.6
	orb.height = 3.2
	orb.radial_segments = 32
	orb.rings = 16
	mesh(w, orb, Vector3(0, 4, -2), material("92bad1", true, true))
	ring(w, Vector3(0, 4, -2), 2.8, 0.05, "f2d396", 0.5)
	ring(w, Vector3(0, 4, -2), 3.3, 0.06, "75d4d0", -0.7)
	# Dome ribs and supporting colonnade frame the astronomical instrument.
	for i in 8:
		var angle := i * TAU / 8
		var p := Vector3(cos(angle) * 9, 0, sin(angle) * 9 - 2)
		prop(w, "quaternius_scifi", "Column_Round", p, Vector3(0.7, 7.5, 0.7))
		solid(w, p + Vector3(0, 3.75, 0), Vector3(0.7, 7.5, 0.7))
		# Upper hemisphere only; no decorative arcs intersect walkable ground.
		for step in 12:
			var a := step * PI / 24
			var b := (step + 1) * PI / 24
			var start := Vector3(cos(angle) * cos(a) * 9.4, 7.5 + sin(a) * 9.4, sin(angle) * cos(a) * 9.4 - 2)
			var end := Vector3(cos(angle) * cos(b) * 9.4, 7.5 + sin(b) * 9.4, sin(angle) * cos(b) * 9.4 - 2)
			var rib := CylinderMesh.new()
			rib.top_radius = 0.07
			rib.bottom_radius = 0.07
			rib.height = start.distance_to(end)
			rib.radial_segments = 6
			var bar := mesh(w, rib, (start + end) * 0.5, material("768a9c"))
			bar.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	ring(w, Vector3(0, 7.5, -2), 9.4, 0.18, "7ed9d4")
	for p in [Vector3(-21, 0, -2), Vector3(21, 0, 0), Vector3(-20, 0, 19), Vector3(20, 0, -20)]:
		planter(w, p, true)
		CV.model(w._stage_root, "BirchTree_1", p + Vector3(0, 1, 0), 0, 0.65, true)
	for p in [Vector3(-7, 0, 13), Vector3(8, 0, -16)]:
		planter(w, p, true)
		prop(w, "quaternius_scifi", "Prop_Crate4", p + Vector3(-2.6, 0, 0), Vector3(1.5, 1.5, 1.5))
		solid(w, p + Vector3(-2.6, 0.75, 0), Vector3(1.5, 1.5, 1.5))
	for side in [-1.0, 1.0]:
		for z in [-20.0, 20.0]:
			prop(w, "quaternius_scifi", "Prop_Computer", Vector3(side * 11, 0, z), Vector3(3, 1.4, 1.4), 0 if z < 0 else PI)
			solid(w, Vector3(side * 11, 0.7, z), Vector3(3, 1.4, 1.4))
		block(w, Vector3(side * 23, 0.02, 0), Vector3(0.08, 0.025, 52), "7dd5d1", false)
		block(w, Vector3(side * 5, 0.02, 12), Vector3(0.08, 0.025, 12), "e4bc77", false)
	signpost(w, "OBSERVATÓRIO  /  SELENE", Vector3(0, 5.8, -27), "bce8ed")
	signpost(w, "01  •  BOTÂNICA", Vector3(-13, 4.1, -4.6), "b3e2c0")
	signpost(w, "02  •  ASTROMETRIA", Vector3(13, 4.1, 14.6), "e3d0fa")
	var moon := SphereMesh.new()
	moon.radius = 19
	moon.height = 38
	moon.radial_segments = 32
	moon.rings = 16
	mesh(w, moon, Vector3(-38, 34, -85), material("c5d8e4", true, true))

static func atmosphere(w: SakuraWorld, index: int) -> void:
	CV.atmosphere(w)
	match index:
		6:
			w.sun.light_color = Color("ffe2b3")
			w.sun.rotation_degrees = Vector3(-42, -30, 0)
			w.sky_mat.sky_top_color = Color("5996ae")
			w.sky_mat.sky_horizon_color = Color("ead5b5")
			w.env.fog_light_color = Color("e4c795")
		7:
			w.sun.light_color = Color("ffe6ce")
			w.sun.rotation_degrees = Vector3(-27, -48, 0)
			w.sky_mat.sky_top_color = Color("729da9")
			w.sky_mat.sky_horizon_color = Color("f2cead")
			w.env.fog_light_color = Color("a1c0c6")
		8:
			w.sun.light_color = Color("c4daf4")
			w.sun.light_energy = 0.85
			w.sun.rotation_degrees = Vector3(-54, -32, 0)
			w.env.ambient_light_color = Color("aebedd")
			w.env.ambient_light_energy = 0.55
			w.sky_mat.sky_top_color = Color("101c36")
			w.sky_mat.sky_horizon_color = Color("435d79")
			w.env.fog_light_color = Color("384960")
