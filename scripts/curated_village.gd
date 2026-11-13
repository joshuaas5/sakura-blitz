class_name CuratedVillage
extends RefCounted
## Authored courtyard using Quaternius CC0 modular architecture and nature.
const VILLAGE := "res://assets/third_party/quaternius_village/"
const NATURE := "res://assets/third_party/quaternius_nature/"
static var scenes: Dictionary = {}
static var materials: Dictionary = {}

static func model(parent: Node3D, asset: String, position: Vector3, yaw: float = 0, size: float = 1, nature: bool = false, tint: Color = Color.WHITE) -> Node3D:
	var path := (NATURE if nature else VILLAGE) + asset + ".gltf"
	if not scenes.has(path):
		scenes[path] = load(path)
	var node: Node3D = scenes[path].instantiate()
	parent.add_child(node)
	node.position = position
	node.rotation.y = yaw
	node.scale = Vector3.ONE * size
	_prepare(node, tint)
	return node

static func _prepare(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = 105
		for i in node.mesh.get_surface_count():
			var original: Material = node.get_active_material(i)
			if not original is StandardMaterial3D:
				continue
			var texture_path: String = original.albedo_texture.resource_path if original.albedo_texture != null else ""
			var key := "%s_%s_%s" % [original.resource_name, texture_path, tint.to_html()]
			if not materials.has(key):
				var mat: StandardMaterial3D = original.duplicate()
				mat.metallic = 0
				mat.roughness = 0.85
				mat.albedo_color *= tint
				if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold = 0.4
				if "MapleTree_Leaves" in original.resource_name:
					var blossom := ShaderMaterial.new()
					blossom.shader = preload("res://assets/shaders/blossom_leaves.gdshader")
					blossom.set_shader_parameter("leaf_texture", mat.albedo_texture)
					materials[key] = blossom
				elif "RoundTiles" in original.resource_name and mat.albedo_texture != null:
					var painted := ShaderMaterial.new()
					painted.shader = preload("res://assets/shaders/palette_pigment.gdshader")
					painted.set_shader_parameter("pigment_texture", mat.albedo_texture)
					painted.set_shader_parameter("palette_color", tint if tint != Color.WHITE else Color("ce6580"))
					materials[key] = painted
				else:
					if "Bush_Leaves" in original.resource_name:
						mat.albedo_color *= Color("8fca72")
					materials[key] = mat
			node.set_surface_override_material(i, materials[key])
	for child in node.get_children():
		_prepare(child, tint)

static func collision(w: SakuraWorld, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	w._stage_root.add_child(body)
	if w.arena_navigation != null and position.y + size.y * 0.5 > 0.15 and position.y - size.y * 0.5 < 1.8:
		w.arena_navigation.obstacles.append(AABB(position - size * 0.5, size))

static func house(w: SakuraWorld, p: Vector3, variant: int, yaw: float = 0, upper: bool = false, walkthrough: bool = false) -> void:
	var root := Node3D.new()
	w._stage_root.add_child(root)
	root.position = p
	root.rotation.y = yaw
	var floors := 2 if upper else 1
	for level in floors:
		for side in 4:
			var angle := side * PI * 0.5
			var basis := Basis(Vector3.UP, angle)
			for segment in [-2.0, 0.0, 2.0]:
				var door: bool = (side == 0 or (walkthrough and side == 2)) and segment == 0 and level == 0
				var window: bool = not door and (side == 0 or (side % 2 == 1 and segment == 0))
				var wall := "Wall_Plaster_Door_Round" if door else ("Wall_Plaster_Window_Wide_Round" if window else "Wall_Plaster_WoodGrid")
				var at := basis * Vector3(segment, level * 3, 3)
				model(root, wall, at, angle)
				if door:
					model(root, "DoorFrame_Round_Brick", at, angle)
					if not walkthrough:
						model(root, "Door_2_Round", at + basis * Vector3(-0.55, 0, 0), angle)
				elif window:
					model(root, "Window_Wide_Round1", at, angle)
					model(root, "WindowShutters_Wide_Round_Open", at, angle)
				if segment == -2 and side % 2 == 0:
					model(root, "Prop_Vine1", at + Vector3(0, 2.8, 0), angle)
	var roof_tint: Color = [Color("d85c84"), Color("36a58c"), Color("5787c8"), Color("e5a34a")][variant % 4]
	model(root, "Roof_RoundTiles_6x6", Vector3(0, floors * 3, 0), 0, 1, false, roof_tint)
	model(root, "Roof_Front_Brick6", Vector3(0, floors * 3, 3), 0)
	model(root, "Roof_Front_Brick6", Vector3(0, floors * 3, -3), PI)
	model(root, "Prop_Chimney2", Vector3(-1.9, floors * 3 + 1.3, -1.5))
	model(root, "Prop_Crate", Vector3(-2.7, 0, 3.8), 0.12)
	model(root, "Prop_Crate", Vector3(-2.3, 1.04, 3.7), -0.2, 0.75)
	if variant % 2 == 0:
		awning(root, Color("9a4b62") if variant % 4 == 0 else Color("457b7d"))
	if walkthrough:
		var orientation := Basis(Vector3.UP, yaw)
		for side in [-1.0, 1.0]:
			collision(w, p + orientation * Vector3(side * 3, 1.5, 0), (orientation * Vector3(0.4, 3, 6)).abs())
			for x in [-2.0, 2.0]:
				collision(w, p + orientation * Vector3(x, 1.5, side * 3), (orientation * Vector3(2, 3, 0.4)).abs())
			collision(w, p + orientation * Vector3(0, 2.7, side * 3), (orientation * Vector3(2, 0.6, 0.4)).abs())
		collision(w, p + Vector3(0, 3.05, 0), Vector3(6, 0.25, 6))
		VillageAtelier.room(w, root, p, yaw)
	else:
		collision(w, p + Vector3(0, floors * 1.5, 0), Vector3(6, floors * 3, 6))

static func build(w: SakuraWorld) -> void:
	w.arena_navigation = ArenaNavigation.new()
	w._current_pvp_spawn = Vector3(0, 0.2, 14)
	w.tr_spawns = [Vector3(-7, 0.2, -17), Vector3(7, 0.2, -17), Vector3(0, 0.2, -21), Vector3(-7, 0.2, 15), Vector3(7, 0.2, 15), Vector3(0, 0.2, 5)]
	collision(w, Vector3(0, -0.25, 0), Vector3(58, 0.5, 62))
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 110)
	ground.mesh = plane
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = preload("res://assets/third_party/quaternius_village/T_UnevenBrick_BaseColor.png")
	stone.albedo_color = Color("d5cfbd")
	stone.uv1_scale = Vector3(38, 38, 38)
	stone.roughness = 0.95
	ground.material_override = stone
	w._stage_root.add_child(ground)
	# Four courtyard blocks, wide central route and two outer flanks.
	house(w, Vector3(-10, 0, -10), 0, 0, true)
	house(w, Vector3(10, 0, -10), 1, 0, false)
	house(w, Vector3(-10, 0, 10), 2, PI * 0.5, false, true)
	house(w, Vector3(10, 0, 10), 3, -PI * 0.5, true)
	# Background street: an inhabited skyline rather than flat arena walls.
	for i in 5:
		house(w, Vector3(-24 + i * 12, 0, -30 - (i % 2) * 3), i, 0, i % 2 == 0)
	for side in [-1.0, 1.0]:
		for i in 3:
			house(w, Vector3(side * 32, 0, -13 + i * 18), i + 1, -side * PI * 0.5, i == 1)
	# Garden islands split fire lanes and offer readable, solid cover.
	for side in [-1.0, 1.0]:
		for z in [-3.0, 7.0]:
			var at := Vector3(side * 6, 0, z)
			for x in [-1.0, 1.0]:
				model(w._stage_root, "Prop_Crate", at + Vector3(x * 0.7, 0, 0), 0, 1.15)
			collision(w, at + Vector3(0, 0.6, 0), Vector3(2.7, 1.2, 1.2))
			model(w._stage_root, "Bush_Large_Flowers", at + Vector3(0, 1.05, 0), 0, 0.7, true)
		model(w._stage_root, "Prop_Wagon", Vector3(side * 18, 0, -1), side * PI * 0.5, 1.2)
		collision(w, Vector3(side * 18, 0.65, -1), Vector3(4, 1.3, 2.2))
	# Continuous boundary collision, concealed by trees and the surrounding village.
	for side in [-1.0, 1.0]:
		collision(w, Vector3(side * 26, 3, 0), Vector3(0.5, 6, 56))
		collision(w, Vector3(0, 3, side * 28), Vector3(52, 6, 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 512
	for side in [-1.0, 1.0]:
		for i in 10:
			var p := Vector3(side * rng.randf_range(21, 25), 0, -25 + i * 5.5)
			model(w._stage_root, "MapleTree_1" if i % 2 == 0 else "BirchTree_1", p, rng.randf() * TAU, rng.randf_range(0.8, 1.2), true)
			model(w._stage_root, "Bush_Small_Flowers", p + Vector3(-side * 1.2, 0, 0), rng.randf() * TAU, 1, true)
			for j in 3:
				model(w._stage_root, "Flower_1_Clump" if j % 2 == 0 else "Flower_3_Clump", p + Vector3(-side * (1.5 + j * 0.6), 0.01, rng.randf_range(-2, 2)), rng.randf() * TAU, 0.8, true)
	for p in [Vector3(-5, 0, -18), Vector3(6, 0, -20), Vector3(-18, 0, 18), Vector3(18, 0, 19)]:
		model(w._stage_root, "MapleTree_2", p, 0, 1.1, true)
		collision(w, p + Vector3(0, 1, 0), Vector3(0.5, 2, 0.5))

	# Curated ground-level clusters add detail without narrowing the playable lanes.
	for side in [-1.0, 1.0]:
		for z in [-13.0, -7.0, 8.0, 12.0]:
			for j in 4:
				var p := Vector3(side * (5.8 + j * 0.35), 0.02, z + rng.randf_range(-0.8, 0.8))
				model(w._stage_root, "Flower_5_Clump" if j % 2 == 0 else "Grass_Small", p, rng.randf() * TAU, 0.65, true)
	fountain(w, Vector3(0, 0, -8))
	# A tall tower and a canopy of blossoms establish a recognizable town center.
	model(w._stage_root, "Roof_Tower_RoundTiles", Vector3(0, 6, -31), 0, 1.1)
	for side in [-1.0, 1.0]:
		model(w._stage_root, "MapleTree_2", Vector3(side * 7.5, 0, -15), side * 0.5, 1.65, true)
		collision(w, Vector3(side * 7.5, 1, -15), Vector3(0.7, 2, 0.7))
		for z in [4.0, 13.0]:
			model(w._stage_root, "Prop_WoodenFence_Single", Vector3(side * 19, 0, z), PI * 0.5, 1)
	for side in [-1.0, 1.0]:
		model(w._stage_root, "MapleTree_2", Vector3(side * 16, 0, 18), side, 1.8, true)
		for j in 5:
			model(w._stage_root, "Flower_3_Clump", Vector3(side * (4.8 + j * 0.35), 0.03, 13 + sin(j) * 0.4), j * 0.7, 0.8, true)
	VillageAtelier.decorate(w)
	w.arena_navigation.build()
	ImportedSceneryBatch.bake(w._stage_root)

static func awning(root: Node3D, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stripe in 10:
		var x := -2.4 + stripe * 0.48
		var c := color if stripe % 2 == 0 else Color("e9d8b8")
		for step in 6:
			var t := step / 6.0
			var n := (step + 1) / 6.0
			var a := Vector3(x, 2.85 - t * 0.5 - sin(t * PI) * 0.1, 3.12 + t * 1.9)
			var b := Vector3(x + 0.48, a.y, a.z)
			var d := Vector3(x, 2.85 - n * 0.5 - sin(n * PI) * 0.1, 3.12 + n * 1.9)
			var e := Vector3(x + 0.48, d.y, d.z)
			for v in [a, d, b, b, d, e]:
				surface.set_color(c)
				surface.add_vertex(v)
		# Scalloped hanging fabric edge, matching the striped canopy.
		for v in [Vector3(x, 2.35, 5.02), Vector3(x + 0.24, 2.1, 5.02), Vector3(x + 0.48, 2.35, 5.02)]:
			surface.set_color(c)
			surface.add_vertex(v)
	surface.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(mat)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	root.add_child(mesh)

static func fountain(w: SakuraWorld, at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	w._stage_root.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = preload("res://assets/third_party/quaternius_village/T_UnevenBrick_BaseColor.png")
	stone.albedo_color = Color("c5c6bc")
	stone.roughness = 0.9
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("6daaa4")
	water.roughness = 0.24
	water.metallic = 0.2
	for spec in [Vector4(2.1, 2.25, 0.28, 0.14), Vector4(2, 2.0, 0.25, 0.39), Vector4(0.35, 0.55, 1.3, 0.85), Vector4(0.9, 0.65, 0.25, 1.48)]:
		var mesh := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = spec.x
		cylinder.bottom_radius = spec.y
		cylinder.height = spec.z
		cylinder.radial_segments = 16
		cylinder.rings = 1
		mesh.mesh = cylinder
		mesh.position.y = spec.w
		mesh.material_override = stone
		root.add_child(mesh)
	for tier in 2:
		var mesh := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.77 if tier == 0 else 0.72
		torus.outer_radius = 2.1 if tier == 0 else 0.98
		torus.rings = 24
		torus.ring_segments = 8
		mesh.mesh = torus
		mesh.position.y = 0.56 if tier == 0 else 1.64
		mesh.material_override = stone
		root.add_child(mesh)
		var pool := MeshInstance3D.new()
		var disk := CylinderMesh.new()
		disk.top_radius = 1.92 if tier == 0 else 0.83
		disk.bottom_radius = disk.top_radius
		disk.height = 0.025
		disk.radial_segments = 32
		pool.mesh = disk
		pool.position.y = 0.53 if tier == 0 else 1.61
		pool.material_override = water
		root.add_child(pool)
	collision(w, at + Vector3(0, 0.35, 0), Vector3(4.2, 0.7, 4.2))
	collision(w, at + Vector3(0, 1.15, 0), Vector3(1.7, 0.9, 1.7))

static func atmosphere(w: SakuraWorld) -> void:
	w.sun.shadow_enabled = true
	w.sun.directional_shadow_max_distance = 60
	w.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	w.sun.shadow_bias = 0.06
	w.sun.rotation_degrees = Vector3(-38, -32, 0)
	w.sun.light_energy = 0.90
	w.sun.light_color = Color("fff0d7")
	w.env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	w.env.ambient_light_color = Color("a6bfd5")
	w.env.ambient_light_energy = 0.36
	w.env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.env.fog_enabled = true
	w.env.fog_light_color = Color("c4c8d5")
	w.env.fog_density = 0.0007
	w.env.fog_sky_affect = 0.0
	w.sky_mat.sky_top_color = Color("3c8bd1")
	w.sky_mat.sky_horizon_color = Color("b7def0")
