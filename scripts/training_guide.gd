class_name TrainingGuide
extends PanelContainer
var game: SakuraBlitzMain
var step := 0
var active := false
var origin := Vector3.ZERO
var yaw := 0.0
var caption: Label
var progress: Label
var skip: Button
var saved_difficulty := 1
var target: StaticBody3D
var target_retry := 0.0

func setup(g: SakuraBlitzMain) -> void:
	game = g
	add_theme_stylebox_override("panel", g._hub._style(Color("193b35")))
	var row := HBoxContainer.new()
	add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	progress = g._hub._label("", 13, Color("93e7c3"))
	caption = g._hub._label("", 16)
	column.add_child(progress)
	column.add_child(caption)
	skip = g._hub._button("Sair do treino", stop)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(skip)
	hide()

func start() -> void:
	remove_target()
	saved_difficulty = game.world.bot_difficulty
	game.world.bot_difficulty = 0
	game.world.spawn_pvp_round()
	game.world.enemies_paused = true
	step = 0
	active = true
	origin = game._body.global_position
	yaw = game._yaw
	_update_text()
	show()

func hit(_result: Dictionary, _weapon: int) -> void:
	if active and step == 3:
		advance()

func advance() -> void:
	step += 1
	origin = game._body.global_position
	yaw = game._yaw
	if step == 3:
		game.world.enemies_paused = true
		game.world.player_spawn_guard = 20
		spawn_target()
	if step == 4:
		remove_target()
		game.profile.data.tutorial_complete = true
		game._save_profile()
		game.world.enemies_paused = true
	_update_text()

func stop() -> void:
	if not active:
		return
	active = false
	remove_target()
	game.world.enemies_paused = false
	game.world.bot_difficulty = saved_difficulty
	game._session_started = false
	hide()
	game._open_hub()

func _process(_delta: float) -> void:
	if not active:
		return
	visible = not game._hub_open and not game._shop_open and not game._paused
	if not visible:
		return
	game.world.combat_time_left = 180
	if step == 3 and not is_instance_valid(target):
		target_retry -= _delta
		if target_retry <= 0:
			target_retry = 1.0
			spawn_target()
	var area := game._safe_ui_rect()
	position = area.position + Vector2(area.size.x * 0.18, 8)
	size = Vector2(area.size.x * 0.64, 84)
	if step == 0 and game._body.global_position.distance_to(origin) > 2:
		advance()
	elif step == 1 and absf(angle_difference(yaw, game._yaw)) > 0.3:
		advance()
	elif step == 2 and game._body.velocity.y > 3:
		advance()

func _update_text() -> void:
	var mobile := game._mobile_hud_enabled
	var messages := [
		"Arraste o analógico para caminhar alguns passos." if mobile else "Use WASD para caminhar alguns passos.",
		"Arraste na área livre para olhar ao redor." if mobile else "Mova o mouse para olhar ao redor.",
		"Toque na seta para pular. Você também pode arrastar para olhar." if mobile else "Aperte Espaço para pular.",
		("Segure MIRAR, ajuste e use ATIRAR para acertar o alvo." if game.profile.data.aim_mode == MobileAim.HOLD else "Toque MIRAR, ajuste e use ATIRAR para acertar o alvo.") if mobile else "Mire e clique para acertar o alvo do estande.",
		"Pronto! Escolha sua arena, modo de tiro e dificuldade dos bots."
	]
	progress.text = "TREINO GUIADO  •  %d / 4" % mini(step + 1, 4) if step < 4 else "TREINO CONCLUÍDO"
	caption.text = messages[step]
	skip.text = "Escolher partida" if step == 4 else "Sair do treino"

func remove_target() -> void:
	if is_instance_valid(target):
		target.queue_free()
	target = null

func spawn_target() -> void:
	var origin := game._body.position
	var found: Variant = null
	for distance in [4.0, 6.0, 3.0, 8.0]:
		for offset in [0.0, -0.35, 0.35, -0.7, 0.7, -1.2, 1.2]:
			var forward := Vector3(-sin(game._yaw + offset), 0, -cos(game._yaw + offset))
			var point: Variant = SpawnDirector.grounded(game.world, origin + forward * distance)
			if point == null:
				continue
			var query := PhysicsRayQueryParameters3D.create(game._cam.global_position, point + Vector3.UP, 1)
			if game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				found = point
				break
		if found != null:
			break
	if found == null:
		return
	target = StaticBody3D.new()
	target.set_meta("is_target", true)
	target.collision_layer = 8
	target.collision_mask = 0
	game.world._stage_root.add_child(target)
	target.position = found
	var direction: Vector3 = origin - found
	target.rotation.y = atan2(direction.x, direction.z)
	var stand := ItemArt.model(target, "sign", Vector3.ZERO, 1.0)
	var art := ItemArt.model(target, "target-large", Vector3(0, 0.8, 0.45), 0.95, PI / 2)
	var extent := SignatureArenas._bounds(stand).merge(SignatureArenas._bounds(art))
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = extent.size
	collision.shape = box
	collision.position = extent.get_center()
	target.add_child(collision)
