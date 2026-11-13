class_name NpcWeaponArt
extends RefCounted
## Imported weapon silhouettes, flattened into the existing animated hand draw.
const S := preload("res://scripts/signature_arenas.gd")
const NAMES := ["Rifle_Assault_East", "Sniper_Rifle_West", "SMG_Full_West"]
static var scenes := {}

static func attach(bot: EnemyBot) -> void:
	var path := "res://assets/third_party/pichuliru_guns/prepared/%s.glb" % NAMES[bot.kind]
	if not scenes.has(path):
		scenes[path] = load(path)
	var source: Node3D = scenes[path].instantiate()
	var bounds := S._bounds(source)
	var length: float = [0.72, 1.0, 0.58][bot.kind]
	var factor := length / maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var basis := Basis(Vector3.RIGHT, 0.9) * Basis(Vector3.UP, PI) * Basis.from_scale(Vector3.ONE * factor)
	var transform := Transform3D(basis, Vector3(-0.03, -0.34, 0.18) - basis * bounds.get_center())
	flatten(source, transform, bot._arm_r)
	source.free()

static func flatten(node: Node3D, parent_transform: Transform3D, arm: Node3D) -> void:
	var transform := parent_transform * node.transform
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var child := MeshInstance3D.new()
			child.mesh = mesh
			child.transform = transform
			var original: Material = node.get_active_material(surface)
			var material := StandardMaterial3D.new()
			material.albedo_color = original.albedo_color if original is StandardMaterial3D else Color("78818a")
			child.material_override = material
			arm.add_child(child)
	for child in node.get_children():
		if child is Node3D:
			flatten(child, transform, arm)
