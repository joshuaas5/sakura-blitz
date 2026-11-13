class_name CombatMatch
extends Node3D
## Local authority for teams and physical capture-the-flag objectives.
const FFA := 0
const TEAMS := 1
const CTF := 2
const LABELS := ["Cada um por si", "Equipes", "Captura de bandeira"]
const COLORS := [Color("93e7c3"), Color("f08c91")]
const TEAM_NAMES := ["Menta", "Coral"]
const POPULATIONS := [6, 6, 8, 8, 8, 8, 8, 8, 8, 18, 18]
const MAP_BOUNDS := [Rect2(-18, -18, 36, 36), Rect2(-19, -19, 38, 38), Rect2(-24, -34, 48, 68), Rect2(-22, -22, 44, 44), Rect2(-22, -24, 44, 48), Rect2(-24, -28, 48, 56), Rect2(-25, -27, 50, 54), Rect2(-25, -27, 50, 54), Rect2(-25, -27, 50, 54), Rect2(-48, -44, 96, 88), Rect2(-56, -38, 112, 76)]
var world: SakuraWorld
var flags: Array[Dictionary] = []
var captures := {}
var _interaction_cd := 0.0

static func population(stage: int, kind: int, override_count: int = 0) -> int:
	var count: int = override_count if stage >= 9 and override_count in [12, 18, 24] else POPULATIONS[stage]
	return count if kind == FFA else count - 1

func setup(w: SakuraWorld) -> void:
	world = w
	var bases: Array[Vector3] = [w._current_pvp_spawn, w.tr_spawns[0]]
	for at in w.tr_spawns:
		if at.z + absf(at.x) * 0.1 < bases[1].z + absf(bases[1].x) * 0.1:
			bases[1] = at
	var route := w.arena_navigation.path(bases[0], bases[1])
	var offset := 6 if w.arena_navigation is SurfaceNavigation else 3
	if route.size() > offset * 2 + 1:
		bases[0] = route[offset]
		bases[1] = route[-offset - 1]
	for team in 2:
		var visual := Node3D.new()
		add_child(visual)
		var pole := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.height = 2
		cylinder.top_radius = 0.045
		cylinder.bottom_radius = 0.06
		cylinder.radial_segments = 8
		pole.mesh = cylinder
		pole.material_override = SignatureArenas.material("e7dfbb")
		pole.position.y = 1
		visual.add_child(pole)
		var cloth := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.2, 0.75)
		cloth.mesh = quad
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/team_flag.gdshader")
		material.set_shader_parameter("team_color", COLORS[team])
		cloth.material_override = material
		cloth.position = Vector3(0.6, 1.65, 0)
		visual.add_child(cloth)
		var marker := MeshInstance3D.new()
		var pad := CylinderMesh.new()
		pad.top_radius = 1.7
		pad.bottom_radius = 1.7
		pad.height = 0.025
		pad.radial_segments = 24
		marker.mesh = pad
		marker.material_override = SignatureArenas.material(COLORS[team].darkened(0.3).to_html(false))
		marker.position = bases[team] - Vector3.UP * 0.03
		add_child(marker)
		flags.append({"home": bases[team], "at": bases[team], "carrier": "", "dropped": false, "timer": 0.0, "visual": visual})
		visual.position = bases[team]

func actor_position(name: String) -> Variant:
	if name == "PLAYER":
		return world.player_pos
	for bot in world.enemies:
		if is_instance_valid(bot) and not bot._dead and bot.bot_name == name:
			return bot.global_position
	return null

func reset_flag(team: int) -> void:
	var flag := flags[team]
	flag.carrier = ""
	flag.dropped = false
	flag.timer = 0.0
	flag.at = flag.home
	flag.visual.position = flag.home

func drop_carrier(name: String, at: Vector3) -> void:
	for team in 2:
		if flags[team].carrier == name:
			flags[team].carrier = ""
			flags[team].dropped = true
			flags[team].timer = 25.0
			flags[team].at = at
			flags[team].visual.position = at
			world.objective_notice.emit("Bandeira %s caída • retorno em 25 s" % TEAM_NAMES[team])

func interact(name: String, at: Vector3) -> void:
	var team := world.team_for(name)
	if team < 0:
		return
	var own := flags[team]
	var enemy := flags[1 - team]
	if own.dropped and at.distance_to(own.at) < 2:
		reset_flag(team)
		world.objective_notice.emit("%s recuperou a bandeira %s" % ["Você" if name == "PLAYER" else name, TEAM_NAMES[team]])
	if enemy.carrier == "" and at.distance_to(enemy.at) < 1.8:
		enemy.carrier = name
		enemy.dropped = false
		world.objective_notice.emit("%s pegou a bandeira %s!" % ["Você" if name == "PLAYER" else name, TEAM_NAMES[1 - team]])
	if enemy.carrier == name and own.carrier == "" and not own.dropped and at.distance_to(own.home) < 2.3:
		world.team_scores[team] += 1
		captures[name] = int(captures.get(name, 0)) + 1
		world.objective_scored.emit(name)
		reset_flag(1 - team)
		world.objective_notice.emit("CAPTURA! Equipe %s • %d / %d" % [TEAM_NAMES[team], world.team_scores[team], world.combat_kill_limit])

func tick(delta: float) -> void:
	for team in 2:
		var flag := flags[team]
		if flag.carrier != "":
			var pos: Variant = actor_position(flag.carrier)
			if pos == null:
				drop_carrier(flag.carrier, flag.at)
			else:
				flag.at = pos
				flag.visual.position = pos + Vector3.UP * 0.7
		elif flag.dropped:
			flag.timer -= delta
			if flag.timer <= 0:
				reset_flag(team)
	_interaction_cd -= delta
	if _interaction_cd > 0:
		return
	_interaction_cd = 0.1
	if world.player_spawn_guard <= 0:
		interact("PLAYER", world.player_pos)
	for bot in world.enemies:
		if is_instance_valid(bot) and not bot._dead:
			interact(bot.bot_name, bot.global_position)

func bot_goal(bot: EnemyBot) -> Vector3:
	var team := bot.team_id
	var own := flags[team]
	var enemy := flags[1 - team]
	if enemy.carrier == bot.bot_name:
		return own.at if own.dropped else own.home
	if bot.runner_idx % 3 == 0 and (own.carrier != "" or own.dropped):
		return own.at
	if enemy.carrier != "":
		var offset := Vector3(-3 if bot.runner_idx % 2 == 0 else 3, 0, 2)
		var escort: Variant = SpawnDirector.grounded(world, enemy.at + offset)
		return escort if escort != null else enemy.at
	return enemy.at
