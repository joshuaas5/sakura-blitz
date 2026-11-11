class_name RetroBatch
extends RefCounted
## MultiMesh batcher for architectural details, grass tufts, and flowers.

var _xf: Array = []
var _col: Array = []


func add(x: float, y: float, z: float, sx: float, sy: float, sz: float, c: Color) -> void:
	_xf.append(Transform3D(Basis.from_scale(Vector3(sx, sy, sz)), Vector3(x + sx * 0.5, y + sy * 0.5, z + sz * 0.5)))
	_col.append(c)


func add_xf(xf: Transform3D, c: Color) -> void:
	_xf.append(xf)
	_col.append(c)


func size() -> int:
	return _xf.size()


func flush(parent: Node3D, glow: float = 0.0, tex: int = -2, local: bool = false) -> MultiMeshInstance3D:
	if _xf.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	mm.mesh = bm
	mm.instance_count = _xf.size()
	var inv := parent.global_transform.affine_inverse() if parent.is_inside_tree() and not local else Transform3D.IDENTITY
	for i in _xf.size():
		mm.set_instance_transform(i, inv * (_xf[i] as Transform3D))
		mm.set_instance_color(i, _col[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_energy_multiplier = glow
	mi.material_override = m
	if tex >= -1:
		mi.set_meta("tex", tex)
	parent.add_child(mi)
	_xf.clear()
	_col.clear()
	return mi
