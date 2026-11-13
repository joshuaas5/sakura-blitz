class_name CozyPortrait
extends SubViewportContainer
## Render the actual model once; catalog cards do not run a second game loop.
var outfit := 0

func _init() -> void:
	custom_minimum_size = Vector2(160, 180)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	resized.connect(func(): viewport.render_target_update_mode = SubViewport.UPDATE_ONCE)
	var bot := EnemyBot.new()
	bot.is_runner = true
	bot.runner_idx = outfit
	bot.set_meta("imperial", outfit == 3)
	bot.process_mode = Node.PROCESS_MODE_DISABLED
	viewport.add_child(bot)
	bot._root = Node3D.new()
	bot.add_child(bot._root)
	CozyAvatar.build(bot)
	bot._root.rotation.y = -0.3
	bot._arm_l.rotation.z = -0.12
	bot._arm_r.rotation.z = 0.12
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	camera.position = Vector3(0, 1.25, 4)
	camera.look_at(Vector3(0, 0.94, 0))
	camera.current = true
