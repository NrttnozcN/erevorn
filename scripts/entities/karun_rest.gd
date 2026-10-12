class_name KarunRest
extends Actor
## Kârun'un yenilgisi (kat 100): diz çöker, tacı ve asası kırılır, gözlerindeki mor ışık söner. Ardından karar ekranı.

var flip := false
var t := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func tick() -> void:
	t += 1
	if t == 50:
		main.float_text(position + Vector2(0, -170), "\"Dünya... zaten ölüyordu...\"", Color(0.85, 0.65, 1.0))
	queue_redraw()


func _draw() -> void:
	var tex := Sprites.tex("boss_karun_kneel")
	if tex == null:
		return
	var s := Boss.KR_SCALE
	var b := Rect2(-Boss.KR_ANCHOR * s, Boss.KR_CANVAS * s)
	if flip:
		b.position.x = -(Boss.KR_CANVAS.x - Boss.KR_ANCHOR.x) * s
	Sprites.draw_actor(self, "boss_karun_kneel", b, flip, false, false, Color(1, 1, 1, clampf(t / 15.0, 0.0, 1.0)))
