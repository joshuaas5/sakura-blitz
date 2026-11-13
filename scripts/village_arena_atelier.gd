class_name VillageArenaAtelier
extends RefCounted
## Dense terrace village: authored facades, delivery trucks, readable roof routes.
const S := preload("res://scripts/signature_arenas.gd")
const CV := preload("res://scripts/curated_village.gd")
const H := preload("res://scripts/harbor_atelier.gd")

static func terrace(w: SakuraWorld, p: Vector3, width: float, height: float, variant: int) -> void:
	var colors := ["efcfb1", "b8d3bd", "ecc6cf", "bad5dd"]
	var color: String = colors[posmod(variant, 4)]
	S.block(w, p + Vector3.UP * height * 0.5, Vector3(width, height, width), color, true, true)
	for side in 4:
		var yaw := side * PI / 2
		var basis := Basis(Vector3.UP, yaw)
		for segment in [-1, 0, 1]:
			var at := p + basis * Vector3(segment * width / 3, 0, width / 2 + 0.015)
			var door: bool = segment == 0 and side == posmod(variant, 4)
			var asset := "Wall_Plaster_Door_Round" if door else "Wall_Plaster_Window_Wide_Round"
			var facade := S.prop(w, "quaternius_village", asset, at, Vector3(width / 3, height, 0.15), yaw)
			CV._prepare(facade, Color(color).lightened(0.3))
			if door:
				S.prop(w, "quaternius_village", "Door_2_Round", at + basis * Vector3(0, 0, 0.09), Vector3(1.2, 2.35, 0.12), yaw)
			else:
				S.prop(w, "quaternius_village", "Window_Wide_Round1", at + basis * Vector3(0, height * 0.36, 0.09), Vector3(width / 3 * 0.74, height * 0.43, 0.12), yaw)
		S.prop(w, "quaternius_village", "Prop_Vine1", p + basis * Vector3(width / 2 - 0.2, height * 0.45, width / 2 + 0.18), Vector3(0.55, height * 0.55, 0.2), yaw)
	var roof_size := Vector3(width + 0.7, 0.28, width + 0.7)
	S.prop(w, "quaternius_village", "Floor_WoodDark", p + Vector3.UP * height, roof_size)
	CV.collision(w, p + Vector3.UP * (height + 0.14), roof_size)
	for side in [-1, 1]:
		# Low cornices are honest cover; openings remain at both X edges.
		S.block(w, p + Vector3(0, height + 0.46, side * (width / 2 + 0.26)), Vector3(width * 0.50, 0.36, 0.16), "638c80")
		CV.model(w._stage_root, "Bush_Small_Flowers", p + Vector3(side * (width / 2 - 0.45), height + 0.28, width / 2 - 0.5), variant, 0.4, true)

static func boundary(w: SakuraWorld) -> void:
	for side in 4:
		var yaw := side * PI / 2
		var basis := Basis(Vector3.UP, yaw)
		var at := basis * Vector3(0, 3.25, 18.35)
		S.block(w, at, (basis * Vector3(37.3, 6.5, 0.55)).abs(), "d3b997", true, true)
		for x in range(-16, 17, 4):
			S.prop(w, "quaternius_village", "Wall_Plaster_WoodGrid", basis * Vector3(x, 3.0, 18.03), Vector3(4, 3.5, 0.22), yaw)
			S.prop(w, "quaternius_village", "Window_Wide_Round1", basis * Vector3(x, 3.8, 17.86), Vector3(1.5, 1.7, 0.12), yaw)
		S.block(w, basis * Vector3(0, 6.5, 18.35), (basis * Vector3(37.5, 0.16, 0.7)).abs(), "9d6c66", false)
	for i in 12:
		var a := i * TAU / 12
		CV.model(w._stage_root, "MapleTree_1" if i % 2 == 0 else "BirchTree_1", Vector3(cos(a) * 27, 0, sin(a) * 27), a, 1.4, true)
	for x in [-26, 26]:
		for z in [-23, 0, 23]:
			CV.house(w, Vector3(x, 0, z), int(z + 24), 0, true)

static func build(w: SakuraWorld) -> void:
	w._current_pvp_spawn = Vector3(0, 0.2, 15.2)
	w.tr_spawns = [Vector3(-15.6, 0.2, -8.5), Vector3(15.6, 0.2, -8.5), Vector3(-2, 0.2, -15.5), Vector3(2, 0.2, -15.5), Vector3(-15.6, 0.2, 7), Vector3(15.6, 0.2, 7), Vector3(0, 0.2, 10.5), Vector3(0, 0.2, -10.5)]
	S.block(w, Vector3(0, -0.3, 0), Vector3(56, 0.6, 56), "a0bc89", true)
	S.block(w, Vector3(0, -0.15, 0), Vector3(36, 0.3, 36), "dfceb1", true, true)
	for x in [-13.5, 13.5]:
		for z in [-13.5, 13.5]:
			terrace(w, Vector3(x, 0, z), 6.2, 4.2, int(x + z + 30))
	for x in [-7.2, 7.2]:
		for z in [-7.2, 7.2]:
			terrace(w, Vector3(x, 0, z), 5.8, 3.4, int(x + z + 20))
	for side in [-1, 1]:
		# Two opposing roof approaches are walkable by the same capsule as the bots.
		# Crates remain a faster player jump route; these treads provide an honest AI route.
		for step in 10:
			var height := (step + 1) * 0.368
			var p := Vector3(side * 11.35, height / 2, side * (-1.3 + step * 0.6))
			CanyonAtelier.surface(w, p, Vector3(2.4, height, 0.65), S.material("a78b64", true))
			S.prop(w, "quaternius_village", "Floor_WoodDark", Vector3(p.x, height + 0.002, p.z), Vector3(2.4, 0.025, 0.65))
		var landing := Vector3(side * 11.2, 3.54, side * 4.7)
		S.prop(w, "quaternius_village", "Floor_WoodDark", landing - Vector3.UP * 0.14, Vector3(2.7, 0.28, 1.8))
		CV.collision(w, landing, Vector3(2.7, 0.28, 1.8))
		# Delivery trucks replace the old cuboid buses; collision keeps the lanes intact.
		S.prop(w, "kenney_car", "delivery" if side < 0 else "truck", Vector3(side * 3.8, 0, 0), Vector3(2.4, 2.6, 7.2), side * PI / 2)
		CV.collision(w, Vector3(side * 3.8, 1.3, 0), Vector3(7.2, 2.6, 2.4))
		var at := Vector3(side * 14.8, 0, 0)
		for px in [-1.1, 1.1]:
			for pz in [-1.1, 1.1]:
				S.block(w, at + Vector3(px, 1.75, pz), Vector3(0.16, 3.5, 0.16), "79654e")
		S.prop(w, "quaternius_village", "Floor_WoodDark", at + Vector3.UP * 3.36, Vector3(2.8, 0.28, 2.8))
		CV.collision(w, at + Vector3.UP * 3.5, Vector3(2.8, 0.28, 2.8))
		for step in 3:
			var height: float = [1.05, 2.05, 2.95][step]
			var p := Vector3(side * 11.2, 0, side * 7.6 - side * step * 1.35)
			S.prop(w, "kenney_pirate", "crate", p, Vector3(1.3, height, 1.3))
			CV.collision(w, p + Vector3.UP * height / 2, Vector3(1.3, height, 1.3))
		DistrictDressing.plaque(w, "PRAÇA / " + ("MENTA" if side > 0 else "CORAL"), Vector3(0, 4.8, side * 17.9), 5, "6b9386" if side > 0 else "b76e7a", PI if side > 0 else 0)
		S.bunting(w, Vector3(-10, 5.6, side * 11), Vector3(10, 5.6, side * 11), false)
	S.prop(w, "quaternius_village", "DoorFrame_Round_Brick", Vector3(0, 0, 0), Vector3(4.6, 4.3, 0.55))
	for x in [-2.1, 2.1]:
		CV.collision(w, Vector3(x, 2.15, 0), Vector3(0.4, 4.3, 0.55))
	CV.collision(w, Vector3(0, 4.05, 0), Vector3(4.6, 0.5, 0.55))
	for at in [Vector3(-4.5, 0.04, 15.2), Vector3(4.5, 0.04, 15.2), Vector3(0, 0.04, 0)]:
		w._add_weapon_pad(at, "PRAÇA / SUPRIMENTOS", Color("b5d9bd"))
	boundary(w)
	H.bake_palette(w._stage_root)
	ImportedSceneryBatch.bake(w._stage_root, 150)
	VillageAtelier.ambience(w, "garden_breeze", Vector3.ZERO, 70, -14)
	w._stage_root.set_meta("village_arena_art_revision", 1)

static func atmosphere(w: SakuraWorld) -> void:
	CV.atmosphere(w)
	w.sun.rotation_degrees = Vector3(-52, -32, 0)
	w.sun.light_energy = 0.85
