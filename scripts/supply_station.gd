class_name SupplyStation
extends Node3D
## Imported ammunition case, magazines and health art. No block stand-ins.
var supplies: Node3D
var badge: Sprite3D
var title: Label3D
var ready_height := 0.0
var last_second := -1
var elapsed := 0.0

func setup(at: Vector3) -> void:
	position = at
	set_meta("preserve_item_art", true)
	var case := ItemArt.model(self, "crate-wide", Vector3.ZERO, 1.1)
	var top: float = case.get_meta("art_height")
	supplies = Node3D.new()
	add_child(supplies)
	ready_height = top + 0.07
	supplies.position.y = ready_height
	ItemArt.model(supplies, "clip-large", Vector3(-0.32, 0, 0), 0.32, -0.28)
	ItemArt.model(supplies, "clip-small", Vector3(0.30, 0, 0), 0.26, 0.28)
	ItemArt.model(supplies, "heart", Vector3(0, 0.25, 0), 0.25)
	badge = ItemArt.icon(self, ItemArt.HEART, Vector3(-0.24, top + 0.73, 0), 0.22)
	ItemArt.icon(self, ItemArt.AMMO, Vector3(0.22, top + 0.73, 0), 0.28)
	title = Label3D.new()
	title.font = preload("res://assets/ui/blossom/nunito_sans.ttf")
	title.font_size = 32
	title.pixel_size = 0.004
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.outline_size = 7
	title.modulate = Color("d6e9c9")
	title.position.y = top + 1.02
	add_child(title)
	set_cooldown(0)

func set_cooldown(seconds: float) -> void:
	var rounded := ceili(maxf(0, seconds))
	if rounded == last_second:
		return
	last_second = rounded
	supplies.visible = rounded == 0
	badge.modulate = Color.WHITE if rounded == 0 else Color("7b8f8c")
	title.text = "VIDA + MUNIÇÃO" if rounded == 0 else "REABASTECE / %ds" % rounded
	title.modulate = Color("d6e9c9") if rounded == 0 else Color("a8b5a9")

func _process(delta: float) -> void:
	elapsed += delta
	supplies.position.y = ready_height + sin(elapsed * 1.7) * 0.045
