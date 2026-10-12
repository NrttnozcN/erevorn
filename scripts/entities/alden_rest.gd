class_name AldenRest
extends Actor
## Kral Alden'ın ölümü (bölge 5): düştüğü yerde buz kırıntıları erir; tahtta buz kabuk çatlayıp dökülür
## (erime karesi, kırık mor mühür), sonra tahtta yalnızca huzura kavuşmuş yaşlı kral kalır, yüzüne ılık ışık vurur.
## Kareler Boss ile aynı 420x470 tuvalde ve aynı çapada (taht tabanının ortası düğümde).
## İlerde her boss için kısa ölüm sinematikleri gelecek; bu oyun içi kısa geçiştir.

const MELT_IN := 30
const MELT_HOLD := 110
const CROSS := 70
const WARM := Color(1.0, 0.78, 0.5)

var died_at := Vector2.ZERO
var empty_throne: Sprite2D
var t := 0
var _light: PointLight2D
var _ice: CPUParticles2D
var _seal: CPUParticles2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = 1.6
	_light.color = WARM
	_light.energy = 0.0
	_light.position = Vector2(0, -120)
	add_child(_light)
	# Erirken bedenden dökülen buz kırıntıları ve damlalar; göğüsten sönen mor mühür parçaları (yumuşak, yuvarlak).
	_ice = _emitter(Vector2(0, -95), Vector2(48, 60), 26, Color(0.8, 0.94, 1.0), Vector2(0, 60), 5.0, 10.0)
	_seal = _emitter(Vector2(10, -105), Vector2(10, 10), 8, Color(0.75, 0.35, 1.0), Vector2(0, -10), 4.0, 8.0)
	if died_at != Vector2.ZERO and died_at.distance_to(position) > 40.0:
		var hz := FrostHazard.new()
		hz.setup("icicle", died_at + Vector2(0, 6), 30.0, 0)
		hz.t = hz.life - 60
		main._spawn(hz, hz.position)


func tick() -> void:
	t += 1
	if t == MELT_IN + MELT_HOLD:
		_ice.emitting = false
		_seal.emitting = false
	if t == MELT_IN + MELT_HOLD:
		main.float_text(position + Vector2(0, -200), "Donmuş Han huzura kavuştu", Color(1.0, 0.88, 0.7))
	if empty_throne:
		empty_throne.modulate.a = 1.0 - clampf(float(t) / MELT_IN, 0.0, 1.0)
	var peace := clampf(float(t - MELT_IN - MELT_HOLD) / CROSS, 0.0, 1.0)
	_light.energy = 0.55 * peace
	queue_redraw()


func _emitter(at: Vector2, extents: Vector2, n: int, c: Color, grav: Vector2, s0: float, s1: float) -> CPUParticles2D:
	var em := CPUParticles2D.new()
	em.material = GlowLayer.additive()
	em.amount = n
	em.lifetime = 1.4
	em.randomness = 0.6
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = extents
	em.position = at
	em.direction = Vector2(0, 1)
	em.spread = 40
	em.gravity = grav
	em.initial_velocity_min = 4
	em.initial_velocity_max = 16
	Atmosphere.soften_sparks(em, s0, s1)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(c, 0.0))
	ramp.set_color(1, Color(c, 0.0))
	ramp.add_point(0.2, Color(c, 0.8))
	em.color_ramp = ramp
	add_child(em)
	return em


func _draw() -> void:
	var s := Boss.AL_SCALE
	var b := Rect2(-Boss.AL_ANCHOR * s, Boss.AL_CANVAS * s)
	var melt := Sprites.tex("boss_z5_melt")
	var peace_t := Sprites.tex("boss_z5_peace")
	var into := clampf(float(t) / MELT_IN, 0.0, 1.0)
	var peace := clampf(float(t - MELT_IN - MELT_HOLD) / CROSS, 0.0, 1.0)
	# Taht altında gölge.
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-92, -92, 184, 184), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	if peace_t and peace > 0.0:
		draw_texture_rect(peace_t, b, false, Color(1, 1, 1, peace))
	if melt and peace < 1.0:
		# Erirken hafif titrer, sonra huzur karesine yavaşça karışır.
		var shake := Vector2(sin(t * 1.7), 0) * (1.0 - peace) * (1.2 if t < MELT_IN + MELT_HOLD else 0.0)
		draw_texture_rect(melt, Rect2(b.position + shake, b.size), false, Color(1, 1, 1, into * (1.0 - peace)))
