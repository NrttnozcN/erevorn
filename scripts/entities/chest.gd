class_name Chest
extends Actor
## Sandık (entities.js:610-736). Normal sandık 2-3 ganimet atar; kilitli sandık altın anahtar ister.

var opened := false
var locked := false


func open_chest() -> void:
	opened = true
	queue_redraw()


func _draw() -> void:
	var painted := Sprites.tex("chest_locked") != null
	if painted:
		var pk := "chest_open" if opened else ("chest_locked" if locked else "chest_closed")
		Sprites.draw_grounded(self, pk, 44.0, 18.0)
	else:
		var key := "chest_open" if opened else "chest_closed"
		var mod := Color(1.0, 0.85, 0.3) if locked else Color.WHITE
		Sprites.draw_flat(self, key, Rect2(-24, -24, 48, 48), mod)
	if locked and not opened and not painted:
		draw_rect(Rect2(-6, -2, 12, 10), Color("ffd700"))
		draw_arc(Vector2(0, -4), 5, PI, TAU, 8, Color("ffd700"), 2)
	if not opened and position.distance_to(main.player.position) < 60:
		main.draw_hint(self, Vector2(0, -36), "[E] AÇ" if not locked else "[E] ANAHTAR")
