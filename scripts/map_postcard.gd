class_name MapPostcard
extends Control
## Small vector map illustrations; no downloaded textures or per-frame animation.
var compact := false
var map_index := 0
var parkour := true
var _thumbnail: Texture2D
const PALETTES := [Color("ee8eaa"), Color("f2b878"), Color("70cfc6"), Color("a69aef"), Color("a3c98a"), Color("e9a588"), Color("d9b777"), Color("6cbbb9"), Color("8ca5d8"), Color("91bb88"), Color("e5ba72")]

func _ready() -> void:
	var screenshot := "res://assets/ui/maps/arena_%d.png" % map_index
	if not parkour and ResourceLoader.exists(screenshot):
		_thumbnail = load(screenshot)
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(100, 60 if compact else 112)
	resized.connect(queue_redraw)

func _draw() -> void:
	if _thumbnail != null:
		var source_size := _thumbnail.get_size()
		var aspect := size.x / maxf(size.y, 1)
		var crop := Vector2(source_size.x, minf(source_size.y, source_size.x / aspect))
		crop.x = minf(crop.x, crop.y * aspect)
		draw_texture_rect_region(_thumbnail, Rect2(Vector2.ZERO, size), Rect2((source_size - crop) * 0.5, crop))
		return
	var c: Color = PALETTES[map_index]
	draw_rect(Rect2(Vector2.ZERO, size), c.darkened(0.67))
	draw_circle(Vector2(size.x * 0.81, size.y * 0.28), 24, c.lightened(0.3))
	for i in 7:
		var x := size.x * float(i) / 6.0
		var h := 25.0 + float((i * 17 + map_index * 11) % 47)
		draw_rect(Rect2(x, size.y - h, size.x / 7.0, h), c.darkened(0.47))
	if parkour:
		for i in 5:
			var p := Vector2(size.x * (0.12 + i * 0.17), size.y * (0.82 - i * 0.08))
			draw_style_box(_slab(c if i % 2 == 0 else Color("eee8df")), Rect2(p, Vector2(size.x * 0.13, 13)))
			if i == 2 or i == 4:
				draw_arc(p + Vector2(12, -17), 9, 0, TAU, 16, Color("f7d584"), 3)
	else:
		for i in 3:
			var p := Vector2(size.x * (0.10 + i * 0.3), size.y * (0.48 + (i % 2) * 0.12))
			draw_rect(Rect2(p, Vector2(size.x * 0.23, 45)), c)
			draw_rect(Rect2(p + Vector2(5, 7), Vector2(size.x * 0.23 - 10, 9)), c.darkened(0.6))
			for j in 3:
				draw_line(p + Vector2(7 + j * 14, 22), p + Vector2(7 + j * 14, 40), c.darkened(0.2), 2)

func _slab(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(6)
	return s
