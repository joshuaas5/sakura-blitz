class_name CombatTactics
extends RefCounted
## Bounded tactical queries: scene geometry and the last observation, never hidden actors.
static func collect_cover(node: Node, result: Array[AABB]) -> void:
	if node is CollisionShape3D and node.shape is BoxShape3D and node.get_parent() is StaticBody3D:
		var box: AABB = node.global_transform * AABB(-node.shape.size * 0.5, node.shape.size)
		if box.size.y > 0.75 and box.size.x < 18 and box.size.z < 18:
			result.append(box)
	for child in node.get_children():
		collect_cover(child, result)

static func clear_point(w: SakuraWorld, at: Vector3) -> Variant:
	var point: Variant = SpawnDirector.grounded(w, at)
	if point == null or absf(point.y - at.y) > 1.1:
		return null
	return point

static func cover(w: SakuraWorld, from: Vector3, threat: Vector3) -> Variant:
	var nearby: Array[AABB] = []
	for box in w.combat_cover:
		if box.get_center().distance_to(from + Vector3.UP) < 11 and box.position.y < from.y + 1.4 and box.end.y > from.y + 0.8:
			nearby.append(box)
	nearby.sort_custom(func(a, b): return a.get_center().distance_squared_to(from) < b.get_center().distance_squared_to(from))
	var best: Variant = null
	var best_score := -INF
	var space := w.get_world_3d().direct_space_state
	for i in mini(4, nearby.size()):
		var box := nearby[i]
		var center := box.get_center()
		for offset in [Vector3(box.size.x / 2 + 1, 0, 0), Vector3(-box.size.x / 2 - 1, 0, 0), Vector3(0, 0, box.size.z / 2 + 1), Vector3(0, 0, -box.size.z / 2 - 1)]:
			var candidate: Vector3 = Vector3(center.x, from.y, center.z) + offset
			if candidate.distance_to(from) > 10 or candidate.distance_to(from) < 1:
				continue
			var point: Variant = clear_point(w, candidate)
			if point == null:
				continue
			var ray := PhysicsRayQueryParameters3D.create(threat + Vector3.UP * 1.4, point + Vector3.UP * 1.2, 1)
			if space.intersect_ray(ray).is_empty():
				continue
			if w.arena_navigation != null and w.arena_navigation.path(from, point).is_empty():
				continue
			var score: float = -from.distance_to(point) + minf(point.distance_to(threat), 18) * 0.2
			if score > best_score:
				best_score = score
				best = point
	return best

static func flank(w: SakuraWorld, from: Vector3, last_seen: Vector3, side: float) -> Variant:
	if w.arena_navigation == null:
		return null
	var toward := (last_seen - from) * Vector3(1, 0, 1)
	if toward.length() < 7 or toward.length() > 24:
		return null
	var right := Vector3(-toward.z, 0, toward.x).normalized()
	for sign_value in [side, -side]:
		var point: Variant = clear_point(w, from + toward * 0.45 + right * sign_value * 5)
		if point != null and not w.arena_navigation.path(from, point).is_empty():
			return point
	return null
