class_name ArenaNavigation
extends RefCounted
## Ground-plane navigation for the four curated arenas; SurfaceNavigation handles layered legacy maps.
## Collision boxes are the single source for clearance; no physics/server bake race.
const CLEARANCE := 0.65
var grid := AStarGrid2D.new()
var obstacles: Array[AABB] = []

func build() -> void:
	grid.region = Rect2i(-25, -27, 51, 55)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(-25, 26):
		for z in range(-27, 28):
			for obstacle in obstacles:
				if obstacle.grow(CLEARANCE).has_point(Vector3(x, 0.9, z)):
					grid.set_point_solid(Vector2i(x, z))
					break

func nearest(at: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(at.x), -25, 25), clampi(roundi(at.z), -27, 27))
	if not grid.is_point_solid(cell):
		return cell
	# Only used when a target is jumping or pressed against cover.
	for radius in range(1, 12):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return cell

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	for point in grid.get_id_path(nearest(from), nearest(to)):
		result.append(Vector3(point.x, 0.15, point.y))
	return result
