class_name WeaponBatch
extends RefCounted
## Merge rigid pieces inside each animated joint, retaining cosmetic material roles.
static func bake(rig: WeaponRig, parent: Node3D) -> void:
	for child in parent.get_children():
		if child is Node3D and not child is MeshInstance3D:
			bake(rig, child)
	var groups := {}
	for child in parent.get_children():
		if not child is MeshInstance3D or child.mesh == null:
			continue
		var role: String = child.get_meta("weapon_role", "")
		for surface in child.mesh.get_surface_count():
			var material: Material = child.get_active_material(surface)
			var key := role if not role.is_empty() else str(material.get_instance_id())
			var arrays: Array = child.mesh.surface_get_arrays(surface)
			arrays[Mesh.ARRAY_TANGENT] = null
			# Viewmodel materials use UV1; UV2/color are not part of this material system.
			arrays[Mesh.ARRAY_TEX_UV2] = null
			arrays[Mesh.ARRAY_COLOR] = null
			if arrays[Mesh.ARRAY_TEX_UV] == null:
				var uv := PackedVector2Array()
				uv.resize(arrays[Mesh.ARRAY_VERTEX].size())
				arrays[Mesh.ARRAY_TEX_UV] = uv
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			if not groups.has(key):
				groups[key] = {"material": material, "role": role, "items": [], "nodes": []}
			groups[key].items.append({"mesh": mesh, "transform": child.transform})
			if not groups[key].nodes.has(child):
				groups[key].nodes.append(child)
	for group in groups.values():
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item in group.items:
			tool.append_from(item.mesh, 0, item.transform)
		var merged := MeshInstance3D.new()
		merged.mesh = tool.commit()
		merged.material_override = group.material
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(merged)
		if not group.role.is_empty():
			rig._register_role(merged, group.role)
		for node in group.nodes:
			for registry in [rig._skin_parts_primary, rig._skin_parts_secondary, rig._skin_parts_accent, rig._sleeve_parts, rig._glove_parts]:
				registry.erase(node)
			if node.get_parent() == parent:
				parent.remove_child(node)
				node.queue_free()
