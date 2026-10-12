class_name HeartHazard
extends Actor
## Kara Taht'ın tehlikeleri (bölge 10), diğer bölge tehlikelerinin kardeşi:
##   crystals — kristal hattı: yerde mor çizgi dolar (tell), sonra hat boyunca mor kristaller fışkırır: hasar + kristalleşme.
##   ember    — Kalp'in kızıl-altın kor zemini: üstünde duran yanar.
##   orb      — Kârun'un rün küresi: düz giden mermi (rün klonu büyücüsü ve Kârun'un küre halkası).
##   spring   — Kalp Pınarı: okla / kılıçla vurulunca birkaç sn altın ışık sütunu; ışıktaki oyuncunun kristali ve yanığı çözülür
##              (Main.lanterns listesinde durur).
##   sera     — Sera'nın ışığı (Kârun savaşı, faz 3): yerde altın-beyaz daire; içindeki oyuncu hasar almaz.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const CRYSTAL := Color(0.72, 0.32, 1.0)
const HEART := Color(1.0, 0.45, 0.2)
const GOLD := Color(1.0, 0.85, 0.5)
const LINE_TELL := 54
const LINE_LIFE := 50
const EMBER_LIFE := 200
const ORB_LIFE := 150
const SPRING_LIT := 360
const SPRING_R := 100.0
const SERA_LIFE := 300

var kind := "crystals"
var radius := 30.0
var damage := 0
var t := 0
var life := LINE_TELL + LINE_LIFE
var vel := Vector2.ZERO
var lit := 0
var _cd := 0
var _hit := false
var _a := Vector2.ZERO
var _b := Vector2.ZERO
var _spots: Array = []
var _seed := randf() * TAU
var _light: PointLight2D


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	match kind:
		"ember": life = EMBER_LIFE
		"orb": life = ORB_LIFE
		"spring": life = 1 << 30
		"sera": life = SERA_LIFE
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = radius / 45.0
	_light.color = {"ember": HEART, "orb": CRYSTAL, "spring": GOLD, "sera": GOLD}.get(kind, CRYSTAL)
	_light.energy = 0.0 if kind == "spring" else 0.5
	_light.position = Vector2(0, _sort_up())
	if kind == "spring":
		_light.texture_scale = SPRING_R / 45.0
	add_child(_light)


## Kristal hattı: start'tan dir yönünde length boyunca.
func setup_line(start: Vector2, dir: Vector2, length: float, p_damage: int) -> void:
	kind = "crystals"
	damage = p_damage
	radius = 16.0
	life = LINE_TELL + LINE_LIFE
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var end := start + dir * length
	position = Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 10.0)
	_a = start - position
	_b = end - position
	var n := maxi(3, int(length / 28.0))
	for i in n:
		_spots.append([(i + 0.5) / n, randf_range(30.0, 46.0), randf() < 0.5])
	add_child(GlowLayer.make(_paint))
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = length / 300.0 + 0.4
	_light.color = CRYSTAL
	_light.energy = 0.5
	_light.position = (_a + _b) * 0.5
	add_child(_light)


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return 8.0 if kind == "orb" else radius


func head() -> Vector2:
	return center() + Vector2(0, -30)


func warms(at: Vector2) -> bool:
	return kind == "spring" and lit > 0 and ((at - center()) * Vector2(1, 1.0 / 0.6)).length() < SPRING_R


func light_up() -> void:
	if kind != "spring":
		return
	if lit == 0:
		main.burst(head(), 44, GOLD)
		main.float_text(head() + Vector2(0, -40), "KALP PINARI AKTI", GOLD.lightened(0.2))
	lit = SPRING_LIT


## Sera'nın ışığı oyuncuyu koruyor mu?
func shields(at: Vector2) -> bool:
	return kind == "sera" and t > 20 and ((at + Vector2(0, 14) - center()) * Vector2(1, 1.0 / 0.42)).length() < radius


func triggered() -> bool:
	return kind != "crystals" or t >= LINE_TELL


func _feet_in(at: Vector2, c: Vector2, r: float) -> bool:
	return ((at + Vector2(0, 14) - c) * Vector2(1, 1.0 / 0.42)).length() < r


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	match kind:
		"crystals":
			if t == LINE_TELL:
				main.shake(5)
			if t >= LINE_TELL and t < LINE_TELL + 12 and not _hit and p.alive():
				var feet := p.position + Vector2(0, 14) - position
				if feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, _a, _b)) < 22.0:
					_hit = true
					if p.take_damage(damage, self):
						p.apply_debuff("crystal")
		"ember":
			if _cd == 0 and t > 8 and t < life - 20 and p.alive() and _feet_in(p.position, center(), radius):
				_cd = 45
				if p.take_damage(damage, self):
					p.apply_debuff("burn")
		"orb":
			position += vel
			if not main.world.is_walkable(center()):
				remove()
				return
			if p.alive() and center().distance_to(p.position + Vector2(0, -10)) < 22.0:
				if p.take_damage(damage, self):
					p.apply_debuff("crystal")
				remove()
				return
		"spring":
			if lit > 0:
				lit -= 1
				if p.alive() and warms(p.position):
					p.cleanse_heart()
			_light.energy = lerpf(_light.energy, 1.1 if lit > 0 else 0.0, 0.1)
	if t >= life:
		remove()
		return
	queue_redraw()


func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"crystals":
			if t < LINE_TELL:
				return
			var a := clampf(float(life - t) / 18.0, 0.0, 1.0)
			var open := clampf(float(t - LINE_TELL) / 10.0, 0.0, 1.0)
			var tex := Sprites.tex("prop_z10_crystals")
			for sp in _spots:
				var u: float = sp[0]
				if u > open:
					continue
				var base: Vector2 = _a.lerp(_b, u)
				_blot(base, 14.0, Color(0.08, 0.02, 0.12, 0.35 * a))
				var rise := clampf((open - u) * 5.0 + 0.2, 0.0, 1.0)
				if tex:
					var h: float = sp[1] * rise
					var w := h * tex.get_width() / tex.get_height()
					draw_set_transform(base, 0, Vector2(-1.0 if sp[2] else 1.0, 1.0))
					draw_texture_rect(tex, Rect2(-w / 2, -h, w, h), false, Color(1, 1, 1, a))
					draw_set_transform(Vector2.ZERO)
		"ember":
			var a := clampf(float(t) / 8.0, 0.0, 1.0) * clampf(float(life - t) / 30.0, 0.0, 1.0)
			_blot(c, radius * 1.1, Color(0.2, 0.04, 0.02, 0.55 * a))
		"spring":
			_blot(c, 32.0, Color(0, 0, 0, 0.35))
			Sprites.draw_grounded(self, "prop_z10_spring", 56.0, c.y + 4, Color(1.08, 1.0, 0.95) if lit > 0 else Color.WHITE)


func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	match kind:
		"crystals":
			if t < LINE_TELL:
				var k := float(t) / LINE_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				var reach := 0.25 + 0.75 * k
				g.streak(PackedVector2Array([_a, _a.lerp(_b, reach)]), 1.4, Color(CRYSTAL, (0.25 + 0.55 * k) * blink))
				for j in 16:
					var u := float(j + 1) / 16
					if u > reach:
						break
					g.glow(_a.lerp(_b, u), 4.0 + 2.0 * k, Color(CRYSTAL, (0.25 + 0.45 * k) * blink))
			else:
				var a := clampf(float(life - t) / 18.0, 0.0, 1.0)
				for sp in _spots:
					g.glow(_a.lerp(_b, sp[0]) + Vector2(0, -16), 14.0, Color(CRYSTAL, 0.25 * a))
		"ember":
			var a := clampf(float(t) / 8.0, 0.0, 1.0) * clampf(float(life - t) / 30.0, 0.0, 1.0)
			var fl := 0.85 + 0.15 * sin(now * 9.0 + _seed)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius * 1.15, Color(HEART, 0.4 * a * fl))
			g.glow(Vector2.ZERO, radius * 0.5, Color(1.0, 0.85, 0.5, 0.3 * a))
			g.draw_set_transform(Vector2.ZERO)
		"orb":
			g.glow(c, 14.0, Color(CRYSTAL, 0.7))
			g.glow(c, 5.0, Color(0.95, 0.85, 1.0, 0.9))
			g.glow(c - vel * 4.0, 9.0, Color(CRYSTAL, 0.3))
		"spring":
			if lit > 0:
				var fade := clampf(float(lit) / 60.0, 0.0, 1.0)
				g.draw_set_transform(c, 0, Vector2(1, 0.6))
				g.glow(Vector2.ZERO, SPRING_R, Color(GOLD, 0.15 * fade))
				g.ring(Vector2.ZERO, SPRING_R, 1.2, Color(GOLD, 0.3 * fade))
				g.draw_set_transform(Vector2.ZERO)
				for i in 6:
					var q := fmod(now * 0.6 + i / 6.0, 1.0)
					g.glow(c + Vector2(sin(i * 2.1) * 10.0, -20.0 - q * 120.0), 8.0, Color(GOLD, 0.5 * fade * (1.0 - q)))
			else:
				var k := 0.5 + 0.5 * sin(now * 1.3 + _seed)
				g.glow(c + Vector2(0, -26), 14.0 + 3.0 * k, Color(HEART, 0.25 + 0.1 * k))
		"sera":
			var a := clampf(float(t) / 20.0, 0.0, 1.0) * clampf(float(life - t) / 30.0, 0.0, 1.0)
			var k := 0.5 + 0.5 * sin(now * 2.0)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius * 1.1, Color(GOLD, (0.18 + 0.06 * k) * a))
			g.ring(Vector2.ZERO, radius, 2.0, Color(1.0, 0.95, 0.8, 0.6 * a))
			g.draw_set_transform(Vector2.ZERO)
			for i in 5:
				var q := fmod(now * 0.5 + i / 5.0, 1.0)
				g.glow(c + Vector2(cos(i * 2.5) * radius * 0.6, -q * 90.0), 6.0, Color(1.0, 0.95, 0.8, 0.5 * a * (1.0 - q)))
