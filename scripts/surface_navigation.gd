class_name SurfaceNavigation
extends ArenaNavigation
## Layered graph built from static collision geometry, including stairs and stacked floors.
## No scene nodes are retained. Five immutable arena graphs can be reused across rounds.
const CELL := 0.5
const RADIUS := 0.52
const MAX_STEP := 0.46
static var _cache: Dictionary = {}
var graph := AStar3D.new()
var columns: Dictionary = {}
var surfaces: Dictionary = {}
var bounds := Rect2i()
var build_ms := 0

static func for_stage(root: Node3D, index: int) -> SurfaceNavigation:
	if _cache.has(index):
		return _cache[index]
	var nav := SurfaceNavigation.new()
	var regions := [Rect2(-18, -18, 36, 36), Rect2(-19, -19, 38, 38), Rect2(-24, -34, 48, 68), Rect2(-22, -22, 44, 44), Rect2(-22, -24, 44, 48)]
	nav.bake(root, regions[index])
	_cache[index] = nav
	return nav

func bake(root: Node3D, region: Rect2) -> void:
	var started := Time.get_ticks_msec()
	graph.clear()
	columns.clear()
	surfaces.clear()
	obstacles.clear()
	bounds = Rect2i(Vector2i(region.position / CELL), Vector2i(region.size / CELL) + Vector2i.ONE)
	_collect(root)
	for box in obstacles:
		var start := Vector2i(floori((box.position.x - RADIUS) / CELL), floori((box.position.z - RADIUS) / CELL))
		var end := Vector2i(ceili((box.end.x + RADIUS) / CELL), ceili((box.end.z + RADIUS) / CELL))
		for x in range(maxi(start.x, bounds.position.x), mini(end.x + 1, bounds.end.x)):
			for z in range(maxi(start.y, bounds.position.y), mini(end.y + 1, bounds.end.y)):
				var cell := Vector2i(x, z)
				if not columns.has(cell):
					columns[cell] = []
				columns[cell].append(box)
	for cell in columns:
		var heights: Array[float] = []
		var x: float = cell.x * CELL
		var z: float = cell.y * CELL
		for box: AABB in columns[cell]:
			var y := snappedf(box.end.y, 0.01)
			if y < -0.2 or y > 8 or x < box.position.x or x > box.end.x or z < box.position.z or z > box.end.z or heights.has(y):
				continue
			heights.append(y)
			var at := Vector3(x, y + 0.05, z)
			if _body_clear(at) and _supported(at):
				var id := graph.get_point_count()
				graph.add_point(id, at)
				if not surfaces.has(cell):
					surfaces[cell] = []
				surfaces[cell].append(id)
	for cell in surfaces:
		for offset in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
			var other: Vector2i = cell + offset
			if not surfaces.has(other):
				continue
			for id: int in surfaces[cell]:
				var from := graph.get_point_position(id)
				for next: int in surfaces[other]:
					var to := graph.get_point_position(next)
					if absf(from.y - to.y) > MAX_STEP + 0.001:
						continue
					if offset.x != 0 and offset.y != 0:
						if not _has_height(cell + Vector2i(offset.x, 0), from.y, to.y) or not _has_height(cell + Vector2i(0, offset.y), from.y, to.y):
							continue
					var middle := (from + to) * 0.5
					middle.y = maxf(from.y, to.y)
					if _body_clear(middle):
						graph.connect_points(id, next)
	# Only adjacency and point positions are needed once the graph is built.
	columns.clear()
	build_ms = Time.get_ticks_msec() - started

func _collect(node: Node) -> void:
	if node is CollisionShape3D and node.get_parent() is StaticBody3D and not node.disabled:
		var shape: Shape3D = node.shape
		var size := Vector3.ZERO
		if shape is BoxShape3D:
			size = shape.size
		elif shape is CylinderShape3D:
			size = Vector3(shape.radius * 2, shape.height, shape.radius * 2)
		if size != Vector3.ZERO:
			obstacles.append(node.global_transform * AABB(-size * 0.5, size))
	for child in node.get_children():
		_collect(child)

func _body_clear(at: Vector3) -> bool:
	var cell := Vector2i(roundi(at.x / CELL), roundi(at.z / CELL))
	for box: AABB in columns.get(cell, []):
		if at.x >= box.position.x and at.x <= box.end.x and at.z >= box.position.z and at.z <= box.end.z and box.position.y < at.y + 0.01 and box.end.y > at.y + 0.01:
			return false
		# Low risers are traversed by collision-tested step assist in EnemyBot.
		if box.end.y <= at.y + MAX_STEP or box.position.y >= at.y + 1.82:
			continue
		if at.x > box.position.x - RADIUS and at.x < box.end.x + RADIUS and at.z > box.position.z - RADIUS and at.z < box.end.z + RADIUS:
			return false
	return true

func _supported(at: Vector3) -> bool:
	# Keep the capsule center away from exposed sides, while allowing stair risers.
	for offset in [Vector3(0.4, 0, 0), Vector3(-0.4, 0, 0), Vector3(0, 0, 0.4), Vector3(0, 0, -0.4)]:
		var sample: Vector3 = at + offset
		var cell := Vector2i(roundi(sample.x / CELL), roundi(sample.z / CELL))
		var found := false
		for box: AABB in columns.get(cell, []):
			if sample.x >= box.position.x and sample.x <= box.end.x and sample.z >= box.position.z and sample.z <= box.end.z and absf(box.end.y + 0.05 - at.y) <= MAX_STEP + 0.01:
				found = true
				break
		if not found:
			return false
	return true


func _has_height(cell: Vector2i, a: float, b: float) -> bool:
	for id: int in surfaces.get(cell, []):
		var y := graph.get_point_position(id).y
		if absf(y - a) <= MAX_STEP and absf(y - b) <= MAX_STEP:
			return true
	return false

func nearest_id(at: Vector3) -> int:
	var cell := Vector2i(roundi(at.x / CELL), roundi(at.z / CELL))
	var best := -1
	var distance := INF
	for radius in range(0, 9):
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				if radius > 0 and absi(x) != radius and absi(z) != radius:
					continue
				for id: int in surfaces.get(cell + Vector2i(x, z), []):
					var delta := graph.get_point_position(id) - at
					var score := delta.x * delta.x + delta.z * delta.z + delta.y * delta.y * 4
					if score < distance:
						distance = score
						best = id
		if best >= 0 and distance < pow((radius + 1) * CELL, 2):
			break
	return best

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := nearest_id(from)
	var end := nearest_id(to)
	if start < 0 or end < 0:
		return PackedVector3Array()
	return graph.get_point_path(start, end)
