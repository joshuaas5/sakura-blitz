class_name MatchResults
extends PanelContainer
## A complete match report with fixed replay actions and expandable standings.
var game: SakuraBlitzMain

func setup(g: SakuraBlitzMain, standings: Array, place: int) -> void:
	game = g
	add_theme_stylebox_override("panel", game._hub._style(Color("173630")))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var banner := HBoxContainer.new()
	banner.add_theme_constant_override("separation", 18)
	content.add_child(banner)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = SIZE_EXPAND_FILL
	banner.add_child(words)
	var teams := game.world.match_kind != CombatMatch.FFA
	var title := "VITÓRIA!" if place == 1 else ("EMPATE" if place == 0 else "PARTIDA CONCLUÍDA / %dº" % place)
	if teams:
		title = "MENTA VENCEU!" if place == 1 else ("EMPATE" if place == 0 else "CORAL VENCEU")
	var heading := game._hub._label(title, 29, Color("a5e3b6") if place == 1 else Color("e4c695"))
	heading.custom_minimum_size.y = 42
	words.add_child(heading)
	var subtitle := game._hub._label("%s • %s" % [game.world.get_active_stage_def().title, CombatMatch.LABELS[game.world.match_kind]], 14)
	subtitle.custom_minimum_size.y = 24
	words.add_child(subtitle)
	if teams:
		words.add_child(game._hub._label("MENTA %d  ×  %d CORAL" % [game.world.team_scores[0], game.world.team_scores[1]], 20, Color("e4c695")))
	if game.size.y >= 520:
		var art := MapPostcard.new()
		art.map_index = game.current_stage
		art.parkour = false
		art.compact = true
		art.custom_minimum_size = Vector2(220, 100)
		banner.add_child(art)
	var stats := GridContainer.new()
	stats.columns = 4 if game.size.x >= 620 else 2
	stats.add_theme_constant_override("h_separation", 8)
	content.add_child(stats)
	var captures := 0
	if is_instance_valid(game.world.match_controller):
		captures = int(game.world.match_controller.captures.get("PLAYER", 0))
	for item in [["ABATES", str(game.kills)], ["PRECISÃO", "%d%%" % game.match_record.accuracy() if game.match_record.shots > 0 else "—"], ["MELHOR SEQUÊNCIA", "%d" % game.match_record.best_streak], ["BANDEIRAS" if game.world.match_kind == CombatMatch.CTF else "HEADSHOTS", str(captures if game.world.match_kind == CombatMatch.CTF else game.headshots)]]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", game._hub._style(Color("25483d")))
		stats.add_child(card)
		var stack := VBoxContainer.new()
		card.add_child(stack)
		stack.add_child(game._hub._label(str(item[0]), 10, Color("b5c8ad")))
		stack.add_child(game._hub._label(str(item[1]), 24, Color("f0d49e")))
	var earnings := HBoxContainer.new()
	content.add_child(earnings)
	var coin := TextureRect.new()
	coin.texture = ItemArt.COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(30, 30)
	earnings.add_child(coin)
	earnings.add_child(game._hub._label("GANHOS NESTA PARTIDA   +%d moedas  /  +%d RP" % [game.match_record.coins, game.match_record.xp], 16, Color("a5e3b6")))
	mastery(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	var roster_label := game._hub._label("CLASSIFICAÇÃO", 14, Color("d9c49a"))
	roster_label.size_flags_horizontal = SIZE_EXPAND_FILL
	title_row.add_child(roster_label)
	var extra: Array[Control] = []
	for index in standings.size():
		var row: Dictionary = standings[index]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		content.add_child(line)
		var rank := game._hub._label("%02d" % row.rank, 13, Color("a8bcaa"))
		rank.size_flags_horizontal = SIZE_SHRINK_BEGIN
		rank.custom_minimum_size.x = 30
		line.add_child(rank)
		var name := "VOCÊ" if row.is_player else str(row.name).trim_prefix("Bot_")
		if teams:
			name += " / " + CombatMatch.TEAM_NAMES[int(row.team_id)]
		var who := game._hub._label(name, 14, Color("a5e3b6") if row.is_player else Color("e0e6d5"))
		line.add_child(who)
		var score := "%d A / %d M" % [row.kills, row.deaths]
		if game.world.match_kind == CombatMatch.CTF:
			score += " / %d B" % int(game.world.match_controller.captures.get("PLAYER" if row.is_player else row.name, 0))
		var values := game._hub._label(score, 13)
		values.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		values.size_flags_horizontal = SIZE_SHRINK_END
		values.custom_minimum_size.x = 145
		line.add_child(values)
		if index >= 3 and not row.is_player:
			line.hide()
			extra.append(line)
	if not extra.is_empty():
		var expanded: Array[bool] = [false]
		var toggle := game._hub._button("Ver todos", func():
			expanded[0] = not expanded[0]
			for row in extra:
				row.visible = expanded[0]
		)
		toggle.custom_minimum_size = Vector2(120, 36)
		toggle.size_flags_horizontal = SIZE_SHRINK_END
		toggle.pressed.connect(func(): toggle.text = "Recolher" if expanded[0] else "Ver todos")
		title_row.add_child(toggle)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	actions.add_child(game._hub._button("Revanche", func(): game._start_from_hub(0, game.current_stage), true))
	actions.add_child(game._hub._button("Próxima arena", func(): game._start_from_hub(0, (game.current_stage + 1) % SakuraWorld.COMBAT_STAGE_DEFS.size())))
	actions.add_child(game._hub._button("Voltar ao lobby", game._open_hub))
	game.resized.connect(fit)
	fit.call_deferred()

func fit() -> void:
	var safe := game._safe_ui_rect().grow(-16)
	size = safe.size.min(Vector2(920, 650))
	position = safe.get_center() - size / 2

func mastery(parent: VBoxContainer) -> void:
	var selected: int = game.weapons.current_idx
	var biggest := 0
	for index in game.profile.data.weapon_kills.size():
		var delta := int(game.profile.data.weapon_kills[index]) - int(game.match_record.mastery_start[index]) if index < game.match_record.mastery_start.size() else 0
		if delta > biggest:
			biggest = delta
			selected = index
	var kills: int = game.profile.data.weapon_kills[selected]
	var goal := 50 if kills < 50 or selected == 3 else 100
	var label := "OURO" if goal == 50 else "SILENCIADOR COSMÉTICO"
	parent.add_child(game._hub._label("%s / MAESTRIA  +%d nesta partida" % [WeaponCatalog.label_for(selected), biggest], 14, Color("d9c49a")))
	var bar := ProgressBar.new()
	bar.max_value = goal
	bar.value = mini(kills, goal)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	bar.add_theme_stylebox_override("background", game._hub._style(Color("284b3e")))
	bar.add_theme_stylebox_override("fill", game._hub._style(Color("c9ac73")))
	parent.add_child(bar)
	parent.add_child(game._hub._label("%d / %d abates • %s" % [kills, goal, label] if kills < goal else "MAESTRIA CONCLUÍDA / " + label, 11, Color("a8bcaa")))
