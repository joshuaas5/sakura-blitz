class_name CanyonAtelier
extends RefCounted
## Amber quarry, botanical outposts and timber crossings on three combat levels.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const H := preload("res://scripts/harbor_atelier.gd")
static var rock: ShaderMaterial
static var timber: ShaderMaterial

static func surface(w: SakuraWorld, at: Vector3, size: Vector3, material: Material, solid: bool = true) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	S.mesh(w, shape, at, material)
	if solid:
		CV.collision(w, at, size)

static func rock_material(node: Node) -> void:
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			node.set_surface_override_material(index, rock)
	for child in node.get_children():
		rock_material(child)

static func lookout(w: SakuraWorld, at: Vector3, tint: Color, yaw: float) -> void:
	for x in [-1.65, 1.65]:
		for z in [-1.65, 1.65]:
			S.block(w, at + Vector3(x, 1.35, z), Vector3(0.16, 2.7, 0.16), "7c6550", true)
	var roof := CV.model(w._stage_root, "Roof_RoundTiles_6x6", at + Vector3.UP * 2.7, yaw, 0.65, false, tint)
	roof.scale.y *= 0.7
	S.block(w, at + Vector3(0, 2.65, 0), Vector3(3.8, 0.16, 3.8), "d7bb8b")
	S.prop(w, "kenney_pirate", "crate-bottles", at + Vector3(1.1, 0, -0.9), Vector3(0.6, 0.7, 0.8))
	CV.collision(w, at + Vector3(1.1, 0.35, -0.9), Vector3(0.6, 0.7, 0.8))

static func build(w: SakuraWorld) -> void:
	if rock == null:
		rock = ShaderMaterial.new()
		rock.shader = preload("res://assets/shaders/amber_strata.gdshader")
		timber = ShaderMaterial.new()
		timber.shader = preload("res://assets/shaders/canyon_timber.gdshader")
	w._current_pvp_spawn = Vector3(0, 4.2, 26.5)
	w.tr_spawns = [Vector3(0, 4.2, -26.5), Vector3(-9.5, 4.2, -25.5), Vector3(9.5, 4.2, -25.5), Vector3(-18.5, 2.8, -14), Vector3(18.5, 2.8, -14), Vector3(-6, 0.2, -10), Vector3(6, 0.2, -10), Vector3(0, 4, -6)]
	surface(w, Vector3(0, -0.3, 0), Vector3(56, 0.6, 72), S.material("d6b284", true))
	var land := PlaneMesh.new()
	land.size = Vector2(1400, 1400)
	S.mesh(w, land, Vector3(0, -0.65, 0), S.material("bb906c"))
	for x in [-25.25, 25.25]:
		surface(w, Vector3(x, 4, 0), Vector3(1.5, 8, 72), rock)
	for z in [-35.5, 35.5]:
		surface(w, Vector3(0, 4, z), Vector3(52, 8, 1), rock)
	for side in [-1, 1]:
		var z: float = side * 27.0
		surface(w, Vector3(0, 2, z), Vector3(36, 4, 12), rock)
		surface(w, Vector3(0, 4.012, z), Vector3(36.3, 0.02, 12.3), S.material("dbbf8d", true), false)
		var front: float = z - side * 5.8
		for x in [-16, -10, -4.5, 2.5, 8, 14]:
			surface(w, Vector3(x + 1.2, 4.575, front + 0.225), Vector3(2.4, 1.15, 0.45), rock)
			S.block(w, Vector3(x + 1.2, 5.17, front + 0.225), Vector3(2.55, 0.12, 0.6), "edcf91")
		for x in [-13.5, 13.5]:
			lookout(w, Vector3(x, 4, z), Color("499a99") if side > 0 else Color("bd6b78"), 0)
		for step in 10:
			var height := (step + 1) * 0.4
			var at_z: float = (z - side * 6.5) - side * float(9 - step) * 0.65 + 0.35
			for x in [-10.2, 10.2]:
				surface(w, Vector3(x, height / 2, at_z), Vector3(3.6, height, 0.7), timber)
				S.block(w, Vector3(x, height + 0.012, at_z), Vector3(3.5, 0.02, 0.08), "debf86")
		DistrictDressing.plaque(w, "POSTO / " + ("AURORA" if side > 0 else "ÂMBAR"), Vector3(0, 6.1, side * 32.6), 7, "5d8380", PI if side > 0 else 0)
	# Central crossing: old width, height and approaches, with actual timber panels.
	surface(w, Vector3(0, 3.825, 0), Vector3(5.6, 0.35, 42), timber)
	for x in [-2.875, 2.875]:
		surface(w, Vector3(x, 4.45, 0), Vector3(0.25, 0.9, 42), timber)
		S.block(w, Vector3(x, 4.94, 0), Vector3(0.32, 0.12, 42), "d7bd8b")
		for z in range(-20, 21, 4):
			S.block(w, Vector3(x, 4.5, z), Vector3(0.34, 1.15, 0.20), "7b5d44")
	for z in [-10, 10]:
		for x in [-2.7, 2.7]:
			S.block(w, Vector3(x, 5.75, z), Vector3(0.2, 3.5, 0.2), "6d6e50", true)
		S.block(w, Vector3(0, 7.5, z), Vector3(6.2, 0.25, 0.3), "568e85")
		S.bunting(w, Vector3(-2.7, 7.2, z), Vector3(2.7, 7.2, z), false)
	for at in [Vector3(-1.45, 4.55, -3.75), Vector3(1.45, 4.55, 5.25)]:
		surface(w, at, Vector3(1.5, 1.1, 1.5), S.material("a88f64", true))
		S.prop(w, "kenney_pirate", "crate", at - Vector3.UP * 0.55, Vector3(1.5, 1.1, 1.5))
	for start_x in [-21.5, 17.5]:
		surface(w, Vector3(start_x + 2, 1.3, 0), Vector3(4, 2.6, 42), rock)
		for z in [-12, 0, 12]:
			surface(w, Vector3(start_x + 2, 3.2, z + 0.25), Vector3(1.6, 1.2, 0.5), rock)
	for side in [-1, 1]:
		for z in [-14, 12]:
			for step in 9:
				var x := 12.6 + step * 0.6
				var h := (step + 1) * (2.6 / 9)
				surface(w, Vector3(x + 0.325 if side > 0 else -x - 0.325, h / 2, z + 1), Vector3(0.65, h, 2), timber)
	for z in [-14, -5, 5, 14]:
		for x in [-7.4, 7.4]:
			surface(w, Vector3(x, 1.2, z + 0.6), Vector3(2.2, 2.4, 1.2), rock)
			S.block(w, Vector3(x, 2.44, z + 0.6), Vector3(2.4, 0.1, 1.4), "d9bc83")
	for at in [Vector3(-15, 0.1, 0), Vector3(15, 0.1, 0)]:
		ItemArt.jump_pad(w._stage_root, at)
		w.kz_jumppads.append(at)
	var water := PlaneMesh.new()
	water.size = Vector2(3.5, 36)
	var blue := ShaderMaterial.new()
	blue.shader = preload("res://assets/shaders/harbor_water.gdshader")
	S.mesh(w, water, Vector3(0, 0.012, 0), blue)
	w._add_weapon_pad(Vector3(0, 4.04, 0), "TRAVESSIA / SUPRIMENTOS", Color("e7c77d"))
	w._add_weapon_pad(Vector3(0, 0.04, 0), "RIACHO / SUPRIMENTOS", Color("83c7b0"))
	w._add_weapon_pad(Vector3(0, 4.04, 24), "POSTO AURORA", Color("83c7b0"))
	backdrop(w)
	H.bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root, 180)
	VillageAtelier.ambience(w, "garden_breeze", Vector3(0, 3, 0), 80, -13)
	w._stage_root.set_meta("canyon_art_revision", 1)

static func backdrop(w: SakuraWorld) -> void:
	for side in [-1, 1]:
		for i in 6:
			var at := Vector3(side * (34 + i % 2 * 5), -3, -40 + i * 16)
			var stone := S.prop(w, "kenney_pirate", "rocks-a" if i % 2 == 0 else "rocks-b", at, Vector3(19, 17 + i % 3 * 4, 23), i * 0.8)
			rock_material(stone)
		for z in [-28, 0, 28]:
			S.prop(w, "kenney_pirate", "palm-detailed-bend", Vector3(side * 30, 0, z), Vector3(4, 8, 4), z * 0.2)
		for z in [-27, 27]:
			CV.house(w, Vector3(side * 33, 3, z), int(z + 28), 0, true)
		H.factory(w, "crane", Vector3(side * 42, 0, -15), 15, side * PI / 2)
	for x in [-18, 18]:
		for z in [-30, 29]:
			CV.model(w._stage_root, "Bush_Small_Flowers", Vector3(x, 4, z), x, 0.8, true)

static func atmosphere(w: SakuraWorld) -> void:
	CV.atmosphere(w)
	w.sun.rotation_degrees = Vector3(-44, -36, 0)
	w.sun.light_color = Color("fff1d1")
	w.sun.light_energy = 0.83
	w.sky_mat.sky_top_color = Color("4e9bc1")
	w.sky_mat.sky_horizon_color = Color("e3d6ba")
	w.sky_mat.ground_horizon_color = Color("e3d6ba")
	w.sky_mat.ground_bottom_color = Color("b68763")
	w.env.fog_light_color = Color("e1b98d")
	w.env.fog_density = 0.00065
