class_name CombatFx
extends Node3D
## Bounded surface impacts: reuse marks instead of allocating cubes for every bullet.
const CAPACITY := 32
var marks: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
var ages: Array[float] = []
var cursor := 0
const SPARKS := 96
var sparks: MultiMeshInstance3D
var spark_positions := PackedVector3Array()
var spark_velocities := PackedVector3Array()
var spark_lives := PackedFloat32Array()
var spark_cursor := 0

func setup() -> void:
	sparks = MultiMeshInstance3D.new()
	sparks.multimesh = MultiMesh.new()
	sparks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	sparks.multimesh.use_colors = true
	var sprite := QuadMesh.new()
	sprite.size = Vector2.ONE * 0.14
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/vfx/petal_spark.svg")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sprite.material = material
	sparks.multimesh.mesh = sprite
	sparks.multimesh.instance_count = SPARKS
	sparks.multimesh.custom_aabb = AABB(Vector3(-200, -20, -200), Vector3(400, 120, 400))
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	spark_positions.resize(SPARKS)
	spark_velocities.resize(SPARKS)
	spark_lives.resize(SPARKS)
	for index in SPARKS:
		sparks.multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	sparks.hide()
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

func burst(at: Vector3, color: Color, count: int) -> void:
	for index in mini(count, 12):
		var slot := spark_cursor
		spark_cursor = (spark_cursor + 1) % SPARKS
		var angle := slot * 2.39996
		spark_positions[slot] = at
		spark_velocities[slot] = Vector3(cos(angle) * 2.4, 1.4 + slot % 3 * 0.6, sin(angle) * 2.4)
		spark_lives[slot] = 0.38
		sparks.multimesh.set_instance_color(slot, color.lightened(0.45) if slot % 3 == 0 else color)
	sparks.show()

func _process(delta: float) -> void:
	var alive := false
	for index in SPARKS:
		if spark_lives[index] <= 0:
			continue
		spark_lives[index] = maxf(0, spark_lives[index] - delta)
		spark_velocities[index].y -= delta * 6
		spark_positions[index] += spark_velocities[index] * delta
		var scale := minf(1, spark_lives[index] * 8)
		sparks.multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * scale), spark_positions[index]))
		alive = alive or spark_lives[index] > 0
	sparks.visible = alive
	for index in CAPACITY:
		if ages[index] >= 8:
			continue
		ages[index] += delta
		materials[index].set_shader_parameter("age", ages[index])
		if ages[index] >= 8:
			marks[index].hide()
