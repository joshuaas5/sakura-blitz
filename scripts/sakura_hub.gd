class_name SakuraHub
extends Control
signal play_requested(mode: int, stage: int)
signal resume_requested
signal profile_changed
signal shop_requested
signal hud_editor_requested
signal training_requested
signal diagnostics_requested

const INK := Color("edf2ef")
const MUTED := Color("9aaeb9")
const MINT := Color("93e7c3")
const PINK := Color("f0a5b7")
const MAPS := [
	["Vila Sakura", "Porto Cobalto", "Cânion Âmbar", "Distrito Neon", "Estação Aurora", "Vila Floral", "Bazar Solar", "Docas do Festival", "Observatório Lunar"],
	["Festival das Nuvens", "Telhados do Sol", "Oásis das Marés", "Órbita Neon", "Jardim do Chá", "Fábrica de Brinquedos"]
]
const DESCS := [
	["Pátios, casas e flancos", "Contêineres e combate próximo", "Pontes e linhas de tiro longas", "Passarelas e combate vertical", "Trens • trilhos • três rotas", "Praça • fonte • casas floridas", "Arcadas • mercado • pavilhão do chá", "Cais • armazéns • veleiros", "Planetário • laboratórios • jardins"],
	["Tambores • giros • céu de sakura", "Chaminés • esteiras • pôr do sol", "Surf • ilhas • pontes suspensas", "Plataformas • giros • neon", "Bambus • pontes • saltos de precisão", "Brinquedos • pinball • esteiras"]
]
var profile: PlayerProfile
var mode := 1
var page := 0
var can_resume := false
var _compact := false
var _body: VBoxContainer
var _grid: GridContainer
var _wallet: Label
var _scroll: ScrollContainer
var _fixed_header: VBoxContainer

func setup(p: PlayerProfile) -> void:
	profile = p
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.color = Color("132c2a")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	_fixed_header = VBoxContainer.new()
	_fixed_header.add_theme_constant_override("separation", 8)
	add_child(_fixed_header)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.offset_left = 28
	scroll.offset_right = -28
	scroll.offset_top = 18
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
	scroll.add_child(_body)
	resized.connect(_layout)
	refresh()

func _label(txt: String, font_size: int = 18, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	return l

func _style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(12)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _button(txt: String, action: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.mouse_filter = MOUSE_FILTER_PASS
	b.text = txt
	b.custom_minimum_size.y = 44 if _compact else 48
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color("132b2b") if primary else INK)
	b.add_theme_stylebox_override("normal", _style(MINT if primary else Color("2b4943")))
	b.add_theme_stylebox_override("hover", _style(MINT.lightened(0.1) if primary else Color("3c5a4f")))
	b.add_theme_stylebox_override("pressed", _style(PINK if primary else Color("4b6857")))
	b.pressed.connect(action)
	return b

func refresh() -> void:
	if not is_instance_valid(_body):
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	for child in _fixed_header.get_children():
		_fixed_header.remove_child(child)
		child.queue_free()
	_grid = null
	_compact = size.y < 600 and size.x > size.y
	_body.add_theme_constant_override("separation", 8 if _compact else 16)
	profile.refresh_day()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	_fixed_header.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(_label("SAKURA / BLITZ", 26 if size.x < 620 or _compact else 34, PINK))
	if not _compact:
		brand.add_child(_label("Um salto. Uma partida. Só mais uma.", 16, MUTED))
	if not _compact and size.x >= 1000:
		var portrait := CozyPortrait.new()
		portrait.outfit = profile.data.character
		portrait.custom_minimum_size = Vector2(112, 112)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_END
		header.add_child(portrait)
	_wallet = _label("%s MOEDAS" % str(profile.data.coins), 15, MINT)
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_wallet)
	var nav := HFlowContainer.new()
	nav.add_theme_constant_override("h_separation", 8)
	_fixed_header.add_child(nav)
	for i in [0, 3, 1, 2]:
		var b := _button(["Jogar", "Maestria", "Ajustes", "Arsenal"][i], func(): page = i; _scroll.scroll_vertical = 0; refresh(), page == i)
		b.custom_minimum_size.x = 110
		nav.add_child(b)
	nav.add_child(_button("Treino", func(): training_requested.emit()))
	if can_resume:
		nav.add_child(_button("Continuar partida", func(): resume_requested.emit()))
	if page == 0:
		_build_maps()
	elif page == 1:
		_build_mastery()
	elif page == 3:
		_build_arsenal()
	else:
		_build_settings()
	_body.add_child(_label("Treino local com bots • progresso salvo neste dispositivo • multiplayer online em desenvolvimento", 13, MUTED))
	_layout.call_deferred()

func _build_maps() -> void:
	if not profile.data.tutorial_complete and not _compact:
		_body.add_child(_button("Primeira vez? Aprender a jogar", func(): training_requested.emit(), true))
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation", 10)
	_body.add_child(intro)
	intro.add_child(_button("CORRIDA / PARKOUR", func(): mode = 1; _scroll.scroll_vertical = 0; refresh(), mode == 1))
	intro.add_child(_button("ARENAS / TIRO", func(): mode = 0; _scroll.scroll_vertical = 0; refresh(), mode == 0))
	if size.y > size.x:
		_body.add_child(_label("Vire o celular na horizontal para jogar.", 18, MINT))
	if not _compact:
		_body.add_child(_label("LOBBY / Escolha sua próxima corrida." if mode == 1 else "LOBBY / Prepare sua partida.", 25))
	if not _compact:
		_body.add_child(_label("8 setores • checkpoints • rota segura e atalhos • 7 bots" if mode == 1 else "9 arenas • 6 armas • disputa entre bots • moedas por abate", 16, MUTED))
	var difficulty := OptionButton.new()
	for preset in BotDifficulty.PRESETS:
		difficulty.add_item("BOTS / " + str(preset.name).to_upper())
	difficulty.select(profile.data.bot_difficulty)
	difficulty.custom_minimum_size.y = 44 if _compact else 52
	_body.add_child(difficulty)
	var hint := _label(BotDifficulty.get_preset(profile.data.bot_difficulty).hint + " • próxima partida", 15, MINT)
	hint.visible = not _compact
	_body.add_child(hint)
	difficulty.item_selected.connect(func(idx: int):
		profile.data.bot_difficulty = idx
		hint.text = BotDifficulty.get_preset(idx).hint
		profile_changed.emit()
	)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_body.add_child(_grid)
	for i in ([6, 7, 8, 5, 0, 1, 2, 3, 4] if mode == 0 else [0, 1, 2, 3, 4, 5]):
		var panel := PanelContainer.new()
		panel.mouse_filter = MOUSE_FILTER_PASS
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _style(Color("203b38")))
		_grid.add_child(panel)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 5 if _compact else 9)
		panel.add_child(v)
		var art := MapPostcard.new()
		art.map_index = i
		art.parkour = mode == 1
		art.compact = _compact
		v.add_child(art)
		if not _compact:
			v.add_child(_label("0%d / %s" % [i + 1, "CORRIDA" if mode == 1 else "ARENA"], 12, MapPostcard.PALETTES[i]))
		v.add_child(_label(MAPS[mode][i], 18 if _compact else 21))
		if not _compact:
			v.add_child(_label(DESCS[mode][i], 14, MUTED))
		var record := float(profile.data.best_times[i]) if mode == 1 else 0.0
		if not _compact:
			v.add_child(_label(("Recorde: %.2fs" % record if record > 0 else "Seu primeiro recorde espera") if mode == 1 else "Treine sua mira • ganhe maestria", 13, MINT))
		var play := _button("CORRER  →" if mode == 1 else "JOGAR  →", func(): play_requested.emit(mode, i), true)
		play.disabled = size.y > size.x
		if play.disabled:
			play.text = "VIRE PARA JOGAR"
		v.add_child(play)
	var challenge := HBoxContainer.new()
	challenge.add_theme_constant_override("separation", 16)
	_body.add_child(challenge)
	challenge.add_child(_label("DESAFIO DO DIA  /  +300 moedas\n10 abates (%d/10) OU termine 1 corrida (%d/1)" % [mini(10, profile.data.daily_kills), mini(1, profile.data.daily_races)], 15, MUTED))
	var claim := _button("RESGATADO" if profile.data.daily_claimed else "Resgatar", func():
		if profile.claim_daily():
			profile_changed.emit()
			refresh()
	)
	claim.disabled = profile.data.daily_claimed or (profile.data.daily_kills < 10 and profile.data.daily_races < 1)
	challenge.add_child(claim)

func _build_arsenal() -> void:
	_body.add_child(_label("Encontre seu ritmo.", 28))
	_body.add_child(_label("Todas as armas disponíveis desde o início. Escolha para a próxima arena; skins e maestria acompanham cada arma.", 16, MUTED))
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_body.add_child(_grid)
	for i in WeaponCatalog.DEFINITIONS.size():
		var w: Dictionary = WeaponCatalog.DEFINITIONS[i]
		var panel := PanelContainer.new()
		panel.mouse_filter = MOUSE_FILTER_PASS
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _style(Color("203b38")))
		_grid.add_child(panel)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		panel.add_child(card)
		var preview := WeaponPortrait.new()
		preview.weapon_index = i
		preview.skin_index = profile.data.weapon_skins[i]
		card.add_child(preview)
		card.add_child(_label(WeaponCatalog.label_for(i), 22, PINK))
		var roles := ["Versátil / médias distâncias", "Precisão / longa distância", "Impacto / arma de apoio", "Velocidade / corpo a corpo", "Mobilidade / curta distância", "Dispersão / combate próximo"]
		card.add_child(_label(roles[i], 14, MUTED))
		var detail := "Corra mais rápido • golpes próximos" if bool(w.melee) else "%d munições • %s • recarga %.1fs" % [int(w.mag), "automática" if bool(w.auto) else "semiautomática", float(w.get("reload", 1.2))]
		card.add_child(_label(detail, 14, MUTED))
		var equipped: bool = profile.data.selected_weapon == i
		var equip := _button("EQUIPADA" if equipped else "EQUIPAR", func():
			profile.data.selected_weapon = i
			profile_changed.emit()
			refresh()
		, equipped)
		equip.disabled = equipped
		card.add_child(equip)
	_body.add_child(_button("Personalizar acabamentos", func(): shop_requested.emit()))


func _build_mastery() -> void:
	_body.add_child(_label("Seu estilo. Sua história.", 28))
	_body.add_child(_label("50 abates: Ouro por arma. 100 abates: silenciador visual nas armas de fogo. Sem alterar a balística.", 16, MUTED))
	for i in WeaponRig.WEAPONS.size():
		var row := VBoxContainer.new()
		_body.add_child(row)
		var count: int = profile.data.weapon_kills[i]
		row.add_child(_label("%s  /  %d abates" % [WeaponRig.WEAPONS[i].name, count], 19))
		var bar := ProgressBar.new()
		bar.max_value = 100 if i in WeaponCatalog.FIREARMS else 50
		bar.value = count
		bar.show_percentage = false
		bar.custom_minimum_size.y = 10
		bar.add_theme_stylebox_override("background", _style(Color("314556")))
		bar.add_theme_stylebox_override("fill", _style(MINT))
		row.add_child(bar)
		var actions := HFlowContainer.new()
		actions.add_theme_constant_override("h_separation", 8)
		row.add_child(actions)
		var gold := _button("Ouro: %d/50" % count if count < 50 else ("Remover Ouro" if profile.data.weapon_skins[i] == 1 else "Equipar Ouro"), func():
			profile.data.weapon_skins[i] = 0 if profile.data.weapon_skins[i] == 1 else 1
			profile_changed.emit()
			refresh()
		)
		gold.disabled = count < 50
		actions.add_child(gold)
		if i in WeaponCatalog.FIREARMS:
			var sup := _button("Silenciador: %d/100" % count if count < 100 else ("Remover silenciador" if profile.data.suppressors[i] else "Equipar silenciador"), func():
				profile.data.suppressors[i] = not profile.data.suppressors[i]
				profile_changed.emit()
				refresh()
			)
			sup.disabled = count < 100
			actions.add_child(sup)
	_body.add_child(_button("Loja de cosméticos e upgrades leves", func(): shop_requested.emit()))

func _build_settings() -> void:
	_body.add_child(_button("Organizar botões na tela", func(): hud_editor_requested.emit(), true))
	_body.add_child(_button("Treino guiado", func(): training_requested.emit()))
	var diagnostics_button := _button("Copiar diagnóstico da última partida", func(): diagnostics_requested.emit())
	diagnostics_button.pressed.connect(func(): diagnostics_button.text = "Diagnóstico copiado — cole para compartilhar")
	_body.add_child(diagnostics_button)
	_body.add_child(_label("Feito para dois polegares.", 28))
	_body.add_child(_label("Esquerda: andar e correr. Direita: olhar. Arraste a partir do botão de pulo para saltar e olhar ao mesmo tempo. Para atirar, segure e arraste o botão de tiro: o mesmo dedo dispara e controla a mira. Pistola, sniper e escopeta disparam uma vez por toque.", 17, MUTED))
	for item in [["sensitivity", "Sensibilidade", 0.4, 2.0], ["ads_sensitivity", "Sensibilidade da mira", 0.25, 1.0], ["music_volume", "Volume da música", 0.0, 1.0], ["effects_volume", "Volume dos efeitos", 0.0, 1.0], ["ambience_volume", "Volume do ambiente", 0.0, 1.0]]:
		var value_label := _label("%s: %.2f" % [item[1], profile.data[item[0]]])
		_body.add_child(value_label)
		var slider := HSlider.new()
		slider.min_value = item[2]
		slider.max_value = item[3]
		slider.step = 0.05
		slider.value = profile.data[item[0]]
		slider.custom_minimum_size.y = 48
		slider.value_changed.connect(func(value: float):
			profile.data[item[0]] = value
			value_label.text = "%s: %.2f" % [item[1], value]
			profile_changed.emit()
		)
		_body.add_child(slider)
	for item in [["haptics", "Vibração (em dispositivos compatíveis)"], ["music_enabled", "Música original Sakura Blitz"], ["show_performance", "Mostrar FPS e tempo dos quadros"]]:
		var check := CheckButton.new()
		check.text = item[1]
		check.button_pressed = profile.data[item[0]]
		check.custom_minimum_size.y = 48
		check.toggled.connect(func(value: bool): profile.data[item[0]] = value; profile_changed.emit())
		_body.add_child(check)
	var quality := OptionButton.new()
	for preset in SakuraBlitzMain.RES_PRESETS:
		quality.add_item(preset.label)
	quality.select(profile.data.quality)
	quality.custom_minimum_size.y = 48
	quality.item_selected.connect(func(idx: int): profile.data.quality = idx; profile_changed.emit())
	_body.add_child(quality)
	_body.add_child(_label("Músicas sintetizadas para este projeto, sem samples externos.\nPC: WASD andar • Espaço pular • mouse mirar/atirar • R recarregar • 1–6 armas • Esc hub • V toque", 15, MUTED))

func _layout() -> void:
	if is_instance_valid(_scroll):
		var safe := MobileLayout.safe_rect(size)
		_fixed_header.position = safe.position + Vector2(18, 12)
		_fixed_header.size.x = safe.size.x - 36
		_fixed_header.reset_size()
		_fixed_header.size.x = safe.size.x - 36
		_scroll.offset_left = safe.position.x + 18
		_scroll.offset_top = safe.position.y + 20 + _fixed_header.size.y
		_scroll.offset_right = safe.end.x - size.x - 18
		_scroll.offset_bottom = safe.end.y - size.y - 12
	if is_instance_valid(_grid):
		_grid.columns = 3 if size.x >= 1100 else (2 if size.x >= 620 else 1)
