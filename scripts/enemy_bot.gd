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
]

const RUNNER_NAMES := [
	"Bot_FallKing", "Bot_SpeedyBR", "Bot_Panadero", "Bot_Yeetus",
	"Bot_KzPro", "Bot_SakuraRun", "Bot_Ninja"
]

const RUNNER_COLORS := [
	Color("ff2a85"), # Hot Pink Fall Guys
	Color("00f5d4"), # Neon Cyan
	Color("ffbe0b"), # Gold Crown
	Color("8ac926"), # Slime Lime
	Color("9b5de5"), # Cyber Purple
	Color("ff6b35"), # Sunset Orange
	Color("00bbf9")  # Electric Blue
]

var world: Node3D
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
	b.position = pos
	b._rng.randomize()
	b.bot_name = BOT_NAMES[posmod(idx_seed, BOT_NAMES.size())]
	b._strafe_dir = -1.0 if b._rng.randf() < 0.5 else 1.0
	b._fire_cd = b._rng.randf_range(0.85, 1.65)
	b.max_hp = 100.0
	b.hp = 100.0
	b.move_speed = 4.9 if bot_kind == 2 else (4.5 if bot_kind == 0 else 3.9)
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
	# Competitive Fall-Guys runner speeds so top bots push the player hard!
	var base_spds := [7.55, 7.35, 7.15, 6.95, 6.80, 6.60, 6.45]
	b.move_speed = float(base_spds[posmod(r_idx, base_spds.size())]) + b._rng.randf_range(-0.12, 0.12)
	b.max_hp = 100.0
	b.hp = 100.0
	parent.add_child(b)
	b._build_visuals()
	return b


func _build_visuals() -> void:
	collision_layer = 0 if is_runner else 4
	collision_mask = 1

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
	if is_runner:
		_build_runner_visuals()
	else:
		_build_operator()

	_hp_bar_root = Node3D.new()
	_hp_bar_root.position = Vector3(0, 2.06, 0)
	add_child(_hp_bar_root)

	if is_runner:
		_name_lbl = Label3D.new()
		_name_lbl.text = bot_name
		_name_lbl.font_size = 24
		_name_lbl.outline_size = 8
		_name_lbl.modulate = RUNNER_COLORS[posmod(runner_idx, RUNNER_COLORS.size())].lightened(0.25)
		_name_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_hp_bar_root.add_child(_name_lbl)
	else:
		var bg := _part(_hp_bar_root, Vector3.ZERO, Vector3(0.80, 0.085, 0.03), Color("161820"), 0.0, true, false)
		bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hp_bar_fill = _part(_hp_bar_root, Vector3(0, 0, 0.01), Vector3(0.76, 0.06, 0.04), Color("ff2a55"), 1.2, true, false)
		_hp_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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


func _build_runner_visuals() -> void:
	var suit_col: Color = RUNNER_COLORS[posmod(runner_idx, RUNNER_COLORS.size())]
	var trim_col := Color("ffffff")
	var visor_col := Color("161922")
	var shoe_col := suit_col.darkened(0.35)

	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.15, 0.76, 0)
	_root.add_child(_leg_l)
	_part(_leg_l, Vector3(0, -0.30, 0), Vector3(0.20, 0.60, 0.22), suit_col.darkened(0.15))
	_part(_leg_l, Vector3(0, -0.66, 0.03), Vector3(0.22, 0.18, 0.28), shoe_col)

	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.15, 0.76, 0)
	_root.add_child(_leg_r)
	_part(_leg_r, Vector3(0, -0.30, 0), Vector3(0.20, 0.60, 0.22), suit_col.darkened(0.15))
	_part(_leg_r, Vector3(0, -0.66, 0.03), Vector3(0.22, 0.18, 0.28), shoe_col)

	# Fall-Guys / Roblox Chibi Hoodie Torso + Racing Number Stripe
	_part(_root, Vector3(0, 1.08, 0), Vector3(0.50, 0.62, 0.32), suit_col, 0.25)
	_part(_root, Vector3(0, 1.08, 0.01), Vector3(0.36, 0.24, 0.34), trim_col, 0.2)

	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-0.32, 1.28, 0)
	_root.add_child(_arm_l)
	_part(_arm_l, Vector3(0, -0.20, 0), Vector3(0.15, 0.44, 0.18), suit_col)

	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.32, 1.28, 0)
	_root.add_child(_arm_r)
	_part(_arm_r, Vector3(0, -0.20, 0), Vector3(0.15, 0.44, 0.18), suit_col)

	_head_node = Node3D.new()
	_head_node.position = Vector3(0, 1.40, 0)
	_root.add_child(_head_node)
	_part(_head_node, Vector3(0, 0.19, 0), Vector3(0.38, 0.38, 0.36), suit_col, 0.25)
	_part(_head_node, Vector3(0, 0.20, -0.15), Vector3(0.28, 0.16, 0.08), visor_col)
	_part(_head_node, Vector3(0, 0.40, 0), Vector3(0.18, 0.10, 0.18), Color("ffd166"), 0.8, true)


func _build_operator() -> void:
	var jacket := Color("c92a42") if kind == 0 else (Color("2b5842") if kind == 1 else Color("344e7a"))
	var vest := Color("1f222b")
	var pants := Color("282d38")
	var boots := Color("16181e")
	var skin := Color("dca884")
	var balaclava := Color("1c1e26")
	var goggles := Color("ffbe0b") if kind == 0 else (Color("00f5d4") if kind == 1 else Color("ff2a85"))

	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.15, 0.78, 0)
	_root.add_child(_leg_l)
	_part(_leg_l, Vector3(0, -0.32, 0), Vector3(0.20, 0.64, 0.22), pants)
	_part(_leg_l, Vector3(0, -0.68, 0.03), Vector3(0.21, 0.18, 0.26), boots)

	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.15, 0.78, 0)
	_root.add_child(_leg_r)
	_part(_leg_r, Vector3(0, -0.32, 0), Vector3(0.20, 0.64, 0.22), pants)
	_part(_leg_r, Vector3(0, -0.68, 0.03), Vector3(0.21, 0.18, 0.26), boots)

	_part(_root, Vector3(0, 1.08, 0), Vector3(0.48, 0.60, 0.28), jacket)
	_part(_root, Vector3(0, 1.09, 0.01), Vector3(0.44, 0.44, 0.32), vest)
	for mx in [-0.12, 0.0, 0.12]:
		_part(_root, Vector3(mx, 0.98, 0.18), Vector3(0.08, 0.14, 0.05), Color("363a45"))

	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-0.31, 1.28, 0)
	_root.add_child(_arm_l)
	_part(_arm_l, Vector3(0, -0.18, 0.16), Vector3(0.15, 0.42, 0.20), jacket)
	_arm_l.rotation.x = -0.55

	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.31, 1.28, 0)
	_root.add_child(_arm_r)
	_part(_arm_r, Vector3(0, -0.18, 0.16), Vector3(0.15, 0.42, 0.20), jacket)
	_arm_r.rotation.x = -0.62

	var gun_col := Color("1a1c22")
	_part(_arm_r, Vector3(-0.12, -0.22, 0.42), Vector3(0.08, 0.12, 0.62), gun_col)
	if kind == 0:
		_part(_arm_r, Vector3(-0.12, -0.20, 0.56), Vector3(0.085, 0.08, 0.22), Color("8c4a27"))
		_part(_arm_r, Vector3(-0.12, -0.34, 0.44), Vector3(0.06, 0.18, 0.08), Color("c85a28"))
	elif kind == 1:
		_part(_arm_r, Vector3(-0.12, -0.12, 0.40), Vector3(0.07, 0.07, 0.30), Color("3b5238"))

	_head_node = Node3D.new()
	_head_node.position = Vector3(0, 1.40, 0)
	_root.add_child(_head_node)
	_part(_head_node, Vector3(0, 0.18, 0), Vector3(0.36, 0.36, 0.36), balaclava)
	_part(_head_node, Vector3(0, 0.20, 0.16), Vector3(0.26, 0.10, 0.04), skin)
	_part(_head_node, Vector3(0, 0.31, -0.01), Vector3(0.40, 0.16, 0.40), vest)
	_part(_head_node, Vector3(0, 0.23, 0.18), Vector3(0.32, 0.095, 0.04), goggles, 2.0, true)


func _physics_process(delta: float) -> void:
	if _dead or world == null or not is_instance_valid(world):
		return
	if world.get("enemies_paused") == true:
		return

	_t += delta

	if is_runner:
		_process_parkour_runner(delta)
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			for i in _meshes.size():
				if is_instance_valid(_meshes[i]):
					_meshes[i].material_override = _orig_mats[i]

	var ppos: Vector3 = world.player_pos
	var to_p := ppos - global_position
	var flat_to := Vector3(to_p.x, 0.0, to_p.z)
	var dist := flat_to.length()

	if is_instance_valid(_hp_bar_root) and dist > 0.2:
		_hp_bar_root.look_at(ppos + Vector3(0, 1.5, 0), Vector3.UP)

	var space := world.get_world_3d().direct_space_state
	var eye_from := global_position + Vector3(0, 1.45, 0)
	var eye_to := ppos + Vector3(0, 1.35, 0)
	var los_q := PhysicsRayQueryParameters3D.create(eye_from, eye_to, 1)
	var has_los := space.intersect_ray(los_q).is_empty()

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

	if not has_los:
		var push := (fwd * 0.88 + right * _strafe_dir * 0.52).normalized()
		if is_on_wall():
			_strafe_dir = -_strafe_dir
			push = (right * _strafe_dir + fwd * 0.35).normalized()
			if is_on_floor():
				velocity.y = 6.2
		velocity.x = lerpf(velocity.x, push.x * move_speed, delta * 7.0)
		velocity.z = lerpf(velocity.z, push.z * move_speed, delta * 7.0)
	else:
		var adv := 0.55 if dist > 20.0 else (-0.42 if dist < 6.0 else 0.0)
		var spd := move_speed * (0.40 if _is_crouching else 0.82)
		var wish := (fwd * adv + right * _strafe_dir).normalized()
		velocity.x = lerpf(velocity.x, wish.x * spd, delta * 8.0)
		velocity.z = lerpf(velocity.z, wish.z * spd, delta * 8.0)

	move_and_slide()

	var spd_ratio := clampf(Vector2(velocity.x, velocity.z).length() / move_speed, 0.0, 1.0)
	var sw := sin(_t * 10.5) * 0.58 * spd_ratio
	if is_instance_valid(_leg_l):
		_leg_l.rotation.x = sw
		_leg_r.rotation.x = -sw

	# Balanced firing so the player has intense gunfights without dying cheaply!
	if has_los and dist < 52.0:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = _rng.randf_range(1.15, 1.95) if kind != 1 else _rng.randf_range(1.85, 2.75)
			_fire_at_player(eye_to, dist)


func _process_parkour_runner(delta: float) -> void:
	if _jump_cd > 0.0:
		_jump_cd -= delta

	# 1. During 5-4-3-2-1 Countdown, hop excitedly at the starting line!
	var cd: float = float(world.get("race_countdown"))
	if cd > 0.0:
		var hop := absf(sin(_t * 6.5 + float(runner_idx) * 1.1)) * 0.32
		_root.position.y = hop
		_root.rotation.y = PI
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

	var wps: Array = world.get("race_waypoints")
	if wps == null or wps.is_empty():
		return

	wp_idx = clampi(wp_idx, 0, wps.size() - 1)
	var target: Vector3 = wps[wp_idx]
	var aim_pt := target + Vector3(lane_offset * 0.65, 0.0, 0.0)
	var to_t := aim_pt - global_position
	var flat := Vector3(to_t.x, 0.0, to_t.z)

	if flat.length() < 2.35 and wp_idx < wps.size() - 1:
		checkpoint_pos = wps[wp_idx]
		wp_idx += 1
		target = wps[wp_idx]
		aim_pt = target + Vector3(lane_offset * 0.65, 0.0, 0.0)
		to_t = aim_pt - global_position
		flat = Vector3(to_t.x, 0.0, to_t.z)

	var dir := flat.normalized() if flat.length() > 0.05 else Vector3(0, 0, -1)
	var yaw := atan2(-dir.x, -dir.z)
	_root.rotation.y = lerp_angle(_root.rotation.y, yaw, minf(1.0, delta * 10.0))

	# Subtle competitive rubber-banding so the race stays intense all 350+ meters!
	var p_prog: float = maxf(0.0, float(world.kz_start_pad.z) - float(world.player_pos.z))
	race_progress_m = maxf(0.0, float(world.kz_start_pad.z) - global_position.z)
	var diff := p_prog - race_progress_m
	var rubber := clampf(1.0 + diff * 0.0045, 0.86, 1.24)
	var cur_spd := move_speed * rubber

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
		elif _jump_cd <= 0.0 and (to_t.y > 0.45 or flat.length() > 4.2 or _rng.randf() < 0.04):
			velocity.y = 9.2 + clampf(to_t.y * 1.4, 0.0, 4.5)
			_jump_cd = _rng.randf_range(0.55, 1.05)

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
	var muzzle := global_position + Vector3(0, 1.15 if _is_crouching else 1.42, 0) + (_root.global_transform.basis.z * 0.55)
	var spread := 0.55 + clampf(dist * 0.012, 0.0, 0.45)
	var aim_error := Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-0.36, 0.36), _rng.randf_range(-spread, spread))
	var dir := ((target_pos + aim_error) - muzzle).normalized()
	var dmg := 13.0 if kind == 1 else 7.5
	var spd := 32.0 if kind == 1 else 24.0
	world.spawn_enemy_orb(muzzle, dir, spd, dmg, Color("ffd166"))


func apply_hit(dmg: float, hit_pos: Vector3, knockback: Vector3, head_mult: float = 3.2) -> Dictionary:
	if _dead or is_runner:
		return {"killed": false, "headshot": false, "dmg": 0.0}

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
	world.add_child(rag)
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
