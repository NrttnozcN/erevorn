class_name Captive
extends Actor
## Kafesteki tutsak (entities.js:4280-4409). Kurtarınca türe göre ödül verir.

const INFO := {"peasant": ["KÖYLÜ", Color("ffd700")], "soldier": ["ASKER", Color("ff7755")],
	"mage": ["BÜYÜCÜ", Color("bb88ff")], "merchant": ["TÜCCAR", Color("ffbb33")]}

var type := "peasant"
var timer := 0


func tick() -> void:
	timer += 1
	queue_redraw()


func _draw() -> void:
	if Sprites.draw_grounded(self, "captive_" + type, 74.0, 22.0):
		if (timer / 20) % 2 == 0 or position.distance_to(main.player.position) < 60:
			main.draw_hint(self, Vector2(0, -64), "[E] KURTAR")
		return
	var c: Color = INFO[type][1]
	draw_rect(Rect2(-18, -21, 36, 42), Color(0.05, 0.05, 0.08, 0.6))
	draw_circle(Vector2(0, -8), 7, c.darkened(0.2))
	draw_rect(Rect2(-6, -1, 12, 16), c.darkened(0.45))
	for i in 5:
		var x := -18 + i * 9
		draw_line(Vector2(x, -21), Vector2(x, 21), Color("8a8a95"), 2)
	draw_rect(Rect2(-18, -21, 36, 42), Color("8a8a95"), false, 2)
	if (timer / 20) % 2 == 0 or position.distance_to(main.player.position) < 60:
		main.draw_hint(self, Vector2(0, -32), "[E] KURTAR")
