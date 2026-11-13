class_name FrameDiagnostics
extends Label
var game: SakuraBlitzMain
var samples: Array[float] = []
var stage_key := ""
var elapsed := 0.0
var frames := 0
var slow_frames := 0
var refresh := 0.0
var stage_instance := 0
var warmed_up := false
var measured_elapsed := 0.0
var render_size := Vector2i.ZERO

func setup(g: SakuraBlitzMain) -> void:
	game = g
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 12)
	add_theme_color_override("font_color", Color("b8e7ca"))
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

func _process(delta: float) -> void:
	visible = game.profile.data.show_performance and not game._hub_open and not game._paused
	if game._hub_open or game._paused:
		return
	var key := "%d/%d/%d" % [game.current_mode, game.current_stage, game._res_idx]
	var instance: int = game.world._stage_root.get_instance_id() if is_instance_valid(game.world._stage_root) else 0
	if key != stage_key or instance != stage_instance or render_size != game._vp.size:
		stage_key = key
		stage_instance = instance
		render_size = game._vp.size
		samples.clear()
		elapsed = 0
		frames = 0
		slow_frames = 0
		measured_elapsed = 0
		warmed_up = false
		refresh = 0
		text = ""
	# Exclude stage loading; sampling begins after a short warm-up.
	elapsed += delta
	if not warmed_up:
		warmed_up = elapsed >= 2
		return
	measured_elapsed += delta
	frames += 1
	slow_frames += int(delta > 0.05)
	samples.append(delta * 1000)
	if samples.size() > 600:
		samples.pop_front()
	refresh -= delta
	if refresh <= 0:
		refresh = 0.5
		text = "%d FPS • p95 %.1f ms\nQuadros >50 ms: %d" % [roundi(1000 / maxf(0.1, mean_ms())), percentile95(), slow_frames]
	var area := game._safe_ui_rect()
	position = Vector2(area.position.x + 18, area.position.y + (172 if game.current_mode == 0 else 48))

func mean_ms() -> float:
	var total := 0.0
	for sample in samples:
		total += sample
	return total / maxf(1, samples.size())

func percentile95() -> float:
	if samples.is_empty():
		return 0
	var sorted := samples.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, ceili(sorted.size() * 0.95) - 1)]

func report() -> String:
	return "SAKURA BLITZ — diagnóstico local\nSistema: %s / %s\nGPU: %s\nModo/mapa/qualidade: %s\nTela: %s\nSessão medida: %.1f s / %d quadros\nJanela recente: %d quadros\nMédia: %.2f ms / %.1f FPS\np95: %.2f ms\nQuadros acima de 50 ms na sessão: %d\nMemória estática do Godot: %.1f MiB (não é RAM total)\n" % [OS.get_name(), OS.get_model_name(), RenderingServer.get_video_adapter_name(), stage_key, str(game.size), measured_elapsed, frames, samples.size(), mean_ms(), 1000 / maxf(0.1, mean_ms()) if not samples.is_empty() else 0, percentile95(), slow_frames, OS.get_static_memory_usage() / 1048576.0]
