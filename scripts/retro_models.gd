class_name RetroModels
## High-detail PS1-Plus 3D models built from faceted low-poly primitives with pixel textures.


static func sakura_tree(w: Node3D, parent: Node3D, p: Vector3, s: float, seed_v: int, pink: bool = true) -> Node3D:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var g := Node3D.new()
	g.position = p
	g.rotation.y = r.randf() * TAU
	parent.add_child(g)

	# Solid trunk collider
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.24 * s
	cyl.height = 2.6 * s
	cs.shape = cyl
	cs.position.y = 1.3 * s
	sb.add_child(cs)
	g.add_child(sb)

	var bark := Color("5c3c28").lerp(Color("7a5238"), r.randf())
	var h := r.randf_range(2.0, 2.6) * s
	var rad := 0.16 * s
	# Root flare + main trunk + 3 limbs
	_bark(w.cyl(g, Vector3.ZERO, rad * 1.5, rad * 2.2, 0.42 * s, bark.darkened(0.14), 8))
	var trunk := _bark(w.cyl(g, Vector3.ZERO, rad * 0.78, rad * 1.15, h + 0.5 * s, bark, 8))
	trunk.rotation.z = r.randf_range(-0.07, 0.07)
	for k in 3:
		var limb := _bark(w.cyl(g, Vector3(0, h * (0.52 + k * 0.14), 0), rad * 0.28, rad * 0.5, h * 0.48, bark, 6))
		limb.rotation = Vector3(r.randf_range(0.45, 0.85) * (1.0 if k % 2 == 0 else -1.0), k * TAU / 3.0 + r.randf_range(-0.3, 0.3), r.randf_range(-0.35, 0.35))

	var palette: Array
	if pink:
		palette = [
			[Color("d47a9e"), Color("f4aac8"), Color("ffe3ef")],
			[Color("c96d92"), Color("ee9ec0"), Color("ffdbf0")],
			[Color("de86a8"), Color("f8b8d2"), Color("fff0f6")]
		][r.randi_range(0, 2)]
	else:
		palette = [
			[Color("2f6a32"), Color("4a8f40"), Color("82c462")],
			[Color("3a6e2c"), Color("5a9a3a"), Color("94cc64")]
		][r.randi_range(0, 1)]

	var top := h + 1.05 * s
	var core := _foliage(w.ball(g, Vector3(0, top, 0), 1.38 * s, palette[1], 8))
	core.scale = Vector3(1.08, 0.78, 1.08)

	var n := r.randi_range(7, 10)
	for k in n:
		var a := TAU * k / float(n) + r.randf_range(-0.25, 0.25)
		var rr := r.randf_range(0.9, 1.3) * s
		var lift := r.randf_range(-0.42, 0.28) * s
		var col: Color = palette[0] if lift < -0.12 * s else palette[1]
		var b := _foliage(w.ball(g, Vector3(cos(a) * rr, top + lift, sin(a) * rr), r.randf_range(0.6, 0.88) * s, col, 7))
		b.scale = Vector3(1.05, 0.76, 1.05)

	for k in r.randi_range(4, 6):
		var a := r.randf() * TAU
		var b := _foliage(w.ball(g, Vector3(cos(a) * 0.6 * s, top + r.randf_range(0.55, 0.92) * s, sin(a) * 0.6 * s), r.randf_range(0.5, 0.72) * s, palette[2], 7))
		b.scale = Vector3(1.0, 0.72, 1.0)

	# Hanging blossom clusters underneath
	for k in 3:
		var a := r.randf() * TAU
		_foliage(w.ball(g, Vector3(cos(a) * 1.0 * s, top - 0.75 * s, sin(a) * 1.0 * s), 0.42 * s, palette[0].darkened(0.08), 6))

	return g


static func _foliage(mi: MeshInstance3D) -> MeshInstance3D:
	mi.set_meta("tex", 6)
	return mi


static func _bark(mi: MeshInstance3D) -> MeshInstance3D:
	mi.set_meta("tex", 1)
	return mi


## Detailed stylized house with walkable flat/gable roof, timber beams, shutters, flowerboxes,
## porch steps, chimney, and optional bouncy café awning.
static func house(w: Node3D, parent: Node3D, x: float, z: float, wd: float, dp: float, h: float,
		wall_c: Color, roof_c: Color, face_dir: Vector2, style: int = 0, has_awning: bool = false) -> void:
	var g := Node3D.new()
	parent.add_child(g)

	var trim := Color("f6f2eb") if wall_c.v < 0.84 else Color("6e4f3a")
	var dark_wood := Color("5a3d2b")
	var stone_base := Color("8e877e")

	# Foundation stone plinth + main solid body
	w.box(g, x - 0.08, 0.0, z - 0.08, wd + 0.16, 0.42, dp + 0.16, stone_base, false, 0.0, 4)
	w.box(g, x, 0.4, z, wd, h - 0.4, dp, wall_c, true, 0.0, 2 if style % 2 == 0 else 7)

	# Corner timber pillars & floor separator beams
	for cx in [x - 0.06, x + wd - 0.10]:
		for cz in [z - 0.06, z + dp - 0.10]:
			w.box(g, cx, 0.38, cz, 0.16, h - 0.38, 0.16, trim, false, 0.0, 1)
	if h > 4.2:
		w.box(g, x - 0.06, 3.2, z - 0.06, wd + 0.12, 0.16, dp + 0.12, trim, false, 0.0, 1)

	# Walkable Roof Deck + Gable Crown so player can parkour across rooftops!
	var ov := 0.45
	w.box(g, x - ov, h, z - ov, wd + ov * 2.0, 0.24, dp + ov * 2.0, roof_c.darkened(0.24), true, 0.0, 3)
	w.roof(g, x - ov * 0.7, h + 0.24, z - ov * 0.7, wd + ov * 1.4, dp + ov * 1.4, 1.75, roof_c)
	# Crisp ridge cap beam along the roof peak + invisible walkable step collider
	w.box(g, x + wd * 0.5 - 0.14, h + 1.88, z - ov * 0.72, 0.28, 0.16, dp + ov * 1.44, roof_c.darkened(0.28), false, 0.0, 3)
	var roof_col: MeshInstance3D = w.box(g, x + wd * 0.18, h + 0.24, z - 0.2, wd * 0.64, 1.35, dp + 0.4, roof_c, true, 0.0, -1)
	roof_col.visible = false

	# Chimney with brick cap
	var chx := x + wd * 0.72
	var chz := z + dp * 0.24
	w.box(g, chx, h + 0.4, chz, 0.58, 2.1, 0.58, Color("8f4d3b"), true, 0.0, 2)
	w.box(g, chx - 0.07, h + 2.5, chz - 0.07, 0.72, 0.14, 0.72, Color("5c3328"), false, 0.0, 2)

	# Windows & Shutters along front/back & sides
	var shut_c: Color = [Color("3b6e8c"), Color("4f8a5b"), Color("94423e"), Color("6c568e"), Color("d97f38")][style % 5]
	var glass_c := Color("fff0c2")
	var floors := 2 if h > 4.6 else 1
	for fl in floors:
		var wy := 1.25 + fl * 2.55
		if wy + 1.2 > h:
			continue
		# Z-facing walls (front/back)
		var cols_x := maxi(1, int(wd / 3.2))
		for ix in cols_x:
			var wx := x + (ix + 0.5) * (wd / float(cols_x)) - 0.55
			for fz_side in [-1, 1]:
				var wz := z - 0.05 if fz_side < 0 else z + dp - 0.03
				# Skip ground middle spot if door is there
				if fl == 0 and ix == cols_x / 2 and ((fz_side < 0 and face_dir.y < -0.5) or (fz_side > 0 and face_dir.y > 0.5)):
					_door(w, g, wx + 0.1, z if fz_side < 0 else z + dp, fz_side, false, trim, dark_wood, roof_c)
					continue
				# Window pane (warmly lit shoji/glass)
				w.box(g, wx, wy, wz, 1.1, 1.15, 0.08, glass_c, false, 0.35, 11)
				# Window frame & sill
				w.box(g, wx - 0.08, wy - 0.08, wz - 0.04, 1.26, 0.1, 0.16, trim, false, 0.0, 1)
				# Shutters
				w.box(g, wx - 0.32, wy, wz - 0.02, 0.28, 1.12, 0.12, shut_c, false, 0.0, 1)
				w.box(g, wx + 1.14, wy, wz - 0.02, 0.28, 1.12, 0.12, shut_c, false, 0.0, 1)

		# X-facing walls (left/right)
		var cols_z := maxi(1, int(dp / 3.2))
		for iz in cols_z:
			var wz2 := z + (iz + 0.5) * (dp / float(cols_z)) - 0.55
			for fx_side in [-1, 1]:
				var wx2 := x - 0.05 if fx_side < 0 else x + wd - 0.03
				if fl == 0 and iz == cols_z / 2 and ((fx_side < 0 and face_dir.x < -0.5) or (fx_side > 0 and face_dir.x > 0.5)):
					_door(w, g, x if fx_side < 0 else x + wd, wz2 + 0.1, fx_side, true, trim, dark_wood, roof_c)
					continue
				w.box(g, wx2, wy, wz2, 0.08, 1.15, 1.1, glass_c, false, 0.35, 11)
				w.box(g, wx2 - 0.04, wy - 0.08, wz2 - 0.08, 0.16, 0.1, 1.26, trim, false, 0.0, 1)
				w.box(g, wx2 - 0.02, wy, wz2 - 0.32, 0.12, 1.12, 0.28, shut_c, false, 0.0, 1)
				w.box(g, wx2 - 0.02, wy, wz2 + 1.14, 0.12, 1.12, 0.28, shut_c, false, 0.0, 1)

	# Optional bouncy striped café awning on the front face!
	if has_awning:
		var aw_y := 2.85
		if absf(face_dir.x) > 0.5:
			var ax := (x - 2.1) if face_dir.x < 0 else (x + wd)
			w.add_bouncy_awning(ax, aw_y, z + 0.6, 2.1, dp - 1.2, Color("e64858"), Color("fff8ee"))
		else:
			var az := (z - 2.1) if face_dir.y < 0 else (z + dp)
			w.add_bouncy_awning(x + 0.6, aw_y, az, wd - 1.2, 2.1, Color("e64858"), Color("fff8ee"))


static func _door(w: Node3D, g: Node3D, wall_pos: float, span_pos: float, side: int, along_x: bool,
		trim: Color, wood: Color, roof_c: Color) -> void:
	if along_x:
		var dx := wall_pos + (-0.06 if side < 0 else -0.02)
		w.box(g, dx, 0.4, span_pos, 0.08, 2.05, 0.95, wood, false, 0.0, 1)
		w.box(g, dx - 0.04, 0.4, span_pos - 0.1, 0.16, 2.15, 0.1, trim, false, 0.0, 1)
		w.box(g, dx - 0.04, 0.4, span_pos + 0.95, 0.16, 2.15, 0.1, trim, false, 0.0, 1)
		var step_x := (wall_pos - 0.75) if side < 0 else wall_pos
		w.box(g, step_x, 0.0, span_pos - 0.2, 0.75, 0.22, 1.35, Color("9e968c"), true, 0.0, 8)
		w.box(g, step_x, 2.55, span_pos - 0.25, 0.85, 0.14, 1.45, roof_c, true, 0.0, 3)
	else:
		var dz := wall_pos + (-0.06 if side < 0 else -0.02)
		w.box(g, span_pos, 0.4, dz, 0.95, 2.05, 0.08, wood, false, 0.0, 1)
		w.box(g, span_pos - 0.1, 0.4, dz - 0.04, 0.1, 2.15, 0.16, trim, false, 0.0, 1)
		w.box(g, span_pos + 0.95, 0.4, dz - 0.04, 0.1, 2.15, 0.16, trim, false, 0.0, 1)
		var step_z := (wall_pos - 0.75) if side < 0 else wall_pos
		w.box(g, span_pos - 0.2, 0.0, step_z, 1.35, 0.22, 0.75, Color("9e968c"), true, 0.0, 8)
		w.box(g, span_pos - 0.25, 2.55, step_z, 1.45, 0.14, 0.85, roof_c, true, 0.0, 3)


## Traditional Vermilion & Gold Torii Archway (walkable top beam for parkour!)
static func torii_gate(w: Node3D, parent: Node3D, center: Vector3, span: float, h: float, yaw: float = 0.0) -> Node3D:
	var g := Node3D.new()
	g.position = center
	g.rotation.y = yaw
	parent.add_child(g)

	var red := Color("d9383a")
	var dark := Color("28232a")
	var gold := Color("f5c242")
	var half := span * 0.5

	for sx in [-half, half]:
		# Base Pedestal + Pillar
		w.cyl(g, Vector3(sx, 0, 0), 0.36, 0.42, 0.55, dark, 10)
		w.cyl(g, Vector3(sx, 0.5, 0), 0.26, 0.30, h - 0.5, red, 10)
		w.box(g, sx - 0.3, h * 0.72, -0.3, 0.6, 0.22, 0.6, gold, false, 0.2, 0)
		# Solid pillar collision
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.32
		cyl.height = h
		cs.shape = cyl
		cs.position = Vector3(sx, h * 0.5, 0)
		sb.add_child(cs)
		g.add_child(sb)

	# Lower tie beam (Nuki) + Upper lintel (Kasagi) with walkable collision
	w.box(g, -half - 0.65, h - 1.05, -0.22, span + 1.3, 0.28, 0.44, red, false, 0.0, 1)
	w.box(g, -half - 1.1, h - 0.25, -0.38, span + 2.2, 0.34, 0.76, red, false, 0.0, 1)
	w.box(g, -half - 1.25, h + 0.08, -0.44, span + 2.5, 0.18, 0.88, dark, false, 0.0, 3)
	# Center gold plaque
	w.box(g, -0.38, h - 0.82, -0.26, 0.76, 0.62, 0.52, gold, false, 0.4, 0)

	# Top collider so player can parkour across the Torii top!
	var sb_top := StaticBody3D.new()
	var cs_top := CollisionShape3D.new()
	var b_top := BoxShape3D.new()
	b_top.size = Vector3(span + 2.4, 0.5, 0.9)
	cs_top.shape = b_top
	cs_top.position = Vector3(0, h, 0)
	sb_top.add_child(cs_top)
	g.add_child(sb_top)
	return g


## Stone Lantern (Toro) with glowing warm flame & halo
static func stone_lantern(w: Node3D, parent: Node3D, p: Vector3) -> void:
	var g := Node3D.new()
	g.position = p
	parent.add_child(g)
	var st := Color("9e9a92")
	w.box(g, -0.35, 0.0, -0.35, 0.7, 0.22, 0.7, st.darkened(0.15), true, 0.0, 4)
	w.cyl(g, Vector3(0, 0.22, 0), 0.16, 0.22, 0.95, st, 8)
	w.box(g, -0.32, 1.15, -0.32, 0.64, 0.14, 0.64, st, false, 0.0, 4)
	# Glowing firebox
	w.box(g, -0.22, 1.29, -0.22, 0.44, 0.38, 0.44, Color("ffd278"), false, 2.2, -1)
	# Pagoda cap
	w.roof(g, -0.44, 1.67, -0.44, 0.88, 0.88, 0.34, st.darkened(0.12))
	w.ball(g, Vector3(0, 2.08, 0), 0.10, st, 6)
	w.halo(p + Vector3(0, 1.48, 0), 2.2, Color("ffbe68"), 0.55)


## Retro Low-Poly Car (solid for vaulting / cover)
static func retro_car(w: Node3D, parent: Node3D, p: Vector3, yaw: float, body_col: Color) -> void:
	var g := Node3D.new()
	g.position = p
	g.rotation.y = yaw
	parent.add_child(g)

	# Body & cabin
	w.box(g, -0.95, 0.32, -2.1, 1.9, 0.62, 4.2, body_col, false, 0.0, 0)
	w.box(g, -0.82, 0.92, -1.05, 1.64, 0.56, 2.1, body_col.lightened(0.08), false, 0.0, 0)
	# Windows
	w.box(g, -0.76, 0.96, -1.08, 1.52, 0.44, 2.16, Color("8cd8ff"), false, 0.25, -1)
	# Headlights & taillights
	for sx in [-0.72, 0.42]:
		w.box(g, sx, 0.52, -2.12, 0.3, 0.18, 0.06, Color("fff3b0"), false, 1.8, -1)
		w.box(g, sx, 0.52, 2.06, 0.3, 0.18, 0.06, Color("ff4757"), false, 1.8, -1)
	# Wheels
	for wx in [-0.96, 0.82]:
		for wz in [-1.35, 1.35]:
			var wh: MeshInstance3D = w.cyl(g, Vector3(wx + 0.07, 0.34, wz), 0.34, 0.34, 0.18, Color("24262e"), 10)
			wh.rotation.z = PI * 0.5
			wh.position = Vector3(wx + (0.16 if wx < 0 else 0.02), 0.34, wz)

	# Solid collider for parkour vaulting on the car
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.95, 1.48, 4.2)
	cs.shape = b
	cs.position = Vector3(0, 0.74, 0)
	sb.add_child(cs)
	g.add_child(sb)
