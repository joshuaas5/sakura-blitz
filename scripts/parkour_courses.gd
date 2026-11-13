class_name ParkourCourses
extends RefCounted
## Two routes per sector. The detour has <=1.2m gaps and 4m-wide landings.
## Central skill lanes are shorter and offer one-shot collectible rings.
const COLORS := [Color("e75d91"), Color("f1a23e"), Color("24baa9"), Color("8660d5"), Color("63b34b"), Color("ec7b46")]
const RECIPES := [
	["DRUMS", "BUMPERS", "SWEEP", "BELT", "DRUMS", "PENDULUM", "MOVERS", "HAMMER"],
	["STEPS", "BELT", "PENDULUM", "MOVERS", "PUSHERS", "STEPS", "HAMMER", "BELT"],
	["STEPS", "SURF", "BUMPERS", "PENDULUM", "SURF", "MOVERS", "BELT", "SWEEP"],
	["MOVERS", "PUSHERS", "SWEEP", "BELT", "HAMMER", "MOVERS", "PENDULUM", "SWEEP"],
	["STEPS", "PENDULUM", "SEESAW", "STEPS", "SURF", "PENDULUM", "MOVERS", "SEESAW"],
	["BUMPERS", "BELT", "DRUMS", "HAMMER", "SEESAW", "PUSHERS", "BELT", "DRUMS"]
]

static func build(w: SakuraWorld, theme: int) -> void:
	var color: Color = COLORS[theme]
	w.apply_atmosphere_preset([0, 1, 0, 2, 0, 1][theme])
	w.kz_start_pad = Vector3(0, 0.2, 20)
	w.race_waypoints.append(Vector3(0, 0.2, 11))
	w.race_fast_waypoints.append(Vector3(0, 0.2, 11))
	w.box(w, -11, -0.7, 8, 22, 0.7, 14, Color("e4ddd1"), true, 0, 8)
	w.box(w, -55, -7, -235, 110, 0.3, 270, Color("253d58") if theme != 3 else Color("171f38"), false, 0, -1)
	w._start_gate_node = Node3D.new()
	w._stage_root.add_child(w._start_gate_node)
	var barrier := w.box(w._start_gate_node, -11, 0, 13.4, 22, 2.8, 0.3, color, true, 0, -1)
	barrier.hide()
	w.box(w._start_gate_node, -11, 2.7, 13.4, 22, 0.18, 0.3, color, false, 0, -1)
	for x in [-10.5, -5.5, 5.5, 10.5]:
		w.box(w._start_gate_node, x, 0, 13.4, 0.16, 2.8, 0.3, color, false, 0, -1)
	_sign(w, Vector3(0, 4.2, 12), SakuraHub.MAPS[1][theme].to_upper(), color)
	var z := 8.0
	for sector in 8:
		var safe_start := w.race_waypoints.size()
		var end := z - 22.0
		# Wide regrouping platforms ensure every route crosses the checkpoint.
		w.box(w, -11, -0.7, end - 4, 22, 0.7, 5, Color("eee6d8"), true, 0, 8)
		# Side detour adds distance, with visible mint markings and safe landings.
		var side := 1.0 if sector % 2 == 0 else -1.0
		var x := 8.0 * side
		w.race_waypoints.append(Vector3(x, 0.2, z - 1))
		for step in 5:
			var p := Vector3(x, 0, z - 2.2 - step * 4.2)
			w.box(w, p.x - 2, -0.4, p.z - 1.6, 4, 0.4, 3.2, color.darkened(0.15), true, 0, 8 if theme in [0, 1, 4] else -1)
			w.box(w, p.x - 1.8, 0.015, p.z - 1.45, 0.12, 0.025, 2.9, Color("90ebba"), false, 0, -1)
			w.race_waypoints.append(p + Vector3(0, 0.2, 0))
		_sign(w, Vector3(x, 2.5, z - 1), "ROTA SEGURA", Color("a2f3c2"))
		_sign(w, Vector3(0, 3.2, z - 1), "%02d / ATALHO" % (sector + 1), color)
		_build_skill_lane(w, str(RECIPES[theme][sector]), z, color)
		w._add_kz_ring(Vector3(0, 1.5, z - 10), sector)
		w.race_waypoints.append(Vector3(x, 0.2, end - 1.8))
		w.add_checkpoint_arch(Vector3(0, 0, end - 1.8), sector + 1, "SETOR %d / 8" % (sector + 1), color)
		if str(RECIPES[theme][sector]) in ["BELT", "BUMPERS", "PENDULUM", "PUSHERS"]:
			for distance in [3.0, 8.0, 14.0, 20.0]:
				w.race_fast_waypoints.append(Vector3(0, 0.2, z - distance))
			w.race_fast_waypoints.append(Vector3(0, 0.2, end - 1.8))
		else:
			w.race_fast_waypoints.append_array(w.race_waypoints.slice(safe_start))
		var cp: Dictionary = w.kz_checkpoints.back()
		cp["width"] = 11.0
		var props := DistrictProps.new()
		props.flowerbed(Vector3(-10, 0.05, end - 2), 1.5, sector + 17)
		props.flowerbed(Vector3(10, 0.05, end - 2), 1.5, sector + 23)
		# Floating masonry bases and mossy borders make each safe landing an island.
		for step in 5:
			var p := Vector3(x, -0.8, z - 2.2 - step * 4.2)
			props.piece("rock", p, Vector3(3.9, 0.8, 3), Color("a18c75"))
			for edge in [-1.0, 1.0]:
				props.piece("ball", p + Vector3(edge * 1.85, 0.45, 0.1), Vector3(0.35, 0.22, 1.9), Color("85966c"))
		for sign_side in [-1.0, 1.0]:
			var p := Vector3(sign_side * (16.0 + sector % 3), -0.2, z - 12)
			match theme:
				0:
					props.island(p, Color("b2d5b1"), sector)
					props.blossom(p, color, sector)
				1:
					props.pavilion(p, color if sector % 2 == 0 else Color("88b6b0"), sector)
				2:
					props.island(p, Color("dcbd8a"), sector)
				4:
					props.pavilion(p, Color("9b625c"), sector)
					props.blossom(p + Vector3(3, 0, 4), Color("9bb87b"), sector)
				5:
					props.tower(p, color, sector % 2)
					props.car(p + Vector3(0, 0, 4), Color("8fcfd0"), PI * 0.5)
				3:
					props.tower(p, color if sector % 2 == 0 else Color("7bd8d4"), sector)
		props.flush(w._stage_root)
		z = end - 4
	w.kz_finish_pad = Vector3(0, 0.2, z - 3.5)
	w.box(w, -5, -0.5, z - 8, 10, 0.5, 9, Color("e3d1aa"), true, 0, -1)
	w._add_finish_sanctuary(Vector3(0, 0, z - 3.5), "CHEGADA")
	w.race_waypoints.append(w.kz_finish_pad)
	w.race_fast_waypoints.append(w.kz_finish_pad)
	_sign(w, Vector3(0, 5.8, z - 3), "CHEGADA", Color("f5d580"))

static func _sign(w: SakuraWorld, p: Vector3, title: String, color: Color) -> void:
	var sign_node := Label3D.new()
	sign_node.text = title
	sign_node.position = p
	sign_node.font_size = 36
	sign_node.pixel_size = 0.006
	sign_node.modulate = color
	sign_node.outline_size = 5
	sign_node.visibility_range_end = 65
	w._stage_root.add_child(sign_node)

static func _build_skill_lane(w: SakuraWorld, kind: String, z: float, color: Color) -> void:
	var dark := Color("344459")
	if kind in ["DRUMS", "MOVERS", "STEPS"]:
		for i in 5:
			var p := Vector3(sin(i * 1.7) * 0.6, 0, z - 2.4 - i * 4.2)
			match kind:
				"DRUMS":
					w.add_bouncy_drum(p, 1.75, color, Color("f5d580"))
				"MOVERS":
					w._add_moving_platform(p, Vector3(3.8, 0.4, 3.4), Vector3(0.65, 0, 0), 1.1, i * 0.7, color)
				_:
					w.box(w, p.x - 1.8, -0.4, p.z - 1.7, 3.6, 0.4 + (i % 2) * 0.4, 3.4, color, true, 0, -1)
		return
	if kind == "SEESAW":
		for i in 3:
			w.add_tilting_seesaw(Vector3(0, 0.12, z - 3.7 - i * 7.2), 5, 6.4, 0.22, 1.15, i * 1.5, color)
		return
	if kind == "SURF":
		w._add_surf_ramp(Vector3(0, -0.4, z - 10.5), 6.5, 2, 18, color)
		w.box(w, -3.4, -0.5, z - 22, 6.8, 0.3, 22, dark, true, 0, -1)
		return
	w.box(w, -2.7, -0.4, z - 22, 5.4, 0.4, 22, dark, true, 0, -1)
	match kind:
		"BELT":
			w.add_speed_conveyor(-2.6, 0.03, z - 21.8, 5.2, 21.8, Vector3(0, 0, 2.0), color)
			for i in 3:
				w.add_bumper_pillar(Vector3(-1.2 if i % 2 == 0 else 1.2, 0, z - 5 - i * 5), 0.5, 1.4, color)
		"BUMPERS":
			for i in 5:
				w.add_bumper_pillar(Vector3(-1.3 if i % 2 == 0 else 1.3, 0, z - 3 - i * 4), 0.55, 1.4, color)
		"SWEEP":
			w._add_sweeper_island(Vector3(0, 0.08, z - 10), 3.0, 1.3)
		"HAMMER":
			for i in 2:
				w.add_spinning_hammer(Vector3(0, 0, z - 6 - i * 10), 2.2, 1.5 if i == 0 else -1.5, Color("f5d580"), color)
		"PENDULUM":
			for i in 2:
				w.add_swinging_pendulum(Vector3(0, 0, z - 6 - i * 10), 6, 6, 1.5, i * 1.4, color)
		"PUSHERS":
			for i in 3:
				var side := -1.0 if i % 2 == 0 else 1.0
				w.add_sliding_pusher(Vector3(side * 3.2, 0, z - 4 - i * 6), Vector3(1.8, 1.6, 2.4), -side, 2.5, 1.6, i * 1.8, color)
