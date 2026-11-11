class_name SakuraWorld
extends Node3D
## Dual-Mode Competitive World for SAKURA BLITZ (Zero Shadow/Texture Flicker, Optimized Single-Active-Stage):
## - MODO 0: MODO TIRO — PHANTOM BLITZ (4 Complex Combat Arenas: Vila BO2, Shipment CQC, Crossfire Sniper Canyon, Cyber-Vertigo 3-Floor)
##   * Continuous 6-bot action + 7 named competitors on the Live Match Kill Leaderboard!
## - MODO 1: MODO PARKOUR — FALL GUYS RACE (4 Hardcore 8-Sector Marathons: 335m to 380m long!)
##   * Zero PvP shooting deaths! Starts with a 5-4-3-2-1 VAI! Starting Gate and 7 Runner Bots racing you for 1st Place!

signal enemy_killed(was_headshot: bool, bot_name: String, hit_pos: Vector3)
signal round_won(round_num: int, ct_score: int, tr_score: int)
signal kz_stage_reached(stage_idx: int, stage_name: String, course_time: float, cp_pos: Vector3)
signal kz_course_finished(course_time: float, best_time: float, place: int)
signal kz_ring_collected(ring_idx: int)
signal player_damaged(amount: float, from_pos: Vector3, attacker_name: String)
signal pickup_collected(kind: String, amount: float)
signal runner_crossed_finish(bot_name: String, place: int, f_time: float)
signal bot_frag_feed(killer_name: String, victim_name: String, weapon_tag: String)

const PSX := preload("res://assets/shaders/psx_pro.gdshader")
const PSX_ALPHA := preload("res://assets/shaders/psx_alpha.gdshader")
const CozyProps := preload("res://scripts/cozy_props.gd")

const MODE_COMBAT := 0
const MODE_PARKOUR := 1

const COMBAT_STAGE_DEFS := [
	{
		"id": 0,
		"short": "F1 VILA BO2",
		"title": "TIRO 1/4 // VILA SAKURA x BO2 NUKETOWN",
		"subtitle": "Combate Misto (Casas 2 Andares, Onibus e Pontes)  |  [M] Mudar p/ Modo Parkour  |  [F1-F4] Mapas",
		"is_pvp": true
	},
	{
		"id": 1,
		"short": "F2 SHIPMENT CQC",
		"title": "TIRO 2/4 // ARENA SHIPMENT & KILLHOUSE (CLOSE QUARTERS)",
		"subtitle": "Combate Curta Distancia Frenetico (Containers, Passarela Superior e Brechas)  |  [M] Modo Parkour",
		"is_pvp": true
	},
	{
		"id": 2,
		"short": "F3 SNIPER CANYON",
		"title": "TIRO 3/4 // DESFILADEIRO CROSSFIRE (LONG QUARTERS & SNIPER)",
		"subtitle": "Combate Longa Distancia (2 Bastioes Sniper, Ponte Suspensa de 44m e Trincheira)  |  [M] Modo Parkour",
		"is_pvp": true
	},
	{
		"id": 3,
		"short": "F4 CYBER VERTIGO",
		"title": "TIRO 4/4 // TORRE CYBER-VERTIGO (3 ANDARES + JUMP-PADS)",
		"subtitle": "Combate Vertical Insano em 3 Andares no Topo do Arranha-Ceu  |  [M] Mudar p/ Modo Parkour",
		"is_pvp": true
	}
]

const PARKOUR_STAGE_DEFS := [
	{
		"id": 0,
		"short": "F1 EL PANADERO",
		"title": "CORRIDA 1/4 // MARATONA EL PANADERO EXTREME (335m • 8 SETORES)",
		"subtitle": "Disputa Contra 7 Bots! Tambores Lily Leapers, Pendulos, See-Saws, Pinball & Big Yeetus!",
		"is_pvp": false
	},
	{
		"id": 1,
		"short": "F2 SLIME CLIMB",
		"title": "CORRIDA 2/4 // SLIME CLIMB & DEATHRUN HARDCORE (350m • 8 SETORES)",
		"subtitle": "Disputa Contra 7 Bots! Paredes Empurradoras, Jump Showdown, Grade Tip-Toe 30 Pisos & Door Dash!",
		"is_pvp": false
	},
	{
		"id": 2,
		"short": "F3 SURF ODYSSEY",
		"title": "CORRIDA 3/4 // CS:GO SURF & KZ ODYSSEY (365m • 8 SETORES)",
		"subtitle": "Disputa Contra 7 Bots! 10 Blocos Bhop, 5 Rampas de Surf, Torre Tripla KZ & Gangorras Aereas!",
		"is_pvp": false
	},
	{
		"id": 3,
		"short": "F4 OMEGA GAUNTLET",
		"title": "CORRIDA 4/4 // FALL GUYS OMEGA GAUNTLET (380m • 8 SETORES)",
		"subtitle": "A Maratona Suprema de 380m! Todos os Obstaculos Combinados ate a Coroa Real!",
		"is_pvp": false
	}
]

const ATMO_PRESETS := [
	{
		"name": "MANHA COZY ENSOLARADA",
		"sky_top": Color("2d7dd2"),
		"sky_hor": Color("ffe5c4"),
		"gnd_hor": Color("f5d6b8"),
		"gnd_bot": Color("6b7f5e"),
		"amb_e": 0.74,
		"sun_c": Color("fff2dc"),
		"sun_e": 0.52,
		"sat": 1.20,
		"con": 1.07
	},
	{
		"name": "GOLDEN HOUR BO2 (POR DO SOL)",
		"sky_top": Color("4a2c6d"),
		"sky_hor": Color("ff8c42"),
		"gnd_hor": Color("e07a5f"),
		"gnd_bot": Color("4a3b32"),
		"amb_e": 0.68,
		"sun_c": Color("ffb76b"),
		"sun_e": 0.64,
		"sat": 1.26,
		"con": 1.09
	},
	{
		"name": "FESTIVAL CREPUSCULO SAKURA",
		"sky_top": Color("1a1b4b"),
		"sky_hor": Color("d45d79"),
		"gnd_hor": Color("6e3b56"),
		"gnd_bot": Color("232038"),
		"amb_e": 0.56,
		"sun_c": Color("ff9ebb"),
		"sun_e": 0.44,
		"sat": 1.28,
		"con": 1.11
	}
]

var game_mode := MODE_COMBAT
var current_stage_idx := 0
var player_pos := Vector3(0.0, 0.2, 15.2)
var enemies_paused := false
var psx_enabled := true

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var atmo_idx := 0

var _stage_root: Node3D
var _mats := {}
var _psx_mats := {}
var _meshes := {}
var _glb_cache := {}
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _petals: CPUParticles3D
var _hazard_cd := 0.0

# Combat Mode (Phantom Blitz) State & Live Bot Leaderboard
var round_number := 1
var ct_score := 0
var tr_score := 0
var bots_per_round := 6
var _bot_respawn_cd := 0.0
var _bot_sim_frag_cd := 3.8
var enemies: Array[EnemyBot] = []
var enemy_orbs: Array[Dictionary] = []
var vfx_items: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var floor_weapon_pads: Array[Dictionary] = []
var bot_scoreboard: Dictionary = {} # bot_name -> {"kills": int, "deaths": int, "pts": int}

# Parkour Race Mode (Fall Guys) State & 7 Runner Bots
var race_countdown := 0.0
var race_countdown_last_int := 6
var race_finished_count := 0
var player_race_place := 0
var _start_gate_node: Node3D
var parkour_runners: Array[EnemyBot] = []
var race_waypoints: Array[Vector3] = []

var kz_ladders: Array[AABB] = []
var surf_ramps: Array[Dictionary] = []
var kz_checkpoints: Array[Dictionary] = []
var kz_rings: Array[Dictionary] = []
var kz_jumppads: Array[Vector3] = []
var bouncy_awnings: Array[AABB] = []
var moving_platforms: Array[Dictionary] = []
var falling_tiles: Array[Dictionary] = []

var _sweeper_pivots: Array[Dictionary] = []
var spinning_hammers: Array[Dictionary] = []
var sliding_pushers: Array[Dictionary] = []
var swinging_pendulums: Array[Dictionary] = []
var tilting_seesaws: Array[Dictionary] = []
var bumper_pillars: Array[Dictionary] = []
var speed_conveyors: Array[Dictionary] = []

var kz_active_stage := 0
var kz_running := false
var kz_time := 0.0
var kz_best_times := [0.0, 0.0, 0.0, 0.0]
var kz_best_time := 0.0
var kz_start_pad := Vector3(0.0, 0.2, 16.5)
var kz_finish_pad := Vector3(0.0, 12.0, -330.0)

var _current_pvp_spawn := Vector3(0.0, 0.2, 15.2)
var tr_spawns: Array[Vector3] = []


func build() -> void:
	_rng.seed = 1999
	_init_bot_scoreboard()
	_build_sky_and_lights()
	_build_petal_breeze()
	load_mode_and_stage(MODE_COMBAT, 0)


func _init_bot_scoreboard() -> void:
	bot_scoreboard.clear()
	for bname in EnemyBot.BOT_NAMES:
		bot_scoreboard[bname] = {"kills": 0, "deaths": 0, "pts": 0}


func get_active_stage_def() -> Dictionary:
	var list := COMBAT_STAGE_DEFS if game_mode == MODE_COMBAT else PARKOUR_STAGE_DEFS
	return list[clampi(current_stage_idx, 0, list.size() - 1)]


func get_stage_defs_for_mode() -> Array:
	return COMBAT_STAGE_DEFS if game_mode == MODE_COMBAT else PARKOUR_STAGE_DEFS


func load_mode_and_stage(new_mode: int, new_stage_idx: int) -> Array:
	game_mode = clampi(new_mode, 0, 1)
	current_stage_idx = clampi(new_stage_idx, 0, 3)
	_clear_active_stage()

	_stage_root = Node3D.new()
	_stage_root.name = "StageRoot_%d_%d" % [game_mode, current_stage_idx]
	add_child(_stage_root)

	if game_mode == MODE_COMBAT:
		if current_stage_idx == 0:
			_build_combat_1_vila_bo2()
		elif current_stage_idx == 1:
			_build_combat_2_shipment_cqc()
		elif current_stage_idx == 2:
			_build_combat_3_sniper_canyon()
		else:
			_build_combat_4_cyber_vertigo()
		kz_running = false
		race_countdown = 0.0
		spawn_pvp_round(bots_per_round)
		return [_current_pvp_spawn, 0.0, 0.0]
	else:
		_build_parkour_marathon(current_stage_idx)
		kz_best_time = float(kz_best_times[current_stage_idx])
		start_parkour_race()
		return [kz_start_pad, 0.0, 0.0]


func start_parkour_race() -> void:
	kz_active_stage = 0
	kz_time = 0.0
	kz_running = false
	race_finished_count = 0
	player_race_place = 0
	var skip_cd := OS.get_cmdline_user_args().has("--test") or OS.get_cmdline_user_args().has("--shot")
	race_countdown = 0.0 if skip_cd else 5.0
	race_countdown_last_int = 6
	if skip_cd:
		kz_running = true
	if is_instance_valid(_start_gate_node):
		_start_gate_node.position.y = -14.0 if skip_cd else 0.0
	_spawn_parkour_runners()


func _spawn_parkour_runners() -> void:
	for r in parkour_runners:
		if is_instance_valid(r):
			r.queue_free()
	parkour_runners.clear()
	if enemies_paused:
		return
	for i in 7:
		var lane_x := (float(i) - 3.0) * 1.45
		var sp := kz_start_pad + Vector3(lane_x, 0.1, -0.6 - float(i % 2) * 0.9)
		var runner := EnemyBot.spawn_parkour_runner(self, _stage_root, sp, i)
		runner.runner_finished.connect(_on_runner_finished)
		parkour_runners.append(runner)


func _on_runner_finished(bot: EnemyBot, f_time: float) -> void:
	race_finished_count += 1
	var place := race_finished_count
	runner_crossed_finish.emit(bot.bot_name, place, f_time)


func get_race_standings() -> Array[Dictionary]:
	var total_dist := maxf(1.0, kz_start_pad.z - kz_finish_pad.z)
	var p_dist := clampf(kz_start_pad.z - player_pos.z, 0.0, total_dist)
	var rows: Array[Dictionary] = [{
		"name": "VOCE",
		"is_player": true,
		"dist": total_dist if player_race_place > 0 else p_dist,
		"pct": 100.0 if player_race_place > 0 else (p_dist / total_dist * 100.0),
		"finished": player_race_place > 0,
		"place": player_race_place
	}]
	for r in parkour_runners:
		if is_instance_valid(r):
			var d := total_dist if r.finish_placed else clampf(kz_start_pad.z - r.global_position.z, 0.0, total_dist)
			rows.append({
				"name": r.bot_name,
				"is_player": false,
				"dist": d,
				"pct": d / total_dist * 100.0,
				"finished": r.finish_placed,
				"place": 0
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.dist) > float(b.dist)
	)
	for i in rows.size():
		rows[i]["rank"] = i + 1
	return rows


func get_combat_standings(player_kills: int, player_deaths: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = [{
		"name": "VOCE",
		"is_player": true,
		"kills": player_kills,
		"deaths": player_deaths,
		"pts": player_kills * 100
	}]
	for bname in bot_scoreboard.keys():
		var d: Dictionary = bot_scoreboard[bname]
		rows.append({
			"name": str(bname),
			"is_player": false,
			"kills": int(d.kills),
			"deaths": int(d.deaths),
			"pts": int(d.pts)
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.kills) != int(b.kills):
			return int(a.kills) > int(b.kills)
		return int(a.deaths) < int(b.deaths)
	)
	for i in rows.size():
		rows[i]["rank"] = i + 1
	return rows


func _clear_active_stage() -> void:
	clear_enemies()
	for r in parkour_runners:
		if is_instance_valid(r):
			r.queue_free()
	parkour_runners.clear()
	for pk in pickups:
		if is_instance_valid(pk.node):
			pk.node.queue_free()
	pickups.clear()
	for fx in vfx_items:
		if is_instance_valid(fx.node):
			fx.node.queue_free()
	vfx_items.clear()

	kz_ladders.clear()
	surf_ramps.clear()
	kz_checkpoints.clear()
	kz_rings.clear()
	kz_jumppads.clear()
	bouncy_awnings.clear()
	moving_platforms.clear()
	falling_tiles.clear()
	_sweeper_pivots.clear()
	spinning_hammers.clear()
	sliding_pushers.clear()
	swinging_pendulums.clear()
	tilting_seesaws.clear()
	bumper_pillars.clear()
	speed_conveyors.clear()
	floor_weapon_pads.clear()
	race_waypoints.clear()
	tr_spawns.clear()
	_start_gate_node = null

	if is_instance_valid(_stage_root):
		_stage_root.free()
		_stage_root = null


func spawn_pvp_transform() -> Array:
	return [_current_pvp_spawn, 0.0, 0.0]


func spawn_kz_transform() -> Array:
	return [kz_start_pad, 0.0, 0.0]


func spawn_stage_transform(stage_idx: int) -> Array:
	return load_mode_and_stage(game_mode, stage_idx)


# ---------------------------------------------------------------- Runtime Kenney 3D GLB Asset Loader + Core Builders

func _target_p(parent: Node3D) -> Node3D:
	if parent == self and is_instance_valid(_stage_root):
		return _stage_root
	return parent


func spawn_kenney_model(parent: Node3D, glb_name: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y: float = 0.0) -> Node3D:
	var tp := _target_p(parent)
	var res_path := "res://assets/models/kenney/" + glb_name
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	if not _glb_cache.has(abs_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(abs_path, state) == OK:
			var proto := doc.generate_scene(state)
			if proto != null:
				_glb_cache[abs_path] = proto
	if _glb_cache.has(abs_path):
		var inst := (_glb_cache[abs_path] as Node).duplicate() as Node3D
		if inst != null:
			inst.position = pos
			inst.scale = sc
			inst.rotation.y = rot_y
			tp.add_child(inst)
			return inst
	return null


func psx_mat(c: Color, emit: float = 0.0, unshaded: bool = false, forced_kind: int = -2) -> Material:
	if unshaded or not psx_enabled:
		var skey := "std|%s|%.2f|%s" % [c.to_html(), emit, unshaded]
		if _mats.has(skey):
			return _mats[skey]
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.55
		if c.a < 0.99:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = emit * 0.65
		if unshaded:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mats[skey] = m
		return m

	var glassy := c.a < 0.99
	var k := forced_kind if forced_kind >= -1 else RetroTex.kind_for(c, emit, glassy)
	var pkey := "psx|%s|%.2f|%d|%s" % [c.to_html(), emit, k, glassy]
	if _psx_mats.has(pkey):
		return _psx_mats[pkey]
	var sm := ShaderMaterial.new()
	sm.shader = PSX_ALPHA if glassy else PSX
	sm.set_shader_parameter("albedo", c)
	sm.set_shader_parameter("emission", emit)
	sm.set_shader_parameter("use_vcol", false)
	sm.set_shader_parameter("kind", k)
	sm.set_shader_parameter("tex", RetroTex.array())
	_psx_mats[pkey] = sm
	return sm


func _box_mesh(s: Vector3) -> BoxMesh:
	var key := "b|%.2f|%.2f|%.2f" % [s.x, s.y, s.z]
	if not _meshes.has(key):
		var bm := BoxMesh.new()
		bm.size = s
		_meshes[key] = bm
	return _meshes[key]


func box(parent: Node3D, x: float, y: float, z: float, sx: float, sy: float, sz: float,
		c: Color, solid: bool = false, emit: float = 0.0, tex_kind: int = -2) -> MeshInstance3D:
	var tp := _target_p(parent)
	var mi := MeshInstance3D.new()
	mi.mesh = _box_mesh(Vector3(sx, sy, sz))
	mi.material_override = psx_mat(c, emit, false, tex_kind)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(x + sx * 0.5, y + sy * 0.5, z + sz * 0.5)
	tp.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(sx, sy, sz)
		cs.shape = sh
		sb.position = mi.position
		sb.add_child(cs)
		tp.add_child(sb)
	return mi


func cyl(parent: Node3D, pos: Vector3, r_top: float, r_bot: float, h: float,
		c: Color, segs: int = 12, emit: float = 0.0, unshaded: bool = false) -> MeshInstance3D:
	var tp := _target_p(parent)
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = psx_mat(c, emit, unshaded)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, h * 0.5, 0)
	tp.add_child(mi)
	return mi


func ball(parent: Node3D, pos: Vector3, rad: float, c: Color, segs: int = 10, emit: float = 0.0) -> MeshInstance3D:
	var tp := _target_p(parent)
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(4, segs / 2)
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.material_override = psx_mat(c, emit)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	tp.add_child(mi)
	return mi


func roof(parent: Node3D, x: float, y: float, z: float, sx: float, sz: float, h: float, c: Color, tex_k: int = 3) -> MeshInstance3D:
	var tp := _target_p(parent)
	var pm := PrismMesh.new()
	pm.size = Vector3(sx, h, sz)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = psx_mat(c, 0.0, false, tex_k)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(x + sx * 0.5, y + h * 0.5, z + sz * 0.5)
	tp.add_child(mi)
	return mi


func halo(p: Vector3, size_m: float, c: Color, strength: float = 0.7) -> MeshInstance3D:
	var tp := _target_p(self)
	var key := "halo|%s|%.2f" % [c.to_html(), strength]
	var m: StandardMaterial3D = _mats.get(key)
	if m == null:
		var g := Gradient.new()
		g.set_color(0, Color(c.r, c.g, c.b, strength))
		g.set_color(1, Color(c.r, c.g, c.b, 0.0))
		g.add_point(0.35, Color(c.r, c.g, c.b, strength * 0.35))
		var tx := GradientTexture2D.new()
		tx.gradient = g
		tx.fill = GradientTexture2D.FILL_RADIAL
		tx.fill_from = Vector2(0.5, 0.5)
		tx.fill_to = Vector2(1.0, 0.5)
		tx.width = 64
		tx.height = 64
		m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_texture = tx
		_mats[key] = m
	var q := QuadMesh.new()
	q.size = Vector2(size_m, size_m)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	tp.add_child(mi)
	return mi


# ---------------------------------------------------------------- Fall Guys & GMod Interactive Parkour Builders & Physics Queries

func add_bouncy_awning(x: float, y: float, z: float, sx: float, sz: float, c1: Color, c2: Color) -> void:
	var stripes := maxi(4, int(sx / 0.45))
	var sw := sx / float(stripes)
	for i in stripes:
		var col := c1 if i % 2 == 0 else c2
		box(self, x + i * sw, y, z, sw - 0.01, 0.20, sz, col, true, 0.0, 0)
	bouncy_awnings.append(AABB(Vector3(x - 0.25, y - 0.15, z - 0.25), Vector3(sx + 0.5, 0.95, sz + 0.5)))


func add_bouncy_drum(center: Vector3, radius: float, shell_col: Color, rim_col: Color = Color("ffd166")) -> void:
	var tp := _target_p(self)
	cyl(tp, center + Vector3(0, -0.55, 0), radius * 1.04, radius * 0.92, 0.55, shell_col, 16, 0.4)
	cyl(tp, center + Vector3(0, -0.05, 0), radius * 1.10, radius * 1.08, 0.12, rim_col, 16, 1.1)
	cyl(tp, center + Vector3(0, 0.06, 0), radius * 0.94, radius * 0.94, 0.08, Color("fff8f0"), 16, 0.8, true)
	cyl(tp, center + Vector3(0, 0.13, 0), radius * 0.42, radius * 0.42, 0.03, shell_col, 12, 1.4, true)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius * 1.05
	sh.height = 0.65
	cs.shape = sh
	sb.position = center + Vector3(0, -0.20, 0)
	sb.add_child(cs)
	tp.add_child(sb)
	bouncy_awnings.append(AABB(center - Vector3(radius * 1.15, 0.20, radius * 1.15), Vector3(radius * 2.3, 1.1, radius * 2.3)))


func add_spinning_hammer(center: Vector3, arm_len: float, spd: float, c_main: Color, c_pad: Color) -> void:
	var tp := _target_p(self)
	cyl(tp, center + Vector3(-arm_len - 0.65, -1.2, 0), 0.22, 0.28, 2.8, c_main, 10, 0.3)
	cyl(tp, center + Vector3(arm_len + 0.65, -1.2, 0), 0.22, 0.28, 2.8, c_main, 10, 0.3)
	var piv := Node3D.new()
	piv.position = center + Vector3(0, 0.95, 0)
	tp.add_child(piv)
	cyl(piv, Vector3(0, -0.35, 0), 0.32, 0.32, 0.70, Color("ffd166"), 12, 0.8)
	box(piv, -arm_len, -0.14, -0.14, arm_len * 2.0, 0.28, 0.28, Color("fff8ee"), false, 0.4, 0)
	for side_s in [-1.0, 1.0]:
		var hx: float = float(side_s) * arm_len
		var head := cyl(piv, Vector3(hx, -0.55, 0), 0.55, 0.55, 1.15, c_pad, 14, 1.2)
		head.rotation.x = PI * 0.5
		head.position = Vector3(hx, 0.0, 0.0)
	spinning_hammers.append({
		"node": piv,
		"center": piv.position,
		"arm_len": arm_len,
		"spd": spd
	})


func add_swinging_pendulum(arch_base: Vector3, width: float, height: float, spd: float, phase: float, ball_col: Color) -> void:
	var tp := _target_p(self)
	var half_w := width * 0.5
	cyl(tp, arch_base + Vector3(-half_w, 0, 0), 0.32, 0.38, height, Color("e63946"), 10, 0.3)
	cyl(tp, arch_base + Vector3(half_w, 0, 0), 0.32, 0.38, height, Color("e63946"), 10, 0.3)
	box(tp, arch_base.x - half_w - 0.6, arch_base.y + height - 0.45, arch_base.z - 0.45, width + 1.2, 0.55, 0.90, Color("ffd166"), false, 0.8, 0)

	var piv := Node3D.new()
	piv.position = arch_base + Vector3(0, height - 0.3, 0)
	tp.add_child(piv)
	var rope_len := height - 1.55
	cyl(piv, Vector3(0, -rope_len, 0), 0.09, 0.09, rope_len, Color("dce2ec"), 8, 0.2)
	ball(piv, Vector3(0, -rope_len, 0), 1.35, ball_col, 12, 1.4)
	cyl(piv, Vector3(0, -rope_len - 0.14, 0), 1.45, 1.45, 0.28, Color("ffd166"), 14, 1.6)
	swinging_pendulums.append({
		"node": piv,
		"pivot_pos": piv.position,
		"rope_len": rope_len,
		"spd": spd,
		"phase": phase,
		"ball_pos": arch_base + Vector3(0, 1.55, 0)
	})


func add_sliding_pusher(base_pos: Vector3, sz: Vector3, slide_dir_x: float, travel: float, spd: float, phase: float, col: Color) -> void:
	var tp := _target_p(self)
	var root := Node3D.new()
	root.position = base_pos
	tp.add_child(root)
	box(root, -sz.x * 0.5, 0.0, -sz.z * 0.5, sz.x, sz.y, sz.z, col, true, 0.8, 0)
	box(root, -sz.x * 0.52, sz.y * 0.35, -sz.z * 0.52, sz.x * 1.04, sz.y * 0.30, sz.z * 1.04, Color("ffd166"), false, 1.3, -1)
	sliding_pushers.append({
		"node": root,
		"base": base_pos,
		"size": sz,
		"dir_x": slide_dir_x,
		"travel": travel,
		"spd": spd,
		"phase": phase,
		"aabb": AABB(base_pos - Vector3(sz.x * 0.55, 0.1, sz.z * 0.55), Vector3(sz.x * 1.1, sz.y + 0.2, sz.z * 1.1))
	})


func add_tilting_seesaw(center: Vector3, width: float, length: float, max_ang: float, spd: float, phase: float, c_top: Color) -> void:
	var tp := _target_p(self)
	cyl(tp, center + Vector3(0, -1.6, -length * 0.45), 0.25, 0.32, 1.6, Color("242b3d"), 10)
	cyl(tp, center + Vector3(0, -1.6, length * 0.45), 0.25, 0.32, 1.6, Color("242b3d"), 10)
	var piv := Node3D.new()
	piv.position = center
	tp.add_child(piv)
	box(piv, -width * 0.5, -0.22, -length * 0.5, width, 0.38, length, c_top, true, 0.6, 0)
	box(piv, -0.25, 0.17, -length * 0.5, 0.50, 0.06, length, Color("fff8ee"), false, 1.2, -1)
	box(piv, -width * 0.5, 0.17, -length * 0.5, 0.28, 0.12, length, Color("ffd166"), false, 1.2, -1)
	box(piv, width * 0.5 - 0.28, 0.17, -length * 0.5, 0.28, 0.12, length, Color("ffd166"), false, 1.2, -1)
	tilting_seesaws.append({
		"node": piv,
		"max_ang": max_ang,
		"spd": spd,
		"phase": phase
	})


func add_bumper_pillar(pos: Vector3, rad: float, h: float, col: Color) -> void:
	var tp := _target_p(self)
	var g := Node3D.new()
	g.position = pos
	tp.add_child(g)
	cyl(g, Vector3.ZERO, rad * 0.85, rad * 0.85, h, Color("242b3d"), 12)
	cyl(g, Vector3(0, h * 0.22, 0), rad * 1.12, rad * 1.12, h * 0.56, col, 14, 1.5, true)
	cyl(g, Vector3(0, h * 0.42, 0), rad * 1.18, rad * 1.18, h * 0.16, Color("ffd166"), 14, 1.8, true)
	bumper_pillars.append({
		"node": g,
		"pos": pos,
		"rad": rad * 1.25,
		"h": h
	})


func add_speed_conveyor(x: float, y: float, z: float, sx: float, sz: float, boost_vec: Vector3, col: Color) -> void:
	box(self, x, y - 0.25, z, sx, 0.25, sz, Color("1e222d"), true, 0.0, 2)
	var stripes := maxi(4, int(sz / 1.4))
	var step_z := sz / float(stripes)
	for i in stripes:
		var c := col if i % 2 == 0 else Color("ffd166")
		box(self, x + 0.2, y + 0.01, z + i * step_z + 0.1, sx - 0.4, 0.04, step_z * 0.65, c, false, 1.5, -1)
	speed_conveyors.append({
		"aabb": AABB(Vector3(x - 0.1, y - 0.2, z - 0.1), Vector3(sx + 0.2, 1.1, sz + 0.2)),
		"vel": boost_vec
	})


func add_checkpoint_arch(pos: Vector3, stage_num: int, title: String, col: Color) -> void:
	box(self, pos.x - 2.6, pos.y, pos.z - 0.35, 5.2, 0.10, 0.70, col, false, 1.8, -1)
	cyl(self, pos + Vector3(-2.6, 0, 0), 0.18, 0.22, 3.4, col, 10, 1.4)
	cyl(self, pos + Vector3(2.6, 0, 0), 0.18, 0.22, 3.4, col, 10, 1.4)
	box(self, pos.x - 2.9, pos.y + 3.2, pos.z - 0.22, 5.8, 0.35, 0.44, Color("ffd166"), false, 1.5, -1)
	spawn_kenney_model(self, "flag.glb", pos + Vector3(-2.6, 3.5, 0), Vector3(1.8, 1.8, 1.8))
	spawn_kenney_model(self, "flag.glb", pos + Vector3(2.6, 3.5, 0), Vector3(1.8, 1.8, 1.8))
	kz_checkpoints.append({"pos": pos + Vector3(0, 0.2, 0), "stage": stage_num, "name": title})
	race_waypoints.append(pos + Vector3(0, 0.2, 0))


func check_bouncy_awning(foot_pos: Vector3) -> bool:
	for ab in bouncy_awnings:
		if (ab as AABB).has_point(foot_pos):
			return true
	return false


func get_moving_platform_delta(foot_pos: Vector3) -> Vector3:
	for mp in moving_platforms:
		var ab: AABB = mp.aabb
		if ab.has_point(foot_pos):
			return mp.delta_pos as Vector3
	return Vector3.ZERO


func get_conveyor_velocity(foot_pos: Vector3) -> Vector3:
	for cv in speed_conveyors:
		if (cv.aabb as AABB).has_point(foot_pos):
			return cv.vel as Vector3
	return Vector3.ZERO


func compute_runner_hazard_vec(foot_pos: Vector3) -> Vector3:
	var body_center := foot_pos + Vector3(0, 0.9, 0)
	for pd in swinging_pendulums:
		var bpos: Vector3 = pd.ball_pos
		if body_center.distance_to(bpos) < 1.85:
			var push_x := 1.0 if body_center.x >= bpos.x else -1.0
			return Vector3(push_x * 11.5, 5.2, 2.0)
	for sp in sliding_pushers:
		var ab: AABB = sp.aabb
		if ab.has_point(body_center):
			return Vector3(float(sp.dir_x) * 10.5, 4.0, 0.0)
	return Vector3.ZERO


func compute_parkour_hazard_impulse(foot_pos: Vector3) -> Dictionary:
	if _hazard_cd > 0.0:
		return {}
	var body_center := foot_pos + Vector3(0, 0.9, 0)

	for bp in bumper_pillars:
		var p: Vector3 = bp.pos
		if absf(foot_pos.y - p.y) < float(bp.h) + 0.6:
			var diff := Vector2(foot_pos.x - p.x, foot_pos.z - p.z)
			if diff.length() < float(bp.rad) + 0.45:
				_hazard_cd = 0.26
				var dir2 := diff.normalized() if diff.length() > 0.01 else Vector2(0, 1)
				return {
					"vel": Vector3(dir2.x * 12.8, 5.8, dir2.y * 12.8),
					"banner": "BUMPER DE PINBALL FALL GUYS!"
				}

	for pd in swinging_pendulums:
		var bpos: Vector3 = pd.ball_pos
		if body_center.distance_to(bpos) < 2.05:
			_hazard_cd = 0.35
			var push_x := 1.0 if body_center.x >= bpos.x else -1.0
			return {
				"vel": Vector3(push_x * 14.5, 6.8, 3.0),
				"banner": "IMPACTO DO PENDULO DEMOLIDOR!"
			}

	for hm in spinning_hammers:
		var n: Node3D = hm.node
		if not is_instance_valid(n):
			continue
		var arm: float = float(hm.arm_len)
		var ang := n.rotation.y
		var right_v := Vector3(cos(ang), 0.0, -sin(ang))
		var tang_v := Vector3(-sin(ang), 0.0, -cos(ang)).normalized()
		for s_i in [-1.0, 1.0]:
			var head_p: Vector3 = (hm.center as Vector3) + right_v * (float(s_i) * arm)
			if body_center.distance_to(head_p) < 1.75:
				_hazard_cd = 0.38
				return {
					"vel": tang_v * float(s_i) * 14.8 + Vector3(0, 8.0, -4.5),
					"banner": "MARTELO BIG YEETUS FALL GUYS!"
				}

	for sp in sliding_pushers:
		var ab: AABB = sp.aabb
		if ab.has_point(body_center):
			_hazard_cd = 0.30
			var dx: float = float(sp.dir_x)
			return {
				"vel": Vector3(dx * 13.5, 4.8, 0.0),
				"banner": "PAREDE EMPURRADORA SLIME CLIMB!"
			}

	for sw in _sweeper_pivots:
		var n: Node3D = sw.node
		if not is_instance_valid(n):
			continue
		var c: Vector3 = sw.center
		var rad: float = float(sw.rad)
		if absf(foot_pos.y - c.y) < 0.78 and Vector2(foot_pos.x - c.x, foot_pos.z - c.z).length() < rad:
			var ang := n.rotation.y
			var bar_dir := Vector2(cos(ang), -sin(ang))
			var rel := Vector2(foot_pos.x - c.x, foot_pos.z - c.z)
			var proj := rel.dot(bar_dir)
			var perp := absf(rel.x * bar_dir.y - rel.y * bar_dir.x)
			if absf(proj) < rad and perp < 0.62:
				_hazard_cd = 0.32
				return {
					"vel": Vector3(-bar_dir.y * 11.2, 6.2, bar_dir.x * 11.2),
					"banner": "BARRA GIRATORIA JUMP SHOWDOWN!"
				}

	return {}


# ---------------------------------------------------------------- Sky & Warm Cozy Flicker-Free Lighting

func _build_sky_and_lights() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_curve = 0.15
	sky_mat.sun_angle_max = 10.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.98
	env.adjustment_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 138.0, 0.0)
	sun.shadow_enabled = false
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(sun)

	apply_atmosphere_preset(0)


func apply_atmosphere_preset(idx: int) -> String:
	atmo_idx = posmod(idx, ATMO_PRESETS.size())
	var p: Dictionary = ATMO_PRESETS[atmo_idx]
	if is_instance_valid(sky_mat):
		sky_mat.sky_top_color = p.sky_top
		sky_mat.sky_horizon_color = p.sky_hor
		sky_mat.ground_horizon_color = p.gnd_hor
		sky_mat.ground_bottom_color = p.gnd_bot
	if is_instance_valid(env):
		env.ambient_light_energy = float(p.amb_e)
		env.adjustment_saturation = float(p.sat)
		env.adjustment_contrast = float(p.con)
	if is_instance_valid(sun):
		sun.light_color = p.sun_c
		sun.light_energy = float(p.sun_e)
	return str(p.name)


func cycle_atmosphere_preset() -> String:
	return apply_atmosphere_preset(atmo_idx + 1)


# ================================================================================================
# MODO 0: 4 COMPLEX COMBAT ARENAS (PHANTOM FORCES / BO2 / CS STYLE)
# ================================================================================================

func _build_combat_1_vila_bo2() -> void:
	_current_pvp_spawn = Vector3(0.0, 0.2, 15.2)
	tr_spawns = [
		Vector3(-12.5, 0.2, -14.5), Vector3(12.5, 0.2, -14.5),
		Vector3(-4.2, 0.2, -14.5), Vector3(4.2, 0.2, -14.5),
		Vector3(-13.5, 0.2, -2.5), Vector3(13.5, 0.2, -2.5),
		Vector3(-10.5, 0.2, 8.5), Vector3(10.5, 0.2, 8.5)
	]
	var grass_col := Color("6ab04c")
	var cobble_floor := Color("d8cfc2")
	var cobble_lane := Color("bfb3a2")
	var timber_wall := Color("7d5a3c")
	var warm_stone := Color("8d8478")
	var crate_wood := Color("c98445")
	var crate_mil := Color("436b50")

	box(self, -28.0, -0.55, -28.0, 56.0, 0.50, 56.0, grass_col, true, 0.0, 5)
	box(self, -18.0, -0.50, -18.0, 36.0, 0.50, 36.0, cobble_floor, true, 0.0, 8)
	box(self, -2.6, 0.0, -17.9, 5.2, 0.03, 35.8, cobble_lane, false, 0.0, 8)
	box(self, -17.9, 0.0, -2.6, 15.3, 0.03, 5.2, cobble_lane, false, 0.0, 8)
	box(self, 2.6, 0.0, -2.6, 15.3, 0.03, 5.2, cobble_lane, false, 0.0, 8)

	for side_z in [-18.4, 18.0]:
		box(self, -18.4, 0.0, side_z, 36.8, 1.35, 0.45, warm_stone, true, 0.0, 4)
		box(self, -18.5, 1.35, side_z - 0.05, 37.0, 0.16, 0.55, timber_wall, false, 0.0, 1)
	for side_x in [-18.4, 18.0]:
		box(self, side_x, 0.0, -18.0, 0.45, 1.35, 36.0, warm_stone, true, 0.0, 4)
		box(self, side_x - 0.05, 1.35, -18.1, 0.55, 0.16, 36.2, timber_wall, false, 0.0, 1)

	CozyProps.cozy_chalet(self, self, Vector3(-13.5, 0.0, 13.5), 6.2, 4.4, 6.2, Color("f7ecd8"), Color("b84a39"))
	CozyProps.cozy_chalet(self, self, Vector3(13.5, 0.0, 13.5), 6.2, 4.4, 6.2, Color("f5e4c8"), Color("3d6b58"))
	CozyProps.cozy_chalet(self, self, Vector3(-13.5, 0.0, -13.5), 6.2, 4.4, 6.2, Color("f5e4c8"), Color("4a6984"))
	CozyProps.cozy_chalet(self, self, Vector3(13.5, 0.0, -13.5), 6.2, 4.4, 6.2, Color("f7ecd8"), Color("b84a39"))

	CozyProps.nuketown_bus(self, self, Vector3(-3.8, 0.0, 0.0), PI * 0.5, Color("e63946"))
	CozyProps.nuketown_bus(self, self, Vector3(3.8, 0.0, 0.0), -PI * 0.5, Color("00a8e8"))
	RetroModels.torii_gate(self, self, Vector3(0.0, 0.0, 0.0), 4.6, 4.3, 0.0)

	var bunker_coords := [
		{"p": Vector2(-7.2, -7.2), "c": Color("3d6b58"), "team": Color("00f5d4")},
		{"p": Vector2(7.2, -7.2), "c": Color("b84a39"), "team": Color("ff2a6d")},
		{"p": Vector2(-7.2, 7.2), "c": Color("3d6b58"), "team": Color("00f5d4")},
		{"p": Vector2(7.2, 7.2), "c": Color("b84a39"), "team": Color("ffd166")},
	]
	for b_info in bunker_coords:
		var bc: Vector2 = b_info.p
		var roof_c: Color = b_info.c
		var stripe_c: Color = b_info.team
		box(self, bc.x - 2.9, 0.0, bc.y - 2.9, 5.8, 3.4, 5.8, Color("f4ead8"), true, 0.0, 2)
		box(self, bc.x - 3.05, 0.0, bc.y - 3.05, 6.1, 0.55, 6.1, warm_stone, false, 0.0, 4)
		box(self, bc.x - 3.02, 2.55, bc.y - 3.02, 6.04, 0.22, 6.04, stripe_c, false, 1.1, -1)
		box(self, bc.x - 3.25, 3.4, bc.y - 3.25, 6.5, 0.28, 6.5, roof_c, true, 0.0, 3)

	CozyProps.market_stall(self, self, Vector3(-12.2, 0.0, 7.6), PI * 0.5, Color("e63946"), Color("fff8ee"))
	bouncy_awnings.append(AABB(Vector3(-13.5, 2.1, 6.0), Vector3(2.6, 0.8, 3.2)))
	CozyProps.market_stall(self, self, Vector3(12.2, 0.0, -7.6), -PI * 0.5, Color("2a9d8f"), Color("fff8ee"))
	bouncy_awnings.append(AABB(Vector3(10.9, 2.1, -9.2), Vector3(2.6, 0.8, 3.2)))

	CozyProps.wooden_watchtower(self, self, Vector3(-14.8, 0.0, 0.0), 3.5)
	CozyProps.wooden_watchtower(self, self, Vector3(14.8, 0.0, 0.0), 3.5)
	_build_crate_stair(Vector3(-11.2, 0.0, -7.6), -1.0, crate_wood, crate_mil)
	_build_crate_stair(Vector3(11.2, 0.0, 7.6), 1.0, crate_wood, crate_mil)

	_add_weapon_pad(Vector3(-4.5, 0.04, 15.2), "AK-47 + MUNICAO", Color("ffd166"))
	_add_weapon_pad(Vector3(4.5, 0.04, 15.2), "AWP + COLETE", Color("00f5d4"))
	_add_weapon_pad(Vector3(0.0, 0.04, 0.0), "KIT MEDICO + MUNICAO", Color("2ec4b6"))

	for i in 10:
		var ang := i * TAU / 10.0 + 0.25
		var tp := Vector3(cos(ang) * 22.8, 0.0, sin(ang) * 22.8)
		RetroModels.sakura_tree(self, self, tp, 1.55, 500 + i * 17, i % 3 != 0)


func _build_combat_2_shipment_cqc() -> void:
	# ARENA SHIPMENT & KILLHOUSE: Ultra-fast Close Quarters Combat (Containers, Upper Catwalk, Breach Rooms)
	_current_pvp_spawn = Vector3(0.0, 0.2, 16.5)
	tr_spawns = [
		Vector3(-14.0, 0.2, -14.0), Vector3(14.0, 0.2, -14.0),
		Vector3(0.0, 0.2, -15.5), Vector3(-14.5, 0.2, 0.0),
		Vector3(14.5, 0.2, 0.0), Vector3(-9.0, 0.2, -6.5),
		Vector3(9.0, 0.2, -6.5), Vector3(0.0, 3.6, 0.0)
	]
	var asphalt := Color("2b303c")
	var concrete := Color("78808e")
	var c_red := Color("d62828")
	var c_blue := Color("0077b6")
	var c_gold := Color("f77f00")
	var c_teal := Color("2a9d8f")
	var wood_ply := Color("c89b6e")

	box(self, -24.0, -0.5, -24.0, 48.0, 0.5, 48.0, asphalt, true, 0.0, 2)
	# Painted tactical court lines
	box(self, -19.0, 0.01, -0.25, 38.0, 0.03, 0.5, Color("ffd166"), false, 0.9, -1)
	box(self, -0.25, 0.01, -19.0, 0.5, 0.03, 38.0, Color("00f5d4"), false, 0.9, -1)

	# High Container Yard Perimeter Walls
	for sz in [-20.0, 19.4]:
		box(self, -20.0, 0.0, sz, 40.0, 4.2, 0.6, concrete, true, 0.0, 4)
		box(self, -20.0, 4.2, sz, 40.0, 0.25, 0.6, Color("ffd166"), false, 1.2, -1)
	for sx in [-20.0, 19.4]:
		box(self, sx, 0.0, -20.0, 0.6, 4.2, 40.0, concrete, true, 0.0, 4)
		box(self, sx, 4.2, -20.0, 0.6, 0.25, 40.0, Color("00f5d4"), false, 1.2, -1)

	# 4 Open Walk-Through Shipping Containers around the center X-Crossfire!
	_build_shipping_container(Vector3(-8.5, 0.0, -8.5), 3.0, 3.0, 7.6, c_red, true)
	_build_shipping_container(Vector3(8.5, 0.0, -8.5), 3.0, 3.0, 7.6, c_blue, true)
	_build_shipping_container(Vector3(-8.5, 0.0, 8.5), 3.0, 3.0, 7.6, c_teal, true)
	_build_shipping_container(Vector3(8.5, 0.0, 8.5), 3.0, 3.0, 7.6, c_gold, true)

	# 4 Outer Side Containers + Second-Floor Stacked Containers
	_build_shipping_container(Vector3(-15.5, 0.0, 0.0), 3.0, 3.2, 8.5, c_blue, false)
	_build_shipping_container(Vector3(15.5, 0.0, 0.0), 3.0, 3.2, 8.5, c_red, false)
	_build_shipping_container(Vector3(0.0, 0.0, -15.5), 8.5, 3.2, 3.0, c_gold, false)

	# Central Elevated Steel Catwalk Bridge (y = 3.2m) connecting the 4 inner container roofs!
	box(self, -10.0, 3.05, -2.0, 20.0, 0.25, 4.0, Color("383f52"), true, 0.0, 2)
	box(self, -2.0, 3.05, -10.0, 4.0, 0.25, 20.0, Color("383f52"), true, 0.0, 2)
	box(self, -10.0, 3.32, -2.0, 20.0, 0.10, 0.18, Color("ffd166"), false, 1.4, -1)
	box(self, -10.0, 3.32, 1.82, 20.0, 0.10, 0.18, Color("ffd166"), false, 1.4, -1)

	# Wooden Killhouse Assault Ramps up to the Catwalk & Container Roofs
	for rx in [-8.5, 8.5]:
		for step in 8:
			box(self, rx - 1.2, step * 0.40, 12.8 + step * 0.55, 2.4, 0.42, 0.60, wood_ply, true, 0.0, 1)
			box(self, rx - 1.2, step * 0.40, -12.8 - step * 0.55, 2.4, 0.42, 0.60, wood_ply, true, 0.0, 1)

	# Plywood Killhouse Cover Walls in the Center Plaza
	box(self, -4.2, 0.0, -1.8, 0.35, 2.2, 3.6, wood_ply, true, 0.0, 1)
	box(self, 3.85, 0.0, -1.8, 0.35, 2.2, 3.6, wood_ply, true, 0.0, 1)

	# 2 Corner Jump-Pads for Instant Roof Flanks!
	for jp in [Vector3(-15.5, 0.1, 15.5), Vector3(15.5, 0.1, -15.5)]:
		cyl(self, jp, 1.2, 1.3, 0.18, Color("ff2a85"), 12, 2.0, true)
		kz_jumppads.append(jp)

	_add_weapon_pad(Vector3(0.0, 0.04, 0.0), "KIT CQC + MUNICAO", Color("ff2a85"))
	_add_weapon_pad(Vector3(0.0, 3.32, 0.0), "DOMINIO DA PASSARELA", Color("ffd166"))
	_add_weapon_pad(Vector3(-12.5, 0.04, 12.5), "RECARGA RAPIDA", Color("00f5d4"))
	_add_weapon_pad(Vector3(12.5, 0.04, -12.5), "RECARGA RAPIDA", Color("00f5d4"))


func _build_shipping_container(center: Vector3, sx: float, sy: float, sz: float, col: Color, open_ends: bool) -> void:
	if not open_ends:
		box(self, center.x - sx * 0.5, center.y, center.z - sz * 0.5, sx, sy, sz, col, true, 0.0, 2)
		box(self, center.x - sx * 0.52, center.y + sy - 0.18, center.z - sz * 0.52, sx * 1.04, 0.18, sz * 1.04, col.lightened(0.18), false, 0.4, -1)
		return
	# Hollow walk-through container: floor, roof, and left/right walls!
	box(self, center.x - sx * 0.5, center.y, center.z - sz * 0.5, sx, 0.18, sz, Color("222630"), true, 0.0, 2)
	box(self, center.x - sx * 0.5, center.y + sy - 0.22, center.z - sz * 0.5, sx, 0.22, sz, col, true, 0.0, 2)
	box(self, center.x - sx * 0.5, center.y, center.z - sz * 0.5, 0.24, sy, sz, col, true, 0.0, 2)
	box(self, center.x + sx * 0.5 - 0.24, center.y, center.z - sz * 0.5, 0.24, sy, sz, col, true, 0.0, 2)


func _build_combat_3_sniper_canyon() -> void:
	# CANION CROSSFIRE / MIRAGE: Long-Range Sniper & Rifle Warfare (56m x 72m)
	_current_pvp_spawn = Vector3(0.0, 4.2, 26.5)
	tr_spawns = [
		Vector3(0.0, 4.2, -26.5), Vector3(-9.5, 4.2, -25.5),
		Vector3(9.5, 4.2, -25.5), Vector3(-18.5, 2.8, -14.0),
		Vector3(18.5, 2.8, -14.0), Vector3(-6.0, 0.2, -10.0),
		Vector3(6.0, 0.2, -10.0), Vector3(0.0, 4.0, -6.0)
	]
	var sand := Color("e6ccb2")
	var sandstone := Color("c89f78")
	var cliff := Color("8d6346")
	var wood := Color("7c5234")
	var trim_ct := Color("00bbf9")
	var trim_tr := Color("ff2a55")

	# Canyon Floor (y = 0)
	box(self, -28.0, -0.6, -36.0, 56.0, 0.6, 72.0, sand, true, 0.0, 8)
	# Canyon Perimeter Cliffs
	for sx in [-26.0, 24.5]:
		box(self, sx, 0.0, -36.0, 1.5, 6.5, 72.0, cliff, true, 0.0, 4)

	# South CT Sniper Bastion (z = +21..+33, y = 4.0m) & North TR Sniper Bastion (z = -33..-21, y = 4.0m)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var bz: float = side * 27.0
		var t_col: Color = trim_ct if side > 0.0 else trim_tr
		box(self, -18.0, 0.0, bz - 6.0, 36.0, 4.0, 12.0, sandstone, true, 0.0, 4)
		box(self, -18.2, 3.8, bz - 6.2, 36.4, 0.25, 12.4, t_col, false, 1.2, -1)
		# Crenellated Sniper Battlements along the front edge
		var front_z: float = bz - side * 5.8
		for bx in [-16.0, -10.0, -4.5, 2.5, 8.0, 14.0]:
			box(self, bx, 4.0, front_z, 2.4, 1.15, 0.45, cliff, true, 0.0, 4)
		# Watchtower Overlooks on the Bastion Wings
		CozyProps.wooden_watchtower(self, self, Vector3(-13.5, 4.0, bz), 3.4)
		CozyProps.wooden_watchtower(self, self, Vector3(13.5, 4.0, bz), 3.4)
		# Stairs from Lower Canyon Floor (y=0) up to Bastion Deck (y=4.0)
		for st in 10:
			var sy: float = float(st) * 0.40
			var sz_pos: float = (bz - side * 6.5) - side * float(9 - st) * 0.65
			box(self, -12.0, 0.0, sz_pos, 3.6, sy + 0.4, 0.70, wood, true, 0.0, 1)
			box(self, 8.4, 0.0, sz_pos, 3.6, sy + 0.4, 0.70, wood, true, 0.0, 1)

	# High Central Suspension Bridge (42m Long Sniper Corridor at y = 3.8m)
	box(self, -2.8, 3.65, -21.0, 5.6, 0.35, 42.0, wood, true, 0.0, 1)
	box(self, -3.0, 4.0, -21.0, 0.25, 0.9, 42.0, Color("ffd166"), true, 0.8, -1)
	box(self, 2.75, 4.0, -21.0, 0.25, 0.9, 42.0, Color("ffd166"), true, 0.8, -1)
	RetroModels.torii_gate(self, self, Vector3(0.0, 4.0, -10.0), 5.6, 4.5, 0.0)
	RetroModels.torii_gate(self, self, Vector3(0.0, 4.0, 10.0), 5.6, 4.5, 0.0)
	# Bridge Cover Crates
	box(self, -2.2, 4.0, -4.5, 1.5, 1.1, 1.5, sandstone, true, 0.0, 1)
	box(self, 0.7, 4.0, 4.5, 1.5, 1.1, 1.5, sandstone, true, 0.0, 1)

	# East & West Elevated Cliff Flank Walkways (x = +-19.5, y = 2.6m)
	for side_x in [-21.5, 17.5]:
		box(self, side_x, 0.0, -21.0, 4.0, 2.6, 42.0, sandstone.darkened(0.08), true, 0.0, 4)
		for cz in [-12.0, 0.0, 12.0]:
			box(self, side_x + 0.6, 2.6, cz, 2.8, 1.2, 0.5, cliff, true, 0.0, 4)

	# Lower Canyon Trench Cover Pillars & Jump-Pads
	for cz in [-14.0, -5.0, 5.0, 14.0]:
		box(self, -8.5, 0.0, cz, 2.2, 2.4, 1.2, cliff, true, 0.0, 4)
		box(self, 6.3, 0.0, cz, 2.2, 2.4, 1.2, cliff, true, 0.0, 4)
	for jp in [Vector3(-15.0, 0.1, 0.0), Vector3(15.0, 0.1, 0.0)]:
		cyl(self, jp, 1.2, 1.3, 0.18, Color("00f5d4"), 12, 2.0, true)
		kz_jumppads.append(jp)

	_add_weapon_pad(Vector3(0.0, 4.04, 0.0), "PONTE SNIPER + AWP", Color("ffd166"))
	_add_weapon_pad(Vector3(0.0, 0.04, 0.0), "OASIS DO CANION + VIDA", Color("2ec4b6"))
	_add_weapon_pad(Vector3(0.0, 4.04, 24.0), "ARSENAL CT", Color("00bbf9"))


func _build_combat_4_cyber_vertigo() -> void:
	# TORRE CYBER-VERTIGO: 3-Floor Vertical Skyscraper Rooftop Arena with 4 Tactical Jump-Pads!
	_current_pvp_spawn = Vector3(0.0, 0.2, 18.0)
	tr_spawns = [
		Vector3(0.0, 0.2, -18.0), Vector3(-15.0, 3.8, -15.0),
		Vector3(15.0, 3.8, -15.0), Vector3(-15.0, 3.8, 15.0),
		Vector3(15.0, 3.8, 15.0), Vector3(0.0, 7.4, 0.0),
		Vector3(-9.0, 0.2, 0.0), Vector3(9.0, 0.2, 0.0)
	]
	var deck_dark := Color("1f2433")
	var deck_mid := Color("2e3548")
	var cyan := Color("00f5d4")
	var pink := Color("ff2a85")
	var gold := Color("ffd166")

	# Floor 1: Skyscraper Rooftop Plaza (46m x 46m, y = 0.0m)
	box(self, -23.0, -1.0, -23.0, 46.0, 1.0, 46.0, deck_dark, true, 0.0, 2)
	for s in [-23.0, 22.4]:
		box(self, -23.0, 0.0, s, 46.0, 1.4, 0.6, cyan, true, 1.2, -1)
		box(self, s, 0.0, -23.0, 0.6, 1.4, 46.0, pink, true, 1.2, -1)

	# 4 Corner Jump-Pads on Floor 1 launching up to Floor 2 & Floor 3!
	for jp in [
		Vector3(-18.5, 0.1, 18.5), Vector3(18.5, 0.1, 18.5),
		Vector3(-18.5, 0.1, -18.5), Vector3(18.5, 0.1, -18.5)
	]:
		cyl(self, jp, 1.35, 1.45, 0.20, cyan, 14, 2.2, true)
		kz_jumppads.append(jp)

	# Floor 1 Neon Server Monoliths for Cover
	for mx in [-8.5, 8.5]:
		for mz in [-8.5, 8.5]:
			box(self, mx - 1.2, 0.0, mz - 1.2, 2.4, 3.6, 2.4, deck_mid, true, 0.0, 2)
			box(self, mx - 1.25, 1.5, mz - 1.25, 2.5, 0.25, 2.5, pink, false, 1.6, -1)

	# Floor 2: Elevated Mezzanine Ring (y = 3.6m)
	box(self, -18.0, 3.4, -18.0, 36.0, 0.30, 5.5, deck_mid, true, 0.0, 2)
	box(self, -18.0, 3.4, 12.5, 36.0, 0.30, 5.5, deck_mid, true, 0.0, 2)
	box(self, -18.0, 3.4, -12.5, 5.5, 0.30, 25.0, deck_mid, true, 0.0, 2)
	box(self, 12.5, 3.4, -12.5, 5.5, 0.30, 25.0, deck_mid, true, 0.0, 2)
	# Ramps from Floor 1 to Floor 2
	for st in 9:
		box(self, -2.2, st * 0.40, 12.5 + (8 - st) * 0.65, 4.4, 0.42, 0.70, cyan.darkened(0.25), true, 0.4, 0)
		box(self, -2.2, st * 0.40, -12.5 - (8 - st) * 0.65, 4.4, 0.42, 0.70, pink.darkened(0.25), true, 0.4, 0)

	# Floor 3: Central High Penthouse Helipad Deck (y = 7.2m)
	box(self, -6.5, 6.9, -6.5, 13.0, 0.35, 13.0, deck_dark, true, 0.0, 2)
	box(self, -6.6, 7.25, -6.6, 13.2, 0.18, 13.2, gold, false, 1.6, -1)
	RetroModels.torii_gate(self, self, Vector3(0.0, 7.25, 0.0), 5.2, 4.2, 0.0)
	# Ramps from Floor 2 (x = +-12.5, y = 3.6m) up to Floor 3 Penthouse (x = +-6.5, y = 7.2m)
	for st in 9:
		var rx := 6.5 + (8 - st) * 0.68
		var ry := 3.6 + st * 0.40
		box(self, -rx - 0.6, ry, -1.8, 0.8, 0.35, 3.6, gold.darkened(0.15), true, 0.6, 0)
		box(self, rx - 0.2, ry, -1.8, 0.8, 0.35, 3.6, gold.darkened(0.15), true, 0.6, 0)

	_add_weapon_pad(Vector3(0.0, 7.28, 0.0), "DOMINIO DA COBERTURA VIP", gold)
	_add_weapon_pad(Vector3(0.0, 0.04, 0.0), "PATIO DE SERVIDORES", cyan)
	_add_weapon_pad(Vector3(-15.0, 3.74, 0.0), "MEZANINO OESTE", pink)
	_add_weapon_pad(Vector3(15.0, 3.74, 0.0), "MEZANINO LESTE", pink)


func _build_crate_stair(base: Vector3, dir_z: float, c_wood: Color, c_mil: Color) -> void:
	box(self, base.x - 0.65, 0.0, base.z - 0.65, 1.3, 1.05, 1.3, c_wood, true, 0.0, 1)
	box(self, base.x - 0.65, 0.0, base.z - 0.65 - dir_z * 1.35, 1.3, 2.05, 1.3, c_mil, true, 0.0, 1)
	box(self, base.x - 0.65, 0.0, base.z - 0.65 - dir_z * 2.70, 1.3, 2.95, 1.3, c_wood.darkened(0.08), true, 0.0, 1)


func _add_weapon_pad(pos: Vector3, label: String, col: Color) -> void:
	box(self, pos.x - 1.1, pos.y, pos.z - 0.65, 2.2, 0.06, 1.3, Color("222836"), false, 0.0, 0)
	box(self, pos.x - 0.95, pos.y + 0.06, pos.z - 0.5, 1.9, 0.05, 1.0, col, false, 1.4, -1)
	box(self, pos.x - 0.55, pos.y + 0.12, pos.z - 0.08, 1.1, 0.08, 0.16, Color("1a1c24"), false, 0.0, 0)
	box(self, pos.x - 0.15, pos.y + 0.12, pos.z + 0.08, 0.22, 0.07, 0.26, Color("c85a28"), false, 0.0, 0)
	floor_weapon_pads.append({"pos": pos, "label": label, "cd": 0.0})


# ================================================================================================
# MODO 1: 4 LONG & HARD FALL-GUYS PARKOUR MARATHONS (335m–380m • 8 SECTORS + STARTING GATE!)
# ================================================================================================

func _build_parkour_marathon(course_idx: int) -> void:
	var pink := Color("ff2a85")
	var cyan := Color("00f5d4")
	var gold := Color("ffd166")
	var purple := Color("8338ec")
	var coral := Color("ff4757")
	var lime := Color("8ac926")
	var cobble := Color("d8cfc2")

	kz_start_pad = Vector3(0.0, 0.2, 16.5)
	race_waypoints.clear()
	race_waypoints.append(Vector3(0.0, 0.2, 12.0))

	# Abyss Floor Visual (Slime / Lava / Canyon Valley far below at y = -5.5m)
	var abyss_col := Color("6ab04c") if course_idx == 0 else (Color("ff2a55") if course_idx == 1 else (Color("1e3799") if course_idx == 2 else Color("7209b7")))
	box(self, -34.0, -6.2, -400.0, 68.0, 0.5, 430.0, abyss_col, false, 0.6 if course_idx != 0 else 0.0, 5)

	# Decorative Clouds & Sakura Trees along the 360m Marathon Corridor
	for i in 22:
		var tz := 12.0 - i * 16.5
		spawn_kenney_model(self, "cloud.glb", Vector3((-1.0 if i % 2 == 0 else 1.0) * 18.0, 14.0 + (i % 3) * 2.5, tz), Vector3(3.8, 2.8, 3.8))

	# Starting Paddock (8-Lane Fall Guys Starting Grid at z = +11..+21)
	box(self, -7.5, -1.0, 11.0, 15.0, 1.0, 10.0, cobble, true, 0.0, 8)
	for lane_i in 8:
		var lx := -5.25 + lane_i * 1.5
		var lc := pink if lane_i % 2 == 0 else cyan
		box(self, lx - 0.55, 0.02, 14.2, 1.1, 0.06, 3.6, lc, false, 1.3, -1)
	RetroModels.torii_gate(self, self, Vector3(0.0, 0.0, 12.5), 9.5, 5.2, 0.0)

	# Physical 5-4-3-2-1 Starting Gate Barrier (Drops when countdown reaches 0!)
	_start_gate_node = Node3D.new()
	_start_gate_node.position = Vector3.ZERO
	_stage_root.add_child(_start_gate_node)
	box(_start_gate_node, -7.2, 0.0, 13.4, 14.4, 3.2, 0.35, Color(1.0, 0.18, 0.52, 0.72), true, 2.0, -1)
	box(_start_gate_node, -7.4, 3.1, 13.3, 14.8, 0.30, 0.55, gold, false, 2.2, -1)

	# 8-Sector Course Recipes (Each sector is ~42m long -> ~350m-380m total!)
	var recipes := [
		# Course 0: EL PANADERO EXTREME (335m)
		["DRUMS", "PENDULUMS", "SEESAWS", "CONVEYOR_PINBALL", "MOVING_GAPS", "HAMMERS", "DRUMS_HIGH", "SWEEPERS"],
		# Course 1: SLIME CLIMB HARDCORE (350m)
		["MOVING_GAPS", "PUSHERS", "SWEEPERS", "TIPTOE", "CONVEYOR_PUSHERS", "DOORDASH_HAMMERS", "FALLING_BRIDGE", "JUMPPAD_TOWER"],
		# Course 2: CS:GO SURF & KZ ODYSSEY (365m)
		["BHOP_ZIGZAG", "SURF_DUAL", "PENDULUMS", "SURF_TRIPLE", "KZ_LADDERS", "SEESAWS", "MOVING_GAPS", "HAMMERS"],
		# Course 3: FALL GUYS OMEGA GAUNTLET (380m)
		["DRUMS", "PUSHERS", "SURF_DUAL", "SWEEPERS", "SEESAWS", "TIPTOE", "CONVEYOR_PINBALL", "OMEGA_CLIMB"]
	]
	var seq: Array = recipes[clampi(course_idx, 0, recipes.size() - 1)]
	var cur_z := 11.0
	var cur_y := 0.0

	for s_idx in 8:
		var kind := str(seq[s_idx])
		var res := _build_parkour_sector(s_idx + 1, kind, cur_z, cur_y, pink, cyan, gold, purple, coral, lime)
		cur_z = float(res.z)
		cur_y = float(res.y)

	# Final Golden Crown Sanctuary at the end of Sector 8!
	kz_finish_pad = Vector3(0.0, cur_y + 0.2, cur_z - 5.5)
	race_waypoints.append(kz_finish_pad)
	_add_finish_sanctuary(Vector3(0.0, cur_y, cur_z - 5.5), "COROA DO CAMPEAO")


func _build_parkour_sector(s_num: int, kind: String, z_in: float, y_in: float,
		pink: Color, cyan: Color, gold: Color, purple: Color, coral: Color, lime: Color) -> Dictionary:
	var z := z_in
	var y := y_in
	var title := "SETOR %d/8: %s" % [s_num, kind]

	if kind == "DRUMS" or kind == "DRUMS_HIGH":
		title = "SETOR %d/8: TAMBORES LILY LEAPERS!" % s_num
		for i in 7:
			var dx := sin(float(i) * 1.35) * 2.3
			z -= 5.4
			y += 0.55 if kind == "DRUMS_HIGH" else 0.25
			add_bouncy_drum(Vector3(dx, y, z), 1.45, pink if i % 2 == 0 else cyan, gold)
			race_waypoints.append(Vector3(dx, y + 0.3, z))
			if i % 2 == 1:
				_add_kz_ring(Vector3(dx, y + 2.5, z - 2.2), s_num * 10 + i)
		z -= 4.8

	elif kind == "PENDULUMS":
		title = "SETOR %d/8: PONTE ESTREITA DOS 4 PENDULOS!" % s_num
		var len_p := 40.0
		# Narrow 2.8m bridge so pendulums sweep the entire width!
		box(self, -1.4, y - 0.35, z - len_p, 2.8, 0.35, len_p, Color("8a5a36"), true, 0.0, 1)
		for i in 4:
			var pz := z - 7.0 - i * 8.8
			add_swinging_pendulum(Vector3(0.0, y, pz), 6.2, 6.4, 2.65 + i * 0.22, i * 1.45, pink if i % 2 == 0 else cyan)
			race_waypoints.append(Vector3(0.0, y + 0.2, pz))
		z -= len_p

	elif kind == "SEESAWS":
		title = "SETOR %d/8: 5 GANGORRAS SEE-SAW INCLINADAS!" % s_num
		for i in 5:
			z -= 4.2
			var ss_col := pink if i % 2 == 0 else (cyan if i % 3 == 0 else gold)
			add_tilting_seesaw(Vector3(0.0, y, z - 3.0), 6.4, 5.6, 0.42, 1.85 + i * 0.18, i * 1.5, ss_col)
			race_waypoints.append(Vector3(0.0, y + 0.3, z - 3.0))
			z -= 4.0

	elif kind == "CONVEYOR_PINBALL":
		title = "SETOR %d/8: ESTEIRA CONTRA-FLUXO & PINBALL!" % s_num
		var clen := 38.0
		# Conveyor pulls you BACKWARD (-7.5 u/s) while you dodge 8 Pinball Bumpers and 2 Pendulums!
		add_speed_conveyor(-2.6, y, z - clen, 5.2, clen, Vector3(0.0, 0.0, 7.2), purple)
		for i in 8:
			var bx := (-1.3 if i % 2 == 0 else 1.3) if i % 3 != 0 else 0.0
			var bz := z - 4.0 - i * 4.2
			add_bumper_pillar(Vector3(bx, y, bz), 0.68, 1.7, pink if i % 2 == 0 else cyan)
			if i % 2 == 0:
				race_waypoints.append(Vector3(-bx * 0.5, y + 0.2, bz))
		add_swinging_pendulum(Vector3(0.0, y, z - clen * 0.5), 6.4, 6.4, 2.8, 0.7, coral)
		z -= clen

	elif kind == "MOVING_GAPS":
		title = "SETOR %d/8: 6 PLATAFORMAS MOVEIS NO ABISMO!" % s_num
		for i in 6:
			z -= 6.2
			y += 0.20
			var dir_s := 1.0 if i % 2 == 0 else -1.0
			_add_moving_platform(
				Vector3(0.0, y, z),
				Vector3(2.8, 0.38, 2.8),
				Vector3(3.4 * dir_s, 0.0, 0.0),
				2.15 + i * 0.18,
				i * 1.1,
				cyan if i % 2 == 0 else pink
			)
			race_waypoints.append(Vector3(0.0, y + 0.3, z))
		z -= 4.5

	elif kind == "HAMMERS" or kind == "DOORDASH_HAMMERS":
		title = "SETOR %d/8: CORREDOR DOS 4 BIG YEETUS!" % s_num
		var hlen := 38.0
		box(self, -2.2, y - 0.35, z - hlen, 4.4, 0.35, hlen, Color("232738"), true, 0.0, 2)
		if kind == "DOORDASH_HAMMERS":
			for d_z in [z - 8.0, z - 22.0]:
				box(self, -2.2, y, d_z, 1.4, 2.5, 0.45, coral, true, 0.8, 0)
				box(self, 0.8, y, d_z, 1.4, 2.5, 0.45, coral, true, 0.8, 0)
		for i in 4:
			var hz := z - 5.5 - i * 8.2
			add_spinning_hammer(Vector3(0.0, y, hz), 2.5, (3.6 if i % 2 == 0 else -3.6), gold, pink if i % 2 == 0 else cyan)
			race_waypoints.append(Vector3(0.0, y + 0.2, hz))
		z -= hlen

	elif kind == "PUSHERS" or kind == "CONVEYOR_PUSHERS":
		title = "SETOR %d/8: SLIME CLIMB — 7 PAREDES EMPURRADORAS!" % s_num
		var plen := 40.0
		box(self, -1.65, y - 0.35, z - plen, 3.3, 0.35, plen, Color("262b3d"), true, 0.0, 2)
		if kind == "CONVEYOR_PUSHERS":
			add_speed_conveyor(-1.6, y + 0.02, z - plen, 3.2, plen, Vector3(0.0, 0.0, 6.2), coral)
		for i in 7:
			var side := -1.0 if i % 2 == 0 else 1.0
			var pz := z - 4.2 - i * 5.0
			add_sliding_pusher(
				Vector3(side * 2.5, y + 0.05, pz),
				Vector3(2.4, 2.1, 3.2),
				-side,
				2.7,
				3.2 + (i % 3) * 0.45,
				i * 1.25,
				pink if i % 2 == 0 else cyan
			)
			race_waypoints.append(Vector3(0.0, y + 0.2, pz))
		z -= plen

	elif kind == "SWEEPERS":
		title = "SETOR %d/8: 4 ARENAS JUMP SHOWDOWN!" % s_num
		for i in 4:
			z -= 8.8
			_add_sweeper_island(Vector3(0.0, y, z), 3.4, (2.35 if i % 2 == 0 else -2.55) * (1.0 + i * 0.08))
			race_waypoints.append(Vector3(0.0, y + 0.2, z))
			if i < 3:
				box(self, -0.75, y - 0.25, z - 5.2, 1.5, 0.25, 2.0, gold, true, 0.8, 0)
		z -= 5.2

	elif kind == "TIPTOE" or kind == "FALLING_BRIDGE":
		title = "SETOR %d/8: GRADE TIP-TOE (30 PISOS NA LAVA)!" % s_num
		for row in 10:
			var rz := z - 3.2 - row * 3.3
			var safe_col := (row + 1) % 3
			for col_i in 3:
				var cx := (col_i - 1) * 2.35
				if col_i == safe_col and kind == "TIPTOE":
					box(self, cx - 0.95, y - 0.28, rz - 0.95, 1.9, 0.28, 1.9, Color("2e3548"), true, 0.3, 2)
					if row % 2 == 0:
						race_waypoints.append(Vector3(cx, y + 0.2, rz))
				else:
					_add_falling_tile(Vector3(cx, y - 0.14, rz), Vector3(1.9, 0.28, 1.9))
					if kind == "FALLING_BRIDGE" and col_i == 1 and row % 2 == 0:
						race_waypoints.append(Vector3(0.0, y + 0.2, rz))
		z -= 36.0

	elif kind == "BHOP_ZIGZAG":
		title = "SETOR %d/8: 10 BLOCOS DE BUNNYHOP PRO!" % s_num
		for i in 10:
			var bx := (-1.65 if i % 2 == 0 else 1.65)
			z -= 4.1
			y += 0.15
			box(self, bx - 1.0, y - 0.35, z - 1.0, 2.0, 0.35, 2.0, Color("222738"), true, 0.0, 2)
			box(self, bx - 1.05, y - 0.04, z - 1.05, 2.1, 0.06, 2.1, cyan if i % 2 == 0 else pink, false, 1.5, -1)
			race_waypoints.append(Vector3(bx, y + 0.2, z))
		z -= 3.8

	elif kind == "SURF_DUAL" or kind == "SURF_TRIPLE":
		var r_cnt := 3 if kind == "SURF_TRIPLE" else 2
		title = "SETOR %d/8: CANION DE SURF CS:GO (%d RAMPAS)!" % [s_num, r_cnt]
		for i in r_cnt:
			var rx := (-1.6 if i % 2 == 0 else 1.6) if r_cnt == 3 else 0.0
			_add_surf_ramp(Vector3(rx, y - 0.8, z - 7.5), 5.6, 3.2, 13.0, cyan if i % 2 == 0 else pink)
			_add_kz_ring(Vector3(rx, y + 2.2, z - 7.5), s_num * 10 + i)
			race_waypoints.append(Vector3(rx, y + 1.8, z - 7.5))
			z -= 14.5
			box(self, -2.0, y - 0.3, z - 2.2, 4.0, 0.3, 2.8, Color("23293a"), true, 0.0, 2)
			race_waypoints.append(Vector3(0.0, y + 0.2, z - 1.0))
			z -= 2.8

	elif kind == "KZ_LADDERS":
		title = "SETOR %d/8: TORRE DUPLA DE ESCADAS KZ!" % s_num
		for t_i in 2:
			var tx := -2.0 if t_i == 0 else 2.0
			var h := 5.2
			box(self, tx - 1.5, y, z - 4.2, 3.0, h, 3.0, Color("23293a"), true, 0.0, 2)
			for r in 10:
				box(self, tx - 0.55, y + 0.35 + r * 0.48, z - 1.15, 1.1, 0.09, 0.12, gold if t_i == 0 else cyan, false, 1.6, -1)
			kz_ladders.append(AABB(Vector3(tx - 0.85, y, z - 1.55), Vector3(1.7, h + 0.6, 0.95)))
			y += h
			race_waypoints.append(Vector3(tx, y + 0.2, z - 2.7))
			z -= 5.2
		box(self, -2.5, y - 0.3, z - 3.5, 5.0, 0.3, 4.0, Color("23293a"), true, 0.0, 2)
		z -= 3.5

	else: # JUMPPAD_TOWER or OMEGA_CLIMB
		title = "SETOR %d/8: ESCALADA REAL FALL MOUNTAIN!" % s_num
		for i in 5:
			z -= 6.5
			y += 1.6
			box(self, -2.4, y - 0.35, z - 2.4, 4.8, 0.35, 4.8, Color("23293a"), true, 0.0, 2)
			var jp := Vector3(0.0, y + 0.05, z)
			cyl(self, jp, 1.1, 1.2, 0.18, lime if i % 2 == 0 else pink, 12, 2.0, true)
			kz_jumppads.append(jp)
			if i % 2 == 1:
				add_spinning_hammer(Vector3(0.0, y, z - 1.2), 2.4, 3.8, gold, cyan)
			race_waypoints.append(Vector3(0.0, y + 0.3, z))
		z -= 4.5

	# Sector Landing Pad + Auto-Checkpoint Archway!
	box(self, -3.2, y - 0.4, z - 4.6, 6.4, 0.4, 4.8, Color("222738"), true, 0.0, 2)
	add_checkpoint_arch(Vector3(0.0, y, z - 2.4), s_num, title, gold if s_num % 2 == 0 else cyan)
	return {"z": z - 4.6, "y": y}


func _add_moving_platform(base_pos: Vector3, sz: Vector3, amp: Vector3, spd: float, phase: float, col: Color) -> void:
	var tp := _target_p(self)
	var root := Node3D.new()
	root.position = base_pos
	tp.add_child(root)
	box(root, -sz.x * 0.5, -sz.y * 0.5, -sz.z * 0.5, sz.x, sz.y, sz.z, Color("222738"), true, 0.0, 2)
	box(root, -sz.x * 0.52, sz.y * 0.3, -sz.z * 0.52, sz.x * 1.04, 0.08, sz.z * 1.04, col, false, 1.6, -1)
	moving_platforms.append({
		"node": root,
		"base": base_pos,
		"amp": amp,
		"spd": spd,
		"phase": phase,
		"size": sz,
		"delta_pos": Vector3.ZERO,
		"aabb": AABB(base_pos - Vector3(sz.x * 0.6, 0.4, sz.z * 0.6), Vector3(sz.x * 1.2, 1.0, sz.z * 1.2))
	})


func _add_falling_tile(base_pos: Vector3, sz: Vector3) -> void:
	var tp := _target_p(self)
	var root := Node3D.new()
	root.position = base_pos
	tp.add_child(root)
	box(root, -sz.x * 0.5, -sz.y * 0.5, -sz.z * 0.5, sz.x, sz.y, sz.z, Color("ff4757"), true, 0.8, 0)
	falling_tiles.append({
		"node": root,
		"base": base_pos,
		"size": sz,
		"state": 0,
		"timer": 0.0
	})


func _add_sweeper_island(center: Vector3, radius: float, rot_spd: float) -> void:
	var tp := _target_p(self)
	cyl(tp, center + Vector3(0, -0.45, 0), radius, radius * 0.88, 0.45, Color("242b3d"), 16)
	cyl(tp, center + Vector3(0, -0.05, 0), radius * 1.02, radius * 1.02, 0.08, Color("00f5d4"), 16, 1.4, true)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 0.5
	cs.shape = sh
	sb.position = center + Vector3(0, -0.22, 0)
	sb.add_child(cs)
	tp.add_child(sb)

	cyl(tp, center, 0.36, 0.42, 1.65, Color("ffd166"), 10, 1.2)
	var piv := Node3D.new()
	piv.position = center + Vector3(0, 0.38, 0)
	tp.add_child(piv)
	box(piv, -radius * 0.95, -0.11, -0.14, radius * 1.9, 0.22, 0.28, Color("ff2a85"), false, 1.8, -1)
	box(piv, -radius * 0.85, 0.92, -0.12, radius * 1.7, 0.20, 0.24, Color("00f5d4"), false, 1.5, -1)
	_sweeper_pivots.append({"node": piv, "spd": rot_spd, "center": center + Vector3(0, 0.38, 0), "rad": radius * 0.95})


func _add_finish_sanctuary(center: Vector3, _badge: String) -> void:
	box(self, center.x - 4.8, center.y - 0.5, center.z - 4.8, 9.6, 0.5, 9.6, Color("f5ebe0"), true, 0.0, 2)
	box(self, center.x - 5.0, center.y - 0.05, center.z - 5.0, 10.0, 0.12, 10.0, Color("ffd166"), false, 1.6, -1)
	RetroModels.torii_gate(self, self, center + Vector3(0, 0, 1.8), 6.2, 4.8, 0.0)
	cyl(self, center, 1.55, 1.65, 0.22, Color("ffd166"), 16, 2.2, true)
	ball(self, center + Vector3(0, 2.2, 0), 0.72, Color("ffd166"), 12, 2.4)
	spawn_kenney_model(self, "flag.glb", center + Vector3(-3.6, 0.0, -2.5), Vector3(2.4, 2.4, 2.4))
	spawn_kenney_model(self, "flag.glb", center + Vector3(3.6, 0.0, -2.5), Vector3(2.4, 2.4, 2.4))


func _add_kz_ring(pos: Vector3, idx: int) -> void:
	var tp := _target_p(self)
	var tm := TorusMesh.new()
	tm.inner_radius = 1.05
	tm.outer_radius = 1.25
	tm.rings = 14
	tm.ring_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = psx_mat(Color("ffd166"), 2.0, true)
	mi.position = pos
	mi.rotation.x = PI * 0.5
	tp.add_child(mi)
	kz_rings.append({"pos": pos, "node": mi, "idx": idx, "cd": 0.0})


func _add_surf_ramp(center: Vector3, width: float, height: float, length: float, trim_col: Color) -> void:
	var tp := _target_p(self)
	var pm := PrismMesh.new()
	pm.size = Vector3(width, height, length)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = psx_mat(Color("263044"), 0.0, false, 2)
	mi.position = center + Vector3(0, height * 0.5, 0)
	tp.add_child(mi)

	box(tp, center.x - 0.14, center.y + height - 0.06, center.z - length * 0.5, 0.28, 0.12, length, trim_col, false, 1.8, -1)
	var half_w := width * 0.5
	var slope_len := sqrt(half_w * half_w + height * height)
	var angle := atan2(height, half_w)
	for side in [-1.0, 1.0]:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(slope_len, 0.25, length)
		cs.shape = b
		sb.position = center + Vector3(float(side) * half_w * 0.5, height * 0.5, 0.0)
		sb.rotation.z = -float(side) * angle
		sb.add_child(cs)
		tp.add_child(sb)

	surf_ramps.append({
		"aabb": AABB(center - Vector3(width * 0.65, 0.4, length * 0.54), Vector3(width * 1.3, height + 1.4, length * 1.08)),
		"center": center,
		"half_w": half_w,
		"height": height
	})


func _build_petal_breeze() -> void:
	_petals = CPUParticles3D.new()
	_petals.amount = 90
	_petals.lifetime = 5.0
	_petals.preprocess = 3.0
	_petals.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_petals.emission_box_extents = Vector3(22.0, 8.0, 22.0)
	_petals.direction = Vector3(-0.25, -1.0, 0.18).normalized()
	_petals.spread = 32.0
	_petals.gravity = Vector3(-0.18, -0.85, 0.12)
	_petals.initial_velocity_min = 0.7
	_petals.initial_velocity_max = 1.5
	var qm := QuadMesh.new()
	qm.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("ffc2d9")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = m
	_petals.mesh = qm
	_petals.position = Vector3(0, 9.0, 0)
	add_child(_petals)


# ---------------------------------------------------------------- Combat, Rounds, Fall-Guys Obstacles & VFX Loop

func spawn_pvp_round(bot_count: int = -1) -> void:
	clear_enemies()
	if enemies_paused or game_mode != MODE_COMBAT or tr_spawns.is_empty():
		return
	var total := bot_count if bot_count > 0 else bots_per_round
	for i in total:
		_spawn_single_combat_bot(i)


func _spawn_single_combat_bot(seed_offset: int) -> void:
	if tr_spawns.is_empty() or not is_instance_valid(_stage_root):
		return
	# Pick a spawn point away from the player so bots don't spawn on top of you
	var best_sp := tr_spawns[posmod(seed_offset, tr_spawns.size())]
	for attempt in 4:
		var cand := tr_spawns[_rng.randi() % tr_spawns.size()]
		if cand.distance_to(player_pos) > 10.0:
			best_sp = cand
			break
	var sp := best_sp + Vector3(_rng.randf_range(-0.8, 0.8), 0.0, _rng.randf_range(-0.8, 0.8))
	var bkind := 1 if seed_offset % 4 == 1 else (2 if seed_offset % 3 == 0 else 0)
	var bot := EnemyBot.spawn_bot(self, _stage_root, sp, bkind, round_number * 5 + seed_offset)
	bot.defeated.connect(_on_bot_defeated)
	enemies.append(bot)


func clear_enemies() -> void:
	for b in enemies:
		if is_instance_valid(b):
			b.queue_free()
	enemies.clear()
	for orb in enemy_orbs:
		if is_instance_valid(orb.node):
			orb.node.queue_free()
	enemy_orbs.clear()


func _on_bot_defeated(bot: EnemyBot, was_headshot: bool, hit_pos: Vector3) -> void:
	enemies.erase(bot)
	if bot_scoreboard.has(bot.bot_name):
		bot_scoreboard[bot.bot_name]["deaths"] = int(bot_scoreboard[bot.bot_name]["deaths"]) + 1
	spawn_voxel_burst(hit_pos, Color("ff2a55") if was_headshot else Color("ffd166"), 16 if was_headshot else 10)
	spawn_pickup(bot.global_position + Vector3(0, 0.45, 0), "heal")
	enemy_killed.emit(was_headshot, bot.bot_name, hit_pos)


func spawn_enemy_orb(pos: Vector3, dir: Vector3, spd: float, dmg: float, col: Color) -> void:
	if game_mode != MODE_COMBAT:
		return
	var mi := ball(_stage_root, pos, 0.14, col, 6, 2.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	enemy_orbs.append({"node": mi, "vel": dir * spd, "dmg": dmg, "life": 2.4})


func spawn_tracer(from_pos: Vector3, to_pos: Vector3, col: Color, thickness: float = 0.025) -> void:
	var span := to_pos - from_pos
	var d := span.length()
	if d < 0.1:
		return
	var mid := (from_pos + to_pos) * 0.5
	var beam := cyl(_stage_root, Vector3.ZERO, thickness, thickness, d, col, 6, 2.5, true)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = mid
	beam.look_at_from_position(mid, to_pos, Vector3.UP)
	beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	vfx_items.append({"node": beam, "vel": Vector3.ZERO, "life": 0.08, "max_life": 0.08, "scale_fade": true})


func spawn_voxel_burst(pos: Vector3, base_col: Color, count: int = 8) -> void:
	var cols := [base_col, Color("ffd166"), Color("ffffff")]
	for i in count:
		var sz := _rng.randf_range(0.06, 0.14)
		var b := box(_stage_root, pos.x, pos.y, pos.z, sz, sz, sz, cols[i % cols.size()], false, 1.6, -1)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var vel := Vector3(_rng.randf_range(-4.8, 4.8), _rng.randf_range(2.2, 6.8), _rng.randf_range(-4.8, 4.8))
		vfx_items.append({"node": b, "vel": vel, "grav": 18.0, "life": 0.45, "max_life": 0.45, "spin": true})


func spawn_damage_number(pos: Vector3, amount: int, is_crit: bool) -> void:
	var tp := _target_p(self)
	var lbl := Label3D.new()
	lbl.text = ("%d HEADSHOT!" % amount) if is_crit else ("-%d" % amount)
	lbl.font_size = 44 if is_crit else 30
	lbl.outline_size = 10
	lbl.modulate = Color("ff2a55") if is_crit else Color("ffd166")
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.position = pos + Vector3(_rng.randf_range(-0.18, 0.18), 0.35, _rng.randf_range(-0.18, 0.18))
	tp.add_child(lbl)
	vfx_items.append({"node": lbl, "vel": Vector3(0, 2.2, 0), "grav": 0.0, "life": 0.72, "max_life": 0.72})


func spawn_pickup(pos: Vector3, kind: String) -> void:
	var tp := _target_p(self)
	var col := Color("2ec4b6")
	var g := Node3D.new()
	g.position = pos
	tp.add_child(g)
	box(g, -0.22, -0.14, -0.22, 0.44, 0.28, 0.44, col, false, 1.5, -1)
	pickups.append({"node": g, "kind": kind, "life": 15.0})


func spawn_killcam_dummy(foot_pos: Vector3, look_target: Vector3) -> Node3D:
	var tp := _target_p(self)
	var g := Node3D.new()
	g.position = foot_pos
	tp.add_child(g)
	var dir := look_target - foot_pos
	dir.y = 0.0
	if dir.length() > 0.05:
		g.rotation.y = atan2(dir.x, dir.z)
	var dark := Color("1c2029")
	var crimson := Color("e63956")
	var skin := Color("e0b190")
	box(g, -0.20, 0.0, -0.10, 0.16, 0.72, 0.20, dark)
	box(g, 0.04, 0.0, -0.10, 0.16, 0.72, 0.20, dark)
	box(g, -0.24, 0.70, -0.14, 0.48, 0.62, 0.28, crimson)
	box(g, -0.22, 0.76, -0.16, 0.44, 0.44, 0.32, dark)
	box(g, -0.16, 1.32, -0.16, 0.32, 0.32, 0.32, skin)
	box(g, -0.18, 1.48, -0.18, 0.36, 0.18, 0.36, crimson)
	box(g, -0.14, 1.42, 0.12, 0.28, 0.08, 0.08, Color("ffd166"), false, 2.0, -1)
	return g


func hit_target_body(_body: Node3D) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta
	if _hazard_cd > 0.0:
		_hazard_cd -= delta

	if is_instance_valid(_petals):
		_petals.position = Vector3(player_pos.x, player_pos.y + 8.0, player_pos.z)

	# 1. Parkour Race 5-4-3-2-1 Countdown & Starting Gate Drop!
	if game_mode == MODE_PARKOUR:
		if race_countdown > 0.0:
			race_countdown = maxf(0.0, race_countdown - delta)
			var cur_int := int(ceil(race_countdown))
			if cur_int != race_countdown_last_int and cur_int > 0:
				race_countdown_last_int = cur_int
				Sfx.play("hitmarker", 0.9 + (5 - cur_int) * 0.08)
			if race_countdown <= 0.0:
				kz_running = true
				Sfx.play("course_win", 1.15)
				if is_instance_valid(_start_gate_node):
					_start_gate_node.position.y = -14.0
		elif kz_running:
			kz_time += delta

	# 2. Rotate Jump Showdown Double-Decker Sweeper Bars
	for sw in _sweeper_pivots:
		var n: Node3D = sw.node
		if is_instance_valid(n):
			n.rotation.y += delta * float(sw.spd)

	# 3. Rotate Fall Guys Big Yeetus Hammers
	for hm in spinning_hammers:
		var n: Node3D = hm.node
		if is_instance_valid(n):
			n.rotation.y += delta * float(hm.spd)

	# 4. Swing Giant Wrecking-Ball Pendulums
	for pd in swinging_pendulums:
		var n: Node3D = pd.node
		if is_instance_valid(n):
			var ang := sin(_t * float(pd.spd) + float(pd.phase)) * 0.72
			n.rotation.z = ang
			var ppos: Vector3 = pd.pivot_pos
			var rlen: float = float(pd.rope_len)
			pd.ball_pos = ppos + Vector3(sin(ang) * rlen, -cos(ang) * rlen, 0.0)

	# 5. Animate Hydraulic Slime-Climb Wall Pushers
	for sp in sliding_pushers:
		var n: Node3D = sp.node
		if is_instance_valid(n):
			var base: Vector3 = sp.base
			var sz: Vector3 = sp.size
			var dx: float = float(sp.dir_x)
			var ext := (sin(_t * float(sp.spd) + float(sp.phase)) * 0.5 + 0.5) * float(sp.travel)
			var new_p := base + Vector3(dx * ext, 0.0, 0.0)
			n.position = new_p
			sp.aabb = AABB(new_p - Vector3(sz.x * 0.56, 0.1, sz.z * 0.56), Vector3(sz.x * 1.12, sz.y + 0.2, sz.z * 1.12))

	# 6. Rock Giant Fall Guys See-Saw Tilting Bridges
	for ss in tilting_seesaws:
		var n: Node3D = ss.node
		if is_instance_valid(n):
			n.rotation.z = sin(_t * float(ss.spd) + float(ss.phase)) * float(ss.max_ang)

	# 7. Animate Moving Platforms
	for mp in moving_platforms:
		var n: Node3D = mp.node
		if not is_instance_valid(n):
			continue
		var old_p := n.position
		var base: Vector3 = mp.base
		var amp: Vector3 = mp.amp
		var s := sin(_t * float(mp.spd) + float(mp.phase))
		var new_p := base + amp * s
		n.position = new_p
		mp.delta_pos = new_p - old_p
		var sz: Vector3 = mp.size
		mp.aabb = AABB(new_p - Vector3(sz.x * 0.62, 0.45, sz.z * 0.62), Vector3(sz.x * 1.24, 1.15, sz.z * 1.24))

	# 8. Animate "Tip Toe / O Chão é Lava!" Shaking & Falling Tiles
	for ft in falling_tiles:
		var n: Node3D = ft.node
		if not is_instance_valid(n):
			continue
		var base: Vector3 = ft.base
		var sz: Vector3 = ft.size
		var st := int(ft.state)
		if st == 0:
			var ab := AABB(base - Vector3(sz.x * 0.55, 0.35, sz.z * 0.55), Vector3(sz.x * 1.1, 0.95, sz.z * 1.1))
			if ab.has_point(player_pos):
				ft.state = 1
				ft.timer = 0.35
		elif st == 1:
			ft.timer = float(ft.timer) - delta
			n.position = base + Vector3(sin(_t * 58.0) * 0.08, 0.0, cos(_t * 52.0) * 0.08)
			if float(ft.timer) <= 0.0:
				ft.state = 2
				ft.timer = 2.4
				n.position = base + Vector3(0.0, -28.0, 0.0)
		elif st == 2:
			ft.timer = float(ft.timer) - delta
			if float(ft.timer) <= 0.0:
				ft.state = 0
				n.position = base

	# Floor weapon/ammo pads in Combat Mode
	for wp in floor_weapon_pads:
		if float(wp.cd) > 0.0:
			wp.cd = float(wp.cd) - delta
		elif player_pos.distance_to(wp.pos as Vector3) < 1.65:
			wp.cd = 7.0
			Sfx.play("pickup")
			pickup_collected.emit("ammo_heal", 40.0)

	# Parkour Checkpoints, Rings & Finish detection when in Parkour Mode
	if game_mode == MODE_PARKOUR:
		for rg in kz_rings:
			var rn: Node3D = rg.node
			if is_instance_valid(rn):
				rn.rotation.z += delta * 1.8
			if float(rg.cd) > 0.0:
				rg.cd = float(rg.cd) - delta
			elif (player_pos + Vector3(0, 0.9, 0)).distance_to(rg.pos as Vector3) < 2.4:
				rg.cd = 4.0
				Sfx.play("cash_buy", 1.1)
				kz_ring_collected.emit(int(rg.idx))
		for cp in kz_checkpoints:
			var cp_p: Vector3 = cp.pos
			if int(cp.stage) > kz_active_stage and player_pos.distance_to(cp_p) < 4.2:
				kz_active_stage = int(cp.stage)
				Sfx.play("ring_pass")
				kz_stage_reached.emit(kz_active_stage, str(cp.name), kz_time, cp_p)
		if player_pos.distance_to(kz_finish_pad) < 3.5 and kz_running:
			kz_running = false
			race_finished_count += 1
			player_race_place = race_finished_count
			if kz_best_time <= 0.0 or kz_time < kz_best_time:
				kz_best_time = kz_time
				kz_best_times[current_stage_idx] = kz_best_time
			Sfx.play("course_win")
			kz_course_finished.emit(kz_time, kz_best_time, player_race_place)

	# Enemy bullets in Combat Mode
	for i in range(enemy_orbs.size() - 1, -1, -1):
		var orb := enemy_orbs[i]
		var n: Node3D = orb.node
		if not is_instance_valid(n):
			enemy_orbs.remove_at(i)
			continue
		orb.life -= delta
		var step_v: Vector3 = (orb.vel as Vector3) * delta
		n.position += step_v
		if game_mode == MODE_COMBAT and n.position.distance_to(player_pos + Vector3(0, 1.0, 0)) < 0.78:
			player_damaged.emit(float(orb.dmg), n.position, "TR_Operador")
			n.queue_free()
			enemy_orbs.remove_at(i)
			continue
		if orb.life <= 0.0 or n.position.y < -2.0:
			n.queue_free()
			enemy_orbs.remove_at(i)

	# Pickups
	for i in range(pickups.size() - 1, -1, -1):
		var pk := pickups[i]
		var n: Node3D = pk.node
		if not is_instance_valid(n):
			pickups.remove_at(i)
			continue
		pk.life -= delta
		n.rotation.y += delta * 2.5
		if n.position.distance_to(player_pos + Vector3(0, 0.7, 0)) < 1.8:
			Sfx.play("pickup")
			pickup_collected.emit(str(pk.kind), 40.0)
			n.queue_free()
			pickups.remove_at(i)
			continue
		if pk.life <= 0.0:
			n.queue_free()
			pickups.remove_at(i)

	# VFX & Ragdolls
	for i in range(vfx_items.size() - 1, -1, -1):
		var fx := vfx_items[i]
		var n: Node3D = fx.node
		if not is_instance_valid(n):
			vfx_items.remove_at(i)
			continue
		fx.life -= delta
		if fx.life <= 0.0:
			n.queue_free()
			vfx_items.remove_at(i)
			continue
		var v: Vector3 = fx.vel
		if fx.has("grav"):
			v.y -= float(fx.grav) * delta
			fx.vel = v
		n.position += v * delta
		if fx.get("spin", false):
			n.rotation += Vector3(6.0, 8.0, 5.0) * delta
		if fx.get("scale_fade", false):
			var r := clampf(float(fx.life) / float(fx.max_life), 0.01, 1.0)
			n.scale = Vector3(r, 1.0, r)

	# Continuous Phantom-Forces Style Combat Respawning & Competitive Bot Scoreboard Progression
	if game_mode == MODE_COMBAT and not enemies_paused:
		for i in range(enemies.size() - 1, -1, -1):
			if not is_instance_valid(enemies[i]):
				enemies.remove_at(i)
		if enemies.size() < bots_per_round:
			_bot_respawn_cd -= delta
			if _bot_respawn_cd <= 0.0:
				_bot_respawn_cd = 1.35
				round_number += 1
				_spawn_single_combat_bot(round_number + enemies.size())

		# Bots also fight each other across the arena so the Kill Leaderboard stays fiercely competitive!
		_bot_sim_frag_cd -= delta
		if _bot_sim_frag_cd <= 0.0:
			_bot_sim_frag_cd = _rng.randf_range(4.2, 7.5)
			var names := EnemyBot.BOT_NAMES
			var k_name: String = names[_rng.randi() % names.size()]
			var v_name: String = names[_rng.randi() % names.size()]
			if k_name != v_name and bot_scoreboard.has(k_name) and bot_scoreboard.has(v_name):
				bot_scoreboard[k_name]["kills"] = int(bot_scoreboard[k_name]["kills"]) + 1
				bot_scoreboard[k_name]["pts"] = int(bot_scoreboard[k_name]["kills"]) * 100
				bot_scoreboard[v_name]["deaths"] = int(bot_scoreboard[v_name]["deaths"]) + 1
				var wtags := ["AK-47 [HS]", "AWP", "DEAGLE [HS]", "KARAMBIT"]
				bot_frag_feed.emit(k_name, v_name, wtags[_rng.randi() % wtags.size()])
