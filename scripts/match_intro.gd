class_name MatchIntro
extends Control
## Non-interactive briefing, synchronized with the actual ready phase.
var game: SakuraBlitzMain
var heading: Label
var mode_label: Label
var rule: Label
var roster: Label
var number: Label

func setup(g: SakuraBlitzMain) -> void:
	game = g
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 45
	heading = game._hub._label("", 30)
	mode_label = game._hub._label("", 13, Color("e6c88f"))
	rule = game._hub._label("", 15, Color("c1d9cc"))
	roster = game._hub._label("", 13, Color("9de4c0"))
	number = game._hub._label("", 74, Color("f0d29a"))
	for label in [heading, mode_label, rule, roster, number]:
		label.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(label)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hide()

func _process(_delta: float) -> void:
	var time := game.world.combat_ready_time
	visible = game.current_mode == 0 and time > 0 and not game._hub_open and not game._paused
	if not visible:
		return
	modulate.a = minf(1, time * 5)
	var safe := game._safe_ui_rect().grow(-24)
	var y := safe.get_center().y - 78
	mode_label.position = Vector2(safe.position.x + 24, y)
	mode_label.size = Vector2(safe.size.x - 190, 24)
	mode_label.text = "SAKURA BLITZ / " + CombatMatch.LABELS[game.world.match_kind].to_upper()
	heading.position = mode_label.position + Vector2(0, 29)
	heading.size = Vector2(safe.size.x - 190, 74)
	heading.text = game.world.get_active_stage_def().title.to_upper()
	rule.position = mode_label.position + Vector2(0, 110)
	rule.size = Vector2(safe.size.x - 190, 54)
	rule.text = ["Encontre adversários e alcance a meta de abates.", "Proteja seus aliados. As eliminações somam para a equipe.", "Pegue a bandeira adversária e volte com a sua em casa."][game.world.match_kind]
	roster.position = mode_label.position + Vector2(0, 174)
	roster.size = Vector2(safe.size.x - 120, 24)
	roster.text = "CADA UM POR SI • %d ADVERSÁRIOS" % game.world.bots_per_round if game.world.match_kind == 0 else "VOCÊ É MENTA • %d × %d • SEM FOGO AMIGO" % [(game.world.bots_per_round + 1) / 2, (game.world.bots_per_round + 1) / 2]
	number.position = Vector2(safe.end.x - 134, safe.get_center().y - 60)
	number.size = Vector2(112, 112)
	number.text = str(maxi(1, ceili(time)))
	queue_redraw()

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.095, 0.09, 0.62))
	var safe := game._safe_ui_rect().grow(-24)
	var y := safe.get_center().y
	draw_rect(Rect2(safe.position.x, y - 100, safe.size.x, 235), Color(0.06, 0.17, 0.15, 0.91))
	draw_line(Vector2(safe.position.x, y - 100), Vector2(safe.end.x, y - 100), Color("ad9669"), 2)
	draw_line(Vector2(safe.position.x, y + 135), Vector2(safe.end.x, y + 135), Color("617f69"), 2)
	draw_arc(Vector2(safe.end.x - 78, y - 4), 55, -PI / 2, -PI / 2 + TAU * fposmod(game.world.combat_ready_time, 1), 64, Color("a3d6b3"), 3, true)
