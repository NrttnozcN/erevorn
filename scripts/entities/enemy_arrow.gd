class_name EnemyArrow
extends Actor
## Okçu Muhafız'ın oku: düz gider, duvara ya da oyuncuya çarpınca biter.
## orb: Tarikat Müridi'nin mor gölge küresi (aynı mantık, daha yavaş, parlayan çizim).
## Goblin Şamanı'nın küresi aynı orb; rengi sarı-yeşil lağım zehri, daha da yavaş.

var dir := Vector2.RIGHT
var speed := 4.2
var life := 80
var damage := 5
var debuff := ""
var orb := false
var tint := ORB_TINT
const UNSHADED := preload("res://scripts/world/unshaded.tres")
const ORB_TINT := Color(0.72, 0.36, 1.0)


func setup(angle: float, p_damage: int, p_debuff: String, p_orb := false) -> void:
	dir = Vector2.from_angle(angle)
	rotation = angle
	damage = p_damage
	debuff = p_debuff
	orb = p_orb
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if orb:
		speed = 3.0
		life = 120
		material = UNSHADED


func tick() -> void:
	position += dir * speed
	life -= 1
	if life <= 0 or not main.world.is_walkable(position):
		remove()
		return
	var p := main.player
	if p.alive() and position.distance_to(p.position + Vector2(0, -20)) < 22.0:
		if p.take_damage(damage, self):
			p.apply_debuff(debuff)
		remove()
		return
	queue_redraw()


func _draw() -> void:
	if orb:
		var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 70.0)
		if Sprites.tex("fx_orb_w"):
			Sprites.draw_flat(self, "fx_orb_w", Rect2(-60 * pulse, -15 * pulse, 72 * pulse, 30 * pulse), tint)
		draw_circle(Vector2(1, 0), 7 * pulse, Color(tint, 0.45))
		draw_circle(Vector2(1, 0), 3.5, tint.lerp(Color.WHITE, 0.7))
		return
	draw_line(Vector2(-14, 0), Vector2(8, 0), Color(0.45, 0.35, 0.25), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(6, -3.5), Vector2(6, 3.5)]), Color(0.75, 0.8, 0.85))
	draw_line(Vector2(-14, 0), Vector2(-9, -3), Color(0.6, 0.85, 1.0, 0.8), 1.5)
	draw_line(Vector2(-14, 0), Vector2(-9, 3), Color(0.6, 0.85, 1.0, 0.8), 1.5)
