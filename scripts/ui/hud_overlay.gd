class_name HudOverlay
extends Control
## Ekran üstüne çizilen parçalar: görev kutusu, mini harita, "PORTAL AÇILDI" yazısı,
## bildirimler, ilk oyun ipuçları, konuşma kutusu ve kırmızı can uyarısı (game.js:2105-2675).

const TUTORIAL := [
	["WASD veya Ok Tuşları ile hareket et", ""],
	["Sol Tık ile saldır", "Düşmana yönelik tıkla!"],
	["Q ve R: dövüş tarzının yetenekleri", "Boşluk: atılma"],
	["[E] ile sandık ve portal aç", "Tüm düşmanları yen → Portal açılır"],
	["İyi oyunlar! Sera seni izliyor...", ""],
]

var hud: Hud


func _draw() -> void:
	var main := hud.main
	if main.player == null or main.state == "start":
		return
	var vs := size
	var x0 := 10.0
	var y0 := Hud.TOP_H + 8.0
	if hud.compact:
		var c := Vector2(vs.x - 86, Hud.TOP_H + 94)
		_draw_round_map(c, 70.0)
		_draw_quest_line(Vector2(vs.x - 16, c.y + 92))
	else:
		_draw_quest(Vector2(x0, y0))
		_draw_minimap(Rect2(x0, y0 + 64, 250, 170))
	if main.portal and main.portal.active and Game.floor_number < 100:
		if (Time.get_ticks_msec() / 500) % 2 == 0:
			_center_text("PORTAL AÇILDI! ÇIKIŞ YOLUNU BUL", Vector2(vs.x / 2, Hud.TOP_H + 64), 10, UiKit.GREEN)
	var ty := vs.y - Hud.BOTTOM_H - 40
	for t in hud._toasts:
		var a := clampf(t[1] / 30.0, 0, 1)
		var w := UiKit.PIXEL.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 30
		var r := Rect2(vs.x / 2 - w / 2, ty, w, 28)
		draw_rect(r, Color(0.05, 0.05, 0.08, 0.92 * a))
		draw_rect(r, Color(1, 0.84, 0, 0.6 * a), false, 1)
		_center_text(t[0], Vector2(vs.x / 2, ty + 18), 9, Color(1, 0.84, 0, a))
		ty -= 34
	if main.tutorial_step >= 0 and main.state == "playing":
		var h: Array = TUTORIAL[main.tutorial_step]
		var r := Rect2(vs.x / 2 - 260, vs.y - Hud.BOTTOM_H - 110, 520, 54)
		draw_rect(r, Color(0, 0.06, 0.1, 0.9))
		draw_rect(r, Color(0, 0.94, 1, 0.5), false, 1)
		_center_text(h[0], Vector2(vs.x / 2, r.position.y + 24), 10, UiKit.CYAN)
		if h[1] != "":
			_center_text(h[1], Vector2(vs.x / 2, r.position.y + 42), 7, UiKit.TEXT_DIM)
	_draw_dialogue()
	var p := main.player
	if p.execution_flash > 0:
		_vignette(Color(1, 0, 0, p.execution_flash / 22.0 * 0.5))
	if p.hp < p.max_hp() * 0.3 and p.alive():
		var pulse := 0.15 + 0.12 * sin(Time.get_ticks_msec() / 200.0)
		_vignette(Color(0.8, 0, 0, pulse))
		if p.hp < p.max_hp() * 0.12 and p.style == "warrior":
			_center_text("DAYANIYORUM...", Vector2(vs.x / 2, vs.y / 2 - 80), 12, Color(1, 0.3, 0.3, 0.8))
	if main.state == "respawning":
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.5))
		_center_text("ARKTAN DÜŞTÜ... (Kalan can: %d)" % Game.lives, vs / 2, 14, Color("ff4d4d"))


func _draw_quest(at: Vector2) -> void:
	var q := Game.quest
	if q.is_empty():
		return
	var r := Rect2(at, Vector2(250, 56))
	var done: bool = q.done
	draw_rect(r, Color(0.0, 0.25, 0.08, 0.85) if done else Color(0.03, 0.06, 0.09, 0.85))
	draw_rect(r, Color(0, 0.94, 1, 0.45) if not done else Color(0.2, 1, 0.3, 0.6), false, 1.5)
	draw_string(UiKit.PIXEL, at + Vector2(10, 20), "GÖREV: " + q.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UiKit.CYAN)
	var desc := "TAMAMLANDI!" if done else "%s (%d/%d)" % [q.desc, q.progress, q.target]
	draw_string(UiKit.PIXEL, at + Vector2(10, 42), desc, HORIZONTAL_ALIGNMENT_LEFT, 236, 7, UiKit.GREEN if done else UiKit.TEXT)


## Sade görünümün haritası: sağ üstte, oyuncuyu ortalayan küçük yuvarlak bir pusula-harita.
func _draw_round_map(c: Vector2, rad: float) -> void:
	var main := hud.main
	var w := main.world
	var circle := PackedVector2Array()
	for i in 40:
		circle.append(c + Vector2.from_angle(TAU * i / 40.0) * rad)
	draw_colored_polygon(circle, Color(0.03, 0.03, 0.05, 0.72))
	var sc := 2.6  # bir karo kaç piksel
	var center_tile := main.player.position / World.TILE
	var to_map := func(tile: Vector2) -> Vector2: return c + (tile - center_tile) * sc
	for i in w.rooms.size():
		if not w.explored.has(i):
			continue
		var rr := w.rooms[i]
		var a: Vector2 = to_map.call(Vector2(rr.position))
		var b: Vector2 = to_map.call(Vector2(rr.end))
		var poly := PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
		for piece in Geometry2D.intersect_polygons(poly, circle):
			draw_colored_polygon(piece, Color(0.62, 0.55, 0.45, 0.55))
		if i + 1 < w.rooms.size() and w.explored.has(i + 1):
			var p1: Vector2 = to_map.call(Vector2(rr.get_center()))
			var p2: Vector2 = to_map.call(Vector2(w.rooms[i + 1].get_center()))
			for seg in [[p1, Vector2(p2.x, p1.y)], [Vector2(p2.x, p1.y), p2]]:
				var clipped := Geometry2D.clip_polyline_with_polygon(PackedVector2Array(seg), circle)
				for cl in clipped:
					draw_polyline(cl, Color(0.62, 0.55, 0.45, 0.5), 1.5)
	var dots := []
	if main.portal and w.explored.has(w.room_index_at(main.portal.position)):
		dots.append([main.portal.position, Color("7fe0ff") if main.portal.active else Color("8a6fb0"), 3.5])
	if main.merchant and w.explored.has(w.room_index_at(main.merchant.position)):
		dots.append([main.merchant.position, UiKit.GOLD, 3.0])
	for d in dots:
		var mp: Vector2 = to_map.call(d[0] / World.TILE)
		if mp.distance_to(c) > rad - 4:
			mp = c + (mp - c).normalized() * (rad - 4)
		draw_circle(mp, d[2], d[1])
	draw_circle(c, 3.5, Color("dff4ff"))
	draw_arc(c, rad, 0, TAU, 48, Color(0.75, 0.65, 0.45, 0.8), 2.0, true)
	draw_arc(c, rad + 3, 0, TAU, 48, Color(0, 0, 0, 0.6), 2.0, true)
	draw_string(UiKit.MODERN, c + Vector2(-rad, -rad - 6), "KAT %d" % Game.floor_number, HORIZONTAL_ALIGNMENT_CENTER, rad * 2, 13, Color(0.9, 0.85, 0.75))


## Sade görünümde görev: kutusuz, haritanın altında sağa yaslı tek satır.
func _draw_quest_line(right: Vector2) -> void:
	var q := Game.quest
	if q.is_empty():
		return
	var text: String = ("✓ " + q.title) if q.done else "%s  %d/%d" % [q.desc, q.progress, q.target]
	var w := UiKit.MODERN.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var at := right - Vector2(w, 0)
	draw_string_outline(UiKit.MODERN, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
	draw_string(UiKit.MODERN, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.GREEN if q.done else Color(0.9, 0.85, 0.75))


func _draw_minimap(r: Rect2) -> void:
	var main := hud.main
	var w := main.world
	draw_rect(r, Color(0.02, 0.04, 0.07, 0.85))
	draw_rect(r, Color(0, 0.94, 1, 0.45), false, 1.5)
	draw_string(UiKit.PIXEL, r.position + Vector2(10, 18), "MINIMAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.CYAN)
	var cnt := "%d/%d" % [w.explored.size(), w.rooms.size()]
	draw_string(UiKit.PIXEL, r.position + Vector2(r.size.x - 50, 18), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.TEXT_DIM)
	var area := Rect2(r.position + Vector2(10, 26), r.size - Vector2(20, 50))
	var t := Time.get_ticks_msec() / 1000.0
	for i in 40:
		var fx := fposmod(i * 37.0 + t * 3.0, area.size.x)
		var fy := fposmod(i * 23.0, area.size.y)
		draw_rect(Rect2(area.position + Vector2(fx, fy), Vector2(2, 2)), Color(0.4, 0.5, 0.7, 0.15))
	var sc := minf(area.size.x / w.width, area.size.y / w.height)
	var off := area.position + (area.size - Vector2(w.width, w.height) * sc) / 2
	for i in w.rooms.size():
		if not w.explored.has(i):
			continue
		var rr := w.rooms[i]
		draw_rect(Rect2(off + Vector2(rr.position) * sc, Vector2(rr.size) * sc), Color(0.3, 0.45, 0.6, 0.65))
		draw_rect(Rect2(off + Vector2(rr.position) * sc, Vector2(rr.size) * sc), Color(0.5, 0.7, 0.9, 0.7), false, 1)
		if i + 1 < w.rooms.size() and w.explored.has(i + 1):
			var a := Vector2(w.rooms[i].get_center()) * sc + off
			var b := Vector2(w.rooms[i + 1].get_center()) * sc + off
			draw_line(a, Vector2(b.x, a.y), Color(0.5, 0.7, 0.9, 0.5), 1.5)
			draw_line(Vector2(b.x, a.y), b, Color(0.5, 0.7, 0.9, 0.5), 1.5)
	var to_map := func(p: Vector2) -> Vector2: return off + p / World.TILE * sc
	if main.portal and w.explored.has(w.room_index_at(main.portal.position)):
		draw_circle(to_map.call(main.portal.position), 4, UiKit.GREEN if main.portal.active else UiKit.PURPLE)
	if main.merchant and w.explored.has(w.room_index_at(main.merchant.position)):
		var mp: Vector2 = to_map.call(main.merchant.position)
		draw_rect(Rect2(mp - Vector2(3, 3), Vector2(6, 6)), Color("ff3b5c") if main.merchant.special else UiKit.GOLD)
	draw_circle(to_map.call(main.player.position), 4, UiKit.CYAN)
	var ly := r.end.y - 10
	draw_string(UiKit.PIXEL, Vector2(r.position.x + 10, ly), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiKit.GREEN)
	draw_string(UiKit.PIXEL, Vector2(r.position.x + 30, ly), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiKit.GOLD)
	draw_string(UiKit.PIXEL, Vector2(r.position.x + 50, ly), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiKit.PURPLE)


## Son çizilen konuşma kutusu (dokunmatikte kutuya dokununca metin ilerler).
var dialogue_rect := Rect2()


func _draw_dialogue() -> void:
	var d := hud.main.dialogue
	if not d.is_open():
		dialogue_rect = Rect2()
		return
	var info := d.speaker_info()
	var vs := size
	var r := Rect2(270, vs.y - Hud.BOTTOM_H - 140, vs.x - 270 - Hud.LOG_W - 20, 120)
	if hud.main.touch_layout:
		# Telefonda sağdaki dokunmatik düğmelere değmesin.
		r.size.x = vs.x - 270 - 410
	dialogue_rect = r
	var border := Color(info.border)
	draw_rect(r, Color(0.02, 0.02, 0.05, 0.95))
	draw_rect(r, border, false, 2)
	var tag := Rect2(r.position + Vector2(14, -12), Vector2(UiKit.PIXEL.get_string_size(info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 20, 22))
	draw_rect(tag, Color(0.02, 0.02, 0.05))
	draw_rect(tag, border, false, 1.5)
	draw_string(UiKit.PIXEL, tag.position + Vector2(10, 16), info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(info.color))
	draw_multiline_string(UiKit.MODERN, r.position + Vector2(16, 34), d.visible_text(), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, 15, 4, UiKit.TEXT)
	if not d.current.auto and d.shown >= d.current.text.length() and (Time.get_ticks_msec() / 400) % 2 == 0:
		draw_string(UiKit.PIXEL, r.end - Vector2(150, 10), "[E] DEVAM ▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(info.color))


var _vignette_tex: GradientTexture2D


func _vignette(c: Color) -> void:
	if _vignette_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 1))
		g.add_point(0.55, Color(1, 1, 1, 0))
		_vignette_tex = GradientTexture2D.new()
		_vignette_tex.gradient = g
		_vignette_tex.fill = GradientTexture2D.FILL_RADIAL
		_vignette_tex.fill_from = Vector2(0.5, 0.5)
		_vignette_tex.fill_to = Vector2(1.05, 1.05)
		_vignette_tex.width = 256
		_vignette_tex.height = 256
	draw_texture_rect(_vignette_tex, Rect2(Vector2.ZERO, size), false, c)


func _center_text(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var fs := roundi(font_size * 1.6)
	var w := UiKit.TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(UiKit.TITLE, at - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(color.r, color.g, color.b, color.a * 0.18))
	draw_string_outline(UiKit.TITLE, at - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, color.a * 0.85))
	draw_string(UiKit.TITLE, at - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
