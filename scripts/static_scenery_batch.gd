class_name StaticSceneryBatch
extends RefCounted
## Merge static box details by material and 24m cell. Keep colliders independent.
## Animated roots and actors are explicitly excluded by the world builder.
static func bake(root: Node3D, excluded: Array[Node]) -> int:
	var groups: Dictionary = {}
	_collect(root, root, excluded, groups)
	var removed := 0
	var cube := BoxMesh.new()
	for key in groups:
		var items: Array = groups[key]
		if items.size() < 3:
			continue
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = cube
		multi.instance_count = items.size()
		for i in items.size():
			var mesh: MeshInstance3D = items[i]
			var xf := root.global_transform.affine_inverse() * mesh.global_transform
			xf.basis = xf.basis.scaled_local((mesh.mesh as BoxMesh).size)
			multi.set_instance_transform(i, xf)
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multi
		batch.material_override = items[0].material_override
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(batch)
		for mesh in items:
			mesh.free()
		removed += items.size() - 1
	return removed

static func _collect(node: Node, root: Node3D, excluded: Array[Node], groups: Dictionary) -> void:
	if node in excluded or node is EnemyBot:
		return
	if node is MeshInstance3D and node.mesh is BoxMesh and node.material_override != null and node.get_child_count() == 0:
		var p: Vector3 = node.global_position
		var key := "%d:%d:%d" % [node.material_override.get_instance_id(), floori(p.x / 24), floori(p.z / 24)]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(node)
	for child in node.get_children():
		_collect(child, root, excluded, groups)
