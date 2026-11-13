class_name DistrictProps
extends RefCounted
## Palette-colored modular scenery, batched per spatial chunk and primitive.
## Decoration has no physics. Playable surfaces belong to the course builder.
var batches: Dictionary = {}

func piece(kind: String, pos: Vector3, scale: Vector3, color: Color, yaw: float = 0.0) -> void:
	if not batches.has(kind):
		batches[kind] = []
	batches[kind].append([Transform3D(Basis(Vector3.UP, yaw).scaled(scale), pos), color])

func pavilion(p: Vector3, color: Color, variant: int) -> void:
	piece("box", p + Vector3(0, 1.4, 0), Vector3(4, 2.8, 3.4), Color("f0dfcc"))
	piece("roof", p + Vector3(0, 3.3, 0), Vector3(4.8, 1.2, 4.1), color)
	for x in [-1.3, 1.3]:
		piece("box", p + Vector3(x, 1.7, 1.73), Vector3(0.9, 1, 0.08), Color("243e50"))
		piece("box", p + Vector3(x, 1.15, 1.9), Vector3(1.1, 0.15, 0.4), color)
	piece("box", p + Vector3(0, 0.9, 1.73), Vector3(0.7, 1.8, 0.12), Color("664d48"))
	# Timber framing, window mullions, planters and painted roof courses.
	for x in [-1.92, 0.0, 1.92]:
		piece("box", p + Vector3(x, 1.4, 1.74), Vector3(0.14, 2.8, 0.16), Color("795e4e"))
	for y in [0.2, 2.7]:
		piece("box", p + Vector3(0, y, 1.76), Vector3(4, 0.14, 0.16), Color("795e4e"))
	for x in [-1.3, 1.3]:
		piece("box", p + Vector3(x, 1.7, 1.8), Vector3(0.06, 1, 0.09), Color("d8bd8b"))
		piece("box", p + Vector3(x, 1.7, 1.8), Vector3(0.9, 0.06, 0.09), Color("d8bd8b"))
		for flower in 3:
			var pos := p + Vector3(x - 0.35 + flower * 0.35, 1.32, 1.95)
			piece("ball", pos, Vector3(0.34, 0.22, 0.27), Color("799672"))
			piece("ball", pos + Vector3(0, 0.1, 0.06), Vector3.ONE * 0.16, Color("e7a4ad"))
	for row in 4:
		piece("box", p + Vector3(0, 2.82 + row * 0.16, 1.95 - row * 0.48), Vector3(4.65, 0.08, 0.14), color.darkened(0.16))
	piece("box", p + Vector3(1, 4, -0.5), Vector3(0.55, 1.7, 0.65), Color("b98572"))
	if variant % 2 == 0:
		piece("ball", p + Vector3(1, 5.2, -0.5), Vector3(0.5, 0.7, 0.5), Color("e7e9dc"))
	else:
		piece("box", p + Vector3(-1, 4.5, 0), Vector3(0.06, 2, 0.06), Color("37475b"))
		piece("box", p + Vector3(-1, 5, 0), Vector3(1.8, 0.06, 0.06), Color("37475b"))

func blossom(p: Vector3, color: Color, variant: int) -> void:
	piece("cylinder", p + Vector3(0, 1.6, 0), Vector3(0.35, 3.2, 0.35), Color("76565d"))
	for i in 4:
		var angle := i * 1.57 + variant * 0.7
		piece("ball", p + Vector3(cos(angle) * 1.1, 3.5 + i * 0.22, sin(angle) * 1.1), Vector3(2.7, 2.1, 2.5), color.lightened(i * 0.045))
		for cluster in 5:
			var a := angle + cluster * 1.25
			piece("ball", p + Vector3(cos(angle) * 1.1 + cos(a), 3.8 + i * 0.22 + sin(a) * 0.4, sin(angle) * 1.1 + sin(a)), Vector3(0.8, 0.65, 0.8), color.lightened(0.12 + cluster * 0.02))
	for i in 5:
		var a := i * TAU / 5 + variant
		piece("ball", p + Vector3(cos(a) * 0.9, 0.15, sin(a) * 0.9), Vector3(0.8, 0.3, 0.6), Color("889d70"))

func tower(p: Vector3, color: Color, variant: int) -> void:
	var h := 6.0 + variant % 4 * 2.5
	piece("box", p + Vector3(0, h * 0.5, 0), Vector3(4, h, 4), Color("24384d"))
	piece("box", p + Vector3(0, h, 0), Vector3(4.6, 0.3, 4.6), color)
	for y in range(1, int(h), 2):
		for x in [-1.2, 0.0, 1.2]:
			piece("box", p + Vector3(x, y, 2.02), Vector3(0.45, 0.8, 0.08), color)
	piece("cylinder", p + Vector3(0, h + 1.5, 0), Vector3(0.09, 3, 0.09), color)
	piece("ball", p + Vector3(0, h + 3.1, 0), Vector3.ONE * 0.4, Color("f6d58c"))

func flowerbed(p: Vector3, length: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in int(length * 4):
		var at := p + Vector3(rng.randf_range(-length * 0.5, length * 0.5), 0, rng.randf_range(-0.3, 0.3))
		var height := rng.randf_range(0.18, 0.4)
		piece("ball", at + Vector3(0, height * 0.4, 0), Vector3(0.28, height, 0.3), Color("698565"))
		var color: Color = [Color("e2a0ac"), Color("edca80"), Color("e9d8bb")][i % 3]
		for petal in 4:
			var a := petal * PI * 0.5
			piece("ball", at + Vector3(cos(a) * 0.065, height, sin(a) * 0.065), Vector3(0.14, 0.07, 0.14), color)
		piece("ball", at + Vector3(0, height + 0.03, 0), Vector3.ONE * 0.07, Color("d9aa5c"))

func vine(p: Vector3, height: float, variant: int) -> void:
	for i in int(height * 4):
		var y := i * 0.25
		var x := sin(y * 3 + variant) * 0.16
		piece("ball", p + Vector3(x, y, 0), Vector3(0.38, 0.2, 0.18), Color("78956b").lightened((i % 3) * 0.045))
		if i % 5 == 0:
			piece("ball", p + Vector3(x + 0.15, y + 0.1, 0.05), Vector3.ONE * 0.15, Color("e0a3b2"))

func island(p: Vector3, color: Color, variant: int) -> void:
	piece("rock", p + Vector3(0, -1.4, 0), Vector3(6, 3, 5), Color("ae8c6c"))
	piece("cylinder", p + Vector3(0, 0, 0), Vector3(6, 0.5, 5), color)
	if variant % 2 == 0:
		blossom(p, Color("91c5a9"), variant)
	else:
		piece("cylinder", p + Vector3(0, 1.6, 0), Vector3(0.6, 3.3, 0.6), Color("86b898"))
		piece("ball", p + Vector3(0, 3.3, 0), Vector3(0.6, 0.6, 0.6), Color("86b898"))

func car(p: Vector3, color: Color, yaw: float = 0.0) -> void:
	# Transform the whole kit so wheels/windows remain coherent across variants.
	var temp := DistrictProps.new()
	temp.piece("box", Vector3(0, 0.65, 0), Vector3(1.9, 0.7, 3.8), color)
	temp.piece("box", Vector3(0, 1.2, 0.1), Vector3(1.65, 0.65, 1.8), Color("334857"))
	temp.piece("box", Vector3(0, 1.57, 0.1), Vector3(1.8, 0.12, 1.9), color)
	for x in [-0.94, 0.94]:
		for z in [-1.15, 1.15]:
			temp.piece("ball", Vector3(x, 0.4, z), Vector3(0.5, 0.8, 0.8), Color("26323e"))
	for x in [-0.6, 0.6]:
		temp.piece("box", Vector3(x, 0.8, 1.91), Vector3(0.4, 0.22, 0.05), Color("f7dfa5"))
	var xf := Transform3D(Basis(Vector3.UP, yaw), p)
	for kind in temp.batches:
		if not batches.has(kind):
			batches[kind] = []
		for item in temp.batches[kind]:
			batches[kind].append([xf * item[0], item[1]])

func flush(parent: Node3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/cozy_painted.gdshader")
	for kind in batches:
		var mesh: Mesh
		match kind:
			"ball":
				var sphere := SphereMesh.new()
				sphere.radial_segments = 10
				sphere.rings = 5
				mesh = sphere
			"cylinder":
				var cylinder := CylinderMesh.new()
				cylinder.height = 1.0
				cylinder.radial_segments = 10
				mesh = cylinder
			"roof", "rock":
				var prism := PrismMesh.new()
				prism.size = Vector3.ONE
				mesh = prism
			_:
				mesh = BoxMesh.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = mesh
		multi.instance_count = batches[kind].size()
		for i in multi.instance_count:
			multi.set_instance_transform(i, batches[kind][i][0])
			multi.set_instance_color(i, batches[kind][i][1])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 95.0
		parent.add_child(instance)
	batches.clear()
