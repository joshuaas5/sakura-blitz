class_name DistrictDressing
extends RefCounted
## Authored street furniture, landmarks and facades for the large FPS districts.
const S := preload("res://scripts/signature_arenas.gd")
const H := preload("res://scripts/harbor_atelier.gd")
const CV := preload("res://scripts/curated_village.gd")

static func bench(w: SakuraWorld, at: Vector3, yaw: float = 0, color: String = "638e7a") -> void:
	var basis := Basis(Vector3.UP, yaw)
	for x in [-0.95, 0.95]:
		H.local_block(w, at, basis, Vector3(x, 0.3, 0), Vector3(0.12, 0.6, 0.68), "4f625b")
	for z in [-0.24, 0, 0.24]:
		H.local_block(w, at, basis, Vector3(0, 0.65, z), Vector3(2.5, 0.12, 0.18), color)
	for y in [0.88, 1.13]:
		H.local_block(w, at, basis, Vector3(0, y, 0.32), Vector3(2.5, 0.18, 0.1), color)
	CV.collision(w, at + Vector3.UP * 0.6, (basis * Vector3(2.5, 1.2, 0.8)).abs())

static func lantern(w: SakuraWorld, at: Vector3, color: String = "e8c785") -> void:
	S.block(w, at + Vector3.UP * 0.1, Vector3(0.5, 0.2, 0.5), "6c7c68")
	S.cylinder(w, at + Vector3.UP * 1.8, 0.065, 3.6, "566e64")
	S.block(w, at + Vector3.UP * 3.6, Vector3(0.5, 0.65, 0.5), color)
	S.cylinder(w, at + Vector3.UP * 3.98, 0.4, 0.18, "638e7a", 0.05)
	for side in [-1, 1]:
		S.block(w, at + Vector3(side * 0.23, 3.6, 0), Vector3(0.045, 0.7, 0.5), "566e64")
	CV.collision(w, at + Vector3.UP * 1.8, Vector3(0.3, 3.6, 0.3))

static func plaque(w: SakuraWorld, text: String, at: Vector3, width: float, color: String, yaw: float = 0) -> void:
	H.local_block(w, at, Basis(Vector3.UP, yaw), Vector3.ZERO, Vector3(width, 0.85, 0.12), color)
	S.signpost(w, text, at + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.075), "f2dfb5", yaw)

static func garden(w: SakuraWorld) -> void:
	for p in [Vector3(-29, 0, -18), Vector3(-29, 0, 0), Vector3(29, 0, 18), Vector3(11, 0, 7), Vector3(-11, 0, -7), Vector3(0, 0, 34)]:
		bench(w, p, PI if p.x < 0 else 0.0)
	for x in [-23, 23]:
		for z in [-24, 24]:
			lantern(w, Vector3(x, 0, z))
	for x in [-4.7, 4.7]:
		S.block(w, Vector3(x, 2.6, 41), Vector3(0.4, 5.2, 0.4), "876d59", true)
		CV.model(w._stage_root, "Prop_Vine4", Vector3(x, 4.7, 41.1), 0, 1.1)
	S.block(w, Vector3(0, 5.1, 41), Vector3(10.2, 0.35, 0.45), "876d59")
	plaque(w, "VALE DO CHÁ", Vector3(0, 4.45, 41), 6, "477b70", PI)
	# A vine pergola frames the middle avenue without narrowing its clear center.
	for x in [-4.5, 4.5]:
		for z in [8, 20]:
			S.block(w, Vector3(x, 1.7, z), Vector3(0.25, 3.4, 0.25), "927956", true)
			CV.model(w._stage_root, "Prop_Vine1", Vector3(x, 3.1, z), 0, 0.8)
		S.block(w, Vector3(x, 3.35, 14), Vector3(0.2, 0.2, 13), "927956")
	for z in range(8, 21, 2):
		S.block(w, Vector3(0, 3.5, z), Vector3(9.6, 0.16, 0.16), "b09a6c")
	S.market(w, Vector3(-9, 0, -4), "bc7083")
	S.market(w, Vector3(9, 0, 4), "659f91")
	plaque(w, "FOLHAS & FLORES", Vector3(-9, 2.4, -3.1), 4.5, "6a7e60")
	for side in [-1, 1]:
		for z in range(-37, 38, 6):
			CV.model(w._stage_root, "Flower_3_Clump" if z % 3 == 0 else "Flower_1_Clump", Vector3(side * 46.2, 0, z), z * 0.2, 0.8, true)
	# Shopfronts receive varied planters and shutters rather than repeated blank walls.
	for x in [-17, 17]:
		for z in [-27, 27]:
			for side in [-1, 1]:
				CV.model(w._stage_root, "Bush_Small_Flowers", Vector3(x + side * 2.2, 0, z + 3.4), side, 0.65, true)
	plaque(w, "POMAR / ESTUFAS →", Vector3(-31, 3, -37), 6, "637e64")
	plaque(w, "← PRAÇA DAS INFUSÕES", Vector3(30, 3, 37), 7, "637e64", PI)

static func trolley(w: SakuraWorld, at: Vector3, color: String) -> void:
	S.block(w, at + Vector3.UP * 0.4, Vector3(1.8, 0.2, 2.8), "5a7881")
	for x in [-0.8, 0.8]:
		for z in [-0.95, 0.95]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.25
			wheel.bottom_radius = 0.25
			wheel.height = 0.15
			wheel.radial_segments = 10
			S.mesh(w, wheel, at + Vector3(x, 0.25, z), S.material("294858")).rotation.z = PI / 2
		S.block(w, at + Vector3(x, 0.9, 1.15), Vector3(0.06, 1, 0.06), "b7c7bf")
	S.block(w, at + Vector3(0, 1.35, 1.15), Vector3(1.65, 0.06, 0.06), "b7c7bf")
	S.block(w, at + Vector3(0, 0.95, -0.2), Vector3(1.6, 0.9, 1.8), color)
	for x in [-0.55, 0.55]:
		S.block(w, at + Vector3(x, 0.95, -0.2), Vector3(0.1, 0.94, 1.85), "e7dfbb")
	CV.collision(w, at + Vector3.UP * 0.75, Vector3(1.8, 1.5, 2.8))

static func terminal(w: SakuraWorld) -> void:
	# Painted platform, rail beds, waiting furniture and ticket terminals.
	S.block(w, Vector3(0, 0.008, 0), Vector3(12, 0.012, 36), "728d91")
	for x in [-18, 18]:
		S.block(w, Vector3(x, 0.009, 0), Vector3(4.5, 0.014, 74), "40565d")
	for x in [-3, 3]:
		for z in [-15, 15]:
			bench(w, Vector3(x, 0, z), PI / 2 if x < 0 else -PI / 2, "d3aa63")
	for x in [-7, 7]:
		for z in [-21, 21]:
			S.block(w, Vector3(x, 1.1, z), Vector3(1.1, 2.2, 0.8), "63989a", true)
			S.block(w, Vector3(x, 1.55, z + 0.42), Vector3(0.78, 0.65, 0.05), "b7dad0")
			S.block(w, Vector3(x, 0.95, z + 0.43), Vector3(0.6, 0.08, 0.06), "294858")
	for x in [-11, 11]:
		for z in [-19, 19]:
			trolley(w, Vector3(x, 0, z), "d79c65" if x < 0 else "bc7478")
	for x in [-40, 40]:
		for z in [-20, 20]:
			S.block(w, Vector3(x, 0.008, z), Vector3(13.5, 0.01, 13.5), "6f8b8b")
			plaque(w, "OFICINA " + str(1 + int(x > 0) * 2 + int(z > 0)), Vector3(x, 4.8, z + 7.27), 5, "496d75")
			for side in [-1, 1]:
				for rib in range(-6, 7):
					S.block(w, Vector3(x + side * 7.24, 2.8, z + rib), Vector3(0.04, 5.4, 0.06), "90b5b0" if x < 0 else "d9ad74")
				var pipe := CylinderMesh.new()
				pipe.top_radius = 0.13
				pipe.bottom_radius = 0.13
				pipe.height = 13
				pipe.radial_segments = 8
				S.mesh(w, pipe, Vector3(x + side * 7.38, 2.9, z), S.material("e1c184")).rotation.x = PI / 2
			for dx in range(-3, 4):
				var paint := BoxMesh.new()
				paint.size = Vector3(0.3, 0.018, 1.1)
				S.mesh(w, paint, Vector3(x + dx * 0.62, 0.018, z + 7.6), S.material("edb83f")).rotation.y = -0.45
	for x in [-29, 29]:
		for z in [-12, 12]:
			H.factory(w, "box-long", Vector3(x, 0, z), 1.6, PI / 2)
			CV.collision(w, Vector3(x, 0.8, z), Vector3(3.5, 1.6, 1.8))
	plaque(w, "PLATAFORMA / SOL", Vector3(0, 4.1, 15.2), 7, "426d78")
	plaque(w, "TRAVESSIA CENTRAL", Vector3(0, 4.1, -15.2), 7, "426d78", PI)
	var face := QuadMesh.new()
	face.size = Vector2(3.8, 3.8)
	var clock := ShaderMaterial.new()
	clock.shader = preload("res://assets/shaders/station_clock.gdshader")
	S.mesh(w, face, Vector3(0, 11.5, -40.45), clock)
	for x in [-50, 50]:
		for z in [-10, 10]:
			lantern(w, Vector3(x, 0, z), "e2ca8c")
