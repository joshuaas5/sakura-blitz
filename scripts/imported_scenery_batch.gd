class_name ImportedSceneryBatch
extends RefCounted
## Combine imported static surfaces by material and spatial cell. Collision stays separate.
static func bake(root: Node3D, max_distance: float = 100) -> void:
	var groups := {}
	var meshes: Array[MeshInstance3D] = []
	_collect(root, root, groups, meshes)
	for key in groups:
		var group: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item in group.items:
			st.append_from(item.mesh, item.surface, item.transform)
		st.set_material(group.material)
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		merged.visibility_range_end = max_distance
		root.add_child(merged)
	for mesh in meshes:
		# Defer destruction until renderer/resource notifications have drained.
		mesh.queue_free()
		mesh.hide()

static func _collect(node: Node, root: Node3D, groups: Dictionary, meshes: Array[MeshInstance3D]) -> void:
	if node.get_meta("preserve_item_art", false):
		return
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		meshes.append(node)
		var xf: Transform3D = root.global_transform.affine_inverse() * node.global_transform
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(surface)
			if material == null:
				continue
			# SurfaceTool cannot safely append different vertex layouts into one surface.
			var key := "%d:%d:%d:%d" % [material.get_instance_id(), node.mesh.surface_get_format(surface), floori(xf.origin.x / 28), floori(xf.origin.z / 28)]
			if not groups.has(key):
				groups[key] = {"material": material, "items": []}
			groups[key].items.append({"mesh": node.mesh, "surface": surface, "transform": xf})
	for child in node.get_children():
		_collect(child, root, groups, meshes)
