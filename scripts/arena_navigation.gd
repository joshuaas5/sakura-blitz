class_name ArenaNavigation
extends RefCounted
## Ground-plane navigation for the four curated arenas; SurfaceNavigation handles layered legacy maps.
## Collision boxes are the single source for clearance; no physics/server bake race.
const CLEARANCE := 0.65
var grid := AStarGrid2D.new()
var obstacles: Array[AABB] = []

func build(region: Rect2i = Rect2i(-25, -27, 51, 55)) -> void:
	grid.region = region
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	# Touch only each collider's footprint, rather than scan every collider per cell.
	for obstacle in obstacles:
		var box := obstacle.grow(CLEARANCE)
		for x in range(maxi(region.position.x, floori(box.position.x)), mini(region.end.x, ceili(box.end.x))):
			for z in range(maxi(region.position.y, floori(box.position.z)), mini(region.end.y, ceili(box.end.z))):
				if box.has_point(Vector3(x, 0.9, z)):
					grid.set_point_solid(Vector2i(x, z))

func nearest(at: Vector3) -> Vector2i:
	var region := grid.region
	var cell := Vector2i(clampi(roundi(at.x), region.position.x, region.end.x - 1), clampi(roundi(at.z), region.position.y, region.end.y - 1))
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
