class_name FireHazard
extends Actor
## Alev Krallığı'nın yerdeki tehlikeleri (bölge 4), GoblinHazard'ın kardeşi:
##   trail — Kor İmpi'nin atılırken bıraktığı kısa yanan iz lekesi: üstünden geçen yanar (~1.5 sn).
##   lava  — Lav Golemi'nin yere vuruşunda kalan lav gölü: üstünde duran yanar ve yavaşlar (~3 sn).
##   rune  — Kül Rahibi'nin rün dairesi: ~1 sn içten dışa dolar (tell), sonra alev sütunu fışkırır.
##   ash   — Kül Rahibi'nin kül bulutu: hasarsız, kısa süre görüşü kapatan gri-siyah duman.
##   crack — IGNIS'in balta savuruşunun açtığı düz yer yarığı: birkaç saniye lav sızdırır, üstünden geçen yanar
##           (setup_crack ile kurulur; faz 3'te beyaz-sarı ve daha uzun ömürlü).
## Y sıralı katmanda zemin işareti aktörlerin altında kalsın diye düğüm dairenin bir yarıçap üstüne konur
## (üstünde ya da hemen arkasında duran aktör önde çizilir); çizim ve vuruş merkezi `center` üstünden yapılır.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const FIRE := Color(1.0, 0.5, 0.12)
const TRAIL_LIFE := 90
const LAVA_LIFE := 180
const RUNE_TELL := 60
const PILLAR := 24
const ASH_LIFE := 100
const CRACK_LIFE := 240
const CRACK_OPEN := 8

var kind := "trail"
var radius := 16.0
var damage := 0
var t := 0
var life := TRAIL_LIFE
## Rün dairesi art arda çizilsin diye başlamadan önce beklenen kare.
var delay := 0
var _burn_cd := 0
var _hit := false
var _seed := randf() * TAU
## Yarık: uçlar (düğüme göre), kırık çizgi noktaları, yan çatlaklar ve faz 3 sıcaklığı.
var _a := Vector2.ZERO
var _b := Vector2.ZERO
var _pts := PackedVector2Array()
var _branches: Array[PackedVector2Array] = []
var _hot := false


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	match kind:
		"trail": life = TRAIL_LIFE
		"lava": life = LAVA_LIFE
		"rune": life = RUNE_TELL + PILLAR
		"ash": life = ASH_LIFE
	position = center - Vector2(0, _sort_up())
	if kind in ["trail", "lava"]:
		# Erimiş kısım ve alevler toplamalı parlar (düz renkli disk / sert üçgen gibi durmasın).
		add_child(GlowLayer.make(_paint_molten))
	elif kind == "rune":
		# Rün dairesi ve alev sütunu toplamalı çizilir: yumuşak haleli parlayan çizgiler, soluk bir koni değil.
		add_child(GlowLayer.make(_paint_pillar))
	elif kind == "ash":
		add_child(GlowLayer.make(_paint_ash))
	if kind != "ash":
		# Kendi ışığını verir: karanlık zeminde turuncu leke.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = radius / 60.0
		l.color = FIRE
		l.energy = 0.9 if kind == "lava" else 0.6
		l.position = Vector2(0, _sort_up())
		add_child(l)


## Yarık: start'tan dir yönünde length boyunca açılır. Düğüm yarığın en üst noktasının biraz üstüne konur,
## böylece üstünde ya da önünde duran aktörler hep önde çizilir.
func setup_crack(start: Vector2, dir: Vector2, length: float, p_damage: int, p_life := CRACK_LIFE, hot := false) -> void:
	kind = "crack"
	damage = p_damage
	life = p_life
	_hot = hot
	radius = length * 0.5
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var end := start + dir * length
	position = Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 10.0)
	_a = start - position
	_b = end - position
	var perp := dir.orthogonal()
	var n := maxi(4, int(length / 13.0))
	for i in n + 1:
		var u := float(i) / n
		var j := (randf() - 0.5) * 10.0 * sin(u * PI) if i > 0 and i < n else 0.0
		_pts.append(_a + (_b - _a) * u + perp * j)
	for i in 4:
		var k := randi_range(2, n - 1)
		var from := _pts[k]
		var ang := dir.angle() + (0.7 + randf() * 0.5) * (1.0 if i % 2 == 0 else -1.0)
		var l := randf_range(14.0, 30.0)
		var mid := from + Vector2.from_angle(ang) * l * 0.5 + perp * (randf() - 0.5) * 4.0
		_branches.append(PackedVector2Array([from, mid, from + Vector2.from_angle(ang + (randf() - 0.5) * 0.4) * l]))
	add_child(GlowLayer.make(_paint_crack))
	for u in [0.3, 0.75]:
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = length / 260.0 + 0.3
		l.color = Color(1.0, 0.85, 0.5) if hot else FIRE
		l.energy = 0.8
		l.position = _a.lerp(_b, u)
		add_child(l)


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return radius


func _ry() -> float:
	return radius * 0.42


## Rün sütunu tell'i bitti mi (alev fışkırıyor mu)?
func erupted() -> bool:
	return kind == "rune" and t >= RUNE_TELL


func tick() -> void:
	if delay > 0:
		delay -= 1
		visible = false
		return
	visible = true
	t += 1
	var p := main.player
	match kind:
		"trail", "lava":
			if _burn_cd > 0:
				_burn_cd -= 1
			var d := (p.position - center()) * Vector2(1, 1.0 / 0.42)
			if _burn_cd == 0 and p.alive() and d.length() < radius * 0.9 and t > 4 and t < life - 20:
				_burn_cd = 30
				if damage > 0:
					p.take_damage(damage, self)
				p.apply_debuff("burn")
				if kind == "lava":
					p.apply_debuff("slow")
				main.float_text(p.position + Vector2(0, -56), "YANIYOR", FIRE.lightened(0.3))
		"crack":
			if _burn_cd > 0:
				_burn_cd -= 1
			# Ayak noktası yarığa yakınsa yanar (yarık açıldıktan sonra, sönmeden önce).
			var feet := p.position + Vector2(0, 18) - position
			var q := Geometry2D.get_closest_point_to_segment(feet, _a, _b)
			if _burn_cd == 0 and p.alive() and t > CRACK_OPEN and t < life - 30 and feet.distance_to(q) < 15.0:
				_burn_cd = 30
				if damage > 0:
					p.take_damage(damage, self)
				p.apply_debuff("burn")
				main.float_text(p.position + Vector2(0, -56), "YANIYOR", FIRE.lightened(0.3))
		"rune":
			if t == RUNE_TELL:
				# Alev sütunu: dairenin içindeki oyuncu yanar.
				main.shake(5)
				main.burst(center() + Vector2(0, -30), radius * 1.2, FIRE)
				var d := (p.position - center()) * Vector2(1, 1.0 / 0.42)
				if not _hit and p.alive() and d.length() < radius:
					_hit = true
					if p.take_damage(damage, self):
						p.apply_debuff("burn")
	if t >= life:
		remove()
		return
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"trail": _draw_trail(c)
		"lava": _draw_lava(c)
		"rune": _draw_rune(c)
		"ash": _draw_ash(c)
		"crack": _draw_crack()


func _fade(fade_in: int, fade_out: int) -> float:
	return clampf(float(t) / fade_in, 0.0, 1.0) * clampf(float(life - t) / fade_out, 0.0, 1.0)


## Yanan iz: yumuşak kenarlı koyu is lekesi; alevler ve köz parıltısı toplamalı katmanda (_paint_molten).
func _draw_trail(c: Vector2) -> void:
	var a := _fade(4, 30)
	_soot(c, radius * 1.25, Color(0.08, 0.03, 0.02, 0.55 * a))


## Lav gölü: koyu kabuklu, düzensiz kenarlı leke (kenarı yumuşak sönen is halesiyle); erimiş göbek, kabarcıklar
## ve sona doğru soğuyup kararma ayrı toplamalı katmanda (_paint_molten).
func _draw_lava(c: Vector2) -> void:
	var a := _fade(8, 50)
	_soot(c, radius * 1.45, Color(0.07, 0.025, 0.012, 0.6 * a))
	draw_set_transform(c, 0, Vector2(1, 0.42))
	var rim := PackedVector2Array()
	for i in 40:
		var ang := i * TAU / 40.0
		rim.append(Vector2.from_angle(ang) * radius * (1.0 + 0.12 * sin(ang * 3.0 + _seed) + 0.06 * sin(ang * 7.0 + _seed * 2.0)))
	draw_colored_polygon(rim, Color(0.09, 0.03, 0.015, 0.45 * a))
	rim.append(rim[0])
	draw_polyline(rim, Color(0.09, 0.03, 0.015, 0.45 * a), 2.0, true)
	draw_set_transform(Vector2.ZERO)


## Yere yatık, kenarı yumuşak koyu leke (is / kabuk gölgesi).
func _soot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


## İz ve lav gölünün erimiş parıltısı (toplamalı): soğudukça söner. İzde titreyen alev dilleri,
## lavda yüzeyde patlayan parlak kabarcıklar.
func _paint_molten(g: GlowLayer) -> void:
	if delay > 0:
		return
	var c := Vector2(0, _sort_up())
	var a := _fade(6, 40)
	var cool := clampf(float(t) / life, 0.0, 1.0)
	var pulse := 0.85 + 0.15 * sin(t * 0.15 + _seed)
	g.draw_set_transform(c, 0, Vector2(1, 0.42))
	if kind == "lava":
		var hot := a * pulse * (1.0 - 0.6 * cool)
		g.glow(Vector2.ZERO, radius * 1.2, Color(1.0, 0.3, 0.04, hot))
		g.glow(Vector2.ZERO, radius * 1.0, Color(1.0, 0.38, 0.06, hot))
		g.glow(Vector2(-radius * 0.15, -radius * 0.05), radius * 0.8, Color(1.0, 0.58, 0.14, hot))
		g.glow(Vector2(radius * 0.25, radius * 0.1), radius * 0.45, Color(1.0, 0.85, 0.4, 0.8 * a * (1.0 - cool)))
		g.glow(Vector2(-radius * 0.3, radius * 0.15), radius * 0.4, Color(1.0, 0.75, 0.3, 0.8 * a * (1.0 - cool)))
		# Kabarcıklar: büyüyüp patlayan yumuşak parlak halkalar.
		for i in 6:
			var ang := _seed + i * 1.05
			var bt := fmod(t * 0.025 + i * 0.29, 1.0)
			var bp := Vector2(cos(ang), sin(ang)) * radius * (0.15 + 0.6 * fmod(i * 0.57, 1.0))
			var ba := 0.6 * (1.0 - bt) * a * (1.0 - 0.7 * cool)
			g.glow(bp, 5.0 + 7.0 * bt, Color(1.0, 0.75, 0.35, ba))
			g.ring(bp, 2.0 + 4.0 * bt, 1.0, Color(1.0, 0.88, 0.55, 0.45 * ba))
		g.draw_set_transform(Vector2.ZERO)
		return
	g.glow(Vector2.ZERO, radius * 1.3, Color(1.0, 0.4, 0.06, 0.7 * a * pulse))
	g.glow(Vector2.ZERO, radius * 0.55, Color(1.0, 0.75, 0.3, 0.55 * a * pulse))
	g.draw_set_transform(Vector2.ZERO)
	# Alev dilleri: sert üçgen değil, yumuşak uzatılmış fx_orb_w lekeleri; her biri ayrı titrer.
	for i in 3:
		var x := (i - 1) * radius * 0.55 + sin(_seed + i) * 3.0
		var h := (14.0 + 8.0 * sin(t * 0.5 + i * 2.1 + _seed)) * a
		var base := c + Vector2(x, 0)
		var lean := sin(t * 0.3 + i + _seed) * 0.12
		g.sprite("fx_orb_w", base + Vector2(0, -h * 0.4), Vector2(h * 1.3, 14.0), Color(1.0, 0.45, 0.08, 0.7 * a), -PI / 2 + lean)
		g.sprite("fx_orb_w", base + Vector2(0, -h * 0.25), Vector2(h * 0.7, 7.0), Color(1.0, 0.8, 0.45, 0.55 * a), -PI / 2 + lean)
		g.glow(base + Vector2(0, -3), 10.0, Color(1.0, 0.55, 0.15, 0.45 * a))


## Rün dairesinin altındaki yanık zemin (normal karışım); parlayan kısmı _paint_pillar'da.
func _draw_rune(c: Vector2) -> void:
	var k := clampf(float(t) / RUNE_TELL, 0.0, 1.0)
	var a := 1.0 if t < RUNE_TELL else 1.0 - float(t - RUNE_TELL) / PILLAR
	_soot(c, radius * 1.15, Color(0.06, 0.02, 0.01, (0.25 + 0.25 * k) * a))


## Rün dairesi (toplamalı): yumuşak haleli turuncu dış halka, içten dışa dolan parıltı ve dönen rün çentikleri (tell).
func _paint_rune(g: GlowLayer, c: Vector2) -> void:
	var k := clampf(float(t) / RUNE_TELL, 0.0, 1.0)
	var blink := 0.7 + 0.3 * sin(t * (0.3 + k * 0.6))
	var spin := t * 0.04 + _seed
	g.draw_set_transform(c, 0, Vector2(1, 0.42))
	g.glow(Vector2.ZERO, radius * 1.15, Color(1.0, 0.32, 0.05, 0.35 * blink))
	g.glow(Vector2.ZERO, radius * maxf(k, 0.05) * 1.1, Color(1.0, 0.6, 0.15, 0.4))
	g.ring(Vector2.ZERO, radius, 2.6, Color(1.0, 0.45, 0.08, 0.95 * blink))
	g.ring(Vector2.ZERO, radius * 0.72, 1.4, Color(1.0, 0.7, 0.25, 0.6))
	g.ring(Vector2.ZERO, radius * maxf(k, 0.02), 1.8, Color(1.0, 0.92, 0.5, 0.9))
	for i in 8:
		var ang := spin + i * TAU / 8.0
		var p0 := Vector2.from_angle(ang) * radius * 0.76
		var p1 := Vector2.from_angle(ang) * radius * 0.95
		g.streak(PackedVector2Array([p0, p1]), 2.0, Color(1.0, 0.8, 0.35, 0.85 * blink))
	# İçte üçgen rün.
	var tri := PackedVector2Array()
	for i in 4:
		tri.append(Vector2.from_angle(-spin * 1.5 + i * TAU / 3.0) * radius * 0.6)
	g.streak(tri, 1.4, Color(1.0, 0.65, 0.2, 0.7))
	g.draw_set_transform(Vector2.ZERO)


## Alev sütunu (toplamalı): daireden yükselen dalgalı alev dilleri, beyaz-sarı göbek ve tepede kıvılcımlar.
func _paint_pillar(g: GlowLayer) -> void:
	if delay > 0:
		return
	var c := Vector2(0, _sort_up())
	if t < RUNE_TELL:
		_paint_rune(g, c)
		return
	var u := float(t - RUNE_TELL) / PILLAR
	var a := clampf(1.0 - u, 0.0, 1.0)
	var h := 130.0 * sin(minf(1.0, u * 2.5) * PI * 0.5)
	var w := radius * (0.9 - 0.3 * u)
	g.draw_set_transform(c, 0, Vector2(1, 0.42))
	g.glow(Vector2.ZERO, radius * 1.4, Color(1.0, 0.45, 0.08, 0.9 * a))
	# Fışkırma anı: daire dışa açılan parlak halkaya döner.
	g.ring(Vector2.ZERO, radius * (1.0 + 0.25 * u), 2.6, Color(1.0, 0.85, 0.4, 0.9 * a))
	g.draw_set_transform(Vector2.ZERO)
	# Alev dilleri: meşale alevindeki yumuşak, uzatılmış fx_orb_w lekeleri; her biri ayrı titrer ve salınır.
	for j in 5:
		var fx := (j - 2) * w * 0.34 + sin(t * 0.6 + j * 1.7 + _seed) * 3.0
		var fh := h * (0.6 + 0.4 * absf(sin(t * 0.45 + j * 2.3 + _seed)))
		var fw := w * (0.75 if j % 2 == 0 else 0.6)
		var lean := sin(t * 0.35 + j) * 0.08
		g.sprite("fx_orb_w", c + Vector2(fx, -fh * 0.5), Vector2(fh, fw), Color(1.0, 0.42, 0.08, 0.75 * a), -PI / 2 + lean)
	g.sprite("fx_orb_w", c + Vector2(0, -h * 0.42), Vector2(h * 0.85, w * 0.7), Color(1.0, 0.82, 0.4, 0.8 * a), -PI / 2)
	g.sprite("fx_orb_w", c + Vector2(0, -h * 0.3), Vector2(h * 0.5, w * 0.35), Color(1.0, 0.97, 0.8, 0.8 * a), -PI / 2)
	for j in 8:
		var sy := fmod(u * 1.6 + j * 0.13, 1.0)
		g.glow(c + Vector2(sin(j * 2.1 + _seed) * w * 0.8, -h * (0.3 + 0.8 * sy)), 6.0, Color(1.0, 0.75, 0.3, 0.8 * a * (1.0 - sy)))
	g.glow(c + Vector2(0, -h * 0.5), h * 0.45 + 10.0, Color(1.0, 0.5, 0.12, 0.35 * a))


## Kül bulutu: üst üste binen, kenarı yumuşak gri-siyah duman yumakları büyür ve dağılır.
func _draw_ash(c: Vector2) -> void:
	var u := float(t) / life
	var a := _ash_alpha()
	var puff := Atmosphere.puff_texture()
	for i in 11:
		var ang := _seed + i * 0.7
		var off := Vector2(cos(ang), sin(ang) * 0.5) * radius * (0.25 + 0.5 * fmod(i * 0.37, 1.0)) * (0.6 + 0.6 * u)
		var r := radius * (0.6 + 0.3 * fmod(i * 0.53, 1.0)) * (0.7 + 0.5 * u)
		var shade := 0.12 + 0.1 * fmod(i * 0.41, 1.0)
		var at := c + off + Vector2(0, -radius * 0.5 - 20.0 * u)
		draw_texture_rect(puff, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(shade, shade * 0.95, shade * 0.9, 0.6 * a))


func _ash_alpha() -> float:
	return clampf(float(life - t) / 40.0, 0.0, 1.0) * clampf(float(t) / 6.0, 0.0, 1.0)


## Kül bulutundan savrulan közler (toplamalı, yumuşak).
func _paint_ash(g: GlowLayer) -> void:
	if delay > 0:
		return
	var c := Vector2(0, _sort_up())
	var u := float(t) / life
	var a := _ash_alpha()
	for i in 6:
		var ang := _seed * 2.0 + i * 1.1
		var sp := c + Vector2(cos(ang), -absf(sin(ang))) * radius * (0.4 + u)
		g.glow(sp, 6.0, Color(1.0, 0.5, 0.15, 0.7 * a))
		g.glow(sp, 2.5, Color(1.0, 0.85, 0.5, 0.8 * a))


## Yarığın açılmış kısmı (0..1): savuruş anında baltanın önünden ileri doğru yırtılır.
func _crack_open() -> float:
	return clampf(float(t) / CRACK_OPEN, 0.0, 1.0)


## Yarık noktalarının açılmış kısmı (son nokta ara değerle).
func _crack_pts() -> PackedVector2Array:
	var k := _crack_open() * (_pts.size() - 1)
	var out := PackedVector2Array()
	for i in _pts.size():
		if i <= k:
			out.append(_pts[i])
		else:
			out.append(_pts[i - 1].lerp(_pts[i], k - (i - 1)))
			break
	return out


## Yarığın zemindeki kısmı (normal karışım): yumuşak is lekeleri ve koyu, ortası kalın kırık çizgi.
func _draw_crack() -> void:
	var a := _fade(1, 50)
	var puff := Atmosphere.puff_texture()
	var pts := _crack_pts()
	if pts.size() < 2:
		return
	for i in range(0, pts.size(), 2):
		var r := 15.0 + 7.0 * sin(float(i) / _pts.size() * PI)
		draw_set_transform(pts[i], 0, Vector2(1, 0.5))
		draw_texture_rect(puff, Rect2(-r, -r, r * 2.0, r * 2.0), false, Color(0.06, 0.02, 0.01, 0.5 * a))
	draw_set_transform(Vector2.ZERO)
	for i in pts.size() - 1:
		var u := float(i) / (_pts.size() - 1)
		var w := 2.0 + 5.0 * sin(clampf(u, 0.05, 0.95) * PI)
		draw_line(pts[i], pts[i + 1], Color(0.05, 0.015, 0.01, 0.9 * a), w + 2.0, true)
	if _crack_open() >= 1.0:
		for br in _branches:
			draw_polyline(br, Color(0.05, 0.015, 0.01, 0.75 * a), 2.0, true)


## Yarığın parlayan kısmı (toplamalı): içinden akan lav çizgisi, sızan lav lekeleri, titreyen küçük alevler
## ve kıvılcımlar. Soğudukça kızıla döner ve söner. Faz 3'te beyaz-sarı yanar.
func _paint_crack(g: GlowLayer) -> void:
	var a := _fade(1, 50)
	var cool := clampf(float(t) / life, 0.0, 1.0)
	var pts := _crack_pts()
	if pts.size() < 2:
		return
	var hot := Color(1.0, 0.92, 0.6) if _hot else Color(1.0, 0.72, 0.28)
	var mid := Color(1.0, 0.75, 0.35) if _hot else Color(1.0, 0.42, 0.08)
	var flash := clampf(1.0 - float(t) / 14.0, 0.0, 1.0)
	var heat := a * (1.0 - 0.55 * cool)
	# Geniş yumuşak kor halesi, üstünde erimiş çizgi ve beyaza yakın ince göbek.
	for i in range(0, pts.size(), 2):
		g.glow(pts[i], 16.0, Color(mid, 0.28 * heat))
	g.streak(pts, 7.0, Color(mid, 0.7 * heat))
	g.streak(pts, 3.0, Color(hot, (0.7 + 0.3 * flash) * heat))
	if _crack_open() >= 1.0:
		for br in _branches:
			g.streak(br, 1.4, Color(mid, 0.6 * heat))
	# Açılış anı: yarık boyunca beyaz parlama.
	if flash > 0.0:
		for i in range(0, pts.size(), 2):
			g.glow(pts[i], 22.0, Color(1.0, 0.85, 0.55, 0.5 * flash))
	# Sızan lav: yarığın birkaç noktasında büyüyüp nabız gibi atan yumuşak lekeler.
	var grow := clampf(float(t - CRACK_OPEN) / 40.0, 0.0, 1.0)
	for i in 5:
		var u := 0.12 + 0.19 * i + 0.04 * sin(_seed + i)
		if u > _crack_open():
			continue
		var p := _pts[0].lerp(_pts[_pts.size() - 1], u)
		var pulse := 0.8 + 0.2 * sin(t * 0.12 + i * 1.7 + _seed)
		var r := (8.0 + 9.0 * grow * fmod(i * 0.61 + 0.4, 1.0)) * pulse
		g.draw_set_transform(p, 0, Vector2(1, 0.5))
		g.glow(Vector2.ZERO, r * 2.0, Color(mid, 0.75 * heat))
		g.glow(Vector2.ZERO, r * 1.0, Color(hot, 0.7 * heat * (1.0 - cool)))
		g.draw_set_transform(Vector2.ZERO)
	# Küçük alev dilleri ve yükselen kıvılcımlar.
	for i in 4:
		var u := 0.2 + 0.2 * i
		if u > _crack_open():
			continue
		var p := _pts[0].lerp(_pts[_pts.size() - 1], u)
		var h := (10.0 + 7.0 * sin(t * 0.45 + i * 2.3 + _seed)) * heat
		g.sprite("fx_orb_w", p + Vector2(0, -h * 0.45), Vector2(h * 1.3, 9.0), Color(mid, 0.65 * heat), -PI / 2 + sin(t * 0.3 + i) * 0.12)
		var sy := fmod(t * 0.02 + i * 0.27, 1.0)
		g.glow(p + Vector2(sin(i * 2.1 + _seed + t * 0.05) * 6.0, -8.0 - 34.0 * sy), 3.5, Color(hot, 0.8 * heat * (1.0 - sy)))
