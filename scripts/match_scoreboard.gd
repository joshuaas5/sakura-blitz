class_name MatchScoreboard
extends PanelContainer
## Live roster for mouse and touch, with separately scrollable team columns.
var game: SakuraBlitzMain
var columns: Array[VBoxContainer] = []
var headers: Array[Label] = []
var rows := {}
var subtitle: Label
var _timer := 0.0

func setup(g: SakuraBlitzMain) -> void:
	game = g
	z_index = 90
	mouse_filter = MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", game._hub._style(Color("18312f")))
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	var title := HBoxContainer.new()
	body.add_child(title)
	var heading := game._hub._label("PLACAR DA PARTIDA", 23)
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_child(heading)
	var close := game._hub._button("VOLTAR", game._toggle_scoreboard)
	close.custom_minimum_size.x = 110
	title.add_child(close)
	subtitle = game._hub._label("", 13, Color("b7d0c3"))
	body.add_child(subtitle)
	var grid := HBoxContainer.new()
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 16)
	body.add_child(grid)
	var teams := game.world.match_kind != CombatMatch.FFA
	for index in (2 if teams else 1):
		var group := VBoxContainer.new()
		group.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(group)
		var header := game._hub._label("", 18, CombatMatch.COLORS[index] if teams else Color("d8bb80"))
		group.add_child(header)
		headers.append(header)
		var legend := HBoxContainer.new()
		var who := game._hub._label("JOGADOR", 11, Color("90aa9f"))
		who.size_flags_horizontal = SIZE_EXPAND_FILL
		legend.add_child(who)
		legend.add_child(game._hub._label("A / M" + (" / B" if game.world.match_kind == CombatMatch.CTF else ""), 11, Color("90aa9f")))
		group.add_child(legend)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		group.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 7)
		scroll.add_child(list)
		columns.append(list)
	for item in game.world.get_combat_standings(game.kills, game.deaths):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var rank := game._hub._label("", 12, Color("90aa9f"))
		rank.custom_minimum_size.x = 25
		rank.size_flags_horizontal = SIZE_SHRINK_BEGIN
		rank.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(rank)
		var player := game._hub._label("VOCÊ" if item.is_player else str(item.name).trim_prefix("Bot_"), 13, Color("a3ebc6") if item.is_player else Color("e1e8de"))
		player.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		player.autowrap_mode = TextServer.AUTOWRAP_OFF
		player.custom_minimum_size = Vector2(80, 22)
		player.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(player)
		var stats := game._hub._label("", 13)
		stats.custom_minimum_size.x = 80
		stats.size_flags_horizontal = SIZE_SHRINK_END
		stats.autowrap_mode = TextServer.AUTOWRAP_OFF
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(stats)
		var group: int = item.team_id if teams else 0
		columns[group].add_child(row)
		rows[item.name] = {"root": row, "rank": rank, "stats": stats}
	var foot := game._hub._label("A: abates • M: mortes • B: bandeiras capturadas\nTab ou toque no placar • a partida continua", 11, Color("90aa9f"))
	body.add_child(foot)
	refresh()
	resized.connect(_fit)
	game.resized.connect(_fit)
	_fit.call_deferred()

func _fit() -> void:
	if game == null:
		return
	var safe := game._safe_ui_rect().grow(-14)
	size = safe.size.min(Vector2(960, 600))
	position = safe.get_center() - size / 2

func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0:
		_timer = 0.4
		refresh()

func refresh() -> void:
	var w := game.world
	var teams := w.match_kind != CombatMatch.FFA
	var seconds := maxi(0, int(w.combat_time_left))
	subtitle.text = "%s • %s • %02d:%02d" % [w.get_active_stage_def().title, CombatMatch.LABELS[w.match_kind], seconds / 60, seconds % 60]
	for index in headers.size():
		headers[index].text = "%s  /  %d" % [CombatMatch.TEAM_NAMES[index].to_upper(), w.team_scores[index]] if teams else "CLASSIFICAÇÃO GERAL"
	var order: Array[int] = [0, 0]
	for item in w.get_combat_standings(game.kills, game.deaths):
		if not rows.has(item.name):
			continue
		var row: Dictionary = rows[item.name]
		var group: int = item.team_id if teams else 0
		var flag_count := 0
		if is_instance_valid(w.match_controller):
			flag_count = int(w.match_controller.captures.get("PLAYER" if item.is_player else item.name, 0))
		row.rank.text = "%02d" % item.rank
		row.stats.text = "%d / %d" % [item.kills, item.deaths]
		if w.match_kind == CombatMatch.CTF:
			row.stats.text += " / %d" % flag_count
		columns[group].move_child(row.root, order[group])
		order[group] += 1
