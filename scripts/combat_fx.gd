class_name CombatFx
extends Node3D
## Bounded surface impacts: reuse marks instead of allocating cubes for every bullet.
const CAPACITY := 32
var marks: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
var ages: Array[float] = []
var cursor := 0

func setup() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	for index in CAPACITY:
		var node := MeshInstance3D.new()
		node.mesh = quad
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/surface_impact.gdshader")
		node.material_override = mat
		add_child(node)
		node.hide()
		marks.append(node)
		materials.append(mat)
		ages.append(10.0)

func impact(at: Vector3, normal: Vector3, color: Color) -> void:
	var index := cursor
	cursor = (cursor + 1) % CAPACITY
	var node := marks[index]
	var axis := normal.normalized()
	if axis.length_squared() < 0.5:
		axis = Vector3.UP
	node.global_position = at + axis * 0.018
	node.quaternion = Quaternion(Vector3.BACK, axis)
	node.rotate_object_local(Vector3.BACK, float(index) * 2.39996)
	materials[index].set_shader_parameter("spark_color", color)
	materials[index].set_shader_parameter("age", 0.0)
	ages[index] = 0.0
	node.show()

func _process(delta: float) -> void:
	for index in CAPACITY:
		if ages[index] >= 8:
			continue
		ages[index] += delta
		materials[index].set_shader_parameter("age", ages[index])
		if ages[index] >= 8:
			marks[index].hide()
