class_name ImportedWeapon
extends RefCounted

static func build(rig: WeaponRig, idx: int) -> Node3D:
	var g := Node3D.new()
	var file: String = {0: "Rifle_Assault_East", 1: "Sniper_Rifle_West", 2: "Pistol_Full_West", 4: "SMG_Full_West", 5: "Shotgun_Auto_West"}[idx]
	var scene: PackedScene = load("res://assets/third_party/pichuliru_guns/prepared/" + file + ".glb")
	var imported: Node3D = scene.instantiate()
	g.add_child(imported)
	var offset: Vector3 = [Vector3(0, 0.025, -0.18), Vector3(0, 0.025, -0.26), Vector3(0, 0.025, -0.07), Vector3.ZERO, Vector3(0, 0.025, -0.14), Vector3(0, 0.025, -0.18)][idx]
	var factor: float = [1.15, 1.0, 1.5, 1.0, 1.55, 1.0][idx]
	var mag := Node3D.new()
	var bolt := Node3D.new()
	g.add_child(mag)
	g.add_child(bolt)
	rig._mag_nodes[idx] = mag
	rig._bolt_nodes[idx] = bolt
	rig._mag_rest_pos[idx] = Vector3.ZERO
	rig._bolt_rest_pos[idx] = Vector3.ZERO
	for part in imported.get_children():
		if not part is MeshInstance3D:
			continue
		part.owner = null
		imported.remove_child(part)
		var target: Node3D = mag if str(part.name).begins_with("Magazine") else (bolt if str(part.name).begins_with("Bolt") or str(part.name).begins_with("Slide__") else g)
		target.add_child(part)
		part.position += offset
		part.scale = Vector3.ONE * factor
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material_name := str(part.name)
		if "Grey_Darker" in material_name or "Grey_Dark" in material_name or "Black_Lighter" in material_name:
			rig._register_role(part, "primary")
		elif "Brown" in material_name:
			rig._register_role(part, "secondary")
		elif "Brass" in material_name or "White" in material_name or "Grey_Light" in material_name:
			rig._register_role(part, "accent")
		else:
			part.material_override = rig._vm_mat(Color("303541"), 0, false, 0.45, 0.4)
	imported.free()
	rig._build_articulated_hand(g, Vector3(0, -0.07, 0.02), Vector3(0.18, 0, 0), false)
	var support := Vector3(-0.03, -0.065, -0.29) if idx != 2 else Vector3(-0.035, -0.08, -0.015)
	var lh := rig._build_articulated_hand(g, support, Vector3(0.25, 0.35, -0.45), true)
	rig._left_hands[idx] = lh
	rig._left_hand_rest[idx] = lh.position
	if idx == 1:
		attachment(g, "Scope_West", Vector3(0, 0.065, -0.20))
	elif idx == 0 or idx == 4:
		attachment(g, "Reflex_West", Vector3(0, 0.105, -0.20))
	rig._charm_nodes[idx] = rig._build_weapon_charm(g, Vector3(-0.035, 0.02, -0.09))
	return g

static func attachment(parent: Node3D, file: String, at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://assets/third_party/pichuliru_guns/attachments/" + file + ".glb")
	var model: Node3D = scene.instantiate()
	parent.add_child(model)
	model.position = at
	_finish_attachment(model)
	return model

static func _finish_attachment(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(i)
			if not original is StandardMaterial3D:
				continue
			var mat: StandardMaterial3D = original.duplicate()
			mat.roughness = 0.35
			mat.metallic = 0.45
			if "Glass" in original.resource_name:
				mat.albedo_color = Color(0.18, 0.48, 0.54, 0.22)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			elif "Black_Lighter" in original.resource_name:
				mat.albedo_color = Color("55616b")
			elif "Black" in original.resource_name:
				mat.albedo_color = Color("222c36")
			node.set_surface_override_material(i, mat)
	for child in node.get_children():
		_finish_attachment(child)

static func tip_for(idx: int) -> Vector3:
	return [Vector3(0, 0.06, -0.57), Vector3(0, 0.06, -0.80), Vector3(0, 0.07, -0.28), Vector3.ZERO, Vector3(0, 0.06, -0.485), Vector3(0, 0.06, -0.552)][idx]
