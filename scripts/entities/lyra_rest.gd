class_name LyraRest
extends Actor
## Lyra'nın ölümü (bölge 6): dikenler kurur ve dökülür (çözülme karesi), sonra Hayat Ağacı'nın dibinde gerçek Lyra
## huzurla uzanır. Ardından Sera'nın ruhu Arktan'a bağlanır: soluk altın-beyaz bir ışık Lyra'dan Arktan'a akar.
## Kareler Boss ile aynı 420x470 tuvalde ve aynı çapada. İlerde her boss için kısa ölüm sinematikleri gelecek;
## bu oyun içi kısa geçiştir.

const BREAK_IN := 30
const BREAK_HOLD := 110
const CROSS := 70
const BOND_DELAY := 40
const BOND_FLY := 90
const HOLY := Color(1.0, 0.92, 0.66)

var died_at := Vector2.ZERO
var empty_tree: Sprite2D
var t := 0
var _light: PointLight2D
var _thorns: CPUParticles2D
var _orb := Vector2.ZERO
var _bond_done := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = 1.6
	_light.color = HOLY
	_light.energy = 0.0
	_light.position = Vector2(0, -60)
	add_child(_light)
	# Kuruyup dökülen diken ve yaprak kırıntıları (yumuşak, yuvarlak; toplamalı değil, karanlıkta koyu).
	_thorns = CPUParticles2D.new()
	_thorns.amount = 26
	_thorns.lifetime = 1.6
	_thorns.randomness = 0.6
	_thorns.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_thorns.emission_rect_extents = Vector2(55, 70)
	_thorns.position = Vector2(0, -110)
	_thorns.direction = Vector2(0, 1)
	_thorns.spread = 40
	_thorns.gravity = Vector2(0, 70)
	_thorns.initial_velocity_min = 4
	_thorns.initial_velocity_max = 16
	Atmosphere.soften_sparks(_thorns, 5.0, 9.0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.55, 0.35, 0.7, 0.0))
	ramp.set_color(1, Color(0.35, 0.3, 0.28, 0.0))
	ramp.add_point(0.2, Color(0.55, 0.35, 0.7, 0.9))
	_thorns.color_ramp = ramp
	add_child(_thorns)
	add_child(GlowLayer.make(_paint))


func tick() -> void:
	t += 1
	if t == BREAK_IN + BREAK_HOLD:
		_thorns.emitting = false
	if empty_tree:
		empty_tree.modulate.a = 1.0 - clampf(float(t) / BREAK_IN, 0.0, 1.0)
	var peace := clampf(float(t - BREAK_IN - BREAK_HOLD) / CROSS, 0.0, 1.0)
	_light.energy = 0.55 * peace
	var start := BREAK_IN + BREAK_HOLD + CROSS + BOND_DELAY
	if t == start:
		main.float_text(position + Vector2(0, -150), "Lyra huzura kavuştu", HOLY)
	if t >= start and not _bond_done:
		# Sera'nın ruhu: Lyra'dan Arktan'a süzülen ışık.
		var u := clampf(float(t - start) / BOND_FLY, 0.0, 1.0)
		var from := position + Vector2(0, -60)
		var to := main.player.position + Vector2(0, -30)
		_orb = from.lerp(to, u * u * (3.0 - 2.0 * u)) + Vector2(0, -sin(u * PI) * 70.0)
		if u >= 1.0:
			_bond_done = true
			Game.sera_bound = true
			main.burst(to, 60, HOLY)
			main.float_text(to + Vector2(0, -50), "Sera'nın ruhu sana bağlandı", HOLY.lightened(0.15))
			Log.add("Sera'nın ruhu Arktan'a bağlandı.", "loot")
	queue_redraw()


func _draw() -> void:
	var s := Boss.LY_SCALE
	var b := Rect2(-Boss.LY_ANCHOR * s, Boss.LY_CANVAS * s)
	var brk := Sprites.tex("boss_z6_death")
	var peace_t := Sprites.tex("boss_z6_peace")
	var into := clampf(float(t) / BREAK_IN, 0.0, 1.0)
	var peace := clampf(float(t - BREAK_IN - BREAK_HOLD) / CROSS, 0.0, 1.0)
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-96, -96, 192, 192), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	if peace_t and peace > 0.0:
		draw_texture_rect(peace_t, b, false, Color(1, 1, 1, peace))
	if brk and peace < 1.0:
		var shake := Vector2(sin(t * 1.7), 0) * (1.0 - peace) * (1.0 if t < BREAK_IN + BREAK_HOLD else 0.0)
		draw_texture_rect(brk, Rect2(b.position + shake, b.size), false, Color(1, 1, 1, into * (1.0 - peace)))


## Sera'nın ruh ışığı: altın-beyaz göbek ve arkasında sönen iz.
func _paint(g: GlowLayer) -> void:
	var start := BREAK_IN + BREAK_HOLD + CROSS + BOND_DELAY
	if t < start or _bond_done:
		if t < BREAK_IN + BREAK_HOLD:
			var k := clampf(float(t) / BREAK_IN, 0.0, 1.0)
			# Kırılan mühürden sönen mor kıvılcımlar.
			g.glow(Vector2(12, -150), 14.0 * (1.0 - float(t) / (BREAK_IN + BREAK_HOLD)) + 2.0, Color(0.72, 0.32, 1.0, 0.5 * k))
		return
	var at := _orb - position
	var pulse := 0.85 + 0.15 * sin(t * 0.3)
	g.glow(at, 28.0 * pulse, Color(HOLY, 0.45))
	g.glow(at, 9.0, Color(1.0, 1.0, 0.92, 0.9))
	for i in 5:
		var back := at + Vector2(sin(t * 0.2 + i) * 4.0, 8.0 + i * 9.0)
		g.glow(back, 10.0 - i * 1.5, Color(HOLY, 0.25 - i * 0.04))
