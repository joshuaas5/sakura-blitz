class_name ItemArt
extends RefCounted
## A finished imported model and source sprite for every gameplay supply item.
const BLASTER := "res://assets/third_party/kenney_blaster/"
const ITEMS := "res://assets/third_party/kenney_items/"
const HEART := preload("res://assets/third_party/kenney_items/Sprites/heart.png")
const COIN := preload("res://assets/third_party/kenney_items/Sprites/coinGold.png")
const AMMO := preload("res://assets/third_party/kenney_blaster/Sprites/clip-large.png")
static var scenes := {}
static var bounds := {}

static func model(parent: Node3D, asset: String, at: Vector3, longest: float, yaw: float = 0) -> Node3D:
	var path := (ITEMS if asset in ["heart", "coinGold", "jewel", "button", "sign"] else BLASTER) + asset + ".glb"
	if not scenes.has(path):
		scenes[path] = load(path)
	var mesh: Node3D = scenes[path].instantiate()
	if not bounds.has(path):
		bounds[path] = SignatureArenas._bounds(mesh)
	var box: AABB = bounds[path]
	var factor := longest / maxf(box.size[box.size.max_axis_index()], 0.01)
	var root := Node3D.new()
	parent.add_child(root)
	root.add_child(mesh)
	mesh.scale = Vector3.ONE * factor
	mesh.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * factor
	root.position = at
	root.rotation.y = yaw
	root.set_meta("art_source", path)
	root.set_meta("art_height", box.size.y * factor)
	root.set_meta("art_size", box.size * factor)
	CuratedVillage._prepare(mesh, Color.WHITE)
	return root

static func icon(parent: Node3D, texture: Texture2D, at: Vector3, width: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = width / maxf(texture.get_width(), 1)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = false
	sprite.shaded = false
	sprite.position = at
	parent.add_child(sprite)
	return sprite

static func pickup(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	root.set_meta("preserve_item_art", true)
	parent.add_child(root)
	var pouch := model(root, "crate-small", Vector3(0, -0.2, 0), 0.55)
	var top: float = -0.2 + float(pouch.get_meta("art_height"))
	model(root, "heart", Vector3(0, top + 0.08, 0), 0.28)
	icon(root, HEART, Vector3(0, top + 0.55, 0), 0.24)
	return root

static func projectile(parent: Node3D, at: Vector3, direction: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	var bullet := model(root, "bullet-foam", Vector3.ZERO, 0.3)
	var source: AABB = bounds[BLASTER + "bullet-foam.glb"]
	var axis := Vector3.ZERO
	axis[source.size.max_axis_index()] = 1
	bullet.quaternion = Quaternion(axis, Vector3.FORWARD)
	if direction.length_squared() > 0.01:
		root.look_at(at + direction, Vector3.RIGHT if absf(direction.normalized().y) > 0.98 else Vector3.UP)
	return root

static func jump_pad(parent: Node3D, at: Vector3) -> Node3D:
	var root := model(parent, "button", at - Vector3.UP * 0.1, 2.3)
	var label := Label3D.new()
	label.text = "IMPULSO"
	label.font = preload("res://assets/ui/blossom/nunito_sans.ttf")
	label.font_size = 32
	label.pixel_size = 0.005
	label.position.y = float(root.get_meta("art_height")) + 0.35
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("dce8c7")
	label.outline_size = 6
	root.add_child(label)
	return root
