class_name CozyAvatar
extends RefCounted
## Articulated, palette-based adventurers. All faces point along +Z.
static var materials: Dictionary = {}

static func part(bot: EnemyBot, parent: Node3D, pos: Vector3, scale: Vector3, color: Color, shape: int = 0) -> MeshInstance3D:
	var mesh: PrimitiveMesh
	if shape == 1:
		var sphere := SphereMesh.new()
		sphere.radial_segments = 8
		sphere.rings = 3
		sphere.height = 1
		mesh = sphere
	elif shape == 2:
		var prism := PrismMesh.new()
		prism.size = Vector3.ONE
		mesh = prism
	elif shape == 3:
		var cloak := CylinderMesh.new()
		cloak.height = 1
		cloak.top_radius = 0.28
		cloak.bottom_radius = 0.5
		cloak.radial_segments = 8
		mesh = cloak
	else:
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		mesh = box
	if not materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1
		materials[color] = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = materials[color]
	node.position = pos
	node.scale = scale
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	bot._meshes.append(node)
	bot._orig_mats.append(node.material_override)
	return node

static func joint(parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	parent.add_child(node)
	return node

static func build(bot: EnemyBot) -> void:
	var index := bot.runner_idx if bot.is_runner else EnemyBot.BOT_NAMES.find(bot.bot_name)
	var family := posmod(index, 3)
	var coat: Color = [Color("93465b"), Color("738366"), Color("3e747a")][family]
	var scarf: Color = [Color("df8c9c"), Color("a8515a"), Color("d9ac62")][family]
	if bot.get_meta("imperial", false):
		coat = Color("ceac63")
		scarf = Color("aa515b")
	var skin: Color = [Color("e7b38c"), Color("b97b56"), Color("efc29c")][posmod(index, 3)]
	var hair: Color = [Color("674535"), Color("403e35"), Color("a65a38")][family]
	var cream := Color("e8d9b8")
	var leather := Color("735242")
	var root := bot._root
	bot._leg_l = joint(root, Vector3(-0.15, 0.65, 0))
	bot._leg_r = joint(root, Vector3(0.15, 0.65, 0))
	for leg in [bot._leg_l, bot._leg_r]:
		part(bot, leg, Vector3(0, -0.14, 0), Vector3(0.25, 0.34, 0.27), cream, 1)
		part(bot, leg, Vector3(0, -0.35, 0), Vector3(0.16, 0.21, 0.18), skin)
		part(bot, leg, Vector3(0, -0.51, 0.04), Vector3(0.22, 0.24, 0.34), leather, 1)
		part(bot, leg, Vector3(0, -0.4, 0), Vector3(0.24, 0.085, 0.25), cream)
	part(bot, root, Vector3(0, 0.97, 0), Vector3(0.56, 0.65, 0.36), coat, 1)
	if family == 1:
		part(bot, root, Vector3(0, 1.03, -0.04), Vector3(0.85, 0.5, 0.62), coat, 3)
	else:
		for side in [-1.0, 1.0]:
			part(bot, root, Vector3(side * 0.18, 0.78, 0), Vector3(0.22, 0.28, 0.35), coat)
	part(bot, root, Vector3(0, 0.99, 0.18), Vector3(0.16, 0.4, 0.035), cream)
	part(bot, root, Vector3(0, 0.78, 0), Vector3(0.53, 0.08, 0.38), leather)
	part(bot, root, Vector3(0, 0.78, 0.2), Vector3(0.09, 0.085, 0.025), Color("d8b878"))
	part(bot, root, Vector3(-0.26, 0.82, 0.09), Vector3(0.22, 0.25, 0.22), leather)
	part(bot, root, Vector3(-0.26, 0.88, 0.21), Vector3(0.23, 0.075, 0.025), scarf)
	var strap := part(bot, root, Vector3(0, 1.02, 0.2), Vector3(0.055, 0.55, 0.025), leather)
	strap.rotation.z = -0.6
	bot._arm_l = joint(root, Vector3(-0.34, 1.19, 0))
	bot._arm_r = joint(root, Vector3(0.34, 1.19, 0))
	for arm in [bot._arm_l, bot._arm_r]:
		part(bot, arm, Vector3(0, -0.15, 0), Vector3(0.22, 0.35, 0.25), coat, 1)
		part(bot, arm, Vector3(0, -0.29, 0), Vector3(0.23, 0.08, 0.26), cream)
		part(bot, arm, Vector3(0, -0.39, 0.015), Vector3(0.16, 0.17, 0.18), skin, 1)
	part(bot, root, Vector3(0, 1.27, 0), Vector3(0.46, 0.14, 0.4), scarf, 1)
	var tail := part(bot, root, Vector3(0.23, 1.19, -0.22), Vector3(0.18, 0.43, 0.04), scarf)
	tail.rotation.z = -0.5
	bot._head_node = joint(root, Vector3(0, 1.54, 0))
	var head := bot._head_node
	part(bot, head, Vector3.ZERO, Vector3(0.57, 0.57, 0.52), skin, 1)
	part(bot, head, Vector3(0, 0.18, -0.055), Vector3(0.63, 0.36, 0.57), hair, 1)
	for x in [-0.18, 0.0, 0.18]:
		var lock := part(bot, head, Vector3(x, 0.18, 0.21), Vector3(0.23, 0.27, 0.18), hair, 2)
		lock.rotation.z = x * 2 + 0.2
	for x in [-0.105, 0.105]:
		part(bot, head, Vector3(x, 0, 0.244), Vector3(0.085, 0.12, 0.018), Color("f9edd6"))
		part(bot, head, Vector3(x, -0.008, 0.258), Vector3(0.045, 0.085, 0.012), Color("342d32"))
		part(bot, head, Vector3(x - 0.009, 0.015, 0.266), Vector3(0.015, 0.02, 0.008), Color.WHITE)
		part(bot, head, Vector3(x * 1.4, -0.09, 0.23), Vector3(0.065, 0.028, 0.018), Color("cc8e7c"))
	part(bot, head, Vector3(0, -0.06, 0.265), Vector3(0.045, 0.05, 0.045), skin, 1)
	part(bot, head, Vector3(0, -0.145, 0.24), Vector3(0.065, 0.018, 0.012), Color("895750"))
	if family == 1:
		part(bot, head, Vector3(0, 0.28, 0), Vector3(0.85, 0.4, 0.72), coat, 2)
		for x in [-0.25, 0.25]:
			part(bot, head, Vector3(x, 0.08, -0.02), Vector3(0.25, 0.42, 0.38), scarf, 2)
	elif family == 2:
		part(bot, head, Vector3(0, 0.23, 0.2), Vector3(0.5, 0.07, 0.1), leather)
		for x in [-0.13, 0.13]:
			part(bot, head, Vector3(x, 0.24, 0.27), Vector3(0.19, 0.16, 0.07), Color("d4b578"), 1)
			part(bot, head, Vector3(x, 0.24, 0.31), Vector3(0.13, 0.1, 0.02), Color("426b73"), 1)
	# Blossom brooch: five petals, readable on the chest without a texture atlas.
	for i in 5:
		var angle := i * TAU / 5
		part(bot, root, Vector3(0.14 + cos(angle) * 0.035, 1.22 + sin(angle) * 0.035, 0.23), Vector3(0.05, 0.05, 0.018), Color("f3c1c4"), 1)
	if not bot.is_runner:
		bot._arm_r.rotation.x = -0.9
		part(bot, bot._arm_r, Vector3(0, -0.35, 0.22), Vector3(0.12, 0.16, 0.55), coat)
		part(bot, bot._arm_r, Vector3(0, -0.35, 0.53), Vector3(0.065, 0.065, 0.18), leather)
	# One vertex-colored mesh per animated joint, instead of one draw per detail.
	bot._meshes.clear()
	bot._orig_mats.clear()
	for pivot in [root, bot._head_node, bot._arm_l, bot._arm_r, bot._leg_l, bot._leg_r]:
		merge_parts(bot, pivot)

static func merge_parts(bot: EnemyBot, pivot: Node3D) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for child in pivot.get_children():
		if not child is MeshInstance3D:
			continue
		var data: Array = child.mesh.get_mesh_arrays()
		var offset := vertices.size()
		var basis: Basis = child.transform.basis.inverse().transposed()
		for i in data[Mesh.ARRAY_VERTEX].size():
			vertices.append(child.transform * data[Mesh.ARRAY_VERTEX][i])
			normals.append((basis * data[Mesh.ARRAY_NORMAL][i]).normalized())
			colors.append(child.material_override.albedo_color)
		for index in data[Mesh.ARRAY_INDEX]:
			indices.append(index + offset)
		pivot.remove_child(child)
		child.free()
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = vertices
	data[Mesh.ARRAY_NORMAL] = normals
	data[Mesh.ARRAY_COLOR] = colors
	data[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	if not materials.has("merged"):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/cozy_painted.gdshader")
		materials["merged"] = mat
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = materials["merged"]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(node)
	bot._meshes.append(node)
	bot._orig_mats.append(node.material_override)
