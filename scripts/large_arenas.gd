class_name LargeArenas
extends RefCounted
## Authored, full-size districts. Routes and spawns use the same solid geometry.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const H := preload("res://scripts/harbor_atelier.gd")
const BOUNDS := [Rect2(-48, -44, 96, 88), Rect2(-56, -38, 112, 76)]

static func build(w: SakuraWorld, stage: int) -> void:
	var tea := stage == 9
	w.combat_bounds = BOUNDS[stage - 9]
	w.arena_navigation = ArenaNavigation.new()
	var size := w.combat_bounds.size
	var floor_shape := BoxMesh.new()
	floor_shape.size = Vector3(size.x + 2, 0.5, size.y + 2)
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://assets/shaders/garden_ground.gdshader") if tea else preload("res://assets/shaders/harbor_apron.gdshader")
	S.mesh(w, floor_shape, Vector3(0, -0.25, 0), floor_mat)
	CV.collision(w, Vector3(0, -0.25, 0), floor_shape.size)
	var landscape := PlaneMesh.new()
	landscape.size = Vector2(1400, 1400)
	S.mesh(w, landscape, Vector3(0, -0.09, 0), S.material("819b72" if tea else "879e96"))
	perimeter(w, tea)
	if tea:
		garden(w)
		DistrictDressing.garden(w)
	else:
		terminal(w)
		DistrictDressing.terminal(w)
	DistrictFinish.build(w, tea)
	w._current_pvp_spawn = Vector3(0, 0.15, size.y / 2 - 5)
	w.tr_spawns = [
		Vector3(-size.x / 2 + 5, 0.15, -size.y / 2 + 5), Vector3(size.x / 2 - 5, 0.15, -size.y / 2 + 5),
		Vector3(-size.x / 2 + 5, 0.15, size.y / 2 - 5), Vector3(size.x / 2 - 5, 0.15, size.y / 2 - 5),
		Vector3(0, 0.15, -size.y / 2 + 5), Vector3(-size.x / 2 + 5, 0.15, 0), Vector3(size.x / 2 - 5, 0.15, 0),
		Vector3(-8, 0.15, -10), Vector3(8, 0.15, 10), Vector3(-30, 0.15, 0), Vector3(30, 0.15, 0),
	]
	for side in [-1, 1]:
		for z in [-30, -18, -6, 6, 18, 30]:
			w.tr_spawns.append(Vector3(side * (size.x / 2 - 3), 0.15, z))
	for z in ([-38, -30, -16, 16, 30, 38] if tea else [-30, -20, -10, 10, 20, 30]):
		w.tr_spawns.append(Vector3(0, 0.15, z))
	for p in [Vector3(-8, 0.04, -10), Vector3(8, 0.04, 10), Vector3(-30, 0.04, 0), Vector3(30, 0.04, 0)]:
		w._add_weapon_pad(p, "SUPRIMENTOS", Color("e7c763"))
	var region := Rect2i(Vector2i(w.combat_bounds.position) + Vector2i.ONE, Vector2i(size) - Vector2i.ONE)
	w.arena_navigation.build(region)
	w._stage_root.set_meta("large_arena", {"bounds": w.combat_bounds, "sectors": w.combat_sectors.size(), "port_area_ratio": size.x * size.y / (38 * 38.0)})
	H.bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root, 200)
	VillageAtelier.ambience(w, "garden_breeze" if tea else "harbor_surf", Vector3(0, 2, 0), 100, -11)

static func sector(w: SakuraWorld, name: String, rect: Rect2) -> void:
	w.combat_sectors.append({"name": name, "bounds": rect})
	var at := rect.get_center()
	# Roads at sector edges link adjacent destinations without long empty journeys.
	w.combat_patrol_points.append(Vector3(at.x, 0.15, at.y))

static func perimeter(w: SakuraWorld, tea: bool) -> void:
	var size := w.combat_bounds.size
	for side in [-1, 1]:
		for axis in 2:
			var basis := Basis(Vector3.UP, PI / 2 if axis == 1 else 0.0)
			var length := size.y if axis == 1 else size.x
			var at := Vector3(side * size.x / 2, 0, 0) if axis == 1 else Vector3(0, 0, side * size.y / 2)
			H.local_block(w, at, basis, Vector3(0, 0.7, 0), Vector3(length, 1.4, 0.5), "b7bba2" if tea else "74949b", true)
			H.local_block(w, at, basis, Vector3(0, 3, 0), Vector3(length, 3.2, 0.4), "51826e" if tea else "355a6b", true)
			for i in int(length / 6) + 1:
				H.local_block(w, at, basis, Vector3(-length / 2 + i * 6, 2.4, 0), Vector3(0.22, 4.8, 0.65), "d5c9a4")
			H.local_block(w, at, basis, Vector3(0, 4.65, 0), Vector3(length, 0.2, 0.6), "e6d5aa")

static func tree(w: SakuraWorld, at: Vector3, variant: int, solid: bool = true) -> void:
	CV.model(w._stage_root, ["MapleTree_1", "MapleTree_2", "BirchTree_1"][variant % 3], at, variant * 1.7, 1.05, true)
	if solid:
		CV.collision(w, at + Vector3.UP * 1.7, Vector3(0.75, 3.4, 0.75))

static func flowerbed(w: SakuraWorld, at: Vector3, wide: bool = false) -> void:
	var width := 6.0 if wide else 3.8
	S.block(w, at + Vector3.UP * 0.55, Vector3(width, 1.1, 2), "c9c8a3", true, true)
	for x in [-1, 1]:
		CV.model(w._stage_root, "Bush_Small_Flowers", at + Vector3(x * width * 0.27, 1, 0), x, 1, true)

static func pavilion(w: SakuraWorld, at: Vector3, roof: String) -> void:
	# A broad covered room with a passage on all four sides; no raised floor.
	for x in [-4.5, 4.5]:
		for z in [-5, 0, 5]:
			S.block(w, at + Vector3(x, 2.1, z), Vector3(0.35, 4.2, 0.35), "775c51", true)
	var tiles := CV.model(w._stage_root, "Roof_RoundTiles_6x6", at + Vector3(0, 4.2, 0), 0, 1, false, Color(roof))
	tiles.scale = Vector3(1.7, 0.9, 2.4)
	S.block(w, at + Vector3(0, 4.1, 0), Vector3(10, 0.22, 14), "c9b284")
	for side in [-1, 1]:
		var gable := CV.model(w._stage_root, "Roof_Front_Brick6", at + Vector3(0, 4.2, side * 7.1), 0 if side > 0 else PI)
		gable.scale = Vector3(1.7, 0.9, 1)
		CV.model(w._stage_root, "Prop_Vine4", at + Vector3(side * 4.4, 3.8, 6.8), 0, 0.9)
	for side in [-1, 1]:
		S.block(w, at + Vector3(side * 3.5, 0.65, 0), Vector3(1.8, 1.3, 3.8), "778e78", true)
	DistrictDressing.plaque(w, "CASA DAS INFUSÕES", at + Vector3(0, 3.3, 6.85), 7, "527f72")

static func greenhouse(w: SakuraWorld, at: Vector3) -> void:
	for side in [-1, 1]:
		for z in [-7, -3.5, 0, 3.5, 7]:
			S.block(w, at + Vector3(side * 5, 2.15, z), Vector3(0.16, 4.3, 0.16), "e7dfbb", true)
		S.block(w, at + Vector3(side * 4, 0.6, 0), Vector3(1.2, 1.2, 13), "a1b993", true)
		var shape := BoxMesh.new()
		shape.size = Vector3(5.4, 0.12, 15.5)
		S.mesh(w, shape, at + Vector3(side * 2.5, 4.5, 0), S.material("97c8c7")).rotation.z = side * -0.19
		for z in [-7.6, -3.8, 0, 3.8, 7.6]:
			H.beam(w, at + Vector3(side * 5.1, 4.02, z), at + Vector3(0, 4.98, z), 0.10, "e7dfbb")
		for z in [-5, -1, 3, 6]:
			CV.model(w._stage_root, "Bush_Small_Flowers", at + Vector3(side * 4, 1.1, z), z, 0.8, true)
	S.signpost(w, "ESTUFA / CAMÉLIAS", at + Vector3(0, 3.4, 7.1), "f1deaa")

static func garden(w: SakuraWorld) -> void:
	for row in 3:
		for col in 3:
			sector(w, ["Pomar Norte", "Casa do Chá", "Alameda das Camélias", "Bosque", "Praça das Infusões", "Estufas", "Jardim de Entrada", "Portão das Flores", "Pátio das Pipas"][row * 3 + col], Rect2(-48 + col * 32, -44 + row * (88.0 / 3), 32, 88.0 / 3))
	# Three longitudinal routes with crossings at north, center and south.
	for x in [-17, 17]:
		for z in [-27, 0, 27]:
			CV.house(w, Vector3(x, 0, z), posmod(int(x + z), 4), PI / 2 if x < 0 else -PI / 2, z == 0, z == 0)
	pavilion(w, Vector3(0, 0, -24), "3e9e91")
	greenhouse(w, Vector3(35, 0, -12))
	greenhouse(w, Vector3(-35, 0, 14))
	CV.fountain(w, Vector3.ZERO)
	S.block(w, Vector3(0, 0.006, 0), Vector3(11, 0.01, 11), "b4c1a2", false, true)
	for x in [-9, 9]:
		for z in [-14, 14]:
			flowerbed(w, Vector3(x, 0, z))
	for x in [-34, 34]:
		for z in [-31, 29]:
			flowerbed(w, Vector3(x, 0, z), true)
	for p in [Vector3(-27, 0, -17), Vector3(27, 0, 17), Vector3(-26, 0, 18), Vector3(27, 0, -27), Vector3(-6, 0, 27), Vector3(7, 0, -37)]:
		flowerbed(w, p)
	for x in [-25, 25]:
		for z in [-35, -8, 8, 35]:
			flowerbed(w, Vector3(x, 0, z))
			tree(w, Vector3(x, 1.1, z), int(absf(x + z)))
	for x in [-12, 12]:
		for z in [-19, 20]:
			S.prop(w, "kenney_pirate", "crate", Vector3(x, 0, z), Vector3(1.7, 1.4, 1.7))
			CV.collision(w, Vector3(x, 0.7, z), Vector3(1.7, 1.4, 1.7))
	for i in 12:
		var x := -43.0 if i % 2 == 0 else 43.0
		var z := -34.0 + (i / 2) * 13
		tree(w, Vector3(x, 0, z), i)
	for z in [-36, 36]:
		S.bunting(w, Vector3(-38, 7, z), Vector3(38, 7, z), false)
	for x in [-10, 10]:
		for z in [-35, 34]:
			CV.model(w._stage_root, "Prop_Wagon", Vector3(x, 0, z), x * 0.07)
			CV.collision(w, Vector3(x, 0.7, z), Vector3(2.6, 1.4, 1.8))
	for side in [-1, 1]:
		for i in 7:
			var at := Vector3(side * 55, -0.5, -48 + i * 16)
			tree(w, at, i + 1, false)
			if i % 2 == 0:
				CV.house(w, Vector3(side * 57, 0, -35 + i * 14), i, 0, true)
		for i in 12:
			tree(w, Vector3(side * 65, -0.05, -66 + i * 12), i, false)
		for z in [-62, 62]:
			var hill := SphereMesh.new()
			hill.radius = 1
			hill.height = 2
			hill.radial_segments = 16
			hill.rings = 8
			var mesh := S.mesh(w, hill, Vector3(side * 85, -8, z), S.material("6c946e"))
			mesh.scale = Vector3(38, 26, 40)
	# Warm fixtures remain painted props; large maps add no dynamic point lights.
	for light in w._stage_root.find_children("*", "OmniLight3D", true, false):
		light.queue_free()
	S.signpost(w, "VALE DO CHÁ", Vector3(0, 6.6, 43.6), "f4dc9b", PI)
	w.combat_patrol_points.assign([Vector3(-32, 0.15, -23), Vector3(0, 0.15, -24), Vector3(32, 0.15, -24), Vector3(-30, 0.15, 0), Vector3(0, 0.15, -10), Vector3(30, 0.15, 0), Vector3(-32, 0.15, 34), Vector3(0, 0.15, 29), Vector3(32, 0.15, 34)])

static func shed(w: SakuraWorld, at: Vector3, color: String) -> void:
	for side in [-1, 1]:
		S.block(w, at + Vector3(side * 7, 3, 0), Vector3(0.45, 6, 14), color, true)
		for x in [-4.8, 4.8]:
			S.block(w, at + Vector3(x, 3, side * 7), Vector3(4.4, 6, 0.45), color, true)
		S.block(w, at + Vector3(0, 5, side * 7), Vector3(5.2, 2, 0.45), "e7dfbb", true)
		for z in [-6.8, 0, 6.8]:
			S.block(w, at + Vector3(side * 6.7, 3.1, z), Vector3(0.25, 6.2, 0.25), "edb83f", true)
	var roof := BoxMesh.new()
	roof.size = Vector3(14.8, 0.24, 15)
	S.mesh(w, roof, at + Vector3(0, 6.1, 0), S.material("36566b"))
	CV.collision(w, at + Vector3(0, 6.1, 0), roof.size)
	for side in [-1, 1]:
		H.factory(w, "machine-window", at + Vector3(side * 5.4, 0, -3), 2.2, -side * PI / 2)
		CV.collision(w, at + Vector3(side * 5.4, 1.1, -3), Vector3(1.8, 2.2, 2.8))
		for z in [-5, 0, 5]:
			S.block(w, at + Vector3(side * 6.1, 4.6, z), Vector3(0.08, 0.1, 2), "e7dfbb")
		H.factory(w, "box-large", at + Vector3(side * 4.8, 0, 3), 1.4)
		CV.collision(w, at + Vector3(side * 4.8, 0.7, 3), Vector3(1.6, 1.4, 1.6))
	S.signpost(w, "OFICINA / GIRASSOL", at + Vector3(0, 4.7, 7.25), "f5dfaa")

static func tram(w: SakuraWorld, at: Vector3, color: String) -> void:
	# Two imported carriages keep the original 15.5 m cover footprint.
	for side in [-1, 1]:
		S.prop(w, "kenney_train", "train-tram-classic", at + Vector3(0, 0, side * 3.9), Vector3(3.8, 3.55, 7.4), PI if side < 0 else 0)
	CV.collision(w, at + Vector3.UP * 1.775, Vector3(3.9, 3.55, 15.5))
	S.signpost(w, "LINHA / SOL", at + Vector3(0, 3.15, 7.66), color)


static func terminal(w: SakuraWorld) -> void:
	for row in 2:
		for col in 3:
			sector(w, ["Oficinas Norte", "Plataforma Norte", "Carga Norte", "Oficinas Sul", "Praça do Relógio", "Carga Sul"][row * 3 + col], Rect2(-56 + col * (112.0 / 3), -38 + row * 38, 112.0 / 3, 38))
	for x in [-40, 40]:
		for z in [-20, 20]:
			shed(w, Vector3(x, 0, z), "66999b" if x < 0 else "c78c55")
	for x in [-18, 18]:
		for z in [-16, 16]:
			tram(w, Vector3(x, 0, z), "d66f70" if x < 0 else "e2b34e")
		for side in [-1, 1]:
			S.block(w, Vector3(x + side * 1.2, 0.018, 0), Vector3(0.1, 0.03, 74), "a4b8b7")
	for side in [-1, 1]:
		for z in [-14, 0, 14]:
			S.block(w, Vector3(side * 5.5, 2.6, z), Vector3(0.4, 5.2, 0.4), "e7dfbb", true)
		var roof := BoxMesh.new()
		roof.size = Vector3(6.3, 0.24, 36)
		S.mesh(w, roof, Vector3(side * 3, 5.7, 0), S.material("4f858f")).rotation.z = side * -0.18
		for z in [-16, -8, 0, 8, 16]:
			H.beam(w, Vector3(side * 6, 5.15, z), Vector3(0, 6.25, z), 0.12, "edb83f")
		S.block(w, Vector3(side * 7, 0.013, 0), Vector3(0.13, 0.02, 36), "edb83f")
	for x in [-8, 8]:
		for z in [-28, 0, 28]:
			H.factory(w, "box-wide", Vector3(x, 0, z), 1.25)
			CV.collision(w, Vector3(x, 0.625, z), Vector3(1.4, 1.25, 2.3))
	for z in [-6, 6]:
		H.factory(w, "box-wide", Vector3(0, 0, z), 1.4, PI / 2)
		CV.collision(w, Vector3(0, 0.7, z), Vector3(2.6, 1.4, 1.6))
	for x in [-28, 28]:
		for z in [-29, 0, 29]:
			H.container(w, Vector3(x, 0, z), 3, 2.7, 5, "478f97", false, "SOL")
	for x in [-51, 51]:
		for z in [-26, 0, 26]:
			H.factory(w, "warning-traffic", Vector3(x, 0, z), 0.7)
	for side in [-1, 1]:
		H.factory(w, "crane", Vector3(side * 65, 0, -20), 19, side * PI / 2)
		H.warehouse(w, Vector3(side * 69, 0, 15), side)
		tram(w, Vector3(side * 22, 0, -53), "66999b")
		for z in [-50, 50]:
			tree(w, Vector3(side * 40, -0.05, z), int(z), false)
	for z in [-33, 33]:
		for x in range(-47, 48, 4):
			S.block(w, Vector3(x, 0.013, z), Vector3(2, 0.02, 0.12), "e4c477")
	S.signpost(w, "TERMINAL GIRASSOL", Vector3(0, 4.2, -16), "f4dca4")
	# Clock tower outside the north gate gives every lane a common landmark.
	S.block(w, Vector3(0, 7, -43), Vector3(6, 14, 5), "659599")
	S.block(w, Vector3(0, 14.3, -43), Vector3(7, 0.6, 6), "e7dfbb")
	w.combat_patrol_points.assign([Vector3(-40, 0.15, -20), Vector3(0, 0.15, -25), Vector3(40, 0.15, -20), Vector3(-40, 0.15, 20), Vector3(0, 0.15, 25), Vector3(40, 0.15, 20), Vector3(-30, 0.15, 0), Vector3(0, 0.15, 0), Vector3(30, 0.15, 0)])

static func atmosphere(w: SakuraWorld, stage: int) -> void:
	CV.atmosphere(w)
	w.sun.light_energy = 0.85
	w.sky_mat.ground_horizon_color = w.sky_mat.sky_horizon_color
	w.sky_mat.ground_bottom_color = Color("7eab8a") if stage == 9 else Color("70a4b2")
	w.sun.directional_shadow_max_distance = 55
	w.env.fog_density = 0.00045
