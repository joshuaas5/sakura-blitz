extends RefCounted
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func touch(g: Control, at: Vector2, pressed: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = g.get_viewport().get_final_transform() * at
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(g: Control, from: Vector2, to: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = g.get_viewport().get_final_transform() * to
	event.relative = g.get_viewport().get_final_transform().basis_xform(to - from)
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func wait_frames(g: Node, count: int = 8) -> void:
	for frame in count:
		await g.get_tree().process_frame

func tap(g: Control, node: Control) -> void:
	var at := node.get_global_rect().get_center()
	touch(g, at, true)
	touch(g, at, false)
	await wait_frames(g)

func swipe(g: Control, origin: Vector2) -> void:
	touch(g, origin, true)
	var last := origin
	for step in 8:
		var next := origin - Vector2(0, (step + 1) * 15)
		drag(g, last, next)
		last = next
		await wait_frames(g, 1)
	touch(g, last, false)
	await wait_frames(g, 45)

func button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := button(child, prefix)
		if found != null:
			return found
	return null

func run(g: SakuraBlitzMain) -> bool:
	var old_window := g.get_window().size
	var old_emulation := Input.is_emulating_touch_from_mouse()
	Input.set_emulate_touch_from_mouse(true)
	g._mobile_hud_enabled = true
	g.get_window().size = Vector2i(844, 390)
	g._hub.mode = 0
	g._hub.page = 0
	g._open_hub()
	await wait_frames(g)
	var scroll := g._hub._scroll
	var play := button(g._hub._grid.get_child(0), "JOGAR")
	check(scroll.get_global_rect().encloses(play.get_global_rect()), "First Play is visible on a small landscape screen")
	var origin: Vector2 = g._hub._grid.get_child(0).get_global_rect().position + Vector2(60, 25)
	await swipe(g, origin)
	check(scroll.scroll_vertical > 60, "Touch drag across map card scrolls lobby")
	check(g._hub_open, "Scrolling cannot start a match")
	check(button(g._hub._fixed_header, "Ajustes").get_global_rect().end.y < scroll.get_global_rect().position.y, "Navigation remains above scrolling content")
	await tap(g, button(g._hub._fixed_header, "Ajustes"))
	check(g._hub.page == 2, "Touch opens settings")
	await swipe(g, scroll.get_global_rect().get_center())
	check(scroll.scroll_vertical > 0, "Settings scroll by touch")
	await tap(g, button(g._hub._fixed_header, "Jogar"))
	play = button(g._hub._grid.get_child(0), "JOGAR")
	await swipe(g, play.get_global_rect().get_center())
	check(g._hub_open, "Dragging over Play does not launch")
	scroll.scroll_vertical = 0
	await wait_frames(g)
	await tap(g, button(g._hub._grid.get_child(0), "JOGAR"))
	check(not g._hub_open and g.current_mode == 0 and g.current_stage == 9, "Touch on Play enters the featured large arena")
	var fire: Vector2 = g._action_rects().fire.get_center()
	touch(g, fire, true)
	check(g._touch_actions.size() == 1 and not g._touch_actions.has(99), "GUI emulation cannot duplicate a gameplay finger")
	touch(g, fire, false)
	check(g._touch_actions.is_empty() and not g._mobile_fire_held, "Touch release clears firing")
	g._toggle_shop(1)
	await wait_frames(g)
	var shop_scroll := g._shop_grid.get_parent() as ScrollContainer
	var before := shop_scroll.scroll_vertical
	origin = g._shop_grid.get_child(0).get_global_rect().position + Vector2(55, 30)
	await swipe(g, origin)
	check(shop_scroll.scroll_vertical > before, "Shop scrolls across product previews")
	await tap(g, button(g._shop_panel, "VOLTAR"))
	check(not g._shop_open, "Shop Back responds to touch")
	g._open_hub()
	g._hub.page = 2
	g._hub.refresh()
	await wait_frames(g)
	await tap(g, button(g._hub._body, "Organizar"))
	check(is_instance_valid(g._hud_editor), "Touch opens HUD editor")
	if is_instance_valid(g._hud_editor):
		await tap(g, button(g._hud_editor, "Cancelar"))
		check(not is_instance_valid(g._hud_editor) and g._hub.visible, "Touch cancels editor into visible lobby")
	await tap(g, button(g._hub._fixed_header, "Treino"))
	check(is_instance_valid(g._training) and g._training.active, "Touch starts tutorial")
	if is_instance_valid(g._training):
		await tap(g, g._training.skip)
		check(not g._training.active and g._hub_open, "Tutorial exit responds to touch")
	g._start_from_hub(0, 5)
	g._show_combat_result(g.world.get_combat_standings(0, 0), 7, 0)
	await wait_frames(g)
	check(g._safe_ui_rect().grow(0.1).encloses(g._result_panel.get_global_rect()), "Combat results fit the mobile safe area")
	var result_scroll := g._result_panel.get_child(0) as ScrollContainer
	await swipe(g, result_scroll.get_global_rect().position + Vector2(50, 160))
	check(result_scroll.scroll_vertical > 0, "Long match results scroll by touch")
	var back := button(g._result_panel, "Voltar ao lobby")
	result_scroll.ensure_control_visible(back)
	await wait_frames(g)
	await tap(g, back)
	check(g._hub_open and not g._result_panel.visible, "Results return to lobby by touch")
	g._start_from_hub(1, 0)
	g._show_race_result(65, 65, 1, 180)
	await wait_frames(g)
	check(g._safe_ui_rect().grow(0.1).encloses(g._result_panel.get_global_rect()), "Race results fit the mobile safe area")
	back = button(g._result_panel, "Voltar ao hub")
	(g._result_panel.get_child(0) as ScrollContainer).ensure_control_visible(back)
	await wait_frames(g)
	await tap(g, back)
	check(g._hub_open and not g._result_panel.visible, "Race results return to lobby by touch")
	Input.set_emulate_touch_from_mouse(old_emulation)
	g.get_window().size = old_window
	print("MENUS: %d checks, %d failures" % [checks, failures])
	return failures == 0
