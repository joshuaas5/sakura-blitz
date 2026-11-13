class_name ImportedSceneryBatch
extends RefCounted
## Combine imported static surfaces by material and spatial cell. Collision stays separate.
static func bake(root: Node3D, max_distance: float = 100) -> void:
	var groups := {}
	var meshes: Array[MeshInstance3D] = []
	var palette := {"sources": {}, "families": {}}
	_collect(root, root, groups, meshes, palette)
	for key in groups:
		var group: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for item in group.items:
			var relative: Transform3D = item.transform
			relative.origin -= group.center
			st.append_from(item.mesh, item.surface, relative)
		st.set_material(group.material)
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.position = group.center
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		merged.visibility_range_end = 58 if group.detail else max_distance
		if group.detail:
			merged.add_to_group("scenery_detail")
		root.add_child(merged)
	root.set_meta("scenery_batch", {"source_meshes": meshes.size(), "draw_surfaces": groups.size(), "material_families": palette.families.size()})
	for mesh in meshes:
		# Defer destruction until renderer/resource notifications have drained.
		mesh.queue_free()
		mesh.hide()

static func _collect(node: Node, root: Node3D, groups: Dictionary, meshes: Array[MeshInstance3D], palette: Dictionary, detail: bool = false) -> void:
	if node.get_meta("preserve_item_art", false):
		return
	detail = detail or node.get_meta("scenery_detail", false)
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		meshes.append(node)
		var xf: Transform3D = root.global_transform.affine_inverse() * node.global_transform
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(surface)
			if material == null:
				continue
			var source: Mesh = node.mesh
			var surface_index: int = surface
			if material is StandardMaterial3D and not material.vertex_color_is_srgb and material.next_pass == null:
				var painted := paint(source, surface, material, palette)
				source = painted.mesh
				material = painted.material
				surface_index = 0
			# The position is local to each cell, so distance culling uses the cell itself.
			var cell := Vector2i(floori(xf.origin.x / 28), floori(xf.origin.z / 28))
			var key := "%d:%d:%d:%d:%s" % [material.get_instance_id(), source.surface_get_format(surface_index), cell.x, cell.y, detail]
			if not groups.has(key):
				groups[key] = {"material": material, "items": [], "detail": detail, "center": Vector3(cell.x * 28 + 14, 0, cell.y * 28 + 14)}
			groups[key].items.append({"mesh": source, "surface": surface_index, "transform": xf})
	for child in node.get_children():
		_collect(child, root, groups, meshes, palette, detail)

static func paint(mesh: Mesh, surface: int, material: StandardMaterial3D, palette: Dictionary) -> Dictionary:
	var source_key := "%d:%d:%d" % [mesh.get_instance_id(), surface, material.get_instance_id()]
	if palette.sources.has(source_key):
		return palette.sources[source_key]
	# Compare every stored render property, retaining textures, UVs, alpha and shading.
	# Only base tint/vertex-color enable differ; these are baked into vertex data.
	var signature: Array = []
	for property in material.get_property_list():
		var name: String = property.name
		if not (int(property.usage) & PROPERTY_USAGE_STORAGE) or name.begins_with("resource_") or name.begins_with("metadata/") or name in ["albedo_color", "vertex_color_use_as_albedo", "vertex_color_is_srgb"]:
			continue
		var value: Variant = material.get(name)
		signature.append([name, value.get_instance_id() if value is Object else value])
	var key := var_to_bytes(signature).hex_encode()
	if not palette.families.has(key):
		var shared: StandardMaterial3D = material.duplicate()
		shared.albedo_color = Color.WHITE
		shared.vertex_color_use_as_albedo = true
		palette.families[key] = shared
	var arrays: Array = mesh.surface_get_arrays(surface)
	var count: int = arrays[Mesh.ARRAY_VERTEX].size()
	var colors := PackedColorArray()
	colors.resize(count)
	for index in count:
		var original: Color = arrays[Mesh.ARRAY_COLOR][index] if material.vertex_color_use_as_albedo and arrays[Mesh.ARRAY_COLOR] != null and arrays[Mesh.ARRAY_COLOR].size() == count else Color.WHITE
		colors[index] = original * material.albedo_color
	arrays[Mesh.ARRAY_COLOR] = colors
	# Static surfaces with no normal mapping can share a stable layout.
	if not material.normal_enabled and not material.heightmap_enabled and not material.anisotropy_enabled:
		arrays[Mesh.ARRAY_TANGENT] = null
	if arrays[Mesh.ARRAY_TEX_UV] == null:
		var uv := PackedVector2Array()
		uv.resize(count)
		arrays[Mesh.ARRAY_TEX_UV] = uv
	if arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_INDEX].is_empty():
		var indices := PackedInt32Array()
		for index in count:
			indices.append(index)
		arrays[Mesh.ARRAY_INDEX] = indices
	var painted := ArrayMesh.new()
	painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var result := {"mesh": painted, "material": palette.families[key]}
	palette.sources[source_key] = result
	return result
