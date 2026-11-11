class_name RetroTex
## High-detail 64x64 procedural pixel textures for the PS1-Plus look.
## Multiplies over any surface colour so every building, roof, tree, cobblestone plaza,
## and parkour wall-run panel gets crisp pixel-art detail.
## Kinds:
##   0 grain/metal, 1 wood planks, 2 bricks, 3 roof shingles, 4 stone/asphalt,
##   5 meadow grass, 6 foliage/sakura, 7 warm plaster, 8 courtyard stone slabs,
##   9 dirt/pebbles, 10 parkour chevron wall-run grip, 11 shoji lattice window.

const N := 64
const KINDS := 12
static var _array: Texture2DArray


static func array() -> Texture2DArray:
	if _array != null:
		return _array
	var imgs: Array[Image] = []
	for k in KINDS:
		var img := Image.create(N, N, false, Image.FORMAT_RGB8)
		var r := RandomNumberGenerator.new()
		r.seed = 137 + k * 43
		for y in N:
			for x in N:
				var v := _texel(k, x, y, r)
				var c := clampf(v * 0.5, 0.05, 0.98)
				img.set_pixel(x, y, Color(c, c, c))
		if k == 6:
			_leaf_blobs(img, r)
		imgs.append(img)
	_array = Texture2DArray.new()
	_array.create_from_images(imgs)
	return _array


static func _texel(k: int, x: int, y: int, r: RandomNumberGenerator) -> float:
	var n := r.randf_range(-1.0, 1.0)
	match k:
		1:
			# Wood planks: 8 texels high, bevel highlight on top, dark seam below, grain streaks
			var row := y / 8
			var tone := 0.90 + 0.16 * fposmod(sin(row * 12.9898) * 43758.5453, 1.0)
			if y % 8 == 7:
				return 0.58
			if y % 8 == 0:
				return 1.12
			var joint := int(fposmod(sin(row * 78.233) * 9631.7, 1.0) * N)
			if x == joint or x == (joint + 1) % N:
				return 0.66
			var grain := sin((x * 0.35) + sin(y * 0.8) * 1.5 + row * 2.1) * 0.05
			return tone + grain + 0.03 * n
		2:
			# Bricks: 16 x 8 texels with recessed mortar & subtle top bevel
			var row := y / 8
			var bx := (x + (8 if row % 2 == 1 else 0)) % 16
			if y % 8 == 7 or bx == 15:
				return 1.18
			if y % 8 == 0 or bx == 0:
				return 1.06
			var id := (x + (8 if row % 2 == 1 else 0)) / 16 + row * 7
			return 0.84 + 0.16 * fposmod(sin(id * 3.17) * 917.3, 1.0) + 0.035 * n
		3:
			# Terracotta / slate roof shingles: scalloped tiles with deep shadow lip
			var row := y / 8
			var tx := (x + (4 if row % 2 == 1 else 0)) % 8
			if y % 8 == 7:
				return 0.56
			if y % 8 == 6:
				return 0.74
			if tx == 7:
				return 0.76
			return (1.14 if y % 8 == 0 else 0.98) + 0.035 * n
		4:
			# Cobblestone / asphalt speckles
			var v := 1.0 + 0.09 * n
			if r.randf() < 0.035:
				v = 0.72
			elif r.randf() < 0.03:
				v = 1.16
			if (x * 3 + y * 5) % 41 == 0:
				v = 0.70
			return v
		5:
			# Sunlit grass: blades and clover clusters
			var v := 1.0 + 0.08 * n
			if (x * 7 + y * 13) % 13 == 0:
				v = 1.25
			elif (x * 5 + y * 3) % 15 == 0:
				v = 0.76
			return v
		6:
			return 0.86 + 0.05 * n
		7:
			# Stucco / warm plaster facade
			return 0.98 + 0.04 * sin(x * 0.4) * cos(y * 0.35) + 0.025 * n
		8:
			# Courtyard stone slabs (16x16 with bevel & ornamental inner corner)
			var lx := x % 16
			var ly := y % 16
			if lx == 0 or ly == 0:
				return 0.72
			if lx == 1 or ly == 1:
				return 1.12
			if lx == 15 or ly == 15:
				return 0.86
			return 1.0 + 0.035 * n
		9:
			# Dirt & garden path
			var v := 0.98 + 0.07 * n
			if r.randf() < 0.04:
				v = 1.18
			return v
		10:
			# Parkour Wall-Run Grip Panel (diagonal chevron stripes + border frame)
			if x < 2 or x >= N - 2 or y < 2 or y >= N - 2:
				return 0.68
			var stripe := posmod(x + y, 16)
			if stripe < 5:
				return 1.22
			elif stripe == 5:
				return 0.65
			return 0.92 + 0.03 * n
		11:
			# Shoji / Lattice frame
			if x % 16 < 2 or y % 16 < 2:
				return 0.55
			return 1.15 + 0.02 * n
	return 1.0 + 0.05 * n


static func _leaf_blobs(img: Image, r: RandomNumberGenerator) -> void:
	for b in 55:
		var cx := r.randi_range(0, N - 1)
		var cy := r.randi_range(0, N - 1)
		var rad := r.randi_range(3, 7)
		for dy in range(-rad, rad + 1):
			for dx in range(-rad, rad + 1):
				var d := Vector2(dx, dy).length()
				if d > rad:
					continue
				var v := 1.20 - 0.12 * (d / rad) - (0.24 if dy > rad * 0.45 else 0.0)
				var c := clampf(v * 0.5, 0.05, 0.98)
				img.set_pixel(posmod(cx + dx, N), posmod(cy + dy, N), Color(c, c, c))


static func kind_for(c: Color, emit: float, glassy: bool) -> int:
	if emit > 0.4 or glassy:
		return -1
	var h := c.h
	var s := c.s
	var v := c.v
	if s < 0.15:
		return 4 if v < 0.42 else 8
	if h > 0.19 and h < 0.46:
		return 6 if v < 0.6 else 5
	if (h < 0.045 or h > 0.92) and s > 0.35 and v > 0.32 and v < 0.85:
		# Sakura pinks -> foliage texture (6), terracotta reds -> roof shingles (3)
		return 6 if h > 0.90 and v > 0.68 else 3
	if h >= 0.03 and h <= 0.14:
		if s > 0.42 or v < 0.52:
			return 1
		if v < 0.72:
			return 9
		return 2
	if v > 0.74 and s < 0.32:
		return 7
	return 0
