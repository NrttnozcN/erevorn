class_name DeathCinematic
extends CanvasLayer
## Boss ölüm sinematiği: son vuruşta dünya ağır çekime girer, sinema bantları iner, kamera bossa yaklaşır; beyaz
## parlamayla ekran bossun boyalı ölüm tablosuna geçer (yavaş yakınlaşma, kıvılcımlar, ad ve son söz), sonra karartıp
## oyuna döner. Dünya bu sürede donar (main.state = "cinematic"); bitince `done` çağrılır. Bir tuşla atlanabilir.
## Tablolar: assets/cine/cine_<anahtar>.jpg (konsept/oyun/sinematik/ altında üretim promptları).

## Testler ve ekran görüntüsü araçları kapatır.
static var enabled := true

const SLOW := 1.1          # ağır çekim + bantlar, sonunda beyaz parlama
const PAINT := 6.4         # tablo ekranda
const OUT := 0.7           # kararış
const SKIP_AFTER := 1.8    # bu saniyeden sonra tuş tablo kısmını geçer

## Bossun ölüm tablosu, adının altındaki son söz ve kıvılcım rengi.
const INFO := {
	"z1": ["Bin yıllık nöbet bitti.", Color(0.7, 0.82, 1.0)],
	"z2": ["Kitaplar küle, gölgeler ışığa döndü.", Color(0.8, 0.65, 1.0)],
	"z3": ["Zincirler kırıldı. Esirler özgür.", Color(1.0, 0.6, 0.25)],
	"z4": ["Son kıvılcımında Kalp'in adını fısıldadı.", Color(1.0, 0.45, 0.15)],
	"z5": ["Buz eridi. Han huzura kavuştu.", Color(0.85, 0.95, 1.0)],
	"z6": ["Dikenler kurudu. Lyra özgür.", Color(1.0, 0.85, 0.45)],
	"z7": ["Kapının ötesi onu geri aldı.", Color(0.75, 0.35, 1.0)],
	"z8": ["Maske kırıldı. Usta, öğrencisinin kanını tanıdı.", Color(1.0, 0.85, 0.45)],
	"z9": ["Yırtık kapandı.", Color(0.4, 0.9, 1.0)],
	"z10": ["Bekçi arındı. Kurt uyuyor.", Color(1.0, 0.75, 0.45)],
	"karun": ["Sonsuzluğun Efendisi diz çöktü.", Color(1.0, 0.55, 0.3)],
}

var main: Main
var key := ""
var title := ""
var focus := Vector2.ZERO
var done: Callable

var t := 0.0
var _painted := false
var _ended := false
var _root: Control
var _top: ColorRect
var _bottom: ColorRect
var _paint: TextureRect
var _flash: ColorRect
var _shade: TextureRect
var _paint_base := Vector2.ZERO
var _title: Label
var _line: Label
var _sparks: CPUParticles2D


## Bossun tablo anahtarı; tablo yoksa "".
static func key_for(b: Boss, zone: int) -> String:
	var k := "karun" if b.is_karun else "z%d" % zone
	return k if ResourceLoader.exists("res://assets/cine/cine_%s.jpg" % k) else ""


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_paint = TextureRect.new()
	_paint.texture = load("res://assets/cine/cine_%s.jpg" % key)
	_paint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paint.stretch_mode = TextureRect.STRETCH_SCALE
	_paint.visible = false
	_root.add_child(_paint)
	var c: Color = INFO[key][1]
	_sparks = CPUParticles2D.new()
	_sparks.material = GlowLayer.additive()
	_sparks.amount = 70
	_sparks.lifetime = 4.0
	_sparks.preprocess = 2.0
	_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparks.direction = Vector2(0.2, -1)
	_sparks.spread = 25
	_sparks.gravity = Vector2(6, -14)
	_sparks.initial_velocity_min = 12
	_sparks.initial_velocity_max = 40
	_sparks.scale_amount_min = 1.5
	_sparks.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(c, 0.0))
	ramp.set_color(1, Color(c, 0.0))
	ramp.add_point(0.25, Color(c, 0.9))
	_sparks.color_ramp = ramp
	_sparks.emitting = false
	_root.add_child(_sparks)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.82))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	_shade = TextureRect.new()
	_shade.texture = gt
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.visible = false
	_root.add_child(_shade)
	_top = _bar()
	_bottom = _bar()
	_title = _label(56, Color(1, 0.96, 0.88))
	_line = _label(24, c.lerp(Color.WHITE, 0.55))
	_title.text = title
	_line.text = INFO[key][0]
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 0.97, 0.9, 0)
	_root.add_child(_flash)
	_layout()


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(r)
	return r


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.modulate.a = 0.0
	_root.add_child(l)
	return l


func _layout() -> void:
	var vs := _root.get_viewport_rect().size
	var bh := vs.y * 0.12
	var into := clampf(t / 0.45, 0.0, 1.0)
	var out := clampf((t - SLOW - PAINT - OUT) / 0.5, 0.0, 1.0)
	var k := ease(into, 0.4) * (1.0 - ease(out, 2.0))
	_top.position = Vector2(0, -bh + bh * k)
	_top.size = Vector2(vs.x, bh)
	_bottom.position = Vector2(0, vs.y - bh * k)
	_bottom.size = Vector2(vs.x, bh)
	# Tablo tam ekran; bantlar yalnızca ağır çekimde ve dönüşte. Yazı alttaki koyu geçişin üstünde.
	_top.visible = not _paint.visible
	_bottom.visible = not _paint.visible
	_shade.position = Vector2(0, vs.y * 0.62)
	_shade.size = Vector2(vs.x, vs.y * 0.38)
	_title.position = Vector2(0, vs.y - 150)
	_title.size = Vector2(vs.x, 70)
	_line.position = Vector2(0, vs.y - 74)
	_line.size = Vector2(vs.x, 34)
	_sparks.position = Vector2(vs.x * 0.5, vs.y * 0.95)
	_sparks.emission_rect_extents = Vector2(vs.x * 0.55, 10)
	# Tabloyu ekranı kaplayacak boyda ölçekle; taşan kısmın çoğunu alttan kırp (yüzler üst yarıda).
	var tex_size := _paint.texture.get_size() if _paint.texture else Vector2(1536, 1024)
	var cover := maxf(vs.x / tex_size.x, vs.y / tex_size.y)
	_paint.size = tex_size * cover
	_paint_base = Vector2((vs.x - _paint.size.x) * 0.5, (vs.y - _paint.size.y) * 0.3)
	_paint.pivot_offset = Vector2(_paint.size.x * 0.5, _paint.size.y * 0.35)


func _input(event: InputEvent) -> void:
	if _ended or t < SKIP_AFTER or t >= SLOW + PAINT:
		return
	var press: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if press:
		t = SLOW + PAINT
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _ended:
		return
	t += delta
	_layout()
	var vs := _root.get_viewport_rect().size
	# 1) Ağır çekim: kamera bossa yaklaşır, sonunda beyaz parlama.
	if t < SLOW:
		var s := t / SLOW
		main.cine_focus = focus
		main.cine_zoom = 0.35 * ease(s, 0.5)
		_flash.color.a = clampf((s - 0.75) / 0.25, 0.0, 1.0)
	elif not _painted:
		_painted = true
		main.cine_slow = false
		_paint.visible = true
		_shade.visible = true
		_sparks.emitting = true
	# 2) Tablo: beyazdan açılır, yavaşça yakınlaşıp kayar; ad ve son söz belirir.
	if _painted:
		var p := clampf((t - SLOW) / PAINT, 0.0, 1.0)
		_flash.color = Color(1, 0.97, 0.9, 1.0 - clampf((t - SLOW) / 0.6, 0.0, 1.0))
		# Yavaş geri çekilme (1.09 -> 1.0) ve hafif yatay kayma; üst kenara yaslı ki yüzler kesilmesin.
		var sc := lerpf(1.09, 1.0, ease(p, 0.6))
		_paint.scale = Vector2(sc, sc)
		_paint.position = _paint_base + Vector2(lerpf(-vs.x * 0.012, vs.x * 0.012, p), 0)
		_title.modulate.a = clampf((t - SLOW - 0.7) / 0.8, 0.0, 1.0)
		_line.modulate.a = clampf((t - SLOW - 1.5) / 0.9, 0.0, 1.0)
		# 3) Kararış: tablo siyaha, sonra dünya siyahtan açılır.
		var dark := clampf((t - SLOW - PAINT) / OUT, 0.0, 1.0)
		if dark > 0.0:
			_flash.color = Color(0, 0, 0, dark)
			_title.modulate.a = 1.0 - dark
			_line.modulate.a = 1.0 - dark
		if dark >= 1.0 and _paint.visible:
			_paint.visible = false
			_shade.visible = false
			_sparks.emitting = false
			main.cine_zoom = 0.0
			main.end_cinematic()
		if not _paint.visible:
			_flash.color.a = 1.0 - clampf((t - SLOW - PAINT - OUT) / 0.5, 0.0, 1.0)
	if t >= SLOW + PAINT + OUT + 0.55:
		_ended = true
		if done.is_valid():
			done.call()
		queue_free()
