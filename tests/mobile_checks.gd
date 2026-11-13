extends RefCounted
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run(g: SakuraBlitzMain) -> bool:
	var previous := g.profile.data.duplicate(true)
	var old_size := g.size
	check(not ProjectSettings.get_setting("application/config/quit_on_go_back"), "Android Back is handled as pause rather than automatic exit")
	for dimensions in [Vector2(640, 360), Vector2(844, 390), Vector2(1280, 720), Vector2(1040, 480)]:
		for handed in [false, true]:
			for race in [false, true]:
				var area := Rect2(Vector2(32, 8), dimensions - Vector2(56, 20))
				var rectangles := MobileLayout.rects(area, {"hud_left_handed": handed}, race)
				check(MobileLayout.valid(rectangles, area), "Default controls fit safe area without overlap")
				check((rectangles.joystick.get_center().x > area.get_center().x) == handed, "Left-handed mode moves joystick to right")
	var invalid := {"jump": Vector4(NAN, 0, 1, 1), "fire": "broken", "extra": Vector4.ONE, "ads": Vector4(3, -1, 7, 0)}
	var clean := MobileLayout.sanitize(invalid)
	check(clean.size() == 1 and clean.ads == Vector4(1, 0, 1.35, 0.3), "Malformed saved layouts are rejected or bounded")
	var path := "user://mobile_layout_test.cfg"
	var profile := PlayerProfile.new(path)
	profile.data.hud_layout = {"jump": Vector4(0.5, 0.85, 0.8, 0.4)}
	profile.data.hud_left_handed = true
	check(profile.write_save() == OK, "HUD preferences save")
	var loaded := PlayerProfile.new(path)
	loaded.read_save()
	check(loaded.data.hud_layout == profile.data.hud_layout and loaded.data.hud_left_handed, "HUD layout survives restart")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	g._start_from_hub(0, 5)
	g._mobile_hud_enabled = true
	g.profile.data.hud_layout = {}
	g.profile.data.hud_left_handed = true
	g._safe_area_override = Rect2(Vector2(32, 12), g.size - Vector2(64, 24))
	g._atelier.sync()
	var ammo: Control = g._atelier.pieces.ammo
	var ammo_rect := Rect2(ammo.position, ammo.size * ammo.scale)
	for action in g._action_rects():
		check(not ammo_rect.intersects(g._action_rects()[action]), "Ammo display does not cover touch controls")
	var joystick := g._mobile_rect("joystick").get_center()
	g._handle_touch(31, joystick, true)
	g._handle_touch_drag(31, joystick + Vector2(0, -40), Vector2(0, -40))
	check(g._mobile_move_vec.y < -0.1, "Right-side joystick controls movement in left-handed mode")
	var jump: Rect2 = g._action_rects().jump
	g._handle_touch(32, jump.get_center(), true)
	var yaw := g._yaw
	g._handle_touch_drag(32, jump.get_center() + Vector2(20, 0), Vector2(20, 0))
	check(g._mobile_jump_held and g._yaw != yaw, "Left-side jump finger can also turn camera")
	g._pause_for_interruption()
	check(g._hub_open and g._touch_actions.is_empty() and g._mobile_move_vec == Vector2.ZERO and not g._mobile_jump_held, "Backgrounding pauses and releases every finger")
	var original: Dictionary = g.profile.data.hud_layout.duplicate(true)
	g._open_hud_editor()
	g._hud_editor.draft.hud_layout.jump = Vector4(0.5, 0.85, 1, 0.5)
	g._hud_editor.finished.emit(false)
	check(g.profile.data.hud_layout == original, "Cancel editor discards draft")
	g._open_hud_editor()
	g._hud_editor.draft.hud_layout.jump = Vector4(0.5, 0.85, 1, 0.5)
	g._hud_editor._save()
	check(not is_instance_valid(g._hud_editor) and g.profile.data.hud_layout.has("jump"), "Editor commits valid layout")
	g._open_hud_editor()
	g._hud_editor.draft.hud_layout.jump = Vector4(0.5, 0.85, 1, 0.7)
	var before_failure: Dictionary = g.profile.data.hud_layout.duplicate(true)
	var old_path := g.profile.path
	g.profile.path = "user://mobile_missing_%d/profile.cfg" % Time.get_ticks_usec()
	g._automation = false
	print("EXPECTED DIAGNOSTIC: rejecting an unwritable HUD save")
	g._hud_editor._save()
	g._automation = true
	g.profile.path = old_path
	check(is_instance_valid(g._hud_editor) and g.profile.data.hud_layout == before_failure, "Failed save keeps editor open and preserves previous layout")
	g._hud_editor.finished.emit(false)
	g._safe_area_override = Rect2()
	g.profile.data.hud_layout = {}
	g.profile.data.hud_left_handed = false
	g._start_training()
	g.set_physics_process(false)
	g._diagnostics.samples.assign([16.0, 16.0, 50.0])
	check(is_equal_approx(g._diagnostics.mean_ms(), 82.0 / 3) and g._diagnostics.percentile95() == 50, "Diagnostic reports actual frame distribution")
	check(g._diagnostics.report().contains("não é RAM total"), "Memory metric is labeled with its scope")
	check(g._training.step == 0 and g.world.enemies_paused, "Training begins with non-attacking bots")
	g._body.position += Vector3(3, 0, 0)
	g._training._process(0)
	check(g._training.step == 1, "Training movement requires actual displacement")
	g._yaw += 0.5
	g._training._process(0)
	check(g._training.step == 2, "Training look requires camera rotation")
	g._body.velocity.y = 5
	g._training._process(0)
	check(g._training.step == 3 and not g.world.enemies_paused, "Jump unlocks practice combat")
	check(not g.profile.data.tutorial_complete, "Training is incomplete before a hit")
	g.weapons.hit_registered.emit({"killed": false}, 0)
	check(g._training.step == 4 and g.profile.data.tutorial_complete, "A confirmed hit completes training")
	g._training.stop()
	check(g._hub_open and not g._training.active, "Training exits into lobby")
	g._start_training()
	g.profile.data.tutorial_complete = false
	g._training.stop()
	check(not g.profile.data.tutorial_complete, "Leaving training does not falsely mark completion")
	g.profile.data = previous
	g._safe_area_override = Rect2()
	g.size = old_size
	g.set_physics_process(true)
	g._start_from_hub(0, 5)
	print("MOBILE: %d checks, %d failures" % [checks, failures])
	return failures == 0
