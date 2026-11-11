extends Node
## Synthesized Retro Arcade Audio Manager (Sfx autoload)
## Supports Tactical Black Ops BGM + Garry's Mod Parkour "El Panadero con el Pan" Radio!

var _streams := {}
var _bgm_streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var muted := false
var bgm_enabled := true
var panadero_mode := false


func _ready() -> void:
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

	for i in 12:
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -5.0
		add_child(ap)
		_pool.append(ap)

	for track in ["bgm_sakura", "bgm_panadero"]:
		var tp := "res://assets/audio/%s.wav" % track
		if ResourceLoader.exists(tp):
			var st := load(tp) as AudioStreamWAV
			if st != null:
				st.loop_mode = AudioStreamWAV.LOOP_FORWARD
				st.loop_begin = 0
				st.loop_end = int(st.get_length() * st.mix_rate)
				_bgm_streams[track] = st

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -10.0
	if _bgm_streams.has("bgm_sakura"):
		_bgm_player.stream = _bgm_streams["bgm_sakura"]
	add_child(_bgm_player)
	if not OS.get_cmdline_user_args().has("--test"):
		_bgm_player.play()


func set_panadero_radio(active: bool) -> void:
	if panadero_mode == active:
		return
	panadero_mode = active
	var key := "bgm_panadero" if panadero_mode else "bgm_sakura"
	if _bgm_streams.has(key):
		_bgm_player.stream = _bgm_streams[key]
		_bgm_player.volume_db = -7.5 if panadero_mode else -10.5
		if bgm_enabled and not muted and not OS.get_cmdline_user_args().has("--test"):
			_bgm_player.play()


func play(sfx_name: String, pitch: float = 1.0, vol_db: float = -4.0) -> void:
	if muted or not _streams.has(sfx_name):
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
