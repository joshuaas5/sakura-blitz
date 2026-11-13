class_name WeaponRig
extends Node3D
## Call of Duty: Black Ops 2 + CS:GO + Roblox VIP 3D Sculpted Viewmodel Rig & Multi-Stage Animation Engine.
## Features:
## - True PBR Metallic & Anodized Specular Viewmodel Materials (_vm_mat) with high-detail cylindrical barrels,
##   fluted sniper shroud, Picatinny rails, holographic sights, curved 7-segment Karambit tiger-claw blade,
##   Torus finger ring, physics-swinging weapon charms, and articulated Left & Right 3D Tactical Hands!
## - Sensational Multi-Stage Keyframed + Spring Animations:
##   * KARAMBIT [4]: CS:GO 360° Index-Finger Ring Draw Spin, 3-Hit Combo (Diagonal Cleave -> Reverse Backhand ->
##     360° Tornado Spin Slash) with 3D glowing slash-arc ribbons, Two-Handed Heavy Overhead Lunge Stab (RMB),
##     and Continuous Freestyle Finger-Spin Inspect ([F])!
##   * FIREARMS [1-3]: Reciprocating Bolt/Slide Blowback on every shot, Spinning 3D Brass Shell Ejection,
##     4-Phase Tactical Reload ([R]: Magazine Pull-Out -> Fresh Mag Insert -> Bolt/Slide Rack -> Ready),
##     and Two-Sided Skin Showcase Inspect ([F])!

signal weapon_changed(idx: int, wname: String, ammo: int, reserve: int)
signal ammo_updated(ammo: int, reserve: int, reloading: bool)
signal shot_fired(weapon_idx: int, kick_pitch: float, kick_yaw: float)
signal hit_registered(result: Dictionary, weapon_idx: int)

const WEAPON_SKINS := [
	{
		"name": "Sakura • Edição Atelier",
		"cost": 0,
		"primary": Color("477b79"),
		"secondary": Color("ba9469"),
		"accent": Color("d8b678"),
		"tracer": Color("ffd166"),
		"emit": 0.0,
		"metal": 0.72,
		"rough": 0.28,
		"rate_mult": 1.0,
		"dmg_mult": 1.0
	},
	{
		"name": "Ouro Imperial",
		"cost": 250,
		"primary": Color("ffbe0b"),
		"secondary": Color("181b22"),
		"accent": Color("fff1a8"),
		"tracer": Color("ffbe0b"),
		"emit": 0.24,
		"metal": 0.92,
		"rough": 0.16,
		"rate_mult": 1.0,
		"dmg_mult": 1.0
	},
	{
		"name": "Sakura • Laca Imperial",
		"cost": 450,
		"primary": Color("a14d63"),
		"secondary": Color("f3ddba"),
		"accent": Color("d8b678"),
		"tracer": Color("00f5d4"),
		"emit": 0.45,
		"metal": 0.65,
		"rough": 0.20,
		"rate_mult": 1.0,
		"dmg_mult": 1.0
	},
	{
		"name": "Brasa do Outono",
		"cost": 700,
		"primary": Color("ff4d29"),
		"secondary": Color("241519"),
		"accent": Color("ffd166"),
		"tracer": Color("ff5400"),
		"emit": 0.38,
		"metal": 0.78,
		"rough": 0.22,
		"rate_mult": 1.0,
		"dmg_mult": 1.0
	},
	{
		"name": "Porcelana da Aurora",
		"cost": 1200,
		"primary": Color("e0fbfc"),
		"secondary": Color("234664"),
		"accent": Color("d9b36f"),
		"tracer": Color("00f5d4"),
		"emit": 0.52,
		"metal": 0.95,
		"rough": 0.12,
		"rate_mult": 1.0,
		"dmg_mult": 1.0
	}
]

const CHAR_SKINS := [
	{
		"name": "Explorador Sakura",
		"cost": 0,
		"sleeve": Color("93465b"),
		"glove": Color("735242"),
		"speed_bonus": 0.0
	},
	{
		"name": "Guardião do Jardim",
		"cost": 300,
		"sleeve": Color("738366"),
		"glove": Color("a8515a"),
		"speed_bonus": 0.0
	},
	{
		"name": "Correio das Nuvens",
		"cost": 500,
		"sleeve": Color("3e747a"),
		"glove": Color("d9ac62"),
		"speed_bonus": 0.0
	},
	{
		"name": "Explorador Imperial",
		"cost": 950,
		"sleeve": Color("ffbe0b"),
		"glove": Color("c92a42"),
		"speed_bonus": 0.0
	}
]

const WEAPONS := WeaponCatalog.DEFINITIONS

var world: SakuraWorld
var cam: Camera3D
var current_idx := 0
var prev_idx := 0
var ammo: Array = []
var reserve: Array = []
var weapon_levels: Array = []
var active_skin_idx := 0
var active_char_skin_idx := 0

var fire_cd := 0.0
var reload_timer := 0.0
var reload_duration := 1.15
var is_reloading := false
var ads_alpha := 0.0
var want_ads := false
var inspect_timer := 0.0
var inspect_duration := 1.45
var _draw_timer := 0.0
var _draw_duration := 0.52

# Multi-Stage Melee & Bolt Animation State
var _melee_anim_t := 0.0
var _melee_anim_dur := 0.38
var _melee_combo := 0
var _melee_heavy := false
var _bolt_kick := 0.0
var _charm_angle := 0.0
var _charm_vel := 0.0

var _pivot: Node3D
var _gun_models: Array[Node3D] = []
var _mag_nodes: Array[Node3D] = []
var _mag_rest_pos: Array[Vector3] = []
var _bolt_nodes: Array[Node3D] = []
var _bolt_rest_pos: Array[Vector3] = []
var _left_hands: Array[Node3D] = []
var _left_hand_rest: Array[Vector3] = []
var _charm_nodes: Array[Node3D] = []
var _karambit_ring_pivot: Node3D
var _slash_fx_root: Node3D
var _slash_fx_timer := 0.0

var _finish_material_cache := {}
var _outfit_material_cache := {}

var _skin_parts_primary: Array[MeshInstance3D] = []
var _skin_parts_secondary: Array[MeshInstance3D] = []
var _skin_parts_accent: Array[MeshInstance3D] = []
var _sleeve_parts: Array[MeshInstance3D] = []
var _glove_parts: Array[MeshInstance3D] = []

var suppressor_enabled: Array = []
var _suppressor_meshes: Array[Node3D] = []

var _muzzle_flash: Node3D
var _muzzle_light: OmniLight3D
var _flash_timer := 0.0
var _recoil_z := 0.0
var _recoil_pitch := 0.0
var _recoil_roll := 0.0
var _sway := Vector2.ZERO
var _bob_t := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	for w in WEAPONS:
		ammo.append(int(w.mag))
		reserve.append(int(w.reserve))
		weapon_levels.append(1)
		suppressor_enabled.append(false)
	for parts in [_mag_nodes, _bolt_nodes, _left_hands, _charm_nodes, _suppressor_meshes]:
		parts.resize(WEAPONS.size())
	for rests in [_mag_rest_pos, _bolt_rest_pos, _left_hand_rest]:
		rests.resize(WEAPONS.size())
		rests.fill(Vector3.ZERO)


func setup(w: SakuraWorld, camera: Camera3D) -> void:
	world = w
	cam = camera
	_rng.randomize()

	_pivot = Node3D.new()
	_pivot.position = Vector3(0.22, -0.20, -0.42)
	add_child(_pivot)

	for i in WEAPONS.size():
		_gun_models.append(_build_karambit() if bool(WEAPONS[i].melee) else ImportedWeapon.build(self, i))
	for m in _gun_models:
		_pivot.add_child(m)

	for i in WeaponCatalog.FIREARMS:
		var tip := ImportedWeapon.tip_for(i)
		var suppressor := ImportedWeapon.attachment(_gun_models[i], "Suppressor_West", tip)
		suppressor.visible = false
		_suppressor_meshes[i] = suppressor
	# 3D Starburst Muzzle Flash
	_muzzle_flash = Node3D.new()
	_muzzle_flash.position = Vector3(0, 0.04, -0.62)
	_muzzle_flash.visible = false
	_pivot.add_child(_muzzle_flash)
	for i in 4:
		var q := _box(_muzzle_flash, Vector3.ZERO, Vector3(0.22, 0.032, 0.032), Color("ffe89e"), 3.8, true)
		q.rotation.z = i * PI / 4.0
	_cyl(_muzzle_flash, Vector3(0, 0, -0.07), 0.008, 0.038, 0.18, Color("ffffff"), 8, 4.2, true, Vector3(PI * 0.5, 0, 0))

	_muzzle_light = OmniLight3D.new()
	_muzzle_light.light_color = Color("ffd166")
	_muzzle_light.light_energy = 0.0
	_muzzle_light.omni_range = 5.5
	_muzzle_light.position = Vector3(0, 0.04, -0.62)
	_pivot.add_child(_muzzle_light)

	# 3D Glowing Slash Ribbon Trail for Karambit Attacks
	_slash_fx_root = Node3D.new()
	_slash_fx_root.position = Vector3(0.0, -0.02, -0.48)
	_slash_fx_root.visible = false
	add_child(_slash_fx_root)
	_build_slash_ribbon()

	select_weapon(0, true)


# ---------------------------------------------------------------- Specular PBR Viewmodel Material & Sculpted Primitives

func _vm_mat(col: Color, emit: float = 0.0, unshaded: bool = false, metal: float = 0.68, rough: float = 0.26) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal * 0.65
	m.roughness = maxf(rough, 0.32)
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _register_role(mi: MeshInstance3D, role: String) -> void:
	match role:
		"primary":
			_skin_parts_primary.append(mi)
		"secondary":
			_skin_parts_secondary.append(mi)
		"accent":
			_skin_parts_accent.append(mi)
		"sleeve":
			_sleeve_parts.append(mi)
		"glove":
			_glove_parts.append(mi)


func _box(parent: Node3D, pos: Vector3, sz: Vector3, col: Color, emit: float = 0.0, unshaded: bool = false, role: String = "", rot: Vector3 = Vector3.ZERO, metal: float = 0.68, rough: float = 0.26) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = _vm_mat(col, emit, unshaded, metal, rough)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_register_role(mi, role)
	return mi


func _cyl(parent: Node3D, pos: Vector3, r_top: float, r_bot: float, h: float, col: Color, segs: int = 14, emit: float = 0.0, unshaded: bool = false, rot: Vector3 = Vector3.ZERO, role: String = "", metal: float = 0.78, rough: float = 0.22) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _vm_mat(col, emit, unshaded, metal, rough)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_register_role(mi, role)
	return mi


func _prism(parent: Node3D, pos: Vector3, sz: Vector3, col: Color, emit: float = 0.0, role: String = "", rot: Vector3 = Vector3.ZERO, left_to_right: float = 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = sz
	pm.left_to_right = left_to_right
	mi.mesh = pm
	mi.material_override = _vm_mat(col, emit, false, 0.85, 0.18)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_register_role(mi, role)
	return mi


func _torus(parent: Node3D, pos: Vector3, r_in: float, r_out: float, col: Color, emit: float = 0.0, role: String = "", rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	tm.rings = 18
	tm.ring_segments = 12
	mi.mesh = tm
	mi.material_override = _vm_mat(col, emit, false, 0.90, 0.15)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_register_role(mi, role)
	return mi


func _build_slash_ribbon() -> void:
	# Multi-segment curved glowing blade arc for Karambit slashes
	for i in 9:
		var u := float(i - 4) / 4.0
		var ang := u * 0.95
		var seg := _box(
			_slash_fx_root,
			Vector3(sin(ang) * 0.28, -cos(ang) * 0.06, -cos(ang) * 0.08),
			Vector3(0.085, 0.012 * (1.15 - absf(u) * 0.65), 0.045),
			Color("00f5d4") if i % 2 == 0 else Color("ff2a6d"),
			3.2,
			true,
			"",
			Vector3(0.0, 0.0, -ang * 0.6)
		)
		seg.name = "slash_%d" % i


# ---------------------------------------------------------------- Articulated 3D Tactical Hands & Weapon Charm

func _build_articulated_hand(parent: Node3D, pos: Vector3, rot: Vector3, is_left: bool) -> Node3D:
	var h := Node3D.new()
	h.position = pos
	h.rotation = rot
	parent.add_child(h)

	var s_sign := -1.0 if is_left else 1.0
	var sleeve_col := Color("232730")
	var glove_col := Color("16181f")
	var skin_col := Color("d9aa86")
	var armor_col := Color("343a46")
	var gold_col := Color("daa854")

	# Forearm Jacket Sleeve + Ribbed Wrist Cuff
	_cyl(h, Vector3(0.0, -0.02, 0.16), 0.044, 0.052, 0.24, sleeve_col, 12, 0.0, false, Vector3(PI * 0.5, 0, 0), "sleeve", 0.15, 0.75)
	_cyl(h, Vector3(0.0, -0.015, 0.045), 0.041, 0.044, 0.045, armor_col, 12, 0.0, false, Vector3(PI * 0.5, 0, 0), "glove", 0.45, 0.45)

	# Tactical Chrono-Watch on Left Wrist
	if is_left:
		_box(h, Vector3(0.0, 0.028, 0.055), Vector3(0.036, 0.012, 0.028), gold_col, 0.2)
		_box(h, Vector3(0.0, 0.035, 0.055), Vector3(0.026, 0.004, 0.020), Color("00f5d4"), 2.2, true)

	# Tactical Glove Palm + Carbon-Fiber Knuckle Plate
	_box(h, Vector3(0.0, -0.01, -0.01), Vector3(0.074, 0.036, 0.078), glove_col, 0.0, false, "glove", Vector3.ZERO, 0.30, 0.55)
	_box(h, Vector3(0.0, 0.012, -0.015), Vector3(0.068, 0.012, 0.042), armor_col, 0.1, false, "accent", Vector3.ZERO, 0.75, 0.25)

	# 4 Sculpted Curled Fingers (Index, Middle, Ring, Pinky) with exposed fingertips
	for f_i in 4:
		var fx := (float(f_i) - 1.5) * 0.017 * s_sign
		var f_len := 0.042 if (f_i == 1 or f_i == 2) else 0.036
		_box(h, Vector3(fx, -0.006, -0.058), Vector3(0.014, 0.016, f_len), glove_col, 0.0, false, "glove", Vector3(0.35, 0, 0), 0.3, 0.5)
		_box(h, Vector3(fx, -0.022, -0.078), Vector3(0.013, 0.014, 0.022), skin_col, 0.0, false, "", Vector3(0.85, 0, 0), 0.1, 0.65)

	# Articulated Opposable Thumb
	_box(h, Vector3(-s_sign * 0.042, 0.004, -0.022), Vector3(0.018, 0.018, 0.044), glove_col, 0.0, false, "glove", Vector3(0.2, s_sign * 0.48, 0.25), 0.3, 0.5)
	_box(h, Vector3(-s_sign * 0.052, 0.012, -0.048), Vector3(0.015, 0.015, 0.022), skin_col, 0.0, false, "", Vector3(0.3, s_sign * 0.65, 0.2), 0.1, 0.65)
	return h


func _build_weapon_charm(parent: Node3D, attach_pos: Vector3) -> Node3D:
	var charm_pivot := Node3D.new()
	charm_pivot.position = attach_pos
	parent.add_child(charm_pivot)
	_torus(charm_pivot, Vector3.ZERO, 0.005, 0.009, Color("ffd166"), 0.5, "accent", Vector3(0, PI * 0.5, 0))
	_cyl(charm_pivot, Vector3(0, -0.018, 0), 0.003, 0.003, 0.022, Color("daa854"), 8, 0.3)
	_box(charm_pivot, Vector3(0, -0.034, 0), Vector3(0.016, 0.018, 0.008), Color("e63946"), 1.2, false, "accent", Vector3(0, 0, PI * 0.25))
	return charm_pivot


# ---------------------------------------------------------------- [4] KARAMBIT TIGER-CLAW (Smooth SurfaceTool Curved Claw + Finger-Ring Pivot)

func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _build_smooth_karambit_handle_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 14
	var rings := []
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		var ang := lerpf(0.10, 0.58, u)
		var cy := lerpf(0.020, 0.116, u)
		var cz := lerpf(-0.008, -0.046, u) - sin(u * PI) * 0.010
		# 3 ergonomic finger grooves along the front edge
		var groove := sin(u * PI * 3.0) * 0.0035
		var hw := 0.0115
		var hd_back := 0.016
		var hd_front := 0.017 - groove
		var n_dir := Vector3(0, sin(ang), -cos(ang)).normalized()
		var back_c := Vector3(0, cy, cz) - n_dir * hd_back
		var front_c := Vector3(0, cy, cz) + n_dir * hd_front
		rings.append([
			back_c + Vector3(-hw, 0, 0),
			back_c + Vector3(hw, 0, 0),
			front_c + Vector3(hw * 0.88, 0, 0),
			front_c + Vector3(-hw * 0.88, 0, 0)
		])
	for i in steps:
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		for k in 4:
			var kn := (k + 1) % 4
			_add_quad(st, r0[k], r1[k], r1[kn], r0[kn])
	st.generate_normals()
	return st.commit()


func _build_smooth_karambit_blade_mesh(is_edge_bevel: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 22
	var rings := []
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		# Smooth circular tiger-claw arc sweeping up, forward, and hooking downward to a needle tip
		var theta := lerpf(0.45, 2.28, u)
		var arc_r := 0.108
		var spine_y := 0.068 + sin(theta) * arc_r * 1.05
		var spine_z := -0.125 + cos(theta) * arc_r
		var rad_in := Vector3(0, -sin(theta), -cos(theta)).normalized()
		var taper := 1.0 - pow(u, 1.45)
		var blade_w := maxf(0.001, 0.036 * taper)
		var half_t := maxf(0.0004, 0.0052 * (1.0 - u * 0.88))

		var spine_pt := Vector3(0, spine_y, spine_z)
		var mid_pt := spine_pt + rad_in * (blade_w * 0.52)
		var edge_pt := spine_pt + rad_in * blade_w

		if not is_edge_bevel:
			# Upper spine & fuller body (from spine to mid-ridge)
			rings.append([
				spine_pt + Vector3(-half_t * 0.85, 0, 0),
				spine_pt + Vector3(half_t * 0.85, 0, 0),
				mid_pt + Vector3(half_t, 0, 0),
				mid_pt + Vector3(-half_t, 0, 0)
			])
		else:
			# Razor-sharp inner bevel (from mid-ridge tapering to 0-width cutting edge!)
			rings.append([
				mid_pt + Vector3(-half_t * 0.95, 0, 0),
				mid_pt + Vector3(half_t * 0.95, 0, 0),
				edge_pt + Vector3(0.0002, 0, 0),
				edge_pt + Vector3(-0.0002, 0, 0)
			])
	for i in steps:
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		for k in 4:
			var kn := (k + 1) % 4
			_add_quad(st, r0[k], r1[k], r1[kn], r0[kn])
	st.generate_normals()
	return st.commit()


func _build_karambit() -> Node3D:
	var g := Node3D.new()
	var handle_col := Color("181a22")
	var crimson := Color("e63956")
	var edge_silver := Color("f0f6fc")
	var gold := Color("ffd166")

	# Left Parrying / Parkour Balance Hand (visible on the left side in martial-arts guard!)
	var lh := _build_articulated_hand(g, Vector3(-0.24, -0.075, -0.05), Vector3(0.28, 0.42, -0.32), true)
	_left_hands[3] = lh
	_left_hand_rest[3] = lh.position

	# Right Knife-Wielding Hand
	_build_articulated_hand(g, Vector3(0.02, -0.055, 0.04), Vector3(0.15, -0.18, 0.12), false)

	# KARAMBIT FINGER-RING PIVOT (Anchored right at the Index Finger so 360° spins rotate around the ring!)
	_karambit_ring_pivot = Node3D.new()
	_karambit_ring_pivot.position = Vector3(0.0, -0.015, -0.035)
	g.add_child(_karambit_ring_pivot)

	# 1. Iconic Circular Index-Finger Retention Ring (TorusMesh) + Pommel Lock
	_torus(_karambit_ring_pivot, Vector3.ZERO, 0.015, 0.023, gold, 0.65, "accent", Vector3(0, 0, PI * 0.5))
	_box(_karambit_ring_pivot, Vector3(0, 0.018, -0.007), Vector3(0.018, 0.016, 0.020), gold, 0.4, false, "accent")

	# 2. Smooth Continuous Sculpted Ergonomic Handle + Gold Torx Rivets + Bolster Guard
	var h_mi := MeshInstance3D.new()
	h_mi.mesh = _build_smooth_karambit_handle_mesh()
	h_mi.material_override = _vm_mat(handle_col, 0.0, false, 0.35, 0.42)
	h_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_karambit_ring_pivot.add_child(h_mi)
	_register_role(h_mi, "secondary")

	for r_i in 3:
		var ru := float(r_i + 1) * 0.25
		_cyl(_karambit_ring_pivot, Vector3(0, lerpf(0.022, 0.112, ru), lerpf(-0.010, -0.045, ru)), 0.0045, 0.0045, 0.025, gold, 10, 0.4, false, Vector3(0, 0, PI * 0.5), "accent")

	_box(_karambit_ring_pivot, Vector3(0, 0.118, -0.048), Vector3(0.026, 0.015, 0.044), gold, 0.5, false, "accent", Vector3(0.55, 0, 0))

	# 3. Smooth Continuous Curved Tiger-Claw Blade Spine + Razor-Sharp Inner Bevel Edge!
	var blade_spine := MeshInstance3D.new()
	blade_spine.mesh = _build_smooth_karambit_blade_mesh(false)
	blade_spine.material_override = _vm_mat(crimson, 0.55, false, 0.92, 0.14)
	blade_spine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_karambit_ring_pivot.add_child(blade_spine)
	_register_role(blade_spine, "primary")

	var blade_edge := MeshInstance3D.new()
	blade_edge.mesh = _build_smooth_karambit_blade_mesh(true)
	blade_edge.material_override = _vm_mat(edge_silver, 0.85, false, 0.96, 0.10)
	blade_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_karambit_ring_pivot.add_child(blade_edge)
	_register_role(blade_edge, "accent")

	return g


# ---------------------------------------------------------------- Skins, Upgrades & Selection

func apply_weapon_skin(skin_idx: int, animate: bool = true) -> void:
	active_skin_idx = clampi(skin_idx, 0, WEAPON_SKINS.size() - 1)
	var sk: Dictionary = WEAPON_SKINS[active_skin_idx]
	var em := float(sk.emit)
	var met := float(sk.get("metal", 0.75))
	var rgh := float(sk.get("rough", 0.22))
	if not _finish_material_cache.has(active_skin_idx):
		var primary: Material = _vm_mat(sk.primary, em, false, met, rgh)
		if active_skin_idx > 0:
			var finish := ShaderMaterial.new()
			finish.shader = preload("res://assets/shaders/weapon_finish.gdshader")
			finish.set_shader_parameter("primary_color", sk.primary)
			finish.set_shader_parameter("accent_color", sk.accent)
			finish.set_shader_parameter("finish", active_skin_idx)
			finish.set_shader_parameter("lacquer", load("res://assets/textures/cozy/aurora_porcelain.png") if active_skin_idx == 4 else preload("res://assets/textures/cozy/sakura_lacquer.png"))
			primary = finish
		_finish_material_cache[active_skin_idx] = [primary, _vm_mat(sk.secondary, em * 0.25, false, met * 0.7, rgh + 0.1), _vm_mat(sk.accent, em * 0.3 + 0.12, false, 0.5, 0.35)]
	var materials: Array = _finish_material_cache[active_skin_idx]
	for mi in _skin_parts_primary:
		mi.material_override = materials[0]
	for mi in _skin_parts_secondary:
		mi.material_override = materials[1]
	for mi in _skin_parts_accent:
		mi.material_override = materials[2]
	if animate:
		trigger_inspect()


func apply_char_skin(c_idx: int) -> void:
	active_char_skin_idx = clampi(c_idx, 0, CHAR_SKINS.size() - 1)
	var cs: Dictionary = CHAR_SKINS[active_char_skin_idx]
	if not _outfit_material_cache.has(active_char_skin_idx):
		_outfit_material_cache[active_char_skin_idx] = [_vm_mat(cs.sleeve, 0.06, false, 0.2, 0.65), _vm_mat(cs.glove, 0.08, false, 0.25, 0.48)]
	for mi in _sleeve_parts:
		mi.material_override = _outfit_material_cache[active_char_skin_idx][0]
	for mi in _glove_parts:
		mi.material_override = _outfit_material_cache[active_char_skin_idx][1]
	trigger_inspect()


func max_mag_for(idx: int) -> int:
	return int(WEAPONS[idx].mag)


func upgrade_current_weapon() -> int:
	weapon_levels[current_idx] = mini(4, int(weapon_levels[current_idx]) + 1)
	refill_all_ammo()
	trigger_inspect()
	return int(weapon_levels[current_idx])


func select_weapon(idx: int, instant: bool = false) -> void:
	idx = posmod(idx, WEAPONS.size())
	if idx == current_idx and not instant:
		return
	prev_idx = current_idx
	current_idx = idx
	is_reloading = false
	reload_timer = 0.0
	want_ads = false
	ads_alpha = 0.0
	_melee_anim_t = 0.0
	_reset_subparts()
	for i in _gun_models.size():
		_gun_models[i].visible = (i == current_idx)
	_draw_duration = 0.58 if current_idx == 3 else 0.44
	_draw_timer = 0.0 if instant else _draw_duration
	_recoil_pitch = -0.22
	_charm_vel += 10.0
	if current_idx == 3:
		Sfx.play("double_jump", 1.18)
	else:
		Sfx.play("pickup", 1.05)
	var w: Dictionary = WEAPONS[current_idx]
	weapon_changed.emit(current_idx, str(w.name), int(ammo[current_idx]), int(reserve[current_idx]))
	ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), false)


func _reset_subparts() -> void:
	for i in WEAPONS.size():
		if is_instance_valid(_mag_nodes[i]):
			_mag_nodes[i].position = _mag_rest_pos[i]
			_mag_nodes[i].rotation = Vector3.ZERO
		if is_instance_valid(_bolt_nodes[i]):
			_bolt_nodes[i].position = _bolt_rest_pos[i]
			_bolt_nodes[i].rotation = Vector3.ZERO
		if is_instance_valid(_left_hands[i]):
			_left_hands[i].position = _left_hand_rest[i]
	if is_instance_valid(_karambit_ring_pivot):
		_karambit_ring_pivot.position = Vector3(0.0, -0.015, -0.035)
		_karambit_ring_pivot.rotation = Vector3.ZERO


func quick_switch() -> void:
	select_weapon(prev_idx if prev_idx != current_idx else 3)


func trigger_inspect() -> void:
	inspect_duration = 1.60 if current_idx == 3 else 1.35
	inspect_timer = inspect_duration
	Sfx.play("double_jump", 1.25, -5.0)


func speed_multiplier() -> float:
	var w: Dictionary = WEAPONS[current_idx]
	var cs: Dictionary = CHAR_SKINS[active_char_skin_idx]
	var base := float(w.speed_mult) + float(cs.speed_bonus)
	if ads_alpha > 0.2 and not bool(w.melee):
		base *= 0.76
	return base


func is_scoped_in() -> bool:
	var w: Dictionary = WEAPONS[current_idx]
	return bool(w.scoped) and ads_alpha > 0.75 and not is_reloading


func add_look_sway(mouse_delta: Vector2) -> void:
	var k := 0.0004 if ads_alpha > 0.5 else 0.0011
	_sway.x = clampf(_sway.x - mouse_delta.x * k, -0.055, 0.055)
	_sway.y = clampf(_sway.y + mouse_delta.y * k, -0.055, 0.055)
	_charm_vel += clampf(mouse_delta.x * 0.14, -8.0, 8.0)


func start_reload() -> void:
	var w: Dictionary = WEAPONS[current_idx]
	var max_m := max_mag_for(current_idx)
	if bool(w.melee) or is_reloading or int(ammo[current_idx]) >= max_m or int(reserve[current_idx]) <= 0:
		return
	is_reloading = true
	want_ads = false
	var lvl_boost := 1.0
	reload_duration = float(w.get("reload", 1.20)) * lvl_boost
	reload_timer = reload_duration
	Sfx.play("reload")
	ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), true)


func grant_kill_ammo_siphon(bonus: int = 8) -> void:
	var w: Dictionary = WEAPONS[current_idx]
	if bool(w.melee):
		return
	bonus = mini(bonus, int(w.get("siphon", bonus)))
	var max_m := max_mag_for(current_idx)
	ammo[current_idx] = mini(max_m, int(ammo[current_idx]) + bonus)
	reserve[current_idx] = int(reserve[current_idx]) + bonus
	ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), is_reloading)


# ---------------------------------------------------------------- Combat Firing, Karambit 3-Combo & Brass Shell Ejection

func _spawn_ejected_brass() -> void:
	if not is_instance_valid(world) or not is_instance_valid(cam) or is_scoped_in():
		return
	var eject_world := _pivot.global_position + cam.global_transform.basis * Vector3(0.06, 0.05, -0.08)
	var b := world.cyl(world, eject_world, 0.008, 0.009, 0.034, Color("ffd166"), 8, 1.2, false)
	var right := cam.global_transform.basis.x
	var up := cam.global_transform.basis.y
	var vel := right * _rng.randf_range(2.2, 3.4) + up * _rng.randf_range(1.6, 2.5)
	world.vfx_items.append({"node": b, "vel": vel, "grav": 14.0, "life": 0.42, "max_life": 0.42, "spin": true})


func _trigger_slash_ribbon(combo_step: int, is_heavy: bool) -> void:
	if not is_instance_valid(_slash_fx_root):
		return
	_slash_fx_root.visible = true
	_slash_fx_timer = 0.16 if not is_heavy else 0.24
	if is_heavy:
		_slash_fx_root.rotation = Vector3(0.35, 0.0, -0.82)
		_slash_fx_root.scale = Vector3(1.35, 1.35, 1.35)
	elif combo_step == 0:
		_slash_fx_root.rotation = Vector3(0.0, 0.0, -0.42)
		_slash_fx_root.scale = Vector3(1.1, 1.0, 1.0)
	elif combo_step == 1:
		_slash_fx_root.rotation = Vector3(0.0, PI, 0.38)
		_slash_fx_root.scale = Vector3(1.15, 1.0, 1.0)
	else:
		_slash_fx_root.rotation = Vector3(0.15, 0.0, 0.12)
		_slash_fx_root.scale = Vector3(1.3, 1.2, 1.2)


func try_fire(moving_speed: float, heavy_melee: bool = false) -> bool:
	if world.game_mode != SakuraWorld.MODE_COMBAT or world.combat_ready_time > 0 or world.combat_is_finished or is_reloading or fire_cd > 0.0:
		return false
	var w: Dictionary = WEAPONS[current_idx]
	var sk: Dictionary = WEAPON_SKINS[active_skin_idx]
	var lvl := clampi(int(weapon_levels[current_idx]), 1, 4)
	var lvl_dmg_mult := 1.0 + (lvl - 1) * 0.01

	# KARAMBIT 3-HIT SLASH COMBO (LMB) & TWO-HANDED HEAVY LUNGE STAB (RMB)
	if bool(w.melee):
		_melee_heavy = heavy_melee
		_melee_anim_dur = (0.52 if heavy_melee else 0.34) * float(sk.rate_mult)
		_melee_anim_t = _melee_anim_dur
		fire_cd = _melee_anim_dur * 0.92
		inspect_timer = 0.0
		_draw_timer = 0.0
		_trigger_slash_ribbon(_melee_combo, heavy_melee)
		if not heavy_melee:
			_melee_combo = (_melee_combo + 1) % 3
		Sfx.play("double_jump", 0.78 if heavy_melee else (1.12 + _melee_combo * 0.08))
		shot_fired.emit(current_idx, 0.028 if heavy_melee else 0.012, (-0.018 if _melee_combo == 1 else 0.018))

		var space := world.get_world_3d().direct_space_state
		var origin := cam.global_position
		var fwd := -cam.global_transform.basis.z
		var query := PhysicsRayQueryParameters3D.create(origin, origin + fwd * 4.2, 1 | 4 | 8)
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			var collider: Object = hit.collider
			if collider is EnemyBot:
				var bot := collider as EnemyBot
				var dmg := (185.0 if heavy_melee else 110.0) * float(sk.dmg_mult) * lvl_dmg_mult
				var res := bot.apply_hit(dmg, hit.position, fwd * 8.5)
				if float(res.dmg) <= 0:
					return true
				world.spawn_voxel_burst(hit.position, Color("e63956"), 10)
				world.spawn_damage_number(hit.position, int(res.dmg), bool(res.headshot))
				Sfx.play("headshot" if bool(res.killed) else "hitmarker")
				res["pos"] = hit.position
				res["weapon_name"] = str(w.name)
				res["bot_name"] = bot.bot_name
				hit_registered.emit(res, current_idx)
			else:
				world.surface_impact(hit.position, hit.normal)
		return true

	if int(ammo[current_idx]) <= 0:
		start_reload()
		return false

	ammo[current_idx] = int(ammo[current_idx]) - 1
	fire_cd = float(w.rate)
	inspect_timer = 0.0
	_draw_timer = 0.0
	ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), false)

	var tracer_col: Color = sk.tracer if active_skin_idx > 0 else (w.color as Color)

	# Audio, Starburst Muzzle Flash, Reciprocating Bolt/Slide Kick & Brass Ejection
	Sfx.play(str(w.sfx), _rng.randf_range(0.97, 1.04), -9.0 if suppressor_enabled[current_idx] else -4.0)
	if world.combat_audio != null:
		world.combat_audio.noise(cam.global_position - Vector3.UP, null, 0.35 if suppressor_enabled[current_idx] else 1.0)
	_flash_timer = 0.048
	_muzzle_flash.position = ImportedWeapon.tip_for(current_idx)
	if suppressor_enabled[current_idx]:
		_muzzle_flash.position.z -= 0.14
	_muzzle_light.position = _muzzle_flash.position
	_muzzle_flash.visible = not is_scoped_in()
	_muzzle_flash.rotation.z = _rng.randf() * TAU
	_muzzle_light.light_color = tracer_col
	_muzzle_light.light_energy = 2.6
	_bolt_kick = 1.0
	_charm_vel += _rng.randf_range(9.0, 15.0)
	_spawn_ejected_brass()

	# Viewmodel & Camera Recoil Spring
	var ads_damp := 0.50 if ads_alpha > 0.5 else 1.0
	var stab_mult := 1.0
	_recoil_z = float(w.recoil_kick) * ads_damp * stab_mult
	_recoil_pitch = float(w.recoil_up) * ads_damp * stab_mult
	_recoil_roll = _rng.randf_range(-0.045, 0.045) * ads_damp
	var cam_kick_pitch := float(w.recoil_up) * (0.38 if ads_alpha > 0.5 else 0.60) * stab_mult
	var cam_kick_yaw := _rng.randf_range(-0.007, 0.007)
	shot_fired.emit(current_idx, cam_kick_pitch, cam_kick_yaw)

	# Hitscan Raycast with ADS vs Hipfire accuracy + Movement Inaccuracy
	var space := world.get_world_3d().direct_space_state
	var origin := cam.global_position
	var fwd := -cam.global_transform.basis.z
	var right := cam.global_transform.basis.x
	var up := cam.global_transform.basis.y
	var muzzle_world := _muzzle_flash.global_position

	var base_spread := lerpf(float(w.spread_hip), float(w.spread_ads), ads_alpha) * stab_mult
	var move_penalty := clampf((moving_speed - 1.5) / 6.0, 0.0, 1.0) * (0.030 if current_idx == 1 else 0.016) * (1.0 - ads_alpha * 0.68)
	var spread := base_spread + move_penalty

	# Resolve every pellet before applying damage: one victim produces one damage/kill event.
	var pellets := int(w.get("pellets", 1))
	var phase := _rng.randf() * TAU
	var victims: Dictionary = {}
	var targets: Dictionary = {}
	for pellet in pellets:
		var scatter := Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread))
		if pellets > 1:
			var radius := sqrt(float(pellet) / float(pellets - 1)) * spread
			scatter = Vector2.from_angle(phase + pellet * 2.399963) * radius
		var dir := (fwd + right * scatter.x + up * scatter.y).normalized()
		var end_pt := origin + dir * float(w.get("range", 115.0))
		var query := PhysicsRayQueryParameters3D.create(origin, end_pt, 1 | 4 | 8)
		var hit := space.intersect_ray(query)
		var tracer_end := end_pt
		if not hit.is_empty():
			tracer_end = hit.position
			var collider: Object = hit.collider
			if collider is EnemyBot:
				var bot := collider as EnemyBot
				var head: bool = hit.position.y - bot.global_position.y >= bot.head_y_min
				var damage := WeaponCatalog.damage_at_distance(current_idx, origin.distance_to(hit.position)) * float(sk.dmg_mult) * lvl_dmg_mult
				if head:
					damage *= float(w.head_mult)
				if not victims.has(bot):
					victims[bot] = {"damage": 0.0, "heads": 0, "count": 0, "head_pos": hit.position, "body_pos": hit.position}
				var entry: Dictionary = victims[bot]
				entry.damage += damage
				entry.count += 1
				entry.heads += int(head)
				entry["head_pos" if head else "body_pos"] = hit.position
			elif collider is Node3D and (collider as Node3D).has_meta("is_target"):
				targets[collider] = hit.position
			elif pellet < 3:
				world.surface_impact(hit.position, hit.normal)
		if pellet < 3:
			world.spawn_tracer(muzzle_world if not is_scoped_in() else (origin + Vector3(0, -0.1, 0)), tracer_end, tracer_col, 0.045 if current_idx == 1 else 0.024)
	for victim in victims:
		var bot := victim as EnemyBot
		var entry: Dictionary = victims[victim]
		var hit_pos: Vector3 = entry.head_pos if entry.heads * 2 >= entry.count else entry.body_pos
		var kb := fwd * (8.5 if current_idx == 1 else 3.5) + Vector3(0, 1.5, 0)
		# Head multipliers are already included per pellet; never multiply the aggregate again.
		var res := bot.apply_hit(float(entry.damage), hit_pos, kb, 1.0)
		if float(res.dmg) <= 0:
			continue
		world.spawn_voxel_burst(hit_pos, Color("e63956") if bool(res.headshot) else tracer_col, 10 if bool(res.headshot) else 5)
		world.spawn_damage_number(hit_pos, int(res.dmg), bool(res.headshot))
		Sfx.play("headshot" if bool(res.headshot) else "hitmarker")
		res["pos"] = hit_pos
		res["weapon_name"] = str(w.name)
		res["bot_name"] = bot.bot_name
		hit_registered.emit(res, current_idx)
	for target in targets:
		world.hit_target_body(target as Node3D)
		Sfx.play("headshot")
		hit_registered.emit({"killed": true, "headshot": true, "dmg": 150.0, "pos": targets[target], "target": true}, current_idx)

	if int(ammo[current_idx]) <= 0:
		start_reload()
	return true


func refill_all_ammo() -> void:
	for i in WEAPONS.size():
		var w: Dictionary = WEAPONS[i]
		ammo[i] = max_mag_for(i)
		reserve[i] = int(w.reserve)
	ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), false)


# ---------------------------------------------------------------- Multi-Stage Viewmodel Animation Engine

func tick_viewmodel(delta: float, h_speed: float, on_floor: bool, sprinting: bool, crouching: bool) -> void:
	if fire_cd > 0.0:
		fire_cd -= delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_muzzle_flash.visible = false
			_muzzle_light.light_energy = 0.0
	if _slash_fx_timer > 0.0:
		_slash_fx_timer -= delta
		if _slash_fx_timer <= 0.0 and is_instance_valid(_slash_fx_root):
			_slash_fx_root.visible = false
	if _draw_timer > 0.0:
		_draw_timer = maxf(0.0, _draw_timer - delta)
	if _melee_anim_t > 0.0:
		_melee_anim_t = maxf(0.0, _melee_anim_t - delta)
	if inspect_timer > 0.0:
		if want_ads or ads_alpha > 0.1 or _melee_anim_t > 0.0:
			inspect_timer = 0.0
		else:
			inspect_timer = maxf(0.0, inspect_timer - delta)

	var w: Dictionary = WEAPONS[current_idx]

	# Smooth ADS transition (Right-Click Sight!)
	var can_ads := want_ads and not is_reloading and not sprinting and not bool(w.melee)
	var prev_ads := ads_alpha
	ads_alpha = move_toward(ads_alpha, 1.0 if can_ads else 0.0, delta * 9.8)
	if prev_ads < 0.1 and ads_alpha >= 0.1:
		Sfx.play("dash", 1.15, -10.0)

	# Hide 3D sniper model when looking through full-screen scope
	_gun_models[1].visible = (current_idx == 1) and not is_scoped_in()

	# Physics-driven Weapon Charm Pendulum
	var charm_accel := -28.0 * _charm_angle - 5.5 * _charm_vel + sin(_bob_t * 2.0) * clampf(h_speed, 0.0, 8.0) * 1.6
	_charm_vel += charm_accel * delta
	_charm_angle = clampf(_charm_angle + _charm_vel * delta, -0.75, 0.75)
	if is_instance_valid(_charm_nodes[current_idx]):
		_charm_nodes[current_idx].rotation = Vector3(_charm_angle * 0.6, 0.0, _charm_angle)

	# Reciprocating Bolt / Deagle Slide Return Spring
	_bolt_kick = move_toward(_bolt_kick, 0.0, delta * (4.2 if current_idx == 1 else 14.0))
	if not is_reloading and is_instance_valid(_bolt_nodes[current_idx]):
		var b_rest := _bolt_rest_pos[current_idx]
		var slide_dist := 0.068 if current_idx == 1 else 0.052
		_bolt_nodes[current_idx].position = b_rest + Vector3(0, 0, slide_dist * _bolt_kick)
		if current_idx == 1:
			_bolt_nodes[current_idx].rotation.z = -_bolt_kick * 0.85

	# 4-Phase Keyframed Tactical Reload (Magazine Pull-Out -> Fresh Mag Slap -> Bolt Rack -> Ready!)
	if is_reloading:
		reload_timer -= delta
		var u := 1.0 - clampf(reload_timer / maxf(0.01, reload_duration), 0.0, 1.0)
		var mag_n := _mag_nodes[current_idx]
		var bolt_n := _bolt_nodes[current_idx]
		var lh_n := _left_hands[current_idx]
		if is_instance_valid(mag_n) and is_instance_valid(lh_n):
			var m_rest := _mag_rest_pos[current_idx]
			var lh_rest := _left_hand_rest[current_idx]
			if u < 0.28:
				# Phase 1: Left hand moves to grab magazine
				var p := u / 0.28
				lh_n.position = lh_rest.lerp(m_rest + Vector3(-0.02, -0.05, 0.02), p)
				mag_n.position = m_rest
			elif u < 0.56:
				# Phase 2: Magazine pulls down out of magwell and fresh magazine slides up in!
				var p := (u - 0.28) / 0.28
				var pull_curve := sin(p * PI)
				var drop_off := Vector3(-0.04, -0.22, 0.05) * pull_curve
				mag_n.position = m_rest + drop_off
				mag_n.rotation.x = pull_curve * 0.45
				lh_n.position = mag_n.position + Vector3(-0.02, -0.04, 0.02)
			elif u < 0.84:
				# Phase 3: Left hand reaches to bolt/slide and racks it back!
				var p := (u - 0.56) / 0.28
				mag_n.position = m_rest
				mag_n.rotation = Vector3.ZERO
				var rack_pull := sin(p * PI)
				if is_instance_valid(bolt_n):
					var b_rest := _bolt_rest_pos[current_idx]
					bolt_n.position = b_rest + Vector3(0, 0, 0.065 * rack_pull)
					lh_n.position = bolt_n.position + Vector3(-0.03, -0.02, 0.02)
			else:
				# Phase 4: Return hands & bolt to combat ready position
				var p := (u - 0.84) / 0.16
				mag_n.position = m_rest
				mag_n.rotation = Vector3.ZERO
				if is_instance_valid(bolt_n):
					bolt_n.position = _bolt_rest_pos[current_idx]
				lh_n.position = lh_n.position.lerp(lh_rest, p)

		if reload_timer <= 0.0:
			is_reloading = false
			_reset_subparts()
			var needed := max_mag_for(current_idx) - int(ammo[current_idx])
			var take := mini(needed, int(reserve[current_idx]))
			ammo[current_idx] = int(ammo[current_idx]) + take
			reserve[current_idx] = int(reserve[current_idx]) - take
			ammo_updated.emit(int(ammo[current_idx]), int(reserve[current_idx]), false)

	_recoil_z = lerpf(_recoil_z, 0.0, minf(1.0, delta * 15.0))
	_recoil_pitch = lerpf(_recoil_pitch, 0.0, minf(1.0, delta * 13.0))
	_recoil_roll = lerpf(_recoil_roll, 0.0, minf(1.0, delta * 14.0))
	_sway = _sway.lerp(Vector2.ZERO, minf(1.0, delta * 10.0))

	if on_floor and h_speed > 0.4:
		_bob_t += delta * minf(h_speed * 1.48, 11.5)
	var bob_scale := (0.20 if ads_alpha > 0.5 else 1.0) * clampf(h_speed / 6.0, 0.0, 1.25)
	var bob_x := sin(_bob_t) * 0.014 * bob_scale
	var bob_y := absf(cos(_bob_t)) * -0.012 * bob_scale

	var hip_pos := Vector3(0.22, -0.20, -0.42)
	if current_idx == 3:
		hip_pos = Vector3(0.20, -0.17, -0.38)
	if crouching and ads_alpha < 0.2:
		hip_pos += Vector3(-0.02, -0.015, 0.02)

	var target_pos: Vector3 = hip_pos.lerp(w.ads_pos as Vector3, ads_alpha)
	var target_rot := Vector3(_recoil_pitch, _sway.x * 1.4, _recoil_roll + (-0.08 if (crouching and ads_alpha < 0.2) else 0.0))

	# Idle Karambit Pose
	if current_idx == 3 and is_instance_valid(_karambit_ring_pivot):
		_karambit_ring_pivot.rotation = Vector3(sin(_bob_t * 0.5) * 0.06, 0.0, 0.0)
		if is_instance_valid(_left_hands[3]):
			_left_hands[3].position = _left_hand_rest[3] + Vector3(cos(_bob_t * 0.5) * 0.008, sin(_bob_t) * 0.008, 0.0)

	# 1. KARAMBIT / WEAPON DRAW ANIMATION (_draw_timer)
	if _draw_timer > 0.0:
		var u := 1.0 - (_draw_timer / maxf(0.01, _draw_duration))
		var ease_u := 1.0 - pow(1.0 - u, 3.0)
		if current_idx == 3 and is_instance_valid(_karambit_ring_pivot):
			# CS:GO 720° Index-Finger Ring Spin + Catch!
			target_pos = hip_pos + Vector3(0.10 * (1.0 - ease_u), -0.16 * (1.0 - ease_u), 0.06 * (1.0 - ease_u))
			target_rot = Vector3(-0.35 * (1.0 - ease_u), 0.45 * (1.0 - ease_u), -0.25 * (1.0 - ease_u))
			_karambit_ring_pivot.rotation = Vector3((1.0 - ease_u) * TAU * 2.0, 0.0, sin(u * PI) * 0.35)
		else:
			target_pos = hip_pos + Vector3(0.0, -0.22 * (1.0 - ease_u), 0.08 * (1.0 - ease_u))
			target_rot = Vector3(-0.55 * (1.0 - ease_u), 0.32 * (1.0 - ease_u), -0.28 * (1.0 - ease_u))

	# 2. KARAMBIT 3-HIT COMBO & HEAVY OVERHEAD LUNGE ANIMATION (_melee_anim_t)
	elif current_idx == 3 and _melee_anim_t > 0.0:
		var u := 1.0 - (_melee_anim_t / maxf(0.01, _melee_anim_dur))
		var swing := sin(u * PI)
		if _melee_heavy:
			# Right-Click Heavy Attack: Wind-Up (0..0.24) -> Violent Reverse-Grip Lunge Stab (0.24..0.60) -> Finger-Spin Recovery (0.60..1.0)
			if u < 0.24:
				var p := u / 0.24
				target_pos = hip_pos + Vector3(0.10 * p, 0.12 * p, 0.10 * p)
				target_rot = Vector3(0.48 * p, -0.35 * p, -0.55 * p)
			elif u < 0.62:
				var p := (u - 0.24) / 0.38
				var punch := sin(p * PI)
				target_pos = hip_pos + Vector3(-0.14 * punch, -0.06 * punch, -0.26 * punch)
				target_rot = Vector3(-0.68 * punch, 0.42 * punch, 0.48 * punch)
				if is_instance_valid(_left_hands[3]):
					_left_hands[3].position = _left_hand_rest[3] + Vector3(0.08 * punch, 0.06 * punch, -0.18 * punch)
			else:
				var p := (u - 0.62) / 0.38
				if is_instance_valid(_karambit_ring_pivot):
					_karambit_ring_pivot.rotation.x = p * TAU
		else:
			var c_mode := posmod(_melee_combo - 1, 3)
			if c_mode == 0:
				# Combo 1: Wide Right-to-Left Diagonal Cleave across the screen!
				var sweep := cos(u * PI) # +1 (right) -> -1 (left)
				target_pos = hip_pos + Vector3(sweep * 0.22 - 0.04, sweep * 0.08, -swing * 0.18)
				target_rot = Vector3(-swing * 0.42, (1.0 - sweep) * 0.52 - 0.35, -sweep * 0.58)
				if is_instance_valid(_karambit_ring_pivot):
					_karambit_ring_pivot.rotation = Vector3(swing * 0.65, 0.0, -swing * 0.45)
			elif c_mode == 1:
				# Combo 2: Fast Left-to-Right Backhand Reverse Slash!
				var sweep := -cos(u * PI) # -1 (left) -> +1 (right)
				target_pos = hip_pos + Vector3(sweep * 0.24, -sweep * 0.05 + 0.04, -swing * 0.20)
				target_rot = Vector3(-swing * 0.35, -sweep * 0.62, sweep * 0.65)
				if is_instance_valid(_karambit_ring_pivot):
					_karambit_ring_pivot.rotation = Vector3(-swing * 0.85, PI * swing * 0.4, 0.0)
			else:
				# Combo 3: 360° Finger-Ring Tornado Finisher!
				target_pos = hip_pos + Vector3(sin(u * TAU) * 0.16, cos(u * PI) * 0.06, -swing * 0.22)
				target_rot = Vector3(-swing * 0.38, sin(u * PI) * 0.45, sin(u * TAU) * 0.45)
				if is_instance_valid(_karambit_ring_pivot):
					_karambit_ring_pivot.rotation = Vector3(u * TAU * 2.0, 0.0, sin(u * PI) * 0.4)

	# 3. SPRINT POSE
	elif sprinting and on_floor and h_speed > 3.5 and ads_alpha < 0.1 and not is_reloading:
		if current_idx == 3:
			# Agile CS:GO Parkour Knife Sprint Pose with rhythmic figure-8 bob
			target_pos = hip_pos + Vector3(-0.04 + sin(_bob_t) * 0.022, -0.02 + absf(cos(_bob_t)) * 0.018, -0.03)
			target_rot = Vector3(0.14, 0.26, -0.18 + sin(_bob_t) * 0.08)
		else:
			target_pos = Vector3(0.06, -0.24, -0.35)
			target_rot = Vector3(-0.24, 0.52, -0.26)

	# 4. MULTI-STAGE RELOAD POSE
	elif is_reloading:
		var u := 1.0 - clampf(reload_timer / maxf(0.01, reload_duration), 0.0, 1.0)
		if u < 0.56:
			target_pos = hip_pos + Vector3(-0.05, -0.04 + sin(u * PI * 3.0) * 0.02, 0.04)
			target_rot = Vector3(0.22, 0.38, 0.48)
		else:
			target_pos = hip_pos + Vector3(-0.02, -0.02, 0.02)
			target_rot = Vector3(0.12, -0.28, -0.42)

	# 5. SHOWCASE INSPECT ANIMATION ([F])
	elif inspect_timer > 0.0:
		var u := 1.0 - (inspect_timer / maxf(0.01, inspect_duration))
		if current_idx == 3 and is_instance_valid(_karambit_ring_pivot):
			# CS:GO Freestyle Finger-Twirl -> Blade Side Showcase -> Reverse Twirl!
			target_pos = hip_pos + Vector3(-0.08 * sin(u * PI), 0.05 * sin(u * PI), -0.04 * sin(u * PI))
			target_rot = Vector3(0.22 * sin(u * PI), 0.55 * sin(u * TAU), -0.35 * sin(u * PI))
			_karambit_ring_pivot.rotation = Vector3(u * TAU * 3.0, sin(u * PI) * 0.65, cos(u * TAU) * 0.25)
		else:
			# Two-Sided Weapon Skin Showcase (Tilts left to show receiver & charm, then right!)
			var s1 := sin(u * PI)
			var s2 := sin(u * TAU)
			target_pos = hip_pos + Vector3(-0.09 * s1, 0.05 * s1, -0.04 * s1)
			target_rot = Vector3(0.18 * s1, 0.62 * s2, 0.48 * s2)

	target_pos += Vector3(bob_x + _sway.x, bob_y + _sway.y, _recoil_z)
	var pos_speed := 30.0 if _melee_anim_t > 0.0 else 22.0
	var rot_speed := 28.0 if _melee_anim_t > 0.0 else 18.0
	_pivot.position = _pivot.position.lerp(target_pos, minf(1.0, delta * pos_speed))
	_pivot.rotation = _pivot.rotation.lerp(target_rot, minf(1.0, delta * rot_speed))


func set_suppressor(idx: int, enabled: bool) -> void:
	if idx not in WeaponCatalog.FIREARMS or not is_instance_valid(_suppressor_meshes[idx]):
		return
	suppressor_enabled[idx] = enabled
	_suppressor_meshes[idx].visible = enabled
