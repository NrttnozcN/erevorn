class_name ForestHazard
extends Actor
## Orman Tapınağı'nın yerdeki tehlikeleri (bölge 6), FrostHazard'ın kardeşi:
##   thorns  — Diken Tazısı ölünce kalan diken yığını: üstünden geçen hasar alır (~2 sn).
##   spores  — mor spor bulutu (Spor Mantarı, Lyra'nın ağlayan ağacı): içinde kalan zehirlenir; vel ile sürüklenebilir.
##             Kutsal Taş'ın arınma ışığına girince söner.
##   roots   — kök tuzağı: yerin altında başlangıçtan hedefe ilerleyen kabarma (tell), hedefte kökler fışkırır: hasar + kök.
##   seed    — Diken Rahibesi'nin tohumu: hedefe yay çizerek düşer, yerde mor halka (tell), sonra diken çemberi açar.
##   rain    — Lyra'nın diken yağmuru: yerde mor daire dolar (tell), sonra tepeden dikenler iner.
##   ring    — Lyra'nın diken çemberi (faz 3): merkezden dışa yayılan diken halkası; halkada bir boşluk var.
##   stone   — Kutsal Taş: okla / kılıçla vurulunca birkaç sn soluk altın-beyaz arınma ışığı yayar; ışıktaki
##             oyuncunun zehri ve kökü çözülür, spor bulutları ışığa giremez. (Main.lanterns listesinde durur.)
## Y sıralı katmanda zemin işareti aktörlerin altında kalsın diye düğüm dairenin bir yarıçap üstüne konur (FrostHazard ile aynı).

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const PURPLE := Color(0.72, 0.32, 1.0)
const PURPLE_SOFT := Color(0.6, 0.3, 0.85)
const HOLY := Color(1.0, 0.92, 0.66)
const BARK := Color(0.42, 0.28, 0.17)
const THORNS_LIFE := 120
const SPORE_LIFE := 180
const ROOT_TRAVEL := 60
const ROOT_LIFE := 50
const SEED_FLY := 16
const SEED_TELL := 60
const SEED_LIFE := 40
const RAIN_TELL := 60
const RAIN_LIFE := 40
const RING_GROW := 80
const STONE_LIT := 420
const STONE_R := 110.0
const STONE_H := 74.0

var kind := "thorns"
var radius := 30.0
var damage := 0
var t := 0
var life := THORNS_LIFE
var vel := Vector2.ZERO
var hurts_enemies := false
var _cd := 0
var _hit := false
var _seed := randf() * TAU
## Kök tuzağı: başlangıç noktası (merkeze göre); tohum: fırladığı nokta.
var from := Vector2.ZERO
## Diken çemberi: en büyük yarıçap, boşluğun açısı ve yarı genişliği.
var reach := 260.0
var gap := 0.0
var gap_half := 0.42
## Kutsal Taş: kalan ışık süresi.
var lit := 0
var _light: PointLight2D
var _fade_out := 0


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	match kind:
		"thorns": life = THORNS_LIFE
		"spores": life = SPORE_LIFE
		"roots": life = ROOT_TRAVEL + ROOT_LIFE
		"seed": life = SEED_FLY + SEED_TELL + SEED_LIFE
		"rain": life = RAIN_TELL + RAIN_LIFE
		"ring": life = RING_GROW + 20
		"stone": life = 1 << 30
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = radius / 55.0
	l.color = PURPLE
	l.energy = 0.3 if kind in ["thorns", "spores"] else 0.5
	l.position = Vector2(0, _sort_up())
	if kind == "stone":
		l.texture_scale = STONE_R / 46.0
		l.energy = 0.0
		l.color = HOLY
		l.position = Vector2(0, _sort_up() - STONE_H * 0.5)
	if kind == "ring":
		l.texture_scale = reach / 60.0
	add_child(l)
	_light = l


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return 8.0 if kind == "ring" else radius


## Kutsal Taş'ın oyulmuş sembolü (vuruş noktası).
func head() -> Vector2:
	return center() + Vector2(0, -STONE_H * 0.55)


## Taş ışığı yanıyorsa ve nokta ışığın içindeyse true (oyuncu arınır, spor giremez).
func warms(at: Vector2) -> bool:
	return kind == "stone" and lit > 0 and ((at - center()) * Vector2(1, 1.0 / 0.6)).length() < STONE_R


func light_up() -> void:
	if kind != "stone":
		return
	if lit == 0:
		main.burst(head(), 44, HOLY)
		main.float_text(head() + Vector2(0, -36), "KUTSAL TAŞ UYANDI", HOLY.lightened(0.2))
	lit = STONE_LIT


## Oyuncu ayağının (yere yatık elipsteki) merkeze uzaklığı yarıçap içinde mi?
func _feet_in(at: Vector2, c: Vector2, r: float) -> bool:
	var d := (at + Vector2(0, 14) - c) * Vector2(1, 1.0 / 0.42)
	return d.length() < r


## Tell bitti mi?
func triggered() -> bool:
	match kind:
		"roots": return t >= ROOT_TRAVEL
		"seed": return t >= SEED_FLY + SEED_TELL
		"rain": return t >= RAIN_TELL
	return true


func _stone_cleansed(at: Vector2) -> bool:
	for l in main.lanterns:
		if l is ForestHazard and is_instance_valid(l) and l.warms(at):
			return true
	return false


func _hurt_player(p: Player, dmg: int, debuff: String) -> void:
	if p.take_damage(dmg, self) and debuff != "":
		p.apply_debuff(debuff)


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	var c := center()
	match kind:
		"thorns":
			if _cd == 0 and p.alive() and _feet_in(p.position, c, radius) and t > 4 and t < life - 15:
				_cd = 40
				_hurt_player(p, damage, "")
		"spores":
			if vel != Vector2.ZERO:
				var np := position + vel
				if main.world.is_walkable(np + Vector2(0, radius)):
					position = np
				else:
					vel = -vel
			if _fade_out == 0 and _stone_cleansed(c):
				# Arınma ışığı spor bulutunu dağıtır.
				_fade_out = 1
				life = mini(life, t + 24)
			if _cd == 0 and t > 10 and t < life - 20 and _fade_out == 0:
				if p.alive() and _feet_in(p.position, c, radius) and p.cleansed == 0:
					_cd = 50
					if p.poison == 0:
						main.float_text(p.position + Vector2(0, -56), "SPOR", PURPLE.lightened(0.3))
					p.apply_debuff("poison")
					if damage > 0:
						p.take_damage(damage, self)
				if hurts_enemies:
					for e in main.enemies:
						if is_instance_valid(e) and not e.removed and e.type != "spor_mantari" and _feet_in(e.position, c, radius):
							e.poisoned = maxi(e.poisoned, 240)
		"roots":
			if t == ROOT_TRAVEL:
				main.shake(5)
				main.burst(c + Vector2(0, -10), radius * 1.2, BARK.lightened(0.3))
				if p.alive() and _feet_in(p.position, c, radius):
					_hurt_player(p, damage, "root")
		"seed":
			if t == SEED_FLY + SEED_TELL:
				main.burst(c + Vector2(0, -8), radius, PURPLE)
				if p.alive() and _feet_in(p.position, c, radius):
					_hurt_player(p, damage, "poison")
		"rain":
			if t == RAIN_TELL + 4:
				main.shake(3)
				if p.alive() and _feet_in(p.position, c, radius):
					_hurt_player(p, damage, "poison")
		"ring":
			var r := reach * clampf(float(t) / RING_GROW, 0.0, 1.0)
			if not _hit and t <= RING_GROW and p.alive():
				var rel := (p.position + Vector2(0, 14) - c) * Vector2(1, 1.0 / 0.42)
				if absf(rel.length() - r) < 14.0 and absf(angle_difference(gap, rel.angle())) > gap_half:
					_hit = true
					_hurt_player(p, damage, "root")
		"stone":
			if lit > 0:
				lit -= 1
				if p.alive() and warms(p.position):
					p.cleanse()
			_light.energy = lerpf(_light.energy, 1.15 if lit > 0 else 0.0, 0.1)
	if t >= life:
		remove()
		return
	queue_redraw()


func _fade(fade_in: int, fade_out: int) -> float:
	return clampf(float(t) / fade_in, 0.0, 1.0) * clampf(float(life - t) / fade_out, 0.0, 1.0)


# ── Çizim (normal karışım) ───────────────────────────────────────────

func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


## Boyalı efekt sprite'ı: tabanı base'te, boyu h; rise ile yerden yükselir, a ile söner.
func _sprite(key: String, base: Vector2, h: float, rise: float, a: float, flip := false) -> bool:
	var tex := Sprites.tex(key)
	if tex == null:
		return false
	var top := Sprites.content_top(key)
	var bot := Sprites.content_bottom(key)
	var full_h := h / maxf(bot - top, 0.05)
	var w := full_h * tex.get_width() / tex.get_height()
	draw_set_transform(base, 0, Vector2(-1.0 if flip else 1.0, maxf(rise, 0.01)))
	draw_texture_rect(tex, Rect2(-w / 2.0, -full_h * bot, w, full_h), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	return true


## Kodla dikenler (doku yoksa): koyu kabuk renkli sivri üçgenler.
func _thorn_code(base: Vector2, h: float, a: float, lean: float) -> void:
	var w := h * 0.22
	var poly := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(lean, -h), base + Vector2(w, 0)])
	draw_polygon(poly, PackedColorArray([Color(0.2, 0.12, 0.1, a), Color(0.62, 0.38, 0.75, a), Color(0.32, 0.2, 0.14, a)]))


func _thorn(base: Vector2, h: float, a: float, i: int, rise := 1.0) -> void:
	if not _sprite("fx_thorn%d" % (1 + i % 3), base, h, rise, a, i % 2 == 0):
		_thorn_code(base, h * rise, a, sin(i * 1.7) * h * 0.2)


func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"thorns":
			var a := _fade(6, 30)
			_blot(c, radius * 1.1, Color(0.06, 0.03, 0.06, 0.4 * a))
			if not _sprite("fx_thorn_pile", c + Vector2(0, 4), 26.0, 1.0, a):
				for i in 6:
					_thorn(c + Vector2(cos(_seed + i) * radius * 0.6, sin(_seed + i * 1.3) * radius * 0.25), 16.0, a, i)
		"roots":
			_draw_roots(c)
		"seed":
			if t >= SEED_FLY + SEED_TELL:
				var k := clampf(float(t - SEED_FLY - SEED_TELL) / 6.0, 0.0, 1.0)
				var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
				for i in 9:
					var ang := _seed + i * TAU / 9.0
					_thorn(c + Vector2(cos(ang), sin(ang) * 0.42) * radius * 0.75, 30.0, a, i, k)
			elif t >= SEED_FLY:
				_sprite("fx_thorn_seed", c + Vector2(0, 2), 14.0, 1.0, 1.0)
		"rain":
			if t >= RAIN_TELL:
				var k := clampf(float(t - RAIN_TELL) / 5.0, 0.0, 1.0)
				var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
				_blot(c, radius, Color(0.08, 0.03, 0.08, 0.35 * a))
				for i in 5:
					var o := Vector2(cos(_seed + i * 1.9), sin(_seed + i * 2.3) * 0.42) * radius * 0.55
					_thorn(c + o, 38.0 + 8.0 * sin(i * 3.1), a, i, k)
		"ring":
			var r := reach * clampf(float(t) / RING_GROW, 0.0, 1.0)
			var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
			var n := maxi(8, int(r * TAU / 34.0))
			# Arkadaki yarı önce, öndeki yarı sonra.
			for pass_i in 2:
				for i in n:
					var ang := i * TAU / n
					if absf(angle_difference(gap, ang)) < gap_half:
						continue
					var front := sin(ang) > 0.0
					if front != (pass_i == 1):
						continue
					_thorn(c + Vector2(cos(ang), sin(ang) * 0.42) * r, 34.0 * (0.75 if front else 1.0), a, i)
		"stone":
			_blot(c, 30.0, Color(0, 0, 0, 0.35))
			if not Sprites.draw_grounded(self, "prop_z6_stone", STONE_H, c.y + 4, Color(1.05, 1.0, 0.92) if lit > 0 else Color.WHITE):
				draw_rect(Rect2(c.x - 14, c.y - STONE_H, 28, STONE_H), Color(0.5, 0.5, 0.46))


## Kök tuzağı: tell'de yerin altında ilerleyen kabarma (toprak çatlakları); tetiklenince boyalı kök patlaması.
func _draw_roots(c: Vector2) -> void:
	var start := from
	if t < ROOT_TRAVEL:
		var k := float(t) / ROOT_TRAVEL
		var head := start.lerp(c, k)
		# İlerleyen kabarma: arkasında kalan koyu toprak izi.
		var n := 14
		for j in n:
			var u := float(j) / n * k
			var at := start.lerp(c, u)
			_blot(at, 9.0 + 4.0 * sin(u * 30.0 + _seed), Color(0.12, 0.07, 0.04, 0.35 * (0.4 + 0.6 * u / maxf(k, 0.01))))
		_blot(head, 16.0, Color(0.18, 0.1, 0.05, 0.55))
		for i in 4:
			var o := Vector2(cos(_seed + i * 1.6 + t * 0.2), sin(_seed + i) * 0.4) * 9.0
			draw_circle(head + o + Vector2(0, -2), 2.2, Color(0.36, 0.25, 0.16, 0.9))
		return
	var a := clampf(float(life - t) / 18.0, 0.0, 1.0)
	var rise := clampf(float(t - ROOT_TRAVEL) / 6.0, 0.0, 1.0)
	_blot(c, radius * 1.1, Color(0.08, 0.05, 0.03, 0.45 * a))
	if not _sprite("fx_root_burst", c + Vector2(0, 6), radius * 1.5, rise, a):
		for i in 7:
			var ang := _seed + i * TAU / 7.0
			var base := c + Vector2(cos(ang), sin(ang) * 0.42) * radius * 0.6
			var tip := base + Vector2(cos(ang) * 6.0, -radius * 1.2 * rise)
			var pts := PackedVector2Array([base, (base + tip) * 0.5 + Vector2(sin(i * 2.0) * 6.0, 0), tip])
			draw_polyline(pts, Color(0.14, 0.08, 0.05, a), 6.0, true)
			draw_polyline(pts, Color(0.45, 0.3, 0.18, a), 3.0, true)


# ── Parıltılar (toplamalı) ───────────────────────────────────────────

func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	match kind:
		"thorns":
			var a := _fade(6, 30)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius, Color(PURPLE, 0.14 * a))
			g.draw_set_transform(Vector2.ZERO)
		"spores":
			var a := _fade(14, 24)
			for i in 7:
				var ang := _seed + i * 0.9 + now * (0.35 + 0.05 * i)
				var o := Vector2(cos(ang), sin(ang * 1.3) * 0.5) * radius * (0.35 + 0.12 * (i % 3))
				g.glow(c + o + Vector2(0, -10 - 6 * sin(now + i)), radius * (0.55 + 0.1 * (i % 2)), Color(PURPLE_SOFT, 0.13 * a))
			g.glow(c + Vector2(0, -8), radius * 0.5, Color(0.85, 0.6, 1.0, 0.12 * a))
			for i in 6:
				var q := fmod(now * 0.5 + i * 0.17 + _seed, 1.0)
				var at := c + Vector2(cos(_seed * 3.0 + i * 1.1) * radius * 0.7, -q * radius * 0.9)
				g.glow(at, 3.0, Color(0.9, 0.7, 1.0, 0.55 * a * (1.0 - q)))
		"roots":
			if t < ROOT_TRAVEL:
				var k := float(t) / ROOT_TRAVEL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 14.0 * k))
				var head := from.lerp(c, k)
				g.glow(head, 14.0, Color(PURPLE, 0.35 * blink))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius * (0.5 + 0.5 * k), 1.6, Color(PURPLE, (0.25 + 0.5 * k) * blink))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var fl := clampf(1.0 - float(t - ROOT_TRAVEL) / 14.0, 0.0, 1.0)
				g.glow(c, radius * 1.3, Color(PURPLE, 0.35 * fl))
		"seed":
			if t < SEED_FLY:
				var u := float(t) / SEED_FLY
				var at := from.lerp(c, u) + Vector2(0, -sin(u * PI) * 50.0)
				g.glow(at, 12.0, Color(PURPLE, 0.7))
				g.glow(at, 4.0, Color(0.95, 0.8, 1.0, 0.9))
			elif t < SEED_FLY + SEED_TELL:
				var k := float(t - SEED_FLY) / SEED_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius, 2.0, Color(PURPLE, (0.35 + 0.5 * k) * blink))
				g.ring(Vector2.ZERO, radius * maxf(k, 0.05), 1.2, Color(0.95, 0.8, 1.0, 0.6))
				g.glow(Vector2.ZERO, radius, Color(PURPLE, 0.08 + 0.14 * k))
				g.draw_set_transform(Vector2.ZERO)
				g.glow(c, 7.0, Color(0.9, 0.6, 1.0, 0.7))
			else:
				var fl := clampf(1.0 - float(t - SEED_FLY - SEED_TELL) / 12.0, 0.0, 1.0)
				g.glow(c, radius * 1.2, Color(PURPLE, 0.4 * fl))
		"rain":
			if t < RAIN_TELL:
				var k := float(t) / RAIN_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius, 2.2, Color(PURPLE, (0.35 + 0.55 * k) * blink))
				g.ring(Vector2.ZERO, radius * maxf(k, 0.05), 1.4, Color(0.95, 0.8, 1.0, 0.65))
				g.glow(Vector2.ZERO, radius, Color(PURPLE, 0.06 + 0.16 * k))
				g.draw_set_transform(Vector2.ZERO)
				if k > 0.7:
					# Son an: tepeden inen dikenlerin parıltısı.
					var y := -200.0 * (1.0 - k) / 0.3
					g.glow(c + Vector2(0, y - 30), 14.0, Color(0.9, 0.6, 1.0, 0.45))
			else:
				var fl := clampf(1.0 - float(t - RAIN_TELL) / 12.0, 0.0, 1.0)
				g.glow(c, radius * 1.2, Color(PURPLE, 0.35 * fl))
		"ring":
			var r := reach * clampf(float(t) / RING_GROW, 0.0, 1.0)
			var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			var arc_from := gap + gap_half
			g.ring(Vector2.ZERO, r, 2.2, Color(PURPLE, 0.55 * a), arc_from, arc_from + TAU - gap_half * 2.0)
			# Boşluğun iki ucunda soluk altın işaret: geçilecek yer.
			g.glow(Vector2.from_angle(gap) * r, 18.0, Color(HOLY, 0.25 * a))
			g.draw_set_transform(Vector2.ZERO)
		"stone":
			var head := c + Vector2(0, -STONE_H * 0.55)
			if lit > 0:
				var fade := clampf(float(lit) / 60.0, 0.0, 1.0)
				var fl := 0.88 + 0.12 * sin(now * 3.0 + _seed)
				g.glow(head, 30.0 * fl, Color(HOLY, 0.5 * fade))
				g.glow(head, 10.0, Color(1.0, 1.0, 0.9, 0.7 * fade))
				g.draw_set_transform(c, 0, Vector2(1, 0.6))
				g.glow(Vector2.ZERO, STONE_R, Color(HOLY, 0.14 * fade))
				g.ring(Vector2.ZERO, STONE_R, 1.2, Color(HOLY, 0.28 * fade))
				g.draw_set_transform(Vector2.ZERO)
				for i in 5:
					var q := fmod(now * 0.4 + i * 0.2 + _seed, 1.0)
					g.glow(c + Vector2(cos(_seed + i * 1.3) * 40.0, -q * 90.0), 3.0, Color(HOLY, 0.6 * fade * (1.0 - q)))
			else:
				var k := 0.5 + 0.5 * sin(now * 1.2 + _seed)
				g.glow(head, 12.0 + 3.0 * k, Color(HOLY, 0.12 + 0.08 * k))
