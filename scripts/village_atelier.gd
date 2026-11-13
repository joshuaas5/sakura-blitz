class_name VillageAtelier
extends RefCounted
## Small authored furnishing kit. Flat colors complement imported painted architecture.
static var materials := {}

static func mat(color: String) -> StandardMaterial3D:
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.85
		materials[color] = material
	return materials[color]

static func geometry(parent: Node3D, shape: PrimitiveMesh, at: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shape.get_mesh_arrays())
	node.mesh = mesh
	node.material_override = mat(color)
	parent.add_child(node)
	node.position = at
	return node

static func box(parent: Node3D, at: Vector3, size: Vector3, color: String) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	geometry(parent, shape, at, color)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: String, top: float = -1) -> void:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 12
	shape.rings = 1
	geometry(parent, shape, at, color)

static func room(w: SakuraWorld, root: Node3D, at: Vector3, yaw: float) -> void:
	# Furnish the side of the room; keep a straight passage through its two doors.
	box(root, Vector3(0, 0.015, 0), Vector3(5.7, 0.025, 5.7), "957453")
	for z in range(-5, 6):
		box(root, Vector3(0, 0.032, z * 0.5), Vector3(5.7, 0.008, 0.018), "715d4b")
	box(root, Vector3(-1.8, 0.87, 0), Vector3(1.45, 0.14, 2.1), "9c7753")
	box(root, Vector3(-1.8, 0.95, 0), Vector3(1.0, 0.025, 1.9), "a6516c")
	for x in [-2.35, -1.25]:
		for z in [-0.8, 0.8]:
			box(root, Vector3(x, 0.42, z), Vector3(0.12, 0.84, 0.12), "765b48")
	var basis := Basis(Vector3.UP, yaw)
	CuratedVillage.collision(w, at + basis * Vector3(-1.8, 0.5, 0), (basis * Vector3(1.45, 1, 2.1)).abs())
	for z in [-0.55, 0.55]:
		cylinder(root, Vector3(-1.8, 1.02, z), 0.19, 0.035, "f0dcad")
		cylinder(root, Vector3(-1.8, 1.1, z), 0.10, 0.15, "78a49d", 0.13)
		cylinder(root, Vector3(-1.8, 1.18, z), 0.11, 0.012, "704e3a")
	cylinder(root, Vector3(-1.8, 1.17, 0), 0.17, 0.28, "e0bf79", 0.13)
	cylinder(root, Vector3(-1.8, 1.33, 0), 0.12, 0.05, "79a7a0", 0.04)
	for z in [-1.6, 1.6]:
		cylinder(root, Vector3(-1.8, 0.48, z), 0.32, 0.12, "739f91")
		cylinder(root, Vector3(-1.8, 0.22, z), 0.16, 0.44, "977853")
		CuratedVillage.collision(w, at + basis * Vector3(-1.8, 0.25, z), Vector3(0.6, 0.5, 0.6))
	for x in [-0.4, 1.2]:
		box(root, Vector3(x, 1.5, -2.6), Vector3(1.2, 0.12, 0.45), "987955")
		for j in 3:
			cylinder(root, Vector3(x - 0.35 + j * 0.35, 1.75, -2.6), 0.12, 0.36, "78a09a" if j % 2 == 0 else "b57881", 0.10)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.4, 0)
	light.light_color = Color("ffd6a1")
	light.light_energy = 0.65
	light.omni_range = 5
	light.shadow_enabled = false
	root.add_child(light)

static func plaque(parent: Node3D, text: String, at: Vector3, yaw: float = 0) -> void:
	var label := Label3D.new()
	label.text = text
	var lettering := FontVariation.new()
	lettering.base_font = preload("res://assets/ui/blossom/nunito_sans.ttf")
	lettering.variation_embolden = 0.5
	label.font = lettering
	label.font_size = 64
	label.pixel_size = 0.0065
	label.modulate = Color("f3dfaf")
	label.outline_modulate = Color("4c5546")
	label.outline_size = 10
	label.position = at
	label.rotation.y = yaw
	parent.add_child(label)

static func decorate(w: SakuraWorld) -> void:
	plaque(w._stage_root, "CASA DO CHÁ", Vector3(-6.84, 2.65, 10), PI / 2)
	plaque(w._stage_root, "PRAÇA DAS FLORES", Vector3(0, 4.3, -27))
	for side in [-1.0, 1.0]:
		for z in [-5.0, 5.0]:
			var p := Vector3(side * 4.4, 0, z)
			# Ground-level lanterns have narrow, explicit collision footprints.
			cylinder(w._stage_root, p + Vector3(0, 0.14, 0), 0.25, 0.28, "8f8c79")
			cylinder(w._stage_root, p + Vector3(0, 1.3, 0), 0.065, 2.5, "777663")
			box(w._stage_root, p + Vector3(0, 2.65, 0), Vector3(0.42, 0.60, 0.42), "eacb8c")
			cylinder(w._stage_root, p + Vector3(0, 3, 0), 0.34, 0.18, "6f978b", 0.08)
			CuratedVillage.collision(w, p + Vector3(0, 1.3, 0), Vector3(0.28, 2.6, 0.28))
		for z in [-18.0, 16.0]:
			var p := Vector3(side * 13, 0, z)
			for x in [-0.7, 0.7]:
				box(w._stage_root, p + Vector3(x, 0.3, 0), Vector3(0.14, 0.6, 0.55), "8f7760")
			box(w._stage_root, p + Vector3(0, 0.65, 0), Vector3(2, 0.12, 0.65), "90ab91")
			box(w._stage_root, p + Vector3(0, 1.05, -0.27), Vector3(2, 0.65, 0.1), "90ab91")
			CuratedVillage.collision(w, p + Vector3(0, 0.6, 0), Vector3(2, 1.2, 0.7))
			cylinder(w._stage_root, p + Vector3(side * 1.4, 0.25, 0), 0.33, 0.5, "b7776a", 0.42)
			CuratedVillage.model(w._stage_root, "Bush_Small_Flowers", p + Vector3(side * 1.4, 0.48, 0), 0, 0.55, true)
	ambience(w, "courtyard_water", Vector3(0, 1, -8), 24, -13)
	ambience(w, "garden_breeze", Vector3(-15, 3, 0), 38, -15)

static func ambience(w: SakuraWorld, name: String, at: Vector3, distance: float, volume: float) -> void:
	var stream := load("res://assets/audio/original/%s.wav" % name) as AudioStreamWAV
	var loop: AudioStreamWAV = stream.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	var audio := AudioStreamPlayer3D.new()
	audio.name = name
	audio.stream = loop
	audio.bus = "Ambience"
	audio.volume_db = volume
	audio.unit_size = 5
	audio.max_distance = distance
	audio.position = at
	w._stage_root.add_child(audio)
	if not Sfx.muted:
		audio.play()
