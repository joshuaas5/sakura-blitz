extends Node
## Synthesized Retro Arcade Audio Manager (Sfx autoload)
## Original procedural music, separate music volume, pooled arcade effects.

var _streams := {}
var _bgm_streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var muted := OS.get_cmdline_user_args().has("--test") or OS.get_cmdline_user_args().has("--qa") or OS.get_cmdline_user_args().has("--shot")
var bgm_enabled := true
var panadero_mode := false
var music_volume := 0.35
var music_context := "lobby"
var effects_volume := 1.0
var ambience_volume := 0.6
var _music_tween: Tween


func _ready() -> void:
	for bus in ["Effects", "Ambience"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var names := [
		"smg_shoot", "shotgun_shoot", "rail_shoot", "reload",
		"hitmarker", "headshot", "enemy_die", "jump",
		"double_jump", "dash", "jumppad", "ring_pass",
		"course_win", "pickup", "hurt", "cash_buy", "rank_up", "killcam"
	]
	for n in names:
		var p := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(p):
			_streams[n] = load(p)

	for n in ["brisa_shoot", "flora_shoot"]:
		_streams[n] = load("res://assets/audio/original/%s.wav" % n)

	for i in 12:
		var ap := AudioStreamPlayer.new()
		ap.bus = "Effects"
		ap.volume_db = -5.0
		add_child(ap)
		_pool.append(ap)

	for track in ["bloom_lobby", "petal_dash", "neon_skirmish"]:
		var tp := "res://assets/audio/original/%s.wav" % track
		if ResourceLoader.exists(tp):
			var st := load(tp) as AudioStreamWAV
			if st != null:
				st.loop_mode = AudioStreamWAV.LOOP_FORWARD
				st.loop_begin = 0
				st.loop_end = int(st.get_length() * st.mix_rate)
				_bgm_streams[track] = st

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = _music_db()
	if _bgm_streams.has("bloom_lobby"):
		_bgm_player.stream = _bgm_streams["bloom_lobby"]
	add_child(_bgm_player)
	if not muted:
		_bgm_player.play()


func set_panadero_radio(active: bool) -> void:
	panadero_mode = active
	set_music_context("race" if active else "combat")


func set_music_context(context: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Ambience"), context == "lobby" or muted or ambience_volume <= 0)
	var track: String = {"lobby": "bloom_lobby", "race": "petal_dash", "combat": "neon_skirmish"}.get(context, "bloom_lobby")
	if context == music_context and _bgm_player.stream != null:
		return
	music_context = context
	if not _bgm_streams.has(track):
		return
	if is_instance_valid(_music_tween):
		_music_tween.kill()
	_bgm_player.stream = _bgm_streams[track]
	_bgm_player.volume_db = -45.0
	if bgm_enabled and not muted:
		_bgm_player.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_bgm_player, "volume_db", _music_db(), 0.65)


func _music_db() -> float:
	return linear_to_db(maxf(0.001, music_volume)) - 6.0


func configure_music(enabled: bool, volume: float) -> void:
	bgm_enabled = enabled
	music_volume = clampf(volume, 0.0, 1.0)
	if is_instance_valid(_music_tween):
		_music_tween.kill()
	_bgm_player.volume_db = _music_db()
	if not enabled or muted:
		_bgm_player.stop()
	elif not _bgm_player.playing:
		_bgm_player.play()

func configure_effects(effects: float, ambience: float) -> void:
	effects_volume = clampf(effects, 0, 1)
	ambience_volume = clampf(ambience, 0, 1)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(maxf(0.001, effects_volume)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"), muted or effects_volume <= 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(maxf(0.001, ambience_volume)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Ambience"), muted or ambience_volume <= 0 or music_context == "lobby")


func play(sfx_name: String, pitch: float = 1.0, vol_db: float = -4.0) -> void:
	if muted or OS.get_cmdline_user_args().has("--test") or not _streams.has(sfx_name):
		return
	for ap in _pool:
		if not ap.playing:
			ap.stream = _streams[sfx_name]
			ap.pitch_scale = pitch
			ap.volume_db = vol_db
			ap.play()
			return
	var ap0 := _pool[0]
	ap0.stream = _streams[sfx_name]
	ap0.pitch_scale = pitch
	ap0.volume_db = vol_db
	ap0.play()


func toggle_bgm() -> bool:
	bgm_enabled = not bgm_enabled
	if bgm_enabled and not muted:
		_bgm_player.play()
	else:
		_bgm_player.stop()
	return bgm_enabled
