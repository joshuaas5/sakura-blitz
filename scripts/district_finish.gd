class_name DistrictFinish
extends RefCounted
## Shared cloth emblems and modular facades, with no extra collision or point lights.
const S := preload("res://scripts/signature_arenas.gd")
const H := preload("res://scripts/harbor_atelier.gd")
static var banners := {}

static func banner(w: SakuraWorld, at: Vector3, yaw: float, solar: bool, alternate: bool) -> void:
	var key := Vector2i(int(solar), int(alternate))
	if not banners.has(key):
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/district_banner.gdshader")
		material.set_shader_parameter("cloth", Color("ac687d") if alternate else Color("3e827b"))
		material.set_shader_parameter("ink", Color("f1d8a6"))
		material.set_shader_parameter("solar", solar)
		banners[key] = material
	var quad := QuadMesh.new()
	quad.size = Vector2(1.25, 1.9)
	var cloth := S.mesh(w, quad, at, banners[key])
	cloth.rotation.y = yaw
	var basis := Basis(Vector3.UP, yaw)
	H.beam(w, at + basis * Vector3(-0.75, 1, 0), at + basis * Vector3(0.75, 1, 0), 0.06, "e6c58d")

static func build(w: SakuraWorld, tea: bool) -> void:
	if tea:
		for side in [-1, 1]:
			for z in [-24, 24]:
				banner(w, Vector3(side * 23, 3.2, z), side * PI / 2, false, z < 0)
		for x in [-17, 17]:
			for z in [-27, 27]:
				banner(w, Vector3(x, 3.9, z + 3.4), 0, false, x < 0)
	else:
		for x in [-40, 40]:
			for z in [-20, 20]:
				for side in [-1, 1]:
					S.prop(w, "quaternius_scifi", "Door_Frame_A", Vector3(x, 0, z + side * 7.1), Vector3(5.4, 4.2, 0.45), PI if side < 0 else 0)
					S.prop(w, "quaternius_scifi", "WallAstra_Straight_Window", Vector3(x + side * 7.3, 1.1, z), Vector3(0.18, 3.6, 9))
				banner(w, Vector3(x - 4.7, 3, z + 7.35), 0, true, x > 0)
		for side in [-1, 1]:
			for z in [-14, 14]:
				banner(w, Vector3(side * 5.5, 3.5, z), side * PI / 2, true, side < 0)
