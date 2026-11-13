class_name AuroraAtelier
extends RefCounted
## Sunlit railway with real rolling stock, covered platforms and two upper crossings.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const H := preload("res://scripts/harbor_atelier.gd")

static func build(w: SakuraWorld) -> void:
	w._current_pvp_spawn = Vector3(0, 0.2, 20)
	w.tr_spawns = [Vector3(-17, 0.2, -17), Vector3(17, 0.2, -17), Vector3(0, 0.2, -21), Vector3(-17, 0.2, 15), Vector3(17, 0.2, 15), Vector3(0, 0.2, 8)]
	S.block(w, Vector3(0, -0.3, 0), Vector3(46, 0.6, 50), "d4c8ac", true, true)
	for x in [-7, 7]:
		for side in [-1, 1]:
			for z in range(-22, 23, 2):
				S.block(w, Vector3(x + side * 2.05, 0.012, z), Vector3(0.12, 0.02, 1.2), "e5ba54", false)
		for z in range(-22, 23, 4):
			S.prop(w, "kenney_train", "track-detailed", Vector3(x, 0.005, z), Vector3(3.4, 0.10, 4))
		for z in [-5, 6]:
			S.prop(w, "kenney_train", "train-electric-city-a" if z < 0 else "train-electric-city-b", Vector3(x, 0, z), Vector3(3.2, 2.75, 8.8), PI if x > 0 else 0)
			CV.collision(w, Vector3(x, 1.375, z), Vector3(3.2, 2.75, 8.8))
	for z in [-12, 12]:
		H.deck(w, Vector3(0, 2.675, z), Vector3(23, 0.35, 2.8))
		for side in [-1, 1]:
			for step in 10:
				var x: float = side * (17 - step * 0.6)
				var height := 0.285 * (step + 1)
				H.deck(w, Vector3(x, height / 2, z), Vector3(0.7, height, 2.8))
		for edge in [-1, 1]:
			H.beam(w, Vector3(-9.5, 3.85, z + edge * 1.35), Vector3(9.5, 3.85, z + edge * 1.35), 0.07, "447b7b", true)
			for x in [-9.5, -5, 0, 5, 9.5]:
				S.block(w, Vector3(x, 3.35, z + edge * 1.35), Vector3(0.08, 1, 0.08), "447b7b")
		for x in [-10, 10]:
			S.prop(w, "quaternius_scifi", "Column_Round", Vector3(x, 0, z), Vector3(0.35, 2.5, 0.35))
			CV.collision(w, Vector3(x, 1.25, z), Vector3(0.35, 2.5, 0.35))
	for side in [-1, 1]:
		var x: float = side * 19.0
		for i in 3:
			var at := Vector3(x, 0, -14.8 + i * 15)
			S.prop(w, "kenney_factory", "box-wide", at, Vector3(2.6, 1.3, 2.4))
			CV.collision(w, at + Vector3.UP * 0.65, Vector3(2.6, 1.3, 2.4))
		for z in [-21, -6, 6, 21]:
			S.prop(w, "quaternius_village", "Prop_MetalFence_Ornament", Vector3(side * 21.8, 0, z), Vector3(2.6, 1.2, 0.15), PI / 2)
		for z in [-21, -3, 20]:
			S.block(w, Vector3(side * 21.4, 3.1, z), Vector3(0.25, 6.2, 0.25), "426e70")
			CV.collision(w, Vector3(side * 21.4, 3.1, z), Vector3(0.25, 6.2, 0.25))
			H.beam(w, Vector3(side * 21.4, 5.4, z), Vector3(side * 14.8, 6.1, z), 0.16, "426e70")
		S.prop(w, "quaternius_scifi", "Platform_Metal", Vector3(side * 18.2, 6.2, 0), Vector3(8.5, 0.18, 48))
		S.block(w, Vector3(side * 22.75, 2.75, 0), Vector3(0.5, 5.5, 50), "aebfaf", true, true)
		for z in [-19, 0, 19]:
			H.factory(w, "screen-panel-wide", Vector3(side * 22.3, 1.2, z), 1.2, side * PI / 2)
			CV.model(w._stage_root, "MapleTree_1", Vector3(side * 28, 0, z), z, 1.3, true)
		for z in [-20, -10, 10, 20]:
			S.prop(w, "quaternius_village", "Wall_Plaster_Window_Wide_Round", Vector3(side * 22.45, 0.4, z), Vector3(3.2, 4.8, 0.15), side * PI / 2)
			S.prop(w, "quaternius_village", "Window_Wide_Round1", Vector3(side * 22.3, 2, z), Vector3(1.6, 1.8, 0.16), side * PI / 2)
		w._add_weapon_pad(Vector3(side * 17, 0.1, 0), "PLATAFORMA / SUPRIMENTOS", Color("a6d0c3"))
	for z in [-24.75, 24.75]:
		S.block(w, Vector3(0, 2.75, z), Vector3(46, 5.5, 0.5), "adbcac", true, true)
		for x in [-17, 0, 17]:
			S.prop(w, "quaternius_village", "DoorFrame_Round_Brick", Vector3(x, 0, z - signf(z) * 0.3), Vector3(3, 4.5, 0.3), PI if z < 0 else 0)
		DistrictDressing.plaque(w, "ESTAÇÃO AURORA / " + ("SAÍDA SUL" if z > 0 else "SAÍDA NORTE"), Vector3(0, 4.4, z - signf(z) * 0.5), 8, "528b86", PI if z > 0 else 0)
		var clock_mesh := QuadMesh.new()
		clock_mesh.size = Vector2(1.5, 1.5)
		var clock_material := ShaderMaterial.new()
		clock_material.shader = preload("res://assets/shaders/station_clock.gdshader")
		var clock := S.mesh(w, clock_mesh, Vector3(0, 2.8, z - signf(z) * 0.6), clock_material)
		clock.rotation.y = PI if z > 0 else 0
		S.prop(w, "kenney_train", "train-tram-classic", Vector3(0, 0, z * 1.5), Vector3(3.5, 3.4, 11), PI)
		for x in [-19, 19]:
			CV.house(w, Vector3(x, 0, z * 1.5), int(x + 20), 0, true)
	H.bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root, 160)
	VillageAtelier.ambience(w, "garden_breeze", Vector3.ZERO, 80, -16)
	w._stage_root.set_meta("aurora_art_revision", 1)

static func atmosphere(w: SakuraWorld) -> void:
	CV.atmosphere(w)
	w.sun.rotation_degrees = Vector3(-42, -54, 0)
	w.sun.light_energy = 0.88
	w.sun.light_color = Color("ffe8bd")
	w.sky_mat.sky_top_color = Color("66b5d3")
	w.sky_mat.sky_horizon_color = Color("eedbbb")
	w.sky_mat.ground_horizon_color = Color("eedbbb")
	w.sky_mat.ground_bottom_color = Color("9aa587")
