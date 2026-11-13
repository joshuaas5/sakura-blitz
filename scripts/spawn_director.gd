class_name SpawnDirector
extends RefCounted
## Score authored spawn points against actual opponents and static geometry.
var recent: Array[Vector3] = []
var last_report := {}

static func grounded(w: SakuraWorld, at: Vector3) -> Variant:
	var space := w.get_world_3d().direct_space_state
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.7, at - Vector3.UP * 1.2, 1))
	if floor_hit.is_empty() or (floor_hit.normal as Vector3).y < 0.7:
		return null
	var point: Vector3 = floor_hit.position + Vector3.UP * 0.05
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.82
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * 0.91)
	query.collision_mask = 1
	return point if space.intersect_shape(query, 1).is_empty() else null

func choose(w: SakuraWorld, player: bool, seed: int = 0, team: int = -1) -> Vector3:
	var candidates: Array = w.tr_spawns.duplicate()
	if player:
		candidates.append(w._current_pvp_spawn)
		team = w.team_for("PLAYER")
	if team >= 0:
		var side := candidates.filter(func(at): return at.z > 1 if team == 0 else at.z < -1)
		if not side.is_empty():
			candidates = side
	var threats: Array[Vector3] = []
	for bot in w.enemies:
		if is_instance_valid(bot) and not bot._dead and (team < 0 or bot.team_id != team):
			threats.append(bot.global_position)
	if not player and (team < 0 or team != w.team_for("PLAYER")):
		threats.append(w.player_pos if w.stage_physics_ready else w._current_pvp_spawn)
	var best: Vector3 = w._current_pvp_spawn if player else w.tr_spawns[posmod(seed, w.tr_spawns.size())]
	var best_score := -INF
	var valid_count := 0
	var space := w.get_world_3d().direct_space_state
	for i in candidates.size():
		var at: Vector3 = candidates[i]
		if w.stage_physics_ready:
			var floor_point: Variant = grounded(w, at)
			if floor_point == null:
				continue
			at = floor_point
		valid_count += 1
		var large := not w.combat_patrol_points.is_empty()
		var nearest := 200.0 if large else 40.0
		var exposed := 0
		for threat in threats:
			var distance := at.distance_to(threat)
			nearest = minf(nearest, distance)
			if w.stage_physics_ready and distance < (48 if large else 36):
				var ray := PhysicsRayQueryParameters3D.create(threat + Vector3.UP * 1.4, at + Vector3.UP * 1.4, 1)
				if space.intersect_ray(ray).is_empty():
					exposed += 1
		var score := minf(nearest, 30) * 2.0 - exposed * 18.0
		if large:
			# Safe cover matters more than sending every respawn to the far corner.
			score = minf(nearest, 22) * 2 - maxf(0, nearest - 36) * 0.7 - exposed * 24
		if nearest < 7:
			score -= (7 - nearest) * 30
		for previous in recent:
			if previous.distance_to(at) < 2:
				score -= 12
		# Deterministic tie breaking avoids jitter moving a spawn into a wall.
		score += float(posmod(i - seed, candidates.size())) * 0.001
		if score > best_score:
			best_score = score
			best = at
	last_report = {"valid_candidates": valid_count, "score": best_score, "position": best}
	recent.append(best)
	if recent.size() > 4:
		recent.pop_front()
	return best
