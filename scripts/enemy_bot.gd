class_name EnemyBot
extends CharacterBody3D
## Dual-Purpose Bot Actor for SAKURA BLITZ:
## 1) MODO TIRO (Phantom Forces / BO2 Operator):
##    - Forgiving, super-satisfying headshot & body hitboxes, tactical movement, balanced damage,
##      and dramatic 3D Ragdoll Tumble Launch on death!
## 2) MODO PARKOUR (Fall Guys Competitive Runner):
##    - Waits at the Starting Gate during the 5-4-3-2-1 countdown, then sprints & jumps along the
##      335m-380m 8-sector obstacle course, reacts to pendulums/hammers/pushers, respawns at sector
##      checkpoints if knocked into slime/lava, and competes for 1st Place at the Final Crown!

signal defeated(bot: EnemyBot, was_headshot: bool, hit_pos: Vector3)
signal runner_finished(bot: EnemyBot, finish_time: float)

const BOT_NAMES := [
	"Bot_S1mple", "Bot_FalleN", "Bot_Coldzera", "Bot_Niko",
	"Bot_Mason", "Bot_Woods", "Bot_Ghost", "Bot_Reznov"
	, "Bot_Matcha", "Bot_Cobalto", "Bot_Pipa", "Bot_Camélia",
	"Bot_Mochi", "Bot_Solar", "Bot_Bambu", "Bot_Canela",
	"Bot_Brisa", "Bot_Âmbar", "Bot_Lótus", "Bot_Jade",
	"Bot_Nori", "Bot_Coral", "Bot_Cedro", "Bot_Aurora"
]

const RUNNER_NAMES := [
	"Bot_FallKing", "Bot_SpeedyBR", "Bot_Panadero", "Bot_Yeetus",
	"Bot_KzPro", "Bot_SakuraRun", "Bot_Ninja"
]

const RUNNER_COLORS := [
	Color("db8da9"), # Petal
	Color("78c6c0"), # Mint
	Color("e4bc76"), # Honey
	Color("a4bc7e"), # Leaf
	Color("a394cf"), # Lilac
	Color("ddaa84"), # Peach
	Color("89b2ce")  # Sky
]

var skill := BotDifficulty.get_preset(1)
var last_damage_by := "PLAYER"
var _target_bot: EnemyBot
var _target_player := false
var _has_target := false
var _target_memory := Vector3.ZERO
var _sense_cd := 0.0
var _steer_cd := 0.0
var _steered_dir := Vector3.ZERO
var _route := PackedVector3Array()
var _route_cursor := 0
var _route_cd := 0.0
var navigation_steps := 0
var _patrol_cd := 0.0
var _memory_until := 0.0
var _tactical_cd := 0.0
var _tactical_until := 0.0
var _tactical_goal := Vector3.ZERO
var tactical_state := "patrol"
var _foot_distance := 0.0
var _spawn_check_pending := true

var world: Node3D
var team_id := -1
var _full_visuals: Array[MeshInstance3D] = []
var _distance_mesh: MeshInstance3D
var _visual_cd := 0.0
var is_runner := false
var runner_idx := 0
var kind := 0 # 0 = Rifleman (AK-47), 1 = Sharpshooter (AWP), 2 = Rusher (SMG/Deagle)
var bot_name := "Bot_S1mple"
var max_hp := 100.0
var hp := 100.0
var move_speed := 4.8
var score_value := 100
var head_y_min := 1.22

# Parkour Runner State
var wp_idx := 0
var lane_offset := 0.0
var checkpoint_pos := Vector3.ZERO
var finish_placed := false
var finish_time := 0.0
var race_progress_m := 0.0
var _respawn_timer := 0.0
var _jump_cd := 0.0
var _knock_vel := Vector3.ZERO

var _root: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _head_node: Node3D
var _hp_bar_fill: MeshInstance3D
var _hp_bar_root: Node3D
var _name_lbl: Label3D
var _meshes: Array[MeshInstance3D] = []
var _orig_mats: Array[Material] = []
var _flash_mat: StandardMaterial3D

var _t := 0.0
var _flash_timer := 0.0
var _fire_cd := 1.25
var _strafe_dir := 1.0
var _strafe_timer := 0.0
var _is_crouching := false
var _dead := false
var _rng := RandomNumberGenerator.new()


static func spawn_bot(w: Node3D, parent: Node3D, pos: Vector3, bot_kind: int, idx_seed: int = 0) -> EnemyBot:
	var b := EnemyBot.new()
	b.world = w
	b.is_runner = false
	b.kind = bot_kind
	b.runner_idx = idx_seed
	b.position = pos
	b._rng.randomize()
	b.bot_name = BOT_NAMES[posmod(idx_seed, BOT_NAMES.size())]
	b.team_id = w.team_for(b.bot_name)
	b._strafe_dir = -1.0 if b._rng.randf() < 0.5 else 1.0
	b.skill = BotDifficulty.get_preset(w.bot_difficulty)
	b._sense_cd = float(b.skill.think) * float(idx_seed) / maxf(w.bots_per_round, 1)
	b._fire_cd = float(b.skill.reaction)
	b.max_hp = 100.0
	b.hp = 100.0
	b.move_speed = float(b.skill.speed) * (1.05 if bot_kind == 2 else (0.9 if bot_kind == 1 else 1.0))
	b._target_memory = pos
	b.score_value = 100
	parent.add_child(b)
	b._build_visuals()
	return b


static func spawn_parkour_runner(w: Node3D, parent: Node3D, pos: Vector3, r_idx: int) -> EnemyBot:
	var b := EnemyBot.new()
	b.world = w
	b.is_runner = true
	b.runner_idx = r_idx
	b.position = pos
	b.checkpoint_pos = pos
	b._rng.randomize()
	b.bot_name = RUNNER_NAMES[posmod(r_idx, RUNNER_NAMES.size())]
	b.lane_offset = (float(r_idx % 5) - 2.0) * 0.48
	b.skill = BotDifficulty.get_preset(w.bot_difficulty)
	b.move_speed = float(b.skill.race_speed) + (3 - r_idx) * 0.10
	b.max_hp = 100.0
	b.hp = 100.0
	parent.add_child(b)
	b._build_visuals()
	return b


func _build_visuals() -> void:
	collision_layer = 0 if is_runner else 4
	collision_mask = 1
	floor_snap_length = 0.5 if not is_runner else 0.1

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	# Generous capsule radius in Combat Mode for ultra-responsive Phantom Forces hit detection!
	cap.radius = 0.34 if is_runner else 0.46
	cap.height = 1.82
	cs.shape = cap
	cs.position = Vector3(0, 0.91, 0)
	add_child(cs)

	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.albedo_color = Color(1.0, 0.95, 0.88)

	_root = Node3D.new()
	add_child(_root)
	CozyAvatar.build(self)

	_hp_bar_root = Node3D.new()
	_hp_bar_root.position = Vector3(0, 2.06, 0)
	add_child(_hp_bar_root)

	if is_runner:
		_name_lbl = Label3D.new()
		_name_lbl.text = bot_name
		_name_lbl.font_size = 16
		_name_lbl.outline_size = 3
		_name_lbl.modulate = RUNNER_COLORS[posmod(runner_idx, RUNNER_COLORS.size())].lightened(0.25)
		_name_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_hp_bar_root.add_child(_name_lbl)
	else:
		var bg := _part(_hp_bar_root, Vector3.ZERO, Vector3(0.80, 0.085, 0.03), Color("161820"), 0.0, true, false)
		bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hp_bar_fill = _part(_hp_bar_root, Vector3(0, 0, 0.01), Vector3(0.76, 0.06, 0.04), Color("ff2a55"), 1.2, true, false)
		_hp_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_full_visuals.assign(_meshes)
		_distance_mesh = CozyAvatar.distance_model(self)
		_distance_mesh.hide()
		_meshes.append(_distance_mesh)
		_orig_mats.append(_distance_mesh.material_override)
		if team_id >= 0:
			var badge := _part(_hp_bar_root, Vector3(0, 0.25, 0), Vector3(0.17, 0.17, 0.17), Color("93e7c3") if team_id == 0 else Color("f08c91"), 0, true, false)
			badge.rotation.z = PI / 4


func _part(parent: Node3D, pos: Vector3, sz: Vector3, col: Color, emit: float = 0.0, unshaded: bool = false, track: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	var m: Material = world.psx_mat(col, emit, unshaded, 0)
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if track:
		_meshes.append(mi)
		_orig_mats.append(m)
	return mi


func _physics_process(delta: float) -> void:
	if _dead or world == null or not is_instance_valid(world):
		return
	if world.get("enemies_paused") == true:
		return

	_t += delta

	if is_runner:
		_process_parkour_runner(delta)
		return

	if _spawn_check_pending:
		_ensure_clear_spawn()
		_spawn_check_pending = false
	_visual_cd -= delta
	if _visual_cd <= 0 and is_instance_valid(_distance_mesh):
		_visual_cd = 0.25
		var distance := global_position.distance_to(world.player_pos)
		var far := distance > (29 if _distance_mesh.visible else 35)
		for part in _full_visuals:
			part.visible = not far
		_distance_mesh.visible = far
		_hp_bar_root.visible = distance < 28 or team_id >= 0
		_hp_bar_fill.visible = distance < 28
		_hp_bar_root.get_child(0).visible = distance < 28
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			for i in _meshes.size():
				if is_instance_valid(_meshes[i]):
					_meshes[i].material_override = _orig_mats[i]

	_sense_cd -= delta
	_patrol_cd -= delta
	if _sense_cd <= 0:
		_sense_cd = float(skill.think) * (1.5 if world.bots_per_round >= 18 and global_position.distance_to(world.player_pos) > 32 else 1.0)
		_choose_target()
	var ppos: Vector3 = world.player_pos if _target_player else (_target_bot.global_position if is_instance_valid(_target_bot) and not _target_bot._dead else _target_memory)
	if not _has_target:
		ppos = _target_memory
	var to_p := ppos - global_position
	var flat_to := Vector3(to_p.x, 0.0, to_p.z)
	var dist := flat_to.length()

	if is_instance_valid(_hp_bar_root) and dist > 0.2:
		_hp_bar_root.look_at(ppos + Vector3(0, 1.5, 0), Vector3.UP)

	var space := world.get_world_3d().direct_space_state
	var eye_from := global_position + Vector3(0, 1.45, 0)
	var eye_to := ppos + Vector3(0, 1.35, 0)
	var los_q := PhysicsRayQueryParameters3D.create(eye_from, eye_to, 1)
	var has_los := _has_target and space.intersect_ray(los_q).is_empty()
	if has_los:
		_target_memory = ppos
		_memory_until = _t + float(skill.memory)
	else:
		ppos = _target_memory
		flat_to = (ppos - global_position) * Vector3(1, 0, 1)
		dist = flat_to.length()
	_tactical_cd = maxf(0, _tactical_cd - delta)
	var movement_goal: Variant = _tactical_destination(has_los, ppos)

	if dist > 0.25:
		var target_yaw := atan2(flat_to.x, flat_to.z)
		_root.rotation.y = lerp_angle(_root.rotation.y, target_yaw, minf(1.0, delta * 9.0))

	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = _rng.randf_range(0.85, 1.95)
		_strafe_dir = -_strafe_dir
		_is_crouching = has_los and _rng.randf() < 0.28

	_root.scale.y = lerpf(_root.scale.y, 0.78 if _is_crouching else 1.0, minf(1.0, delta * 12.0))
	head_y_min = 0.96 if _is_crouching else 1.22

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	var fwd := flat_to.normalized() if dist > 0.1 else Vector3.FORWARD
	var right := Vector3(-fwd.z, 0.0, fwd.x)

	if not has_los or movement_goal != null or absf(ppos.y - global_position.y) > 1.5:
		if movement_goal != null:
			var displacement: Vector3 = movement_goal - global_position
			fwd = Vector3(displacement.x, 0, displacement.z).normalized() if displacement.length() > 0.7 else Vector3.ZERO
		var push := fwd if movement_goal != null else (fwd * 0.88 + right * _strafe_dir * 0.52).normalized()
		if world.arena_navigation != null:
			_route_cd -= delta
			if _route_cd <= 0 or _route.is_empty():
				_route = world.arena_navigation.path(global_position, movement_goal if movement_goal != null else ppos)
				_route_cursor = 0
				_route_cd = 0.7 + runner_idx * 0.04
			var tolerance := 0.24 if world.arena_navigation is SurfaceNavigation else 0.55
			while _route_cursor < _route.size() and Vector2(global_position.x, global_position.z).distance_to(Vector2(_route[_route_cursor].x, _route[_route_cursor].z)) < tolerance and absf(global_position.y - _route[_route_cursor].y) < 0.5:
				_route_cursor += 1
			if _route_cursor < _route.size():
				var next := _route[_route_cursor] - global_position
				push = Vector3(next.x, 0, next.z).normalized()
			elif world.arena_navigation is SurfaceNavigation:
				push = Vector3.ZERO
		elif is_on_wall():
			_strafe_dir = -_strafe_dir
			push = (right * _strafe_dir + fwd * 0.35).normalized()
			if is_on_floor():
				velocity.y = 6.2
		if world.arena_navigation is SurfaceNavigation:
			# Dense stair waypoints need immediate steering; cached/inertial steering
			# can overshoot a tread before its next decision.
			velocity.x = push.x * move_speed
			velocity.z = push.z * move_speed
		else:
			velocity.x = lerpf(velocity.x, push.x * move_speed, delta * 7.0)
			velocity.z = lerpf(velocity.z, push.z * move_speed, delta * 7.0)
	else:
		var adv := 0.65 if dist > 18.0 else (-0.6 if dist < 6.0 or (hp < 35 and world.bot_difficulty == 2) else 0.0)
		var spd := move_speed * (0.40 if _is_crouching else float(skill.strafe))
		var wish := (fwd * adv + right * _strafe_dir).normalized()
		velocity.x = lerpf(velocity.x, wish.x * spd, delta * 8.0)
		velocity.z = lerpf(velocity.z, wish.z * spd, delta * 8.0)

	_steer_cd -= delta
	var desired := Vector3(velocity.x, 0, velocity.z)
	if _steer_cd <= 0 or world.arena_navigation is SurfaceNavigation:
		_steer_cd = 0.12
		_steered_dir = desired.normalized() if world.arena_navigation is SurfaceNavigation and _route_cursor < _route.size() and (not has_los or movement_goal != null or absf(ppos.y - global_position.y) > 1.5) else _steer_direction(desired.normalized())
	velocity.x = _steered_dir.x * desired.length()
	velocity.z = _steered_dir.z * desired.length()
	if global_position.y < -3.0:
		global_position = world.tr_spawns[runner_idx % world.tr_spawns.size()]
		_ensure_clear_spawn()
		velocity = Vector3.ZERO
	if world.arena_navigation is SurfaceNavigation:
		_try_combat_step(delta)
	move_and_slide()
	_foot_distance += Vector2(velocity.x, velocity.z).length() * delta if is_on_floor() else 0.0
	if _foot_distance > 2.0 and world.combat_audio != null:
		_foot_distance = 0
		world.combat_audio.footstep(global_position)

	var spd_ratio := clampf(Vector2(velocity.x, velocity.z).length() / move_speed, 0.0, 1.0)
	var sw := sin(_t * 10.5) * 0.58 * spd_ratio
	if is_instance_valid(_leg_l):
		_leg_l.rotation.x = sw
		_leg_r.rotation.x = -sw

	# Balanced firing so the player has intense gunfights without dying cheaply!
	if has_los and dist < 52.0:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = float(skill.interval) * _rng.randf_range(0.9, 1.1)
			_fire_at_player(eye_to, dist)


func _process_parkour_runner(delta: float) -> void:
	if _jump_cd > 0.0:
		_jump_cd -= delta

	# 1. During 5-4-3-2-1 Countdown, hop excitedly at the starting line!
	var cd: float = float(world.get("race_countdown"))
	if cd > 0.0:
		var hop := absf(sin(_t * 6.5 + float(runner_idx) * 1.1)) * 0.32
		_root.position.y = hop
		_root.rotation.y = 0.0
		if is_instance_valid(_leg_l):
			var sw0 := sin(_t * 12.0 + float(runner_idx)) * 0.45
			_leg_l.rotation.x = sw0
			_leg_r.rotation.x = -sw0
		race_progress_m = 0.0
		return

	_root.position.y = 0.0
	if finish_placed:
		# Victory dance at the Crown!
		_root.position.y = absf(sin(_t * 8.0 + float(runner_idx))) * 0.45
		_root.rotation.y += delta * 4.5
		return

	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			global_position = checkpoint_pos + Vector3(lane_offset * 0.6, 0.4, 0.0)
			velocity = Vector3.ZERO
			_knock_vel = Vector3.ZERO
		return

	var wps: Array = world.race_fast_waypoints if world.bot_difficulty >= 1 and runner_idx < world.bot_difficulty * 2 else world.race_waypoints
	if wps == null or wps.is_empty():
		return

	wp_idx = clampi(wp_idx, 0, wps.size() - 1)
	var target: Vector3 = wps[wp_idx]
	var aim_pt := target + Vector3(lane_offset * 0.65, 0.0, 0.0)
	var to_t := aim_pt - global_position
	var flat := Vector3(to_t.x, 0.0, to_t.z)

	if flat.length() < 0.95 and is_on_floor() and wp_idx < wps.size() - 1:
		checkpoint_pos = wps[wp_idx]
		wp_idx += 1
		target = wps[wp_idx]
		aim_pt = target + Vector3(lane_offset * 0.65, 0.0, 0.0)
		to_t = aim_pt - global_position
		flat = Vector3(to_t.x, 0.0, to_t.z)

	var dir := flat.normalized() if flat.length() > 0.05 else Vector3(0, 0, -1)
	var yaw := atan2(dir.x, dir.z)
	_root.rotation.y = lerp_angle(_root.rotation.y, yaw, minf(1.0, delta * 10.0))

	race_progress_m = maxf(0.0, float(world.kz_start_pad.z) - global_position.z)
	var cur_spd := move_speed if is_on_floor() else minf(move_speed, flat.length() * 4.0)

	# Apply conveyor & hazard impulses from the world!
	var conv: Vector3 = world.call("get_conveyor_velocity", global_position)
	var haz: Vector3 = world.call("compute_runner_hazard_vec", global_position)
	if haz.length() > 0.5:
		_knock_vel = haz * 0.55
		velocity.y = maxf(velocity.y, haz.y * 0.65)

	_knock_vel = _knock_vel.move_toward(Vector3.ZERO, delta * 18.0)
	velocity.x = dir.x * cur_spd + conv.x * 0.55 + _knock_vel.x
	velocity.z = dir.z * cur_spd + conv.z * 0.55 + _knock_vel.z

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		# Jump when target waypoint is higher, or approaching a gap/bar, or on a bouncy drum
		if world.call("check_bouncy_awning", global_position):
			velocity.y = 14.5
		elif _jump_cd <= 0.0 and (to_t.y > 0.45 or _runner_needs_jump(dir)):
			velocity.y = 9.2 + clampf(to_t.y * 1.4, 0.0, 4.5)
			_jump_cd = 0.25

	move_and_slide()

	# Check if knocked into slime/lava or fell off bridge
	if global_position.y < -1.6 or global_position.y < target.y - 7.5:
		_respawn_timer = 1.15
		return

	# Check if reached Final Crown!
	var fin_pad: Vector3 = world.get("kz_finish_pad")
	if global_position.distance_to(fin_pad) < 3.6 and not finish_placed:
		finish_placed = true
		finish_time = float(world.get("kz_time"))
		race_progress_m = maxf(race_progress_m, float(world.kz_start_pad.z) - fin_pad.z)
		runner_finished.emit(self, finish_time)

	# Sprint leg & arm animation
	var sw := sin(_t * 14.5 + float(runner_idx)) * 0.72
	if is_instance_valid(_leg_l):
		_leg_l.rotation.x = sw
		_leg_r.rotation.x = -sw
	if is_instance_valid(_arm_l):
		_arm_l.rotation.x = -sw * 0.85
		_arm_r.rotation.x = sw * 0.85


func _fire_at_player(target_pos: Vector3, dist: float) -> void:
	var muzzle := global_position + Vector3(0, 1.35, 0)
	var spread := float(skill.spread) * (0.7 + dist * 0.018)
	var aim_error := Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-spread * 0.45, spread * 0.45), _rng.randf_range(-spread, spread))
	var dir := (target_pos + aim_error - muzzle).normalized()
	world.spawn_enemy_orb(muzzle + dir * 0.55, dir, 48.0, 18.0, Color("f1c782"), self)
	if world.combat_audio != null:
		world.combat_audio.play_at(["smg_shoot", "shotgun_shoot", "rail_shoot"][kind], muzzle, -13)
		world.combat_audio.noise(muzzle, self)


func apply_hit(dmg: float, hit_pos: Vector3, knockback: Vector3, head_mult: float = 3.2, attacker: String = "PLAYER") -> Dictionary:
	if _dead or is_runner or world.same_team(attacker, bot_name):
		return {"killed": false, "headshot": false, "dmg": 0.0}

	last_damage_by = attacker
	var local_y := hit_pos.y - global_position.y
	var is_head := local_y >= head_y_min
	var final_dmg := roundf(dmg * (head_mult if is_head else 1.0))
	hp -= final_dmg

	_flash_timer = 0.09
	for mi in _meshes:
		if is_instance_valid(mi):
			mi.material_override = _flash_mat

	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	if is_instance_valid(_hp_bar_fill):
		_hp_bar_fill.scale.x = maxf(0.01, ratio)
		_hp_bar_fill.position.x = -0.38 * (1.0 - ratio)

	velocity += knockback * 0.55
	if hp <= 0.0:
		_dead = true
		_spawn_ragdoll_launch(knockback, is_head)
		defeated.emit(self, is_head, hit_pos)
		queue_free()
		return {"killed": true, "headshot": is_head, "dmg": final_dmg}

	return {"killed": false, "headshot": is_head, "dmg": final_dmg}


func _spawn_ragdoll_launch(knockback: Vector3, is_head: bool) -> void:
	if not is_instance_valid(world) or not is_instance_valid(_root):
		return
	# Detach visual operator root into world.vfx_items for a super-satisfying Phantom Forces ragdoll launch!
	var rag := _root
	remove_child(rag)
	world._stage_root.add_child(rag)
	rag.global_position = global_position
	var launch_vel := knockback.normalized() * (9.5 if is_head else 6.8) + Vector3(0.0, 5.8 if is_head else 4.2, 0.0)
	world.vfx_items.append({
		"node": rag,
		"vel": launch_vel,
		"grav": 20.0,
		"life": 0.68,
		"max_life": 0.68,
		"spin": true
	})


func _choose_target() -> void:
	var previous: EnemyBot = _target_bot
	var was_player := _target_player
	_target_bot = null
	_target_player = false
	_has_target = false
	var best := 48.0
	var origin := global_position + Vector3.UP * 1.4
	var space := world.get_world_3d().direct_space_state
	var player_dist := global_position.distance_to(world.player_pos)
	if not world.same_team(bot_name, "PLAYER") and world.player_spawn_guard <= 0 and player_dist < best and _in_view(world.player_pos):
		var query := PhysicsRayQueryParameters3D.create(origin, world.player_pos + Vector3.UP * 1.35, 1)
		if space.intersect_ray(query).is_empty():
			_target_player = true
			_has_target = true
			best = player_dist
			_target_memory = world.player_pos
	for opponent in world.enemies:
		if not is_instance_valid(opponent) or opponent == self or opponent._dead or world.same_team(bot_name, opponent.bot_name):
			continue
		var distance := global_position.distance_to(opponent.global_position)
		if distance >= best or not _in_view(opponent.global_position):
			continue
		var query := PhysicsRayQueryParameters3D.create(origin, opponent.global_position + Vector3.UP * 1.35, 1)
		if not space.intersect_ray(query).is_empty():
			continue
		best = distance
		_target_bot = opponent
		_target_player = false
		_has_target = true
		_target_memory = opponent.global_position
	if was_player != _target_player or previous != _target_bot:
		_fire_cd = maxf(_fire_cd, float(skill.reaction))
	if _has_target:
		_memory_until = _t + float(skill.memory)
		if not world.combat_patrol_points.is_empty():
			_patrol_cd = 0
	if not _has_target and _patrol_cd <= 0 and _memory_until <= _t:
		_patrol_cd = 3.0
		var destinations: Array = world.tr_spawns.filter(func(p): return global_position.distance_to(p) > 8.0)
		if not destinations.is_empty():
			_target_memory = destinations[_rng.randi() % destinations.size()]
		if not world.combat_patrol_points.is_empty():
			# Retain a reachable sector goal long enough to actually arrive there.
			var sectors: Array = world.combat_patrol_points.filter(func(p): return global_position.distance_to(p) > 10 and global_position.distance_to(p) < 48)
			if not sectors.is_empty():
				_target_memory = sectors[_rng.randi() % sectors.size()]
			_patrol_cd = clampf(global_position.distance_to(_target_memory) / move_speed * 1.6 + 2, 4, 40)


func _in_view(at: Vector3) -> bool:
	var direction := (at - global_position) * Vector3(1, 0, 1)
	return direction.length() < 2 or _root.global_basis.z.normalized().dot(direction.normalized()) > cos(deg_to_rad(float(skill.fov) * 0.5))

func hear_noise(at: Vector3, loudness: float) -> void:
	if is_runner or _dead or _has_target:
		return
	var range_limit := float(skill.hearing) * loudness
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, at + Vector3.UP * 0.8, 1)
	if not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		range_limit *= 0.5
	if global_position.distance_to(at) > range_limit:
		return
	_target_memory = at
	_memory_until = _t + float(skill.memory)
	_patrol_cd = float(skill.memory)
	_route_cd = 0
	tactical_state = "investigate"

func _tactical_destination(visible: bool, threat: Vector3) -> Variant:
	if world.match_kind == CombatMatch.CTF and is_instance_valid(world.match_controller):
		tactical_state = "flag"
		return world.match_controller.bot_goal(self)
	if _t < _tactical_until:
		return _tactical_goal
	tactical_state = "engage" if visible else ("investigate" if _memory_until > _t else "patrol")
	if _tactical_cd > 0 or world.bot_difficulty == 0 or _memory_until <= _t:
		return null
	_tactical_cd = 3.0 + runner_idx * 0.07
	var destination: Variant = null
	if hp < 45:
		destination = CombatTactics.cover(world, global_position, threat)
		if destination != null:
			tactical_state = "cover"
	elif not visible and world.bot_difficulty == 2:
		destination = CombatTactics.flank(world, global_position, threat, _strafe_dir)
		if destination != null:
			tactical_state = "flank"
	if destination != null:
		_tactical_goal = destination
		_tactical_until = _t + 2.8
		_route_cd = 0
	return destination

func _steer_direction(desired: Vector3) -> Vector3:
	var space := world.get_world_3d().direct_space_state
	var eye := global_position + Vector3.UP * 0.8
	var best := Vector3.ZERO
	var score := -100.0
	for angle in [0.0, 0.65, -0.65, 1.3, -1.3, 2.3, -2.3]:
		var direction := desired.rotated(Vector3.UP, angle)
		var front := eye + direction * 1.5
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, front, 1)).is_empty():
			var high_ray := PhysicsRayQueryParameters3D.create(eye + Vector3.UP * 1.0, front + Vector3.UP * 1.0, 1)
			if angle == 0.0 and is_on_floor() and space.intersect_ray(high_ray).is_empty():
				velocity.y = 6.2
				return desired
			continue
		var floor_query := PhysicsRayQueryParameters3D.create(front, front - Vector3.UP * 2.3, 1)
		if space.intersect_ray(floor_query).is_empty():
			continue
		var current_score := direction.dot(desired) + direction.dot(_steered_dir) * 0.2
		if current_score > score:
			score = current_score
			best = direction
	return best


func _try_combat_step(delta: float) -> void:
	if not is_on_floor() or velocity.y > 0.1:
		return
	var motion := Vector3(velocity.x, 0, velocity.z) * delta
	var contact := KinematicCollision3D.new()
	if motion.length_squared() < 0.00001 or not test_move(global_transform, motion, contact):
		return
	# Read the actual contacted riser, including a rounded capsule touching its
	# corner. A ray through the capsule center can miss that corner entirely.
	var collider := contact.get_collider()
	if not collider is StaticBody3D or collider.get_child_count() != 1:
		return
	var shape_node := collider.get_child(0) as CollisionShape3D
	if shape_node == null or not shape_node.shape is BoxShape3D:
		return
	var size: Vector3 = shape_node.shape.size
	var box: AABB = shape_node.global_transform * AABB(-size * 0.5, size)
	var rise := box.end.y + 0.012 - global_position.y
	if rise < 0.02 or rise > SurfaceNavigation.MAX_STEP + 0.01:
		return
	var lift := Vector3.UP * rise
	if test_move(global_transform, lift):
		return
	var raised := global_transform
	raised.origin += lift
	if test_move(raised, motion):
		return
	global_position.y = raised.origin.y
	# A tiny upward component prevents floor snap from undoing the lift before
	# the capsule center passes the edge; normal gravity resumes next frame.
	velocity.y = 0.05
	navigation_steps += 1


func _runner_needs_jump(direction: Vector3) -> bool:
	var space := world.get_world_3d().direct_space_state
	var ahead := global_position + direction * 1.25
	var floor_query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.6, ahead - Vector3.UP * 1.2, 1)
	if space.intersect_ray(floor_query).is_empty():
		return true
	var obstacle := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.35, ahead + Vector3.UP * 0.35, 1)
	return not space.intersect_ray(obstacle).is_empty()


func _ensure_clear_spawn() -> void:
	var space := world.get_world_3d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = (get_child(0) as CollisionShape3D).shape
	shape_query.collision_mask = 1
	var original := global_position
	for attempt in 25:
		var offset := Vector3.ZERO if attempt == 0 else Vector3(cos(attempt * 2.4), 0, sin(attempt * 2.4)) * (1.2 + attempt * 0.3)
		var candidate := original + offset
		var floor_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 1.0, candidate - Vector3.UP * 4.0, 1)
		var floor_hit := space.intersect_ray(floor_query)
		if floor_hit.is_empty() or (floor_hit.normal as Vector3).y < 0.7:
			continue
		candidate.y = floor_hit.position.y + 0.05
		shape_query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 0.91)
		if space.intersect_shape(shape_query, 1).is_empty():
			global_position = candidate
			_target_memory = candidate
			return
