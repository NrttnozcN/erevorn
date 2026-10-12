class_name WallShade
extends Node2D
## Zemin ile duvarın birleştiği yere gölge ve ince bir taş kenarı çizer, böylece
## boyalı karolar düz bir kesik gibi değil, duvarın dibine gömülmüş gibi görünür.

const SHADOW := Color(0.02, 0.01, 0.04, 0.62)
const CLEAR := Color(0.02, 0.01, 0.04, 0.0)
const RIM := Color(0.55, 0.5, 0.62, 0.22)
const LIP := Color(0.0, 0.0, 0.0, 0.55)

var world: World


func _draw() -> void:
	if world == null or world.map.size() != world.width * world.height:
		return
	var t := float(World.TILE)
	for y in world.height:
		for x in world.width:
			var o := Vector2(x, y) * t
			if world.get_tile(x, y) == World.WALL:
				# Duvarın zemine bakan kenarı: ön yüz dokusu (varsa), koyu bir dudak ve ince bir ışık çizgisi.
				if world.get_tile(x, y + 1) != World.WALL:
					_face(x, o, t)
					draw_rect(Rect2(o.x, o.y + t - 5, t, 5), LIP)
					draw_line(o + Vector2(0, t - 6), o + Vector2(t, t - 6), RIM, 1.5)
				if world.get_tile(x, y - 1) != World.WALL:
					draw_line(o, o + Vector2(t, 0), LIP, 3.0)
				if world.get_tile(x - 1, y) != World.WALL:
					draw_line(o, o + Vector2(0, t), LIP, 3.0)
				if world.get_tile(x + 1, y) != World.WALL:
					draw_line(o + Vector2(t, 0), o + Vector2(t, t), LIP, 3.0)
				continue
			# Zemin: kuzeydeki duvar uzun gölge düşürür, yanlar ve güney kısa.
			if world.get_tile(x, y - 1) == World.WALL:
				_grad(o, o + Vector2(t, 0), Vector2(0, t * 0.55))
			if world.get_tile(x - 1, y) == World.WALL:
				_grad(o + Vector2(0, t), o, Vector2(t * 0.3, 0))
			if world.get_tile(x + 1, y) == World.WALL:
				_grad(o + Vector2(t, 0), o + Vector2(t, t), Vector2(-t * 0.3, 0))
			if world.get_tile(x, y + 1) == World.WALL:
				_grad(o + Vector2(t, t), o + Vector2(0, t), Vector2(0, -t * 0.2))


## a-b duvar kenarı, d gölgenin zemine uzanma yönü ve boyu.
func _grad(a: Vector2, b: Vector2, d: Vector2) -> void:
	draw_polygon(PackedVector2Array([a, b, b + d, a + d]), PackedColorArray([SHADOW, SHADOW, CLEAR, CLEAR]))


## 3/4 kamerada duvarın ön yüzü: karonun tamamını ve üstündeki karonun alt yarısını kaplar,
## böylece duvar yüksekmiş gibi görünür. Doku yatayda kesintisiz bir şerit (tile_wall_face).
func _face(x: int, o: Vector2, t: float) -> void:
	var tex := Sprites.tex(world.tile_key("tile_wall_face"))
	if tex == null:
		return
	var h := t * 1.5
	var tw := tex.get_width()
	var src_w := tw / 8.0
	var sx := fmod(x * src_w, tw)
	draw_texture_rect_region(tex, Rect2(o.x, o.y + t - h, t, h), Rect2(sx, 0, src_w, tex.get_height()))
	draw_polygon(PackedVector2Array([Vector2(o.x, o.y + t - h), Vector2(o.x + t, o.y + t - h), Vector2(o.x + t, o.y + t - h + 10), Vector2(o.x, o.y + t - h + 10)]),
		PackedColorArray([Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]))
