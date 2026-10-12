extends Node
## Eski oyunun SpriteEngine'inden birebir dışa aktarılmış kareler: res://assets/sprites/<anahtar>.png
## draw_actor(), eski oyundaki nefes alma / yürüme sallantısı / saldırı hamlesi efektlerini uygular
## (sprites.js:1929-1991).

var _cache := {}


func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := "res://assets/sprites/%s.png" % key
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = t
	return t


## Karedeki görünür piksellerin alt kenarı (0..1, kare yüksekliğine oranla). Gölge / hale yerleşimi için.
func content_bottom(key: String) -> float:
	return _content(key).y


## Ayakların yatay merkezi, kutu merkezine göre (-0.5..0.5). Gölgeyi ayağa oturtmak için.
func content_feet_x(key: String) -> float:
	var ck := key + "#feet"
	if _cache.has(ck):
		return _cache[ck]
	var t := tex(key)
	var v := 0.0
	if t:
		var img := t.get_image()
		var used := img.get_used_rect()
		var y0 := used.end.y - maxi(1, int(used.size.y * 0.08))
		var sum := 0.0
		var n := 0
		for y in range(y0, used.end.y):
			for x in range(used.position.x, used.end.x):
				if img.get_pixel(x, y).a > 0.15:
					sum += x
					n += 1
		if n > 0:
			v = (sum / n) / img.get_width() - 0.5
	_cache[ck] = v
	return v


## Görünür piksellerin üst kenarı (0..1).
func content_top(key: String) -> float:
	return _content(key).x


func _content(key: String) -> Vector2:
	var ck := key + "#content"
	if _cache.has(ck):
		return _cache[ck]
	var t := tex(key)
	var v := Vector2(0, 1)
	if t:
		var img := t.get_image()
		var used := img.get_used_rect()
		v = Vector2(float(used.position.y) / img.get_height(), float(used.end.y) / img.get_height())
	_cache[ck] = v
	return v


## Dokuyu kutuya oranını bozmadan yerleştirir: yükseklik kutu yüksekliği, genişlik doku oranından;
## yatayda ortalı, alt kenar (ayak) kutunun altında. Doku yoksa kutunun kendisi döner.
func fit_box(key: String, box: Rect2) -> Rect2:
	var t := tex(key)
	if t == null or t.get_height() == 0:
		return box
	var w := box.size.y * t.get_width() / t.get_height()
	return Rect2(box.get_center().x - w / 2.0, box.position.y, w, box.size.y)


## box: çizim kutusu (dünya koordinatı, CanvasItem'ın yerel uzayında). Sprite kutuya gerilir,
## eski oyunda olduğu gibi.
func draw_actor(ci: CanvasItem, key: String, box: Rect2, flip: bool, moving: bool, attacking: bool,
		modulate := Color.WHITE, multi := true) -> void:
	var t := tex(key)
	if t == null:
		return
	var now := Time.get_ticks_msec()
	var base := Vector2(box.get_center().x, box.end.y)
	var rot := 0.0
	var w := box.size.x
	var h := box.size.y
	var lift := 0.0
	if attacking:
		base.x += -8.0 if flip else 8.0
		rot = -0.12 if flip else 0.12
	elif moving:
		# Adım başına bir sekme: ayak yere basınca çöker, geçişte yükselir.
		var wt := now / 133.0
		lift = absf(sin(wt)) * (5.0 if multi else 7.0)
		var step := cos(wt * 2.0)
		h *= 1.0 + step * (0.03 if multi else 0.05)
		w *= 1.0 - step * (0.015 if multi else 0.025)
		rot = sin(wt) * (0.045 if multi else 0.12)
		base.x += (-3.0 if flip else 3.0)
	else:
		var bt := sin(now / 250.0)
		h *= 1.0 + bt * 0.025
		w *= 1.0 - bt * 0.01
	ci.draw_set_transform(base, rot, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect(t, Rect2(-w / 2.0, -h - lift, w, h), false, modulate)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Piksel sprite (karo, eşya, sandık): yumuşatmasız, kutuya gerilmiş.
## Boyalı nesne çizimi: görünür kısmın yüksekliği h olur, alt kenarı foot_y'ye oturur.
## Doku yoksa false döner (çağıran eski çizime düşer).
func draw_grounded(ci: CanvasItem, key: String, h: float, foot_y: float, modulate := Color.WHITE) -> bool:
	var t := tex(key)
	if t == null:
		return false
	var top := content_top(key)
	var bot := content_bottom(key)
	var full_h := h / maxf(bot - top, 0.05)
	var w := full_h * t.get_width() / t.get_height()
	ci.draw_texture_rect(t, Rect2(-w / 2.0, foot_y - full_h * bot, w, full_h), false, modulate)
	return true


func draw_flat(ci: CanvasItem, key: String, box: Rect2, modulate := Color.WHITE) -> void:
	var t := tex(key)
	if t:
		ci.draw_texture_rect(t, box, false, modulate)
