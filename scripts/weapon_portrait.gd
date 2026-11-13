class_name WeaponPortrait
extends SubViewportContainer
## Catalog renders the same mesh and materials as the equipped weapon, once per resize.
var weapon_index := 0
var skin_index := 0

func _init() -> void:
	custom_minimum_size = Vector2(200, 125)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 230)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	resized.connect(func(): viewport.render_target_update_mode = SubViewport.UPDATE_ONCE)
	var rig := WeaponRig.new()
	viewport.add_child(rig)
	var model: Node3D = ImportedWeapon.build(rig, weapon_index) if not bool(WeaponCatalog.DEFINITIONS[weapon_index].melee) else rig._build_karambit()
	rig.add_child(model)
	# Hide hands and sleeves from product previews while retaining weapon geometry.
	for part in rig._sleeve_parts:
		part.get_parent().hide()
	rig.apply_weapon_skin(skin_index, false)
	model.rotation_degrees = Vector3(-8, -72, 0)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b7cad1")
	environment.environment.ambient_light_energy = 0.6
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -40, 0)
	light.light_energy = 1.2
	viewport.add_child(light)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = [0.40, 0.48, 0.25, 0.42, 0.38, 0.42][weapon_index]
	camera.position = Vector3(0.12, 0.08, 2)
	camera.look_at(Vector3(0.12, 0, 0))
	camera.current = true
