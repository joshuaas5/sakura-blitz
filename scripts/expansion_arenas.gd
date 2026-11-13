class_name ExpansionArenas
extends RefCounted

static func build(w: SakuraWorld, garden: bool) -> void:
	var floor_col := Color("b2b79a") if garden else Color("b9ad96")
	var accent := Color("9aca9e") if garden else Color("e9ae74")
	w._current_pvp_spawn = Vector3(0, 0.2, 20)
	w.tr_spawns = [Vector3(-17, 0.2, -17), Vector3(17, 0.2, -17), Vector3(0, 0.2, -21), Vector3(-17, 0.2, 15), Vector3(17, 0.2, 15), Vector3(0, 0.2, 8)]
	w.box(w, -23, -0.6, -25, 46, 0.6, 50, floor_col, true, 0, 8)
	for x in [-23.0, 22.5]:
		w.box(w, x, 0, -25, 0.5, 2.5, 50, Color("3b5758"), true, 0, -1)
	for z in [-25.0, 24.5]:
		w.box(w, -23, 0, z, 46, 2.5, 0.5, Color("3b5758"), true, 0, -1)
	if garden:
		_garden(w, accent)
	else:
		_railway(w, accent)
	# Three lanes, connected by two elevated overlooks with broad stairs.
	for z in [-12.0, 12.0]:
		w.box(w, -11.5, 2.5, z - 1.4, 23, 0.35, 2.8, Color("d9c6a5"), true, 0, -1)
		for side in [-1.0, 1.0]:
			for step in 10:
				var x: float = side * (17.0 - step * 0.6)
				w.box(w, x - 0.35, 0, z - 1.4, 0.7, 0.285 * (step + 1), 2.8, Color("cab391"), true, 0, -1)
		w.box(w, -10.5, 2.85, z - 1.4, 21, 0.10, 0.12, accent, false, 0, -1)
	for x in [-17.0, 17.0]:
		w._add_weapon_pad(Vector3(x, 0.1, 0), "SUPRIMENTOS", accent)
	ParkourCourses._sign(w, Vector3(0, 6.0, -22), "JARDIM DE VIDRO" if garden else "ESTAÇÃO AURORA", accent)
	var border := DistrictProps.new()
	for side in [-1.0, 1.0]:
		for z in [-18, -6, 6, 18]:
			border.blossom(Vector3(side * 25, 0, z), Color("d9a0ae") if z % 3 == 0 else Color("9baf7d"), z)
	border.flush(w._stage_root)

static func _railway(w: SakuraWorld, accent: Color) -> void:
	for x in [-7.0, 7.0]:
		for rail in [-0.8, 0.8]:
			w.box(w, x + rail, 0.03, -24, 0.12, 0.08, 48, Color("93a4b4"), false, 0, -1)
		for i in 24:
			w.box(w, x - 1.2, 0.01, -24 + i * 2, 2.4, 0.05, 0.2, Color("a48b7d"), false, 0, -1)
		for z in [-5.0, 6.0]:
			_train(w, Vector3(x, 0, z), accent if x < 0 else Color("76b6bd"))
	# Cargo alcoves break long flanking sightlines without closing the lane.
	for side in [-1.0, 1.0]:
		for i in 3:
			w.box(w, side * 19 - 1.3, 0, -16 + i * 15, 2.6, 1.3, 2.4, Color("9f826a"), true, 0, 1)
		var props := DistrictProps.new()
		props.pavilion(Vector3(side * 28, 0, -8), Color("709ea1"), 1)
		props.tower(Vector3(side * 28, 0, 14), accent, 2)
		props.flush(w._stage_root)

static func _train(w: SakuraWorld, p: Vector3, color: Color) -> void:
	w.box(w, p.x - 1.5, 0.4, p.z - 4.3, 3, 2.1, 8.6, color, true, 0, -1)
	w.box(w, p.x - 1.6, 2.5, p.z - 4.4, 3.2, 0.25, 8.8, Color("d8d3c8"), true, 0, -1)
	for side in [-1.0, 1.0]:
		for i in 5:
			w.box(w, p.x + side * 1.51 - 0.02, 1.3, p.z - 3.7 + i * 1.5, 0.04, 0.75, 1.05, Color("274957"), false, 0, -1)
		for z in [-2.8, 2.8]:
			w.ball(w, p + Vector3(side * 1.2, 0.35, z), 0.48, Color("222d3e"), 8)
	w.box(w, p.x - 1.3, 1.3, p.z + 4.31, 2.6, 0.8, 0.05, Color("274957"), false, 0, -1)
	for x in [-0.9, 0.9]:
		w.ball(w, p + Vector3(x, 1.0, 4.4), 0.14, Color("f5d89b"), 8)

static func _garden(w: SakuraWorld, accent: Color) -> void:
	var props := DistrictProps.new()
	for x in [-8.0, 8.0]:
		for z in [-6.0, 6.0]:
			w.box(w, x - 2.3, 0, z - 2.7, 4.6, 1.1, 5.4, Color("d7c2a5"), true, 0, -1)
			w.box(w, x - 2.1, 1.08, z - 2.5, 4.2, 0.12, 5, Color("628c76"), false, 0, -1)
			props.blossom(Vector3(x, 1, z), Color("abc8a7") if z > 0 else Color("dea4b6"), int(x + z))
			props.flowerbed(Vector3(x, 1.2, z + 2.2), 4, int(x * z + 500))
			props.flowerbed(Vector3(x, 1.2, z - 2.2), 4, int(x * z + 600))
	# Open pergola: no transparent fullscreen glass or costly blended surfaces.
	for x in [-12.0, 12.0]:
		for z in [-18.0, 0.0, 18.0]:
			w.box(w, x - 0.15, 0, z - 0.15, 0.3, 6, 0.3, Color("547c75"), true, 0, -1)
			props.vine(Vector3(x, 0, z + 0.2), 5.8, int(z))
	for z in range(-18, 19, 3):
		w.box(w, -12.3, 6, z - 0.10, 24.6, 0.20, 0.20, accent, false, 0, -1)
	for x in [-17.0, 17.0]:
		props.pavilion(Vector3(x * 1.8, 0, -10), Color("849c8a"), 1)
	props.flush(w._stage_root)
	w.cyl(w, Vector3(0, -0.05, 0), 2.4, 2.6, 0.3, Color("8ebec1"), 16)
	w.box(w, -0.7, 0, -0.7, 1.4, 1.7, 1.4, Color("e7d8bf"), true, 0, -1)
	w.ball(w, Vector3(0, 2.2, 0), 0.65, Color("9bb5be"), 12)
