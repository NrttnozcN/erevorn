class_name GlowLayer
extends Node2D
## Toplamalı (additive), karanlıktan etkilenmeyen çizim katmanı: alevler, parıltılar, nadirlik haleleri.
## painter her karede bu düğümün üstüne çizer: func(layer: GlowLayer) -> void

static var _add_mat: CanvasItemMaterial

var painter: Callable


static func additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _add_mat


static func make(fn: Callable, behind := false) -> GlowLayer:
	var g := GlowLayer.new()
	g.painter = fn
	g.material = additive()
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	g.show_behind_parent = behind
	return g


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)


## Yumuşak ışık lekesi (merkez parlak, kenar şeffaf).
func glow(at: Vector2, radius: float, c: Color) -> void:
	draw_texture_rect(Atmosphere.soft_texture(), Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2), false, c)


## Boyalı fx sprite'ı (fx_*): merkez at, boyut s, açı a.
func sprite(key: String, at: Vector2, s: Vector2, c: Color, a := 0.0) -> void:
	var t := Sprites.tex(key)
	if t == null:
		return
	draw_set_transform(at, a, Vector2.ONE)
	draw_texture_rect(t, Rect2(-s / 2, s), false, c)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Yumuşak kenarlı, parlayan halka: geniş soluk hale + ince parlak çizgi (kenar yumuşatmalı, sert piksel halka değil).
func ring(at: Vector2, radius: float, width: float, c: Color, from := 0.0, to := TAU) -> void:
	var n := clampi(int(radius * absf(to - from) / 6.0), 24, 128)
	draw_arc(at, radius, from, to, n, Color(c, c.a * 0.16), width * 4.0, true)
	draw_arc(at, radius, from, to, n, Color(c, c.a * 0.32), width * 2.0, true)
	draw_arc(at, radius, from, to, n, c, width, true)


## Yumuşak parlayan çizgi (çatlak, rün çizgisi): hale + ince çekirdek, kenar yumuşatmalı.
func streak(pts: PackedVector2Array, width: float, c: Color) -> void:
	draw_polyline(pts, Color(c, c.a * 0.18), width * 4.0, true)
	draw_polyline(pts, Color(c, c.a * 0.38), width * 2.0, true)
	draw_polyline(pts, c, width, true)
