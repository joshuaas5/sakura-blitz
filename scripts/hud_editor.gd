class_name HudEditor
extends Control
signal finished(saved: bool)
var game: SakuraBlitzMain
var draft := {}
var selected := "jump"
var race := false
var dragging := -2
var drag_offset := Vector2.ZERO
var message: Label
var size_slider: HSlider
var alpha_slider: HSlider
var toolbar: VBoxContainer
var toolbar_panel: PanelContainer
var refreshing := false

func open(g: SakuraBlitzMain) -> void:
	game = g
	draft = {"hud_layout_revision": g.profile.data.hud_layout_revision, "hud_left_handed": g.profile.data.hud_left_handed, "hud_layout": g.profile.data.hud_layout.duplicate(true)}
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	toolbar_panel = panel
	panel.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	panel.offset_bottom = 145
	panel.add_theme_stylebox_override("panel", g._hub._style(Color("132c2a")))
	add_child(panel)
	toolbar = VBoxContainer.new()
	panel.add_child(toolbar)
	var row := HFlowContainer.new()
	toolbar.add_child(row)
	for entry in [["Salvar", _save], ["Cancelar", func(): finished.emit(false)], ["Restaurar", _reset], ["Canhoto / destro", _mirror], ["Tiro / corrida", _mode]]:
		row.add_child(g._hub._button(entry[0], entry[1], entry[0] == "Salvar"))
	message = g._hub._label("Arraste os botões. Toque em um para ajustar tamanho e transparência.", 14)
	toolbar.add_child(message)
	var sliders := HBoxContainer.new()
	toolbar.add_child(sliders)
	sliders.add_child(g._hub._label("Tamanho", 14))
	size_slider = HSlider.new()
	size_slider.min_value = 0.7
	size_slider.max_value = 1.35
	size_slider.step = 0.05
	size_slider.custom_minimum_size = Vector2(130, 32)
	sliders.add_child(size_slider)
	sliders.add_child(g._hub._label("Opacidade", 14))
	alpha_slider = HSlider.new()
	alpha_slider.min_value = 0.3
	alpha_slider.max_value = 1
	alpha_slider.step = 0.05
	alpha_slider.custom_minimum_size = Vector2(130, 32)
	sliders.add_child(alpha_slider)
	size_slider.value_changed.connect(func(value): _adjust(value, false))
	alpha_slider.value_changed.connect(func(value): _adjust(value, true))
	_select("jump")
	resized.connect(func(): dragging = -2; queue_redraw())
	queue_redraw()

func area() -> Rect2:
	return game._safe_ui_rect()

func _select(action: String) -> void:
	selected = action
	refreshing = true
	var value: Vector4 = draft.hud_layout.get(action, Vector4(0.5, 0.5, 1, 0.85))
	size_slider.value = value.z
	alpha_slider.value = value.w
	refreshing = false
	message.text = "%s selecionado • Arraste e ajuste abaixo. Pausa fixa." % MobileLayout.LABELS[action]
	queue_redraw()

func _store(rect: Rect2, scale_value: float, alpha: float) -> void:
	var relative := (rect.get_center() - area().position) / area().size
	draft.hud_layout[selected] = Vector4(relative.x, relative.y, scale_value, alpha)

func _adjust(value: float, alpha: bool) -> void:
	if refreshing:
		return
	var current: Rect2 = MobileLayout.rects(area(), draft, race)[selected]
	var old: Vector4 = draft.hud_layout.get(selected, Vector4(0.5, 0.5, 1, 0.85))
	_store(current, old.z if alpha else value, value if alpha else old.w)
	queue_redraw()

func _reset() -> void:
	dragging = -2
	draft.hud_layout = {}
	draft.hud_layout_revision = 2
	draft.hud_left_handed = false
	_select(selected)

func _mirror() -> void:
	dragging = -2
	draft.hud_left_handed = not draft.hud_left_handed
	for key in draft.hud_layout:
		var value: Vector4 = draft.hud_layout[key]
		if key != "pause":
			value.x = 1 - value.x
			draft.hud_layout[key] = value
	queue_redraw()

func _mode() -> void:
	dragging = -2
	race = not race
	_select("jump")

func _save() -> void:
	for mode in [false, true]:
		if not MobileLayout.valid(MobileLayout.rects(area(), draft, mode), area()):
			message.text = "Separe os controles sobrepostos antes de salvar (confira tiro e corrida)."
			return
	var previous: Dictionary = game.profile.data.hud_layout.duplicate(true)
	var previous_hand: bool = game.profile.data.hud_left_handed
	var previous_revision: int = game.profile.data.hud_layout_revision
	game.profile.data.hud_layout = MobileLayout.sanitize(draft.hud_layout)
	game.profile.data.hud_left_handed = draft.hud_left_handed
	game.profile.data.hud_layout_revision = draft.hud_layout_revision
	if game._save_profile() != OK:
		game.profile.data.hud_layout = previous
		game.profile.data.hud_left_handed = previous_hand
		game.profile.data.hud_layout_revision = previous_revision
		message.text = "Não foi possível salvar. Seu layout anterior foi preservado. Tente novamente."
		return
	finished.emit(true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed and dragging == event.index:
		dragging = -2
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		finished.emit(false)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_pointer(event.index, event.position, event.pressed and not event.canceled)
	elif event is InputEventScreenDrag and dragging == event.index:
		_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and dragging == -1:
		_move(event.position)
	accept_event()

func _pointer(index: int, at: Vector2, pressed: bool) -> void:
	if not pressed:
		if dragging == index:
			dragging = -2
		return
	if dragging != -2:
		return
	var rectangles := MobileLayout.rects(area(), draft, race)
	for action in rectangles:
		if action != "pause" and rectangles[action].has_point(at):
			_select(action)
			dragging = index
			drag_offset = rectangles[action].get_center() - at
			break

func _move(at: Vector2) -> void:
	var rect: Rect2 = MobileLayout.rects(area(), draft, race)[selected]
	rect.position = (at + drag_offset - rect.size / 2).clamp(area().position, area().end - rect.size)
	_store(rect, size_slider.value, alpha_slider.value)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.09, 0.10, 0.94))
	if game == null:
		return
	toolbar_panel.offset_left = area().position.x
	toolbar_panel.offset_right = area().end.x - size.x
	toolbar_panel.offset_top = area().position.y
	draw_rect(area().grow(-2), Color("70bcaa"), false, 2)
	var rectangles := MobileLayout.rects(area(), draft, race)
	var valid := MobileLayout.valid(rectangles, area())
	var font := ThemeDB.fallback_font
	for action in rectangles:
		var rect: Rect2 = rectangles[action]
		var color := Color("97e7c8") if valid else Color("ef939b")
		color.a = MobileLayout.opacity(draft, action)
		draw_circle(rect.get_center(), rect.size.x / 2, color.darkened(0.5))
		draw_arc(rect.get_center(), rect.size.x / 2, 0, TAU, 48, color, 3 if action == selected else 1.5, true)
		var label: String = MobileLayout.LABELS[action]
		var text_size := 13 if rect.size.x < 80 else 16
		draw_string(font, rect.get_center() + Vector2(-font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x / 2, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, Color.WHITE)
