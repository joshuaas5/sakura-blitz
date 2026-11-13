class_name NeonAtelier
extends RefCounted
## Three-level botanical technology atrium. Routes retain their original stair geometry.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const H := preload("res://scripts/harbor_atelier.gd")
const SCI := "quaternius_scifi"

static func platform(w: SakuraWorld, at: Vector3, size: Vector3) -> void:
	H.deck(w, at, size)
	# The imported panels are planar; place them on the physical top surface.
	S.prop(w, SCI, "Platform_DarkPlates", at + Vector3.UP * (size.y / 2 + 0.003), size)

static func rail(w: SakuraWorld, a: Vector3, b: Vector3) -> void:
	H.beam(w, a, b, 0.07, "b6d4ce", true)
	var count := maxi(1, int(a.distance_to(b) / 2.5))
	for i in count + 1:
		var p := a.lerp(b, float(i) / count)
		S.block(w, p - Vector3.UP * 0.47, Vector3(0.07, 1, 0.07), "547f86")

static func facade(w: SakuraWorld) -> void:
	for side in 4:
		var yaw := side * PI / 2
		var basis := Basis(Vector3.UP, yaw)
		for x in range(-20, 21, 5):
			for level in 3:
				var at := basis * Vector3(x, level * 4, 22.8)
				# This kit's wall width runs along Z, unlike the village kit.
				var wall := S.prop(w, SCI, "WallWindow_Straight", at, Vector3(0.5, 4, 5), yaw + PI / 2)
				CV._prepare(wall, Color("a7cfd4") if level == 0 else (Color("e6bfd0") if level == 1 else Color("c2d5c1")))
			S.prop(w, SCI, "Column_Round", basis * Vector3(x + 2.4, 0, 22.5), Vector3(0.35, 12, 0.35), yaw)
		CV.collision(w, basis * Vector3(0, 6, 22.95), (basis * Vector3(46, 12, 0.5)).abs())
		DistrictDressing.plaque(w, "SAKURA / TECH GARDEN", basis * Vector3(0, 10.5, 22.1), 8, "527e8e", yaw + PI)
		for z in [-33, -43]:
			for x in [-28, -12, 7, 27]:
				var p := basis * Vector3(x, -2, z)
				var height := 20.0 + posmod(x, 3) * 7
				S.block(w, p + Vector3.UP * height / 2, Vector3(11, height, 7), "637c89", false)
				S.prop(w, SCI, "WallAstra_Straight_Window", p + basis * Vector3(0, 0, 3.6), Vector3(0.4, height, 11), yaw + PI / 2)
	# Broad roof ribs frame an open sky without a transparent fullscreen surface.
	for z in [-21, -7, 7, 21]:
		H.beam(w, Vector3(-23, 12, z), Vector3(23, 12, z), 0.18, "527984")

static func build(w: SakuraWorld) -> void:
	w._current_pvp_spawn = Vector3(0, 0.2, 18)
	w.tr_spawns = [Vector3(0, 0.2, -18), Vector3(-15, 3.8, -15), Vector3(15, 3.8, -15), Vector3(-15, 3.8, 15), Vector3(15, 3.8, 15), Vector3(0, 7.4, 0), Vector3(-9, 0.2, 0), Vector3(9, 0.2, 0)]
	platform(w, Vector3(0, -0.3, 0), Vector3(46, 0.6, 46))
	for x in [-18.5, 18.5]:
		for z in [-18.5, 18.5]:
			var at := Vector3(x, 0.1, z)
			ItemArt.jump_pad(w._stage_root, at)
			w.kz_jumppads.append(at)
	for x in [-8.5, 8.5]:
		for z in [-8.5, 8.5]:
			S.prop(w, SCI, "Prop_Computer", Vector3(x, 0, z), Vector3(2.4, 3.6, 2.4), PI if z > 0 else 0)
			CV.collision(w, Vector3(x, 1.8, z), Vector3(2.4, 3.6, 2.4))
	for z in [-15.25, 15.25]:
		platform(w, Vector3(0, 3.55, z), Vector3(36, 0.3, 5.5))
		# Stair approaches stay open in the centre.
		for side in [-1, 1]:
			rail(w, Vector3(side * 3.2, 4.7, signf(z) * 12.5), Vector3(side * 12.3, 4.7, signf(z) * 12.5))
	for x in [-15.25, 15.25]:
		platform(w, Vector3(x, 3.55, 0), Vector3(5.5, 0.3, 25))
		for side in [-1, 1]:
			rail(w, Vector3(signf(x) * 12.5, 4.7, side * 2.5), Vector3(signf(x) * 12.5, 4.7, side * 12.3))
	for step in 9:
		for side in [-1, 1]:
			var z: float = (7.65 + step * 0.65) * side
			platform(w, Vector3(0, step * 0.41 + 0.21, z), Vector3(4.4, 0.42, 0.7))
			S.block(w, Vector3(0, step * 0.41 + 0.426, z - side * 0.28), Vector3(4.3, 0.012, 0.08), "a7d5be", false)
	platform(w, Vector3(0, 7.075, 0), Vector3(13, 0.35, 13))
	for step in 9:
		var rx := 6.5 + (8 - step) * 0.68
		var ry := 3.6 + step * 0.4
		platform(w, Vector3(-rx - 0.2, ry + 0.175, 0), Vector3(0.8, 0.35, 3.6))
		platform(w, Vector3(rx + 0.2, ry + 0.175, 0), Vector3(0.8, 0.35, 3.6))
	for x in [-5.7, 5.7]:
		for z in [-5.7, 5.7]:
			S.prop(w, SCI, "Column_Round", Vector3(x, 0, z), Vector3(0.5, 6.9, 0.5))
			CV.collision(w, Vector3(x, 3.45, z), Vector3(0.5, 6.9, 0.5))
	for x in [-16, 16]:
		for z in [-11, 11]:
			S.prop(w, SCI, "Column_Round", Vector3(x, 0, z), Vector3(0.5, 3.4, 0.5))
			CV.collision(w, Vector3(x, 1.7, z), Vector3(0.5, 3.4, 0.5))
	for z in [-5.9, 5.9]:
		rail(w, Vector3(-5.9, 8.25, z), Vector3(5.9, 8.25, z))
		S.prop(w, SCI, "Prop_AccessPoint", Vector3(0, 7.25, z * 0.8), Vector3(1.1, 1.15, 0.45), PI if z > 0 else 0)
	for x in [-17, 17]:
		for z in [-15.7, 15.7]:
			S.prop(w, SCI, "Prop_Crate3", Vector3(x, 3.7, z), Vector3(1.1, 0.9, 1.1))
			CV.collision(w, Vector3(x, 4.15, z), Vector3(1.1, 0.9, 1.1))
	for x in [-20.8, 20.8]:
		for z in [-10, 0, 10]:
			S.planter(w, Vector3(x, 0, z), false)
	for data in [[Vector3(0, 7.28, 0), "N3 / JARDIM SUSPENSO"], [Vector3(0, 0.04, 0), "N1 / ÁTRIO"], [Vector3(-15, 3.74, 0), "N2 / OESTE"], [Vector3(15, 3.74, 0), "N2 / LESTE"]]:
		w._add_weapon_pad(data[0], data[1], Color("b3d5c6"))
	for z in [-15.5, 15.5]:
		DistrictDressing.plaque(w, "N2 / " + ("CORAL" if z < 0 else "MENTA"), Vector3(0, 5.2, z), 4.8, "ac6e8a" if z < 0 else "538b84", PI if z > 0 else 0)
	for x in [-5.5, 5.5]:
		CV.model(w._stage_root, "Bush_Small_Flowers", Vector3(x, 7.25, 5), x, 0.5, true)
		S.prop(w, "quaternius_village", "Prop_Vine1", Vector3(x, 5.3, 6.5), Vector3(0.45, 1.8, 0.25))
	facade(w)
	H.bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root, 180)
	w._stage_root.set_meta("neon_art_revision", 1)

static func atmosphere(w: SakuraWorld) -> void:
	CV.atmosphere(w)
	w.sun.rotation_degrees = Vector3(-58, 28, 0)
	w.sun.light_energy = 0.73
	w.sun.light_color = Color("f4e4cd")
	w.sky_mat.sky_top_color = Color("6790b3")
	w.sky_mat.sky_horizon_color = Color("dbbdce")
	w.sky_mat.ground_horizon_color = Color("dbbdce")
	w.sky_mat.ground_bottom_color = Color("79929f")
	w.env.ambient_light_color = Color("a4c8de")
	w.env.ambient_light_energy = 0.42
	w.env.fog_light_color = Color("9fbdd2")
	w.env.fog_density = 0.0007
