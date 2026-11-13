class_name CombatAudio
extends Node3D
## A bounded stage-owned 3D voice pool. Hearing cues are independent of device volume.
const VOICES := 16
var world: SakuraWorld
var pool: Array[AudioStreamPlayer3D] = []
var streams := {}
var previous_player := Vector3.ZERO
var player_distance := 0.0
var voice_cursor := 0
var last_requested := ""
var airborne_drop := 0.0
var was_grounded := false

func setup(w: SakuraWorld) -> void:
	world = w
	previous_player = w.player_pos
	for name in ["step_stone", "step_wood", "step_metal", "land_soft"]:
		streams[name] = load("res://assets/audio/original/%s.wav" % name)
	for name in ["smg_shoot", "shotgun_shoot", "rail_shoot", "brisa_shoot"]:
		streams[name] = Sfx._streams[name]
	for i in VOICES:
		var voice := AudioStreamPlayer3D.new()
		voice.bus = "Effects"
		voice.unit_size = 5
		voice.max_distance = 45
		add_child(voice)
		pool.append(voice)

func play_at(name: String, at: Vector3, volume: float = -12, pitch: float = 1) -> void:
	last_requested = name
	if Sfx.muted or not streams.has(name):
		return
	var voice := pool[voice_cursor]
	for candidate in pool:
		if not candidate.playing:
			voice = candidate
			break
	voice_cursor = (voice_cursor + 1) % VOICES
	voice.stop()
	voice.stream = streams[name]
	voice.global_position = at
	var occlusion := PhysicsRayQueryParameters3D.create(world.player_pos + Vector3.UP * 1.4, at + Vector3.UP * 0.3, 1)
	voice.volume_db = volume - (8.0 if not world.get_world_3d().direct_space_state.intersect_ray(occlusion).is_empty() else 0.0)
	voice.pitch_scale = pitch
	voice.play()

func noise(at: Vector3, source: EnemyBot = null, loudness: float = 1) -> void:
	if world.game_mode != SakuraWorld.MODE_COMBAT:
		return
	for bot in world.enemies:
		if is_instance_valid(bot) and bot != source and not bot._dead:
			bot.hear_noise(at, loudness)

func footstep(at: Vector3, player: bool = false) -> void:
	var wood: bool = world.game_mode == 0 and (world.current_stage_idx == 7 or (world.current_stage_idx == 5 and at.x > -13.2 and at.x < -6.8 and at.z > 6.8 and at.z < 13.2))
	var metal: bool = world.game_mode == 0 and world.current_stage_idx == 1 and at.y > 0.1
	play_at("step_metal" if metal else ("step_wood" if wood else "step_stone"), at + Vector3.UP * 0.15, -15 if player else -12, 0.95 + float(voice_cursor % 4) * 0.035)
	if player:
		noise(at, null, 0.22)

func _physics_process(_delta: float) -> void:
	var movement := world.player_pos.distance_to(previous_player)
	var descent := maxf(0, previous_player.y - world.player_pos.y)
	previous_player = world.player_pos
	if movement > 4:
		airborne_drop = 0
		was_grounded = world.player_grounded
		player_distance = 0
		return
	if not world.player_grounded:
		airborne_drop += descent
		player_distance = 0
		was_grounded = false
		return
	if not was_grounded and airborne_drop > 0.3:
		play_at("land_soft", world.player_pos, -13)
	was_grounded = true
	airborne_drop = 0
	player_distance += movement
	if player_distance > 2.0:
		player_distance = 0
		footstep(world.player_pos, true)
