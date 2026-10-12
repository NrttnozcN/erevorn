class_name Fx
extends Node2D
## Uçan hasar yazıları, patlama halkaları, atılma izleri ve kesik efektleri.

const FONT := preload("res://assets/fonts/Cinzel-Bold.ttf")

var main: Main
var texts: Array = []
var bursts: Array = []
var ghosts: Array = []
var slashes: Array = []
var sprites: Array = []


func _ready() -> void:
	# Proje varsayılanı piksel (nearest) süzme; 256 px'lik fx_* sprite'ları küçültülünce kumlanmasın.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Patlama halkaları toplamalı ayrı katmanda: yumuşak haleli parlayan halka, sert piksel çember değil.
	add_child(GlowLayer.make(_paint_bursts))


## Boyalı efekt: büyüyerek söner (fx_* sprite'ları).
func add_sprite(pos: Vector2, key: String, size: float, color := Color.WHITE, life := 18, grow := 0.3, angle := 0.0) -> void:
	if Sprites.tex(key) == null:
		return
	sprites.append({"pos": pos, "key": key, "size": size, "color": color, "life": life, "max": life, "grow": grow, "angle": angle})


func add_text(pos: Vector2, text: String, color: Color) -> void:
	texts.append({"pos": pos + Vector2(randf_range(-8, 8), 0), "text": text, "color": color, "life": 50})


func add_burst(pos: Vector2, radius: float, color: Color) -> void:
	bursts.append({"pos": pos, "r": radius, "color": color, "life": 20})


func add_slash(from: Vector2, to: Vector2) -> void:
	slashes.append({"a": from, "b": to, "life": 14})


func add_afterimage(p: Player) -> void:
	ghosts.append({"pos": p.position, "key": "%s_walk1" % p.style, "flip": p.facing_left,
		"size": 48.0 * ClassData.STYLES[p.style].draw_scale, "life": 14})


func tick() -> void:
	for list in [texts, bursts, ghosts, slashes, sprites]:
		for item in list:
			item.life -= 1
	for t in texts:
		t.pos.y -= 0.35 + 1.2 * t.life / 50.0
	texts = texts.filter(func(t): return t.life > 0)
	bursts = bursts.filter(func(b): return b.life > 0)
	ghosts = ghosts.filter(func(g): return g.life > 0)
	slashes = slashes.filter(func(s): return s.life > 0)
	sprites = sprites.filter(func(s): return s.life > 0)
	queue_redraw()


func _draw() -> void:
	for sp in sprites:
		var k: float = 1.0 - float(sp.life) / sp.max
		var c: Color = sp.color
		c.a *= pow(1.0 - k, 0.7)
		var s: float = sp.size * (1.0 + sp.grow * k)
		draw_set_transform(sp.pos, sp.angle, Vector2.ONE)
		Sprites.draw_flat(self, sp.key, Rect2(-s / 2, -s / 2, s, s), c)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for g in ghosts:
		var s: float = g.size
		Sprites.draw_actor(self, g.key, Rect2(g.pos.x - s / 2, g.pos.y - s / 2, s, s), g.flip, false, false,
			Color(0.3, 0.8, 1.0, g.life / 28.0))
	for b in bursts:
		# Koyu (duman / kül) patlamalar toplamalı katmanda görünmez: yumuşak koyu leke olarak burada çizilir.
		var c: Color = b.color
		if c.get_luminance() < 0.45:
			var k: float = 1.0 - b.life / 20.0
			var r: float = b.r * (0.5 + 0.7 * k)
			draw_texture_rect(Atmosphere.puff_texture(), Rect2(b.pos - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(c, 0.45 * (1.0 - k)))
	for s in slashes:
		var a: float = s.life / 14.0
		draw_line(s.a, s.b, Color(0.3, 0.9, 1.0, a * 0.25), 22 * a + 2, true)
		draw_line(s.a, s.b, Color(0.3, 0.9, 1.0, a * 0.6), 12 * a + 1, true)
		draw_line(s.a, s.b, Color(0.85, 0.97, 1.0, a), 4 * a + 1, true)
	for t in texts:
		var c: Color = t.color
		c.a = clampf(t.life / 25.0, 0, 1)
		# Önce büyük çıkıp oturan, yumuşak parlamalı boyalı yazı.
		var age: float = 50 - t.life
		var pop: float = 1.0 + 0.45 * maxf(0.0, 1.0 - age / 7.0)
		var fs: int = 22 if t.text.ends_with("!") else 19
		var w := FONT.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_set_transform(t.pos, 0, Vector2(pop, pop))
		var at := Vector2(-w / 2, 0)
		var glow := Color(c.r, c.g, c.b, c.a * 0.28)
		draw_string_outline(FONT, at, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 9, glow)
		draw_string_outline(FONT, at, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.06, 0.03, 0.02, c.a * 0.9))
		draw_string(FONT, at, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c.lerp(Color.WHITE, 0.15))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Patlama halkası (toplamalı): içten yumuşak parıltı, dışa açılan haleli halka.
func _paint_bursts(g: GlowLayer) -> void:
	for b in bursts:
		var k: float = 1.0 - b.life / 20.0
		var c: Color = b.color
		var a := pow(1.0 - k, 1.3)
		var r: float = b.r * (0.4 + 0.6 * k)
		g.glow(b.pos, r * 1.1, Color(c, 0.55 * a))
		g.ring(b.pos, r, 2.5, Color(c.lerp(Color.WHITE, 0.25), 0.8 * a))
