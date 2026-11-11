extends RefCounted
## Richly detailed, cozy 3D low-poly architectural & street props for SAKURA BLITZ.
## Built using world.box, world.cyl, world.ball, world.roof, and world.halo.
## All geometry trims are offset by >= 0.04m to strictly avoid coplanar Z-fighting.
## Main structural surfaces have solid = true so players can walk, climb, and parkour on them.


## 1. Cozy Alpine / Village Chalet with stone plinth, timber frame, glowing windows, shutters,
## flower-box planters with colorful blooms, wooden door with porch awning & lantern, pitched roof,
## and chimney with billowing smoke puff spheres!
static func cozy_chalet(world, parent: Node3D, pos: Vector3, sx: float, sy: float, sz: float,
		wall_col: Color, roof_col: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)

	var hx := sx * 0.5
	var hz := sz * 0.5
	var plinth_h := clampf(sy * 0.12, 0.36, 0.58)
	var wall_h := sy - plinth_h
	var trim_col: Color = wall_col.darkened(0.55).lerp(Color("3d2617"), 0.65)
	var stone_col := Color("7a766e")
	var dark_wood := Color("4a3020")

	# 1. Foundation stone plinth (solid, offset outward by 0.08m)
	world.box(g, -hx - 0.08, 0.0, -hz - 0.08, sx + 0.16, plinth_h, sz + 0.16, stone_col, true, 0.0, 4)
	world.box(g, -hx - 0.12, plinth_h - 0.08, -hz - 0.12, sx + 0.24, 0.08, sz + 0.24, stone_col.darkened(0.12), false, 0.0, 8)

	# 2. Main structural wall body (solid, warm plaster / timber texture)
	world.box(g, -hx, plinth_h, -hz, sx, wall_h, sz, wall_col, true, 0.0, 7)

	# 3. Corner timber posts (protrude by 0.05m beyond wall faces)
	var post_w := 0.18
	world.box(g, -hx - 0.05, plinth_h, hz - 0.13, post_w, wall_h, post_w, trim_col, false, 0.0, 1)
	world.box(g, hx - 0.13, plinth_h, hz - 0.13, post_w, wall_h, post_w, trim_col, false, 0.0, 1)
	world.box(g, -hx - 0.05, plinth_h, -hz - 0.05, post_w, wall_h, post_w, trim_col, false, 0.0, 1)
	world.box(g, hx - 0.13, plinth_h, -hz - 0.05, post_w, wall_h, post_w, trim_col, false, 0.0, 1)

	# Top eaves wall plate & mid-level belly band
	world.box(g, -hx - 0.06, sy - 0.14, -hz - 0.06, sx + 0.12, 0.16, sz + 0.12, trim_col, false, 0.0, 1)
	var mid_y := plinth_h + wall_h * 0.50
	world.box(g, -hx - 0.05, mid_y - 0.07, -hz - 0.05, sx + 0.10, 0.14, sz + 0.10, trim_col, false, 0.0, 1)

	# Side wall vertical posts and diagonal timber knee braces
	world.box(g, -hx - 0.05, plinth_h, -0.09, 0.10, wall_h, 0.18, trim_col, false, 0.0, 1)
	world.box(g, hx - 0.05, plinth_h, -0.09, 0.10, wall_h, 0.18, trim_col, false, 0.0, 1)
	# Upper corner knee braces
	world.box(g, -hx - 0.04, sy - 0.52, hz - 0.48, 0.09, 0.38, 0.38, trim_col, false, 0.0, 1)
	world.box(g, hx - 0.05, sy - 0.52, hz - 0.48, 0.09, 0.38, 0.38, trim_col, false, 0.0, 1)
	world.box(g, -hx - 0.04, sy - 0.52, -hz + 0.10, 0.09, 0.38, 0.38, trim_col, false, 0.0, 1)
	world.box(g, hx - 0.05, sy - 0.52, -hz + 0.10, 0.09, 0.38, 0.38, trim_col, false, 0.0, 1)

	# 4. Wooden door with porch awning and warm glowing lantern
	var door_x := -hx * 0.38
	# Door frame & panel
	world.box(g, door_x - 0.08, plinth_h, hz - 0.02, 1.22, 2.18, 0.14, trim_col, false, 0.0, 1)
	world.box(g, door_x, plinth_h, hz + 0.04, 1.06, 2.10, 0.08, Color("4d321f"), false, 0.0, 1)
	# Brass knob & iron hinges
	world.box(g, door_x + 0.88, plinth_h + 1.0, hz + 0.10, 0.08, 0.14, 0.06, Color("e5b838"), false, 0.3, 0)
	world.box(g, door_x + 0.06, plinth_h + 1.6, hz + 0.10, 0.14, 0.05, 0.04, Color("22201d"), false, 0.0, 0)
	world.box(g, door_x + 0.06, plinth_h + 0.5, hz + 0.10, 0.14, 0.05, 0.04, Color("22201d"), false, 0.0, 0)
	# Stone porch steps (solid)
	world.box(g, door_x - 0.20, 0.0, hz + 0.10, 1.46, plinth_h * 0.52, 0.65, Color("76726b"), true, 0.0, 8)
	world.box(g, door_x - 0.12, plinth_h * 0.52, hz + 0.06, 1.30, plinth_h * 0.48, 0.42, Color("827d76"), true, 0.0, 8)
	# Wooden porch awning brackets & canopy (solid for jump/parkour)
	world.box(g, door_x - 0.18, plinth_h + 2.05, hz + 0.05, 0.12, 0.32, 0.70, trim_col, false, 0.0, 1)
	world.box(g, door_x + 1.12, plinth_h + 2.05, hz + 0.05, 0.12, 0.32, 0.70, trim_col, false, 0.0, 1)
	world.box(g, door_x - 0.28, plinth_h + 2.32, hz + 0.02, 1.62, 0.12, 0.86, roof_col.darkened(0.22), true, 0.0, 3)
	world.roof(g, door_x - 0.26, plinth_h + 2.44, hz + 0.04, 1.58, 0.82, 0.38, roof_col, 3)

	# Porch warm lantern
	var lx := door_x + 1.25
	var ly := plinth_h + 1.70
	var lz := hz + 0.22
	world.box(g, lx, ly + 0.12, hz + 0.05, 0.06, 0.06, 0.20, Color("22201d"), false, 0.0, 0)
	world.box(g, lx - 0.03, ly + 0.08, lz - 0.03, 0.12, 0.04, 0.12, Color("22201d"), false, 0.0, 0)
	world.box(g, lx - 0.02, ly - 0.08, lz - 0.02, 0.10, 0.16, 0.10, Color("ffd56b"), false, 2.6, -1)
	world.box(g, lx - 0.03, ly - 0.12, lz - 0.03, 0.12, 0.04, 0.12, Color("22201d"), false, 0.0, 0)
	world.halo(g.to_global(Vector3(lx + 0.03, ly, lz + 0.03)), 2.4, Color("ffa43c"), 0.75)

	# 5. Front window with shutters and flower-box planter
	var win_x := hx * 0.42
	var win_y := plinth_h + 0.95
	var shut_col := Color("3d6848")
	# Glowing window pane
	world.box(g, win_x - 0.55, win_y, hz + 0.04, 1.10, 1.15, 0.06, Color("fff2b8"), false, 2.2, 11)
	# Window frame & muntin cross
	world.box(g, win_x - 0.65, win_y - 0.08, hz + 0.02, 1.30, 0.09, 0.18, trim_col, false, 0.0, 1)
	world.box(g, win_x - 0.65, win_y + 1.14, hz + 0.02, 1.30, 0.09, 0.16, trim_col, false, 0.0, 1)
	world.box(g, win_x - 0.03, win_y, hz + 0.07, 0.06, 1.15, 0.04, trim_col, false, 0.0, 1)
	world.box(g, win_x - 0.55, win_y + 0.55, hz + 0.07, 1.10, 0.06, 0.04, trim_col, false, 0.0, 1)
	# Shutters
	world.box(g, win_x - 0.92, win_y, hz + 0.05, 0.30, 1.15, 0.07, shut_col, false, 0.0, 1)
	world.box(g, win_x + 0.62, win_y, hz + 0.05, 0.30, 1.15, 0.07, shut_col, false, 0.0, 1)
	world.box(g, win_x - 0.92, win_y + 0.55, hz + 0.09, 0.30, 0.06, 0.04, trim_col, false, 0.0, 1)
	world.box(g, win_x + 0.62, win_y + 0.55, hz + 0.09, 0.30, 0.06, 0.04, trim_col, false, 0.0, 1)
	# Flower-box planter with soil & rich flower blooms
	world.box(g, win_x - 0.62, win_y - 0.32, hz + 0.07, 1.24, 0.25, 0.28, dark_wood, true, 0.0, 1)
	world.box(g, win_x - 0.59, win_y - 0.09, hz + 0.09, 1.18, 0.03, 0.24, Color("22170f"), false, 0.0, 9)
	world.box(g, win_x - 0.57, win_y - 0.07, hz + 0.10, 1.14, 0.12, 0.22, Color("3a7830"), false, 0.0, 6)
	var flower_colors: Array[Color] = [
		Color("e63946"), Color("f4a261"), Color("a06cd5"),
		Color("ff758f"), Color("fff8f0"), Color("e63946"), Color("f4a261")
	]
	for i in 7:
		var fx := win_x - 0.48 + i * 0.16
		var fz := hz + 0.16 + (0.04 if i % 2 == 0 else -0.03)
		var fy := win_y + 0.05 + (0.03 if i % 3 == 0 else 0.0)
		world.ball(g, Vector3(fx, fy, fz), 0.075, flower_colors[i], 6)

	# Back wall glowing windows with shutters
	for side in [-1.0, 1.0]:
		var bwin_x: float = float(side) * hx * 0.45
		world.box(g, bwin_x - 0.45, win_y, -hz - 0.08, 0.90, 1.05, 0.06, Color("fff2b8"), false, 1.8, 11)
		world.box(g, bwin_x - 0.52, win_y - 0.06, -hz - 0.12, 1.04, 0.08, 0.14, trim_col, false, 0.0, 1)
		world.box(g, bwin_x - 0.78, win_y, -hz - 0.10, 0.26, 1.05, 0.06, shut_col, false, 0.0, 1)
		world.box(g, bwin_x + 0.52, win_y, -hz - 0.10, 0.26, 1.05, 0.06, shut_col, false, 0.0, 1)

	# 6. Pitched roof with chimney and smoke puff spheres
	var ov := 0.48
	# Roof walkable base deck
	world.box(g, -hx - ov, sy, -hz - ov, sx + ov * 2.0, 0.22, sz + ov * 2.0, roof_col.darkened(0.24), true, 0.0, 3)
	var roof_h := clampf(sy * 0.46, 1.6, 2.4)
	world.roof(g, -hx - ov * 0.82, sy + 0.20, -hz - ov * 0.82, sx + ov * 1.64, sz + ov * 1.64, roof_h, roof_col, 3)
	# Peak ridge beam (walkable)
	world.box(g, -hx - ov * 0.86, sy + roof_h + 0.14, -0.16, sx + ov * 1.72, 0.16, 0.32, roof_col.darkened(0.32), true, 0.0, 3)
	# Invisible parkour ramp collider
	var rcol: MeshInstance3D = world.box(g, -hx * 0.72, sy + 0.20, -hz * 0.5, sx * 1.44, roof_h * 0.82, sz, roof_col, true, 0.0, -1)
	rcol.visible = false

	# Chimney with brick texture
	var chx := hx * 0.50
	var chz := -hz * 0.35
	world.box(g, chx - 0.34, sy + 0.4, chz - 0.34, 0.68, roof_h + 1.15, 0.68, Color("7d4534"), true, 0.0, 2)
	world.box(g, chx - 0.40, sy + roof_h + 1.50, chz - 0.40, 0.80, 0.14, 0.80, Color("482a20"), false, 0.0, 4)
	world.box(g, chx - 0.22, sy + roof_h + 1.62, chz - 0.22, 0.44, 0.05, 0.44, Color("1a1412"), false, 0.0, 0)

	# Smoke puff spheres
	var ch_top := Vector3(chx, sy + roof_h + 1.72, chz)
	world.ball(g, ch_top + Vector3(0.02, 0.22, 0.02), 0.18, Color(0.92, 0.92, 0.95, 0.85), 6)
	world.ball(g, ch_top + Vector3(0.12, 0.62, 0.09), 0.27, Color(0.90, 0.91, 0.94, 0.75), 7)
	world.ball(g, ch_top + Vector3(0.28, 1.12, 0.18), 0.38, Color(0.88, 0.89, 0.93, 0.65), 7)
	world.ball(g, ch_top + Vector3(0.50, 1.75, 0.30), 0.50, Color(0.85, 0.87, 0.92, 0.50), 7)
	world.ball(g, ch_top + Vector3(0.78, 2.50, 0.45), 0.62, Color(0.82, 0.85, 0.90, 0.35), 7)


## 2. Retro Nuketown / Cozy Bus or Van for iconic mid-map tactical cover and parkour vaulting!
## Features chassis, wheels with hubcaps, chrome bumpers, dual headlights with glowing halos,
## retro two-tone livery, split windshield, panoramic windows, destination marquee, roof rack & cargo.
static func nuketown_bus(world, parent: Node3D, pos: Vector3, yaw: float, body_col: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)

	# Solid tactical cover collider
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.40, 2.55, 7.20)
	cs.shape = b
	cs.position = Vector3(0, 1.30, 0)
	sb.add_child(cs)
	g.add_child(sb)

	# 1. Undercarriage chassis frame
	world.box(g, -1.05, 0.22, -3.20, 2.10, 0.32, 6.40, Color("1e2024"), false, 0.0, 0)

	# 2. Wheels with hubcaps (Front axle: Z = -2.2, Rear axle: Z = 2.1)
	for wz in [-2.2, 2.1]:
		for side in [-1.0, 1.0]:
			var wx: float = float(side) * 1.18
			var wh: MeshInstance3D = world.cyl(g, Vector3(wx, 0.44, wz), 0.44, 0.44, 0.26, Color("1c1d22"), 12)
			wh.rotation.z = PI * 0.5
			wh.position = Vector3(wx, 0.44, wz)

			var cap_x: float = float(side) * 1.32
			var cap: MeshInstance3D = world.cyl(g, Vector3(cap_x, 0.44, wz), 0.22, 0.22, 0.04, Color("dcdfe6"), 10)
			cap.rotation.z = PI * 0.5
			cap.position = Vector3(cap_x, 0.44, wz)

			world.ball(g, Vector3(float(side) * 1.35, 0.44, wz), 0.07, Color("f0b429"), 6)

	# 3. Heavy retro bumpers
	world.box(g, -1.25, 0.32, -3.75, 2.50, 0.34, 0.26, Color("353840"), true, 0.0, 0)
	world.box(g, -1.28, 0.42, -3.79, 2.56, 0.12, 0.08, Color("d4d8e0"), false, 0.0, 0)

	world.box(g, -1.25, 0.32, 3.52, 2.50, 0.34, 0.26, Color("353840"), true, 0.0, 0)
	world.box(g, -1.28, 0.42, 3.73, 2.56, 0.12, 0.08, Color("d4d8e0"), false, 0.0, 0)

	# 4. Lower body & two-tone cream beltline stripe
	world.box(g, -1.18, 0.50, -3.50, 2.36, 0.95, 7.00, body_col, false, 0.0, 0)
	world.box(g, -1.21, 1.40, -3.53, 2.42, 0.14, 7.06, Color("fdfbf2"), false, 0.0, 0)

	# 5. Front grille & horizontal slats
	world.box(g, -0.65, 0.60, -3.55, 1.30, 0.48, 0.08, Color("1c1d22"), false, 0.0, 0)
	for s in 3:
		world.box(g, -0.60, 0.66 + s * 0.12, -3.57, 1.20, 0.04, 0.04, Color("d8dde6"), false, 0.0, 0)

	# Headlights & turn signals
	world.box(g, -1.05, 0.70, -3.57, 0.32, 0.30, 0.09, Color("2a2d33"), false, 0.0, 0)
	world.box(g, -1.02, 0.73, -3.61, 0.26, 0.24, 0.06, Color("fff8d0"), false, 2.6, -1)
	world.box(g, 0.73, 0.70, -3.57, 0.32, 0.30, 0.09, Color("2a2d33"), false, 0.0, 0)
	world.box(g, 0.76, 0.73, -3.61, 0.26, 0.24, 0.06, Color("fff8d0"), false, 2.6, -1)

	world.box(g, -1.15, 0.72, -3.56, 0.09, 0.24, 0.08, Color("ff9f1c"), false, 1.6, -1)
	world.box(g, 1.06, 0.72, -3.56, 0.09, 0.24, 0.08, Color("ff9f1c"), false, 1.6, -1)

	world.halo(g.to_global(Vector3(-0.89, 0.85, -3.70)), 2.0, Color("fff2b0"), 0.55)
	world.halo(g.to_global(Vector3(0.89, 0.85, -3.70)), 2.0, Color("fff2b0"), 0.55)

	# Rear taillights
	world.box(g, -1.05, 0.72, 3.49, 0.26, 0.30, 0.06, Color("d91e2e"), false, 2.2, -1)
	world.box(g, 0.79, 0.72, 3.49, 0.26, 0.30, 0.06, Color("d91e2e"), false, 2.2, -1)

	# 6. Upper cabin & windows
	world.box(g, -1.16, 1.54, -3.45, 2.32, 0.74, 6.90, body_col.lightened(0.08), false, 0.0, 0)

	# Split front windshield
	world.box(g, -1.08, 1.58, -3.52, 0.98, 0.65, 0.08, Color("88d2f0"), false, 0.28, -1)
	world.box(g, 0.10, 1.58, -3.52, 0.98, 0.65, 0.08, Color("88d2f0"), false, 0.28, -1)
	world.box(g, -0.07, 1.56, -3.54, 0.14, 0.70, 0.08, Color("22242a"), false, 0.0, 0)

	# Destination lightbox marquee
	world.box(g, -0.75, 2.26, -3.53, 1.50, 0.22, 0.10, Color("1e2025"), false, 0.0, 0)
	world.box(g, -0.70, 2.28, -3.56, 1.40, 0.18, 0.05, Color("fff3a8"), false, 2.2, -1)

	# Side panoramic windows
	var side_win_z: Array[float] = [-2.1, -0.8, 0.5, 1.8]
	for wz in side_win_z:
		# Left side windows
		world.box(g, -1.19, 1.60, wz, 0.06, 0.58, 1.05, Color("88d2f0"), false, 0.22, -1)
		world.box(g, -1.21, 1.57, wz - 0.04, 0.04, 0.64, 1.13, Color("22242a"), false, 0.0, 0)
		# Right side windows
		world.box(g, 1.13, 1.60, wz, 0.06, 0.58, 1.05, Color("88d2f0"), false, 0.22, -1)
		world.box(g, 1.17, 1.57, wz - 0.04, 0.04, 0.64, 1.13, Color("22242a"), false, 0.0, 0)

	# Rear window
	world.box(g, -0.92, 1.62, 3.42, 1.84, 0.58, 0.08, Color("88d2f0"), false, 0.22, -1)

	# 7. Curved roof tiers
	world.box(g, -1.14, 2.28, -3.38, 2.28, 0.22, 6.76, body_col.lightened(0.12), true, 0.0, 0)
	world.box(g, -0.95, 2.48, -3.20, 1.90, 0.12, 6.40, Color("fdfbf2"), true, 0.0, 0)

	# 8. Roof rack & cargo cover
	world.box(g, -0.88, 2.60, -2.40, 0.06, 0.22, 4.80, Color("2d3036"), false, 0.0, 0)
	world.box(g, 0.82, 2.60, -2.40, 0.06, 0.22, 4.80, Color("2d3036"), false, 0.0, 0)
	world.box(g, -0.88, 2.60, -2.40, 1.76, 0.22, 0.06, Color("2d3036"), false, 0.0, 0)
	world.box(g, -0.88, 2.60, 2.34, 1.76, 0.22, 0.06, Color("2d3036"), false, 0.0, 0)

	for k in 5:
		var rz := -2.0 + k * 1.0
		world.box(g, -0.85, 2.58, rz - 0.05, 1.70, 0.05, 0.10, Color("3a3d45"), true, 0.0, 0)

	# Roof crates & spare wheel
	world.box(g, -0.65, 2.60, -1.80, 0.70, 0.48, 0.80, Color("764c28"), true, 0.0, 1)
	world.box(g, 0.08, 2.60, -1.75, 0.60, 0.40, 0.70, Color("5c381c"), true, 0.0, 1)
	var st: MeshInstance3D = world.cyl(g, Vector3(0.0, 2.60, 1.10), 0.40, 0.40, 0.22, Color("1c1d22"), 10)
	st.scale = Vector3(1.0, 1.0, 1.0)
	world.box(g, -0.45, 2.60, -0.40, 0.90, 0.35, 1.10, Color("456b4a"), true, 0.0, 0)


## 3. Vibrant Market Stall ("El Panadero" Bakery & Fruit Stall) with striped cloth canopy
## (solid for parkour / bouncing!), wooden counter, support posts, crates of bread & fruit, and hanging paper lanterns!
static func market_stall(world, parent: Node3D, pos: Vector3, yaw: float,
		awning_col1: Color, awning_col2: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)

	# 1. Wooden counter base & display wings
	world.box(g, -1.25, 0.0, 0.35, 2.50, 0.92, 0.45, Color("5c3d28"), true, 0.0, 1)
	world.box(g, -1.25, 0.0, -0.55, 0.45, 0.92, 0.90, Color("523624"), true, 0.0, 1)
	world.box(g, 0.80, 0.0, -0.55, 0.45, 0.92, 0.90, Color("523624"), true, 0.0, 1)

	# Polished wood countertop slabs
	world.box(g, -1.35, 0.92, 0.30, 2.70, 0.08, 0.58, Color("7c5236"), true, 0.0, 1)
	world.box(g, -1.35, 0.92, -0.55, 0.55, 0.08, 0.85, Color("7c5236"), true, 0.0, 1)
	world.box(g, 0.80, 0.92, -0.55, 0.55, 0.08, 0.85, Color("7c5236"), true, 0.0, 1)

	# 2. 4 Timber support posts & top rafters
	var post_col := Color("482e1c")
	world.box(g, -1.36, 0.0, 0.76, 0.14, 2.30, 0.14, post_col, true, 0.0, 1)
	world.box(g, 1.22, 0.0, 0.76, 0.14, 2.30, 0.14, post_col, true, 0.0, 1)
	world.box(g, -1.36, 0.0, -0.90, 0.14, 2.62, 0.14, post_col, true, 0.0, 1)
	world.box(g, 1.22, 0.0, -0.90, 0.14, 2.62, 0.14, post_col, true, 0.0, 1)

	world.box(g, -1.40, 2.50, -0.92, 2.80, 0.12, 0.16, post_col, false, 0.0, 1)
	world.box(g, -1.40, 2.18, 0.76, 2.80, 0.12, 0.16, post_col, false, 0.0, 1)
	world.box(g, -1.38, 2.18, -0.90, 0.14, 0.14, 1.80, post_col, false, 0.0, 1)
	world.box(g, 1.24, 2.18, -0.90, 0.14, 0.14, 1.80, post_col, false, 0.0, 1)

	# 3. Striped cloth roof canopy (solid for bouncing & parkour)
	var stripe_count := 8
	var stripe_w := 3.0 / float(stripe_count)
	for i in stripe_count:
		var scol: Color = awning_col1 if i % 2 == 0 else awning_col2
		var sx := -1.50 + i * stripe_w
		world.box(g, sx, 2.30, -1.02, stripe_w - 0.01, 0.16, 2.00, scol, true, 0.0, 0)
		world.box(g, sx, 2.12, 0.96, stripe_w - 0.02, 0.20, 0.06, scol, false, 0.0, 0)

	var sb_c := StaticBody3D.new()
	var cs_c := CollisionShape3D.new()
	var b_c := BoxShape3D.new()
	b_c.size = Vector3(3.05, 0.22, 2.05)
	cs_c.shape = b_c
	cs_c.position = Vector3(0, 2.45, -0.02)
	sb_c.add_child(cs_c)
	g.add_child(sb_c)

	# 4. "El Panadero" Bakery signboard
	world.box(g, -0.80, 0.46, 0.82, 1.60, 0.36, 0.06, Color("fbf5e6"), false, 0.0, 1)
	world.box(g, -0.84, 0.42, 0.80, 1.68, 0.44, 0.05, post_col, false, 0.0, 1)
	world.box(g, -0.72, 0.53, 0.86, 1.44, 0.22, 0.04, Color("c03426"), false, 0.0, 0)
	world.box(g, -0.15, 0.57, 0.88, 0.30, 0.14, 0.04, Color("f5c842"), false, 0.5, 0)

	# Crates of French bread & golden buns
	world.box(g, -1.15, 1.00, 0.38, 0.65, 0.22, 0.42, Color("764b26"), true, 0.0, 1)
	for b_idx in 4:
		world.box(g, -1.10 + b_idx * 0.14, 1.08, 0.40, 0.10, 0.16, 0.38, Color("d48833"), false, 0.0, 1)
		world.box(g, -1.09 + b_idx * 0.14, 1.20, 0.44, 0.08, 0.05, 0.30, Color("fae8c8"), false, 0.0, 0)

	world.box(g, -0.42, 1.00, 0.38, 0.60, 0.22, 0.42, Color("684220"), true, 0.0, 1)
	world.ball(g, Vector3(-0.30, 1.15, 0.48), 0.085, Color("e09c48"), 7)
	world.ball(g, Vector3(-0.14, 1.15, 0.48), 0.085, Color("f4c07a"), 7)
	world.ball(g, Vector3(-0.30, 1.15, 0.65), 0.085, Color("d08432"), 7)
	world.ball(g, Vector3(-0.14, 1.15, 0.65), 0.085, Color("e8a252"), 7)

	# Crates of ripe fruit (apples & oranges)
	world.box(g, 0.28, 1.00, 0.38, 0.65, 0.22, 0.42, Color("764b26"), true, 0.0, 1)
	var fruit_cols: Array[Color] = [Color("d9232e"), Color("f58220"), Color("d9232e"), Color("f58220"), Color("d9232e"), Color("f58220")]
	for f in 6:
		var fx := 0.40 + (f % 3) * 0.15
		var fz := 0.48 + (f / 3) * 0.16
		world.ball(g, Vector3(fx, 1.14, fz), 0.075, fruit_cols[f], 6)

	# Ground stacked crates and barrel
	world.box(g, 1.45, 0.0, 0.15, 0.68, 0.50, 0.65, Color("684222"), true, 0.0, 1)
	world.box(g, 1.50, 0.50, 0.20, 0.58, 0.42, 0.55, Color("784d28"), true, 0.0, 1)
	world.cyl(g, Vector3(-1.75, 0.0, 0.45), 0.32, 0.26, 0.65, Color("805533"), 10)

	# 5. Hanging warm paper lanterns
	for lx in [-0.85, 0.85]:
		world.cyl(g, Vector3(lx, 2.08, 0.82), 0.015, 0.015, 0.14, Color("1c1d20"), 6)
		world.box(g, lx - 0.08, 2.05, 0.74, 0.16, 0.04, 0.16, Color("1c1d20"), false, 0.0, 0)
		world.cyl(g, Vector3(lx, 1.80, 0.82), 0.12, 0.10, 0.25, Color("e83828"), 8, 2.2)
		world.box(g, lx - 0.06, 1.76, 0.76, 0.12, 0.04, 0.12, Color("1c1d20"), false, 0.0, 0)
		world.cyl(g, Vector3(lx, 1.64, 0.82), 0.02, 0.01, 0.12, Color("e83828"), 6)
		world.halo(g.to_global(Vector3(lx, 1.92, 0.82)), 1.9, Color("ffa43c"), 0.65)


## 4. Traditional Japanese Tōrō Stone Lantern with base, pedestal, glowing warm fire-box,
## tiered cap roof, jewel finial, and world.halo light glow.
static func stone_lantern(world, parent: Node3D, pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)

	var st := Color("7a7770")

	# 1. Kiso (stepped base plinth)
	world.box(g, -0.38, 0.0, -0.38, 0.76, 0.20, 0.76, st.darkened(0.12), true, 0.0, 4)
	world.box(g, -0.30, 0.20, -0.30, 0.60, 0.12, 0.60, st, false, 0.0, 4)

	# 2. Sao (pedestal / pillar shaft)
	world.cyl(g, Vector3(0, 0.32, 0), 0.15, 0.20, 0.95, st.lightened(0.08), 8)
	world.cyl(g, Vector3(0, 0.74, 0), 0.18, 0.18, 0.08, st.darkened(0.15), 8)

	# 3. Chūdai (hearth middle platform)
	world.box(g, -0.28, 1.20, -0.28, 0.56, 0.06, 0.56, st.darkened(0.15), false, 0.0, 4)
	world.box(g, -0.36, 1.26, -0.36, 0.72, 0.14, 0.72, st, false, 0.0, 4)

	# 4. Hibukuro (glowing fire-box chamber & corner stone pillars)
	world.box(g, -0.20, 1.40, -0.20, 0.40, 0.38, 0.40, Color("ffd06e"), false, 3.2, -1)
	world.box(g, -0.25, 1.40, 0.17, 0.08, 0.38, 0.08, st.darkened(0.20), false, 0.0, 4)
	world.box(g, 0.17, 1.40, 0.17, 0.08, 0.38, 0.08, st.darkened(0.20), false, 0.0, 4)
	world.box(g, -0.25, 1.40, -0.25, 0.08, 0.38, 0.08, st.darkened(0.20), false, 0.0, 4)
	world.box(g, 0.17, 1.40, -0.25, 0.08, 0.38, 0.08, st.darkened(0.20), false, 0.0, 4)
	world.box(g, -0.25, 1.74, -0.25, 0.50, 0.05, 0.50, st.darkened(0.20), false, 0.0, 4)

	# 5. Kasa (pagoda cap roof)
	world.box(g, -0.44, 1.79, -0.44, 0.88, 0.08, 0.88, st, false, 0.0, 4)
	world.roof(g, -0.50, 1.87, -0.50, 1.00, 1.00, 0.40, st.darkened(0.14), 4)

	# 6. Hōju (sacred jewel finial)
	world.cyl(g, Vector3(0, 2.27, 0), 0.12, 0.15, 0.08, st, 8)
	world.ball(g, Vector3(0, 2.42, 0), 0.12, st.lightened(0.06), 7)

	# 7. Warm light glow halo
	world.halo(g.to_global(Vector3(0, 1.59, 0)), 2.6, Color("ffba54"), 0.68)


## 5. Wooden Tactical Watchtower with 4 timber pillars, perimeter cross-bracing,
## elevated wooden platform with tactical sandbags & railings, pitched roof, and climbable ladder.
static func wooden_watchtower(world, parent: Node3D, pos: Vector3, height: float) -> void:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)

	var plat_y := maxf(3.2, height)
	var roof_eaves_y := plat_y + 2.30
	var wood_col := Color("482e1c")
	var dark_wood := Color("3a2416")

	# 1. 4 Timber corner pillars with stone footings
	for px in [-1.35, 1.35]:
		for pz in [-1.35, 1.35]:
			world.box(g, px - 0.18, 0.0, pz - 0.18, 0.36, 0.35, 0.36, Color("76726c"), true, 0.0, 4)
			world.box(g, px - 0.12, 0.30, pz - 0.12, 0.24, roof_eaves_y - 0.30, 0.24, wood_col, true, 0.0, 1)

	# 2. Mid-level horizontal tie-beams & diagonal cross-braces
	var tier_h := plat_y * 0.50
	world.box(g, -1.35, tier_h - 0.08, 1.25, 2.70, 0.16, 0.16, wood_col, false, 0.0, 1)
	world.box(g, -1.35, tier_h - 0.08, -1.41, 2.70, 0.16, 0.16, wood_col, false, 0.0, 1)
	world.box(g, -1.41, tier_h - 0.08, -1.35, 0.16, 0.16, 2.70, wood_col, false, 0.0, 1)
	world.box(g, 1.25, tier_h - 0.08, -1.35, 0.16, 0.16, 2.70, wood_col, false, 0.0, 1)

	# Left & Right diagonal cross braces
	world.box(g, -1.43, 0.35, -1.25, 0.10, tier_h - 0.40, 2.50, dark_wood, false, 0.0, 1)
	world.box(g, -1.43, tier_h + 0.10, -1.25, 0.10, plat_y - tier_h - 0.30, 2.50, dark_wood, false, 0.0, 1)
	world.box(g, 1.33, 0.35, -1.25, 0.10, tier_h - 0.40, 2.50, dark_wood, false, 0.0, 1)
	world.box(g, 1.33, tier_h + 0.10, -1.25, 0.10, plat_y - tier_h - 0.30, 2.50, dark_wood, false, 0.0, 1)

	# 3. Elevated platform deck joists & floor planks (solid)
	world.box(g, -1.55, plat_y - 0.20, -1.55, 3.10, 0.20, 3.10, Color("442918"), true, 0.0, 1)
	world.box(g, -1.65, plat_y, -1.65, 3.30, 0.18, 3.30, Color("5c3c26"), true, 0.0, 1)

	# 4. Tactical sandbags & safety railings
	# Side & back railings
	world.box(g, -1.60, plat_y + 0.18, -1.55, 0.10, 0.90, 3.10, wood_col, true, 0.0, 1)
	world.box(g, 1.50, plat_y + 0.18, -1.55, 0.10, 0.90, 3.10, wood_col, true, 0.0, 1)
	world.box(g, -1.60, plat_y + 0.18, -1.60, 1.15, 0.90, 0.10, wood_col, true, 0.0, 1)
	world.box(g, 0.45, plat_y + 0.18, -1.60, 1.15, 0.90, 0.10, wood_col, true, 0.0, 1)

	# Front tactical sandbag wall
	world.box(g, -1.50, plat_y + 0.18, 1.32, 3.00, 0.72, 0.30, Color("ad996d"), true, 0.0, 4)
	for s in 5:
		world.box(g, -1.45 + s * 0.58, plat_y + 0.90, 1.30, 0.54, 0.14, 0.32, Color("b8a478"), true, 0.0, 4)

	# 5. Pitched roof with peak beam & slope collider
	var ov := 0.45
	world.box(g, -1.65 - ov, roof_eaves_y, -1.65 - ov, 3.30 + ov * 2.0, 0.16, 3.30 + ov * 2.0, dark_wood, true, 0.0, 1)
	world.roof(g, -1.65 - ov * 0.85, roof_eaves_y + 0.16, -1.65 - ov * 0.85, 3.30 + ov * 1.7, 3.30 + ov * 1.7, 1.50, Color("583d2a"), 3)
	world.box(g, -1.65 - ov * 0.88, roof_eaves_y + 1.66, -0.16, 3.30 + ov * 1.76, 0.16, 0.32, Color("2d1b10"), true, 0.0, 3)

	var r_col: MeshInstance3D = world.box(g, -1.20, roof_eaves_y + 0.16, -1.00, 2.40, 1.20, 2.00, Color("583d2a"), true, 0.0, -1)
	r_col.visible = false

	# 6. Climbable ladder rungs (solid step geometry + KZ Ladder volume registration)
	world.box(g, -0.38, 0.0, -1.78, 0.08, plat_y + 1.10, 0.08, wood_col, true, 0.0, 1)
	world.box(g, 0.30, 0.0, -1.78, 0.08, plat_y + 1.10, 0.08, wood_col, true, 0.0, 1)

	var rung_count := int(plat_y / 0.30) + 3
	for r in rung_count:
		var ry := 0.25 + r * 0.30
		world.box(g, -0.34, ry, -1.76, 0.68, 0.07, 0.07, Color("7c5234"), true, 0.0, 1)

	if "kz_ladders" in world and world.kz_ladders is Array:
		var lad_center: Vector3 = g.to_global(Vector3(0, plat_y * 0.5, -1.75))
		var lad_size := Vector3(1.2, plat_y + 1.2, 0.9)
		world.kz_ladders.append(AABB(lad_center - lad_size * 0.5, lad_size))


## 6. Cozy Campfire Spot with stone ring, crossed wooden logs, glowing orange/gold flame blocks,
## and radiant warm world.halo glow.
static func campfire_spot(world, parent: Node3D, pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)

	# 1. Ash and soot ground pit
	world.cyl(g, Vector3(0, 0.01, 0), 0.78, 0.88, 0.06, Color("1e1b18"), 12)
	world.cyl(g, Vector3(0, 0.04, 0), 0.42, 0.48, 0.08, Color("2d1810"), 10)

	# 2. Ring of river stones (solid)
	var stone_colors: Array[Color] = [
		Color("6e6a64"), Color("7d7972"), Color("88847c"),
		Color("65625c"), Color("747169"), Color("827e77"),
		Color("6a6760"), Color("7c7871"), Color("85817a"), Color("6e6b63")
	]
	for i in 10:
		var a := i * TAU / 10.0
		var rx := cos(a) * 0.72
		var rz := sin(a) * 0.72
		var rh := 0.18 + (i % 3) * 0.04
		var rw := 0.28 + ((i + 1) % 2) * 0.04
		world.box(g, rx - rw * 0.5, 0.0, rz - rw * 0.5, rw, rh, rw, stone_colors[i], true, 0.0, 4)

	# 3. Crossed campfire wooden logs
	world.box(g, -0.48, 0.06, -0.12, 0.96, 0.16, 0.18, Color("452c1a"), true, 0.0, 1)
	world.box(g, -0.12, 0.10, -0.48, 0.18, 0.16, 0.96, Color("3d2616"), true, 0.0, 1)
	world.box(g, -0.38, 0.16, -0.38, 0.76, 0.15, 0.16, Color("4f321e"), true, 0.0, 1)
	world.box(g, -0.38, 0.16, 0.22, 0.76, 0.15, 0.16, Color("382213"), true, 0.0, 1)
	world.box(g, -0.14, 0.14, -0.14, 0.28, 0.10, 0.28, Color("32120a"), false, 0.8, -1)

	# 4. Glowing orange/gold flame blocks & embers
	world.box(g, -0.18, 0.12, -0.18, 0.36, 0.46, 0.36, Color("ff6600"), false, 3.4, -1)
	world.box(g, -0.11, 0.20, -0.11, 0.22, 0.50, 0.22, Color("ffd034"), false, 4.2, -1)
	world.box(g, -0.06, 0.44, -0.06, 0.12, 0.36, 0.12, Color("fff690"), false, 4.8, -1)

	world.box(g, 0.10, 0.22, -0.09, 0.13, 0.30, 0.13, Color("ff4800"), false, 3.2, -1)
	world.box(g, -0.21, 0.18, 0.05, 0.13, 0.26, 0.13, Color("ff7700"), false, 3.2, -1)
	world.box(g, 0.02, 0.24, 0.11, 0.12, 0.24, 0.12, Color("ffa000"), false, 3.4, -1)
	world.box(g, -0.08, 0.20, -0.21, 0.12, 0.22, 0.12, Color("ff5000"), false, 3.2, -1)

	world.box(g, 0.14, 0.38, 0.08, 0.06, 0.06, 0.06, Color("ffcc00"), false, 4.0, -1)
	world.box(g, -0.12, 0.42, 0.14, 0.06, 0.06, 0.06, Color("ff8800"), false, 4.0, -1)

	# 5. Radiant warm halo light glow
	world.halo(g.to_global(Vector3(0, 0.45, 0)), 3.2, Color("ff8824"), 0.85)
	world.halo(g.to_global(Vector3(0, 0.60, 0)), 5.2, Color("ffaa38"), 0.38)

	# 6. Rustic camping log benches (solid for sitting / low cover)
	world.box(g, -1.45, 0.0, -0.55, 0.45, 0.36, 1.10, Color("543622"), true, 0.0, 1)
	world.box(g, 1.00, 0.0, -0.55, 0.45, 0.36, 1.10, Color("543622"), true, 0.0, 1)
