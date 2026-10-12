class_name Merchant
extends Actor
## Gizemli Satıcı. Her katta portalın yanında durur; her 5. katta özel satıcı gelir.

var special := false
var timer := 0
var stock: Array = []


func tick() -> void:
	timer += 1
	queue_redraw()


func _draw() -> void:
	var key := "merchant_idle1" if (timer / 22) % 2 == 0 else "merchant_idle2"
	if special:
		draw_circle(Vector2(0, 4), 26, Color(1, 0.2, 0.3, 0.18))
	if Sprites.tex("merchant_p1") != null:
		Sprites.draw_grounded(self, "merchant_p1" if (timer / 22) % 2 == 0 else "merchant_p2", 74.0, 20.0)
	else:
		Sprites.draw_flat(self, key, Rect2(-24, -24, 48, 48))
	if position.distance_to(main.player.position) < 70:
		main.draw_hint(self, Vector2(0, -36), "[E] DÜKKAN")
