class_name Hearts
extends Control
## Can kalpleri: yazı tipine bağlı ♥ yerine çizilir (tarayıcıda sistem yazı tipi yok, karakter kutu çıkıyordu).
## Dolu kalp kırmızı, boş kalp yalnızca çerçeve.

const SIZE := 18.0
const GAP := 5.0
const RED := Color("ff3b5c")

var lives := 3
var total := 3


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_lives(n: int, of: int) -> void:
	lives = n
	total = of
	custom_minimum_size = Vector2(total * (SIZE + GAP) - GAP, SIZE)
	queue_redraw()


func _draw() -> void:
	for i in total:
		var pts := _heart(Vector2(i * (SIZE + GAP) + SIZE * 0.5, SIZE * 0.5), SIZE * 0.5)
		if i < lives:
			draw_colored_polygon(pts, RED)
			draw_polyline(pts + PackedVector2Array([pts[0]]), RED.darkened(0.35), 1.2, true)
		else:
			draw_colored_polygon(pts, Color(RED, 0.12))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(RED, 0.75), 1.5, true)


## Klasik kalp eğrisi, merkez c, yarıçap r.
func _heart(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 40:
		var t := TAU * k / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y + 1.5) * (r / 16.5))
	return pts
