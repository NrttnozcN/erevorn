class_name Shrine
extends Actor
## Sunak: 30 saniyelik güç, hız ya da yenilenme kutsaması verir (entities.js:4216-4277).

const INFO := {"atk": ["GÜÇ SUNAĞI", Color("ff4d4d")], "spd": ["HIZ SUNAĞI", Color("ffcc33")], "regen": ["YAŞAM SUNAĞI", Color("00f0ff")]}

var type := "atk"
var used := false
var timer := 0


func tick() -> void:
	timer += 1
	queue_redraw()


func _draw() -> void:
	var c: Color = INFO[type][1]
	if used:
		c = Color(0.3, 0.3, 0.35)
	if Sprites.draw_grounded(self, "shrine_used" if used else "shrine_" + type, 66.0, 22.0):
		if not used:
			var gl := 0.5 + 0.3 * sin(timer / 15.0)
			draw_circle(Vector2(0, -34), 16, Color(c.r, c.g, c.b, 0.22 * gl))
			if position.distance_to(main.player.position) < 60:
				main.draw_hint(self, Vector2(0, -72), "[E] " + INFO[type][0])
		return
	draw_rect(Rect2(-8, -24, 16, 48), Color("2a2a38"))
	draw_rect(Rect2(-10, 18, 20, 6), Color("3a3a4a"))
	var glow := 0.5 + 0.3 * sin(timer / 15.0)
	if not used:
		draw_circle(Vector2(0, -30), 14, Color(c.r, c.g, c.b, 0.25 * glow))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -40), Vector2(7, -30), Vector2(0, -20), Vector2(-7, -30)]), c)
	if not used and position.distance_to(main.player.position) < 60:
		main.draw_hint(self, Vector2(0, -50), "[E] " + INFO[type][0])
