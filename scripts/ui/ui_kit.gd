class_name UiKit
## Eski arayüzün görünümü (style.css): koyu yarı saydam paneller, ince camgöbeği çerçeve,
## başlıklarda Press Start 2P, metinde Outfit.

const PIXEL := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MODERN := preload("res://assets/fonts/Outfit.ttf")
const TITLE := preload("res://assets/fonts/Cinzel-Bold.ttf")
const CYAN := Color("00f0ff")
const PINK := Color("ff007f")
const PURPLE := Color("b026ff")
const GOLD := Color("ffd700")
const RED := Color("ff3333")
const GREEN := Color("39ff14")
const TEXT := Color("f0f0f5")
const TEXT_DIM := Color("a0a0b5")


static func box(bg := Color(0.07, 0.07, 0.1, 0.85), border := Color(0, 0.94, 1, 0.18), radius := 8, width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func panel(bg := Color(0.07, 0.07, 0.1, 0.85), border := Color(0, 0.94, 1, 0.18)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p


## Boyalı stile uygun başlık/rakam yazısı (Cinzel).
static func title_label(text: String, size := 12, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", TITLE)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	return l


static func label(text: String, size := 12, pixel := false, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", PIXEL if pixel else MODERN)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, size := 10, color := CYAN) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", PIXEL)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.45))
	var n := box(Color(0.05, 0.05, 0.08, 0.9), Color(color.r, color.g, color.b, 0.45), 6)
	var h := box(Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.95), color, 6)
	var d := box(Color(0.05, 0.05, 0.07, 0.6), Color(0.3, 0.3, 0.35, 0.4), 6)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", d)
	return b


static func bar(fill: Color, height := 10) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.14)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(3)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


static func tex_rect(t: Texture2D, size: Vector2, smooth := false) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Eşya açıklaması (ipucu kutusu için). Kuşanılı eşyayla farkı da gösterir.
static func item_tooltip(item: Dictionary, equipped: Dictionary, barter: bool) -> String:
	var lines: PackedStringArray = []
	var c: Color = ItemData.RARITY_COLORS.get(item.rarity, TEXT)
	lines.append("[color=#%s][b]%s[/b][/color]" % [c.to_html(false), item.name])
	lines.append("[color=#%s]%s[/color]" % [c.to_html(false), ItemData.RARITY_LABELS.get(item.rarity, "")])
	if item.get("count", 1) > 1:
		lines.append("Adet: %d" % item.count)
	for k: String in ["atk", "def", "hp", "crit", "spd"]:
		var v = item.stats.get(k, 0)
		if v == 0 and not equipped.get("stats", {}).has(k):
			continue
		var diff = v - equipped.get("stats", {}).get(k, 0)
		var dtxt := ""
		if not equipped.is_empty() and diff != 0:
			dtxt = " [color=#%s](%s%s)[/color]" % ["39ff14" if diff > 0 else "ff3333", "+" if diff > 0 else "", _num(diff)]
		if v != 0 or dtxt != "":
			lines.append("+%s %s%s" % [_num(v), ItemData.STAT_LABELS[k], dtxt])
	var fx := ItemData.effect_text(item.get("effect", {}))
	if fx != "":
		lines.append("[color=#ffd700]%s[/color]" % fx)
	if item.get("socket_limit", 0) > 0:
		lines.append("Yuva: %d/%d %s" % [item.sockets.size(), item.socket_limit, ", ".join(item.sockets)])
	if item.get("desc", "") != "":
		lines.append("[color=#a0a0b5][i]%s[/i][/color]" % item.desc)
	lines.append("[color=#ffd700]Satış: %d altın[/color]" % ItemData.sell_price(item, barter))
	return "\n".join(lines)


static func _num(v) -> String:
	if v is float:
		return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	return str(v)
