class_name Pickup
extends Actor
## Yerdeki eşya ya da altın. Fırlayıp iki kez seker; 70 piksel içinde oyuncuya çekilir (entities.js:2655-2673).

var item := {}
var gold := 0
var vel := Vector2.ZERO
var lift := 0.0
var lift_vel := 0.0
var bounces := 2
var bob := randf() * TAU


func setup_item(p_item: Dictionary) -> void:
	item = p_item
	_pop()


func setup_gold(amount: int) -> void:
	gold = amount
	_pop()


func _pop() -> void:
	vel = Vector2(randf_range(-2.5, 2.5), 0)
	lift_vel = randf_range(6, 11)


func tick() -> void:
	if bounces > 0 or lift > 0:
		position = main.world.move_point(position, vel)
		lift += lift_vel
		lift_vel -= 0.5
		if lift <= 0:
			lift = 0
			bounces -= 1
			lift_vel = absf(lift_vel) * 0.45
			vel *= 0.6
			if bounces <= 0:
				lift_vel = 0
				vel = Vector2.ZERO
	var p := main.player
	var d := position.distance_to(p.position)
	if d < 70.0 and p.alive() and lift == 0:
		position += (p.position - position).normalized() * minf(d, 4.5 + (70.0 - d) * 0.1)
		if position.distance_to(p.position) < 18.0:
			main.collect(self)
	bob += 0.08
	queue_redraw()


func _draw() -> void:
	var y := -lift + sin(bob) * 2.0
	draw_set_transform(Vector2(0, 10), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 9, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if gold > 0:
		Sprites.draw_flat(self, "item_gold", Rect2(-12, y - 12, 24, 24))
		return
	var c: Color = ItemData.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	if item.get("rarity", "common") != "common":
		c.a = 0.35 + 0.15 * sin(bob * 2)
		draw_circle(Vector2(0, y), 15, c)
	Sprites.draw_flat(self, ItemData.icon_key(item), Rect2(-14, y - 14, 28, 28))
