class_name Screens
extends CanvasLayer
## Tam ekran pencereler (index.html overlay-screen): başlangıç ve dövüş tarzı seçimi, seviye kartları,
## çanta, dükkan, demirci, ruh taşları, hikaye, duraklatma, oyun sonu ve final seçimi.
## Açık bir pencere oyunu durdurur; kapanınca oyun kaldığı yerden sürer.

const STORY := {
	10: ["MÜHÜR KUYUSU", "İlk mühür kapısı. Bin yıl önce kapının önünde bırakılan nöbetçi, mor sisle devleşmiş bekliyor. Göğsünde çatlak bir kurt mührü."],
	20: ["FISILTI TÜNELLERİ", "Kristallerin ışığını yutan gölgeler... Kârun'un çırağı, Gölge Dokuyucu, ustasının kütüphanesini bekliyor."],
	30: ["DEMİR KÖLELERİNİN OCAKLARI", "Halat köprüler ve demir kafesler... Köle Efendisi kemik tahtında oturuyor. Esirleri kurtarmak için önce onu durdur."],
	40: ["İLK OCAK", "Mühür çeliğinin dövüldüğü ocak. Kendini ateşe teslim etmiş eski bir nöbetçi, Ateş Komutanı, kapıda bekliyor."],
	50: ["AK BUZ KURGANLARI", "Buzun içinde donmuş savaşçılar... Kârun'a en uzun direnen Donmuş Han tahtına zincirli bekliyor."],
	60: ["ULU KAYIN", "Dünya ağacının kökleri... Sera'nın yüz elli yıl önce son nefesini verdiği yer. Yoldaşı Lyra ağaca bağlı bekliyor."],
	70: ["VALEN'İN KARA ZİNDANLARI", "İmparatorluğun nöbetçilere işkence ettiği hücreler... Yanık Yüzlü Komutan mor sisle devleşmiş, seni bekliyor."],
	80: ["GÖK KURULTAYI", "Nöbetçilerin doğduğu meclis... Ataların hocası, demir maskenin ardında Kârun'un düzenine boyun eğmiş."],
	90: ["KAPININ ÖTESİ", "İlk Savaş'ta kapanan kapının ardı... Gerçekliği yutan bir irade uyanıyor. Kârun bile ondan korkuyor."],
	100: ["KARA TAHT — SON SAVAŞ", "En dipte, Kalp'in üzerinde Kârun'un Kara Tahtı. Önce yozlaşmış Gök Börü, sonra Kârun. \"Dünya zaten ölüyor.\""],
}

var main: Main
var dim: ColorRect
var current: Control
var current_name := ""
var tooltip: PanelContainer
var tooltip_text: RichTextLabel
var selected_style := "warrior"
var bag_tab := "all"
var _menu_target := -1


func _ready() -> void:
	layer = 10
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	add_child(dim)
	tooltip = UiKit.panel(Color(0.04, 0.04, 0.07, 0.97), Color(0, 0.94, 1, 0.4))
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.visible = false
	tooltip.z_index = 100
	tooltip_text = RichTextLabel.new()
	tooltip_text.bbcode_enabled = true
	tooltip_text.fit_content = true
	tooltip_text.custom_minimum_size = Vector2(260, 0)
	tooltip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text.add_theme_font_override("normal_font", UiKit.MODERN)
	tooltip_text.add_theme_font_override("bold_font", UiKit.MODERN)
	tooltip_text.add_theme_font_override("italics_font", UiKit.MODERN)
	tooltip_text.add_theme_font_size_override("normal_font_size", 13)
	tooltip_text.add_theme_font_size_override("bold_font_size", 15)
	tooltip_text.add_theme_font_size_override("italics_font_size", 12)
	tooltip.add_child(tooltip_text)
	add_child(tooltip)


func _process(_delta: float) -> void:
	if tooltip.visible:
		var m := tooltip.get_viewport().get_mouse_position()
		var vs := tooltip.get_viewport_rect().size
		var p := m + Vector2(18, 18)
		if p.x + tooltip.size.x > vs.x:
			p.x = m.x - tooltip.size.x - 12
		if p.y + tooltip.size.y > vs.y:
			p.y = vs.y - tooltip.size.y - 4
		tooltip.position = p


func show_tooltip(bb: String) -> void:
	tooltip_text.text = bb
	tooltip.size = Vector2.ZERO
	tooltip.visible = true


func hide_tooltip() -> void:
	tooltip.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if current == null:
		return
	if event.is_action_pressed("cancel") or (event.is_action_pressed("bag") and current_name == "bag") \
		or (event.is_action_pressed("interact") and current_name in ["shop", "forge"]) \
		or (event.is_action_pressed("confirm") and current_name in ["story", "meta"]):
		if current_name in ["shop", "bag", "forge", "story", "pause", "meta"]:
			close()
			get_viewport().set_input_as_handled()


func _open(name: String, node: Control, state := "") -> void:
	if current:
		current.queue_free()
	hide_tooltip()
	current = node
	current_name = name
	dim.visible = name != "start"
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(node)
	if state != "":
		main.state = state


func close() -> void:
	if current:
		current.queue_free()
	current = null
	var was := current_name
	current_name = ""
	dim.visible = false
	hide_tooltip()
	if was == "meta" and main.player == null:
		show_start()
		return
	if main.state in ["upgrade", "shop", "bag", "forge", "story", "pause"]:
		main.state = "playing"


func _center_card(min_size: Vector2, border := Color(0, 0.94, 1, 0.35)) -> Array:
	var wrap := CenterContainer.new()
	var card := UiKit.panel(Color(0.04, 0.04, 0.07, 0.96), border)
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 24
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_right = 24
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 18
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 18
	card.custom_minimum_size = min_size
	wrap.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	return [wrap, v]


func _title(v: Control, text: String, color := UiKit.CYAN, size := 16) -> void:
	var l := UiKit.label(text, size, true, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)


func _para(v: Control, text: String, size := 14, color := UiKit.TEXT) -> Label:
	var l := UiKit.label(text, size, false, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(420, 0)
	v.add_child(l)
	return l


# ── Başlangıç ekranı ─────────────────────────────────────────────────

func show_start() -> void:
	main.state = "start"
	Sfx.music("menu")
	if main.hud:
		main.hud.visible = false
	var root := Control.new()
	var bg := TextureRect.new()
	bg.texture = load("res://assets/menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(bg)

	var left := UiKit.panel(Color(0.04, 0.04, 0.06, 1.0), Color(1, 1, 1, 0.06))
	(left.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(0)
	left.anchor_bottom = 1.0
	left.offset_right = 330
	root.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 12)
	left.add_child(lv)
	lv.add_child(UiKit.label("DÖVÜŞ TARZINI SEÇ", 13, true))
	var cards := {}
	for s: String in ["warrior", "ranger", "mage"]:
		var info: Dictionary = ClassData.STYLES[s]
		var card := Button.new()
		card.focus_mode = Control.FOCUS_NONE
		card.custom_minimum_size = Vector2(0, 112)
		card.toggle_mode = true
		card.button_pressed = s == selected_style
		var col: Color = info.color
		card.add_theme_stylebox_override("normal", UiKit.box(Color(0.07, 0.07, 0.1, 0.9), Color(1, 1, 1, 0.08)))
		card.add_theme_stylebox_override("hover", UiKit.box(Color(0.1, 0.1, 0.14, 0.95), Color(col.r, col.g, col.b, 0.5)))
		card.add_theme_stylebox_override("pressed", UiKit.box(Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.95), col, 8, 2))
		var cv := VBoxContainer.new()
		cv.set_anchors_preset(Control.PRESET_FULL_RECT)
		cv.offset_left = 12
		cv.offset_right = -12
		cv.offset_top = 10
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cv)
		var head := HBoxContainer.new()
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(head)
		head.add_child(UiKit.tex_rect(Sprites.tex(s + "_idle1"), Vector2(40, 48), true))
		var hv := VBoxContainer.new()
		hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(hv)
		hv.add_child(UiKit.label(info.title, 11, true, col))
		hv.add_child(UiKit.label(info.desc, 12, false, UiKit.TEXT_DIM))
		for b: Array in info.bars:
			var br := HBoxContainer.new()
			br.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bl := UiKit.label(b[0], 7, true, UiKit.TEXT_DIM)
			bl.custom_minimum_size = Vector2(110, 0)
			br.add_child(bl)
			var pb := UiKit.bar(col, 6)
			pb.value = b[1] * 100
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			br.add_child(pb)
			cv.add_child(br)
		cards[s] = card
		card.pressed.connect(func():
			selected_style = s
			for k in cards:
				cards[k].button_pressed = k == s)
		lv.add_child(card)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(filler)
	lv.add_child(UiKit.label("v0.2.0 Godot | Ülgen Soft", 11, false, UiKit.TEXT_DIM))

	var right := UiKit.panel(Color(0.04, 0.04, 0.06, 1.0), Color(1, 1, 1, 0.06))
	(right.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(0)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = -330
	root.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 14)
	right.add_child(rv)
	var t := UiKit.label("- EREVORN -", 18, true, UiKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(t)
	var story := UiKit.label("Kırık bir kılıç, silinmiş bir hafıza ve yüz katlık bir zindan... Damarlarında Sera'nın kanı akıyor. Kârun bu soyun peşinde. Kim olduğunu ancak aşağı indikçe öğreneceksin.", 13, false, UiKit.TEXT)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(story)
	var go := UiKit.button("İnişe başla.", 12, Color("ff3b3b"))
	go.custom_minimum_size = Vector2(0, 44)
	go.pressed.connect(_start)
	rv.add_child(go)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(sp)
	var stones := UiKit.label("Ruh Taşı: %d" % Game.soul_stones, 10, true, UiKit.PURPLE)
	stones.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(stones)
	var resume := Game.saved_run()
	var cont_label := "DEVAM ET (KAT %d)" % int(resume.oyun.get("floor_number", 1)) if not resume.is_empty() else "DEVAM ET"
	for b in [[cont_label, _continue], ["RUH TAŞLARI", show_meta], ["TAM EKRAN", _toggle_fullscreen], ["ÇIKIŞ", func(): get_tree().quit()]]:
		var btn := UiKit.button(b[0], 10, UiKit.TEXT)
		btn.custom_minimum_size = Vector2(0, 38)
		btn.pressed.connect(b[1])
		rv.add_child(btn)
	_open("start", root)


func _start() -> void:
	close()
	main.start_run(selected_style)


## Yarım koşu varsa onu sürdürür, yoksa seçili tarzla yeni iniş.
func _continue() -> void:
	if Game.has_run():
		main.continue_run()
	else:
		_start()


func _toggle_fullscreen() -> void:
	var w := get_window()
	w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


# ── Seviye atlama ────────────────────────────────────────────────────

func show_level_up() -> void:
	var parts := _center_card(Vector2(760, 0), Color(0.69, 0.15, 1, 0.6))
	var v: VBoxContainer = parts[1]
	_title(v, "SEVİYE ATLADIN!", UiKit.GOLD, 20)
	_para(v, "Seviye %d. Bir güç seç:" % main.player.level, 14, UiKit.TEXT_DIM)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var picks := ClassData.UPGRADES.duplicate()
	picks.shuffle()
	for u: Dictionary in picks.slice(0, 3):
		var col: Color = ItemData.RARITY_COLORS[u.rarity]
		var b := UiKit.button("", 9, col)
		b.custom_minimum_size = Vector2(220, 150)
		var bv := VBoxContainer.new()
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var tl := UiKit.label(u.title, 10, true, col)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(tl)
		var dl := UiKit.label(u.desc, 14, false, UiKit.TEXT)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bv.add_child(dl)
		var rl := UiKit.label(ItemData.RARITY_LABELS[u.rarity], 7, true, Color(col, 0.7))
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(rl)
		b.pressed.connect(func():
			main.player.apply_upgrade(u.id)
			Log.add("Güç seçildi: %s" % u.title, "level")
			close())
		row.add_child(b)
	_open("upgrade", parts[0], "upgrade")


# ── Oyun sonu ────────────────────────────────────────────────────────

func show_game_over(stones: int) -> void:
	var parts := _center_card(Vector2(460, 0), Color(1, 0.2, 0.2, 0.6))
	var v: VBoxContainer = parts[1]
	_title(v, "ELENDİN", Color("ff3b3b"), 22)
	_para(v, "Arktan'ın inişi burada sona erdi... ama kan unutmaz.", 14, UiKit.TEXT_DIM)
	for line in [["Ziyaret Edilen Kat", str(Game.floor_number), UiKit.TEXT], ["Toplanan Altın", str(Game.gold), UiKit.GOLD],
			["Alt Edilen Düşman", str(Game.kills), Color("ff4d4d")], ["Kazanılan Ruh Taşı", "+%d" % stones, UiKit.PURPLE]]:
		var h := HBoxContainer.new()
		var a := UiKit.label(line[0], 14)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(UiKit.label(line[1], 11, true, line[2]))
		v.add_child(h)
	var b := UiKit.button("YENİDEN DENE", 11, Color("ff4d4d"))
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(func():
		close()
		show_start())
	v.add_child(b)
	_open("gameover", parts[0], "gameover")


# ── Çanta ────────────────────────────────────────────────────────────

func show_bag() -> void:
	if main.state != "playing":
		return
	var parts := _center_card(Vector2(780, 0))
	var v: VBoxContainer = parts[1]
	v.add_theme_constant_override("separation", 9)
	_title(v, "ÇANTA", UiKit.CYAN, 16)
	# Üst bölüm: kuşanılan eşyalar + karakter değerleri
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	v.add_child(top)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 4)
	top.add_child(ev)
	ev.add_child(UiKit.title_label("KUŞANILANLAR", 13, UiKit.GOLD))
	var eg := GridContainer.new()
	eg.name = "Equip"
	eg.columns = 4
	eg.add_theme_constant_override("h_separation", 6)
	eg.add_theme_constant_override("v_separation", 6)
	ev.add_child(eg)
	ev.add_child(UiKit.label("Tık: çıkar (silah hariç)", 10, false, UiKit.TEXT_DIM))
	var sp := UiKit.panel(Color(0.06, 0.05, 0.04, 0.85), Color(1, 0.84, 0, 0.22))
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var sv := VBoxContainer.new()
	sv.name = "Stats"
	sv.add_theme_constant_override("separation", 4)
	sp.add_child(sv)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(tabs)
	for t in [["all", "TÜMÜ"], ["gear", "EKİPMAN"], ["shard", "TAŞ PARÇALARI"], ["stone", "TAŞLAR"]]:
		var b := UiKit.button(t[1], 8, UiKit.CYAN if bag_tab == t[0] else UiKit.TEXT_DIM)
		b.pressed.connect(func():
			bag_tab = t[0]
			show_bag())
		tabs.add_child(b)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var craft := HBoxContainer.new()
	craft.name = "Craft"
	craft.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(craft)
	var bulk := HBoxContainer.new()
	bulk.alignment = BoxContainer.ALIGNMENT_CENTER
	bulk.add_theme_constant_override("separation", 10)
	v.add_child(bulk)
	var sell_all := UiKit.button("TÜMÜNÜ SAT", 8, UiKit.GOLD)
	sell_all.pressed.connect(_bulk_sell)
	bulk.add_child(sell_all)
	var salv_all := UiKit.button("TÜMÜNÜ PARÇALA", 8, UiKit.PURPLE)
	salv_all.pressed.connect(_bulk_salvage)
	bulk.add_child(salv_all)
	var bulk_note := UiKit.label("(kuşanılmamış ekipman; efsanevi ve kızıl hariç)", 10, false, UiKit.TEXT_DIM)
	bulk.add_child(bulk_note)
	var hint := UiKit.label("Sol tık: Kuşan / Kullan  |  Sağ tık: Sat / Parçala", 12, false, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var close_b := UiKit.button("KAPAT  [I]", 9)
	close_b.pressed.connect(close)
	v.add_child(close_b)
	_open("bag", parts[0], "bag")
	refresh_bag()


## Kuşanılan yuvalar: simge + nadirlik çerçevesi; tıklayınca çıkarılır.
func _fill_equipment(eg: GridContainer) -> void:
	for c in eg.get_children():
		c.queue_free()
	var p := main.player
	for slot: String in ItemData.SLOTS:
		var b := Hud.SlotButton.new()
		b.slot_label = ItemData.SLOT_LABELS[slot]
		b.item = p.equipment[slot]
		b.custom_minimum_size = Vector2(52, 52)
		b.pressed.connect(func(): main.hud._unequip(slot))
		b.mouse_entered.connect(func(): main.hud._hover_slot(slot))
		b.mouse_exited.connect(hide_tooltip)
		eg.add_child(b)


## Karakter değerleri ve kalıcı kazanımlar (parçalama + tutsaklar).
func _fill_stats(sv: VBoxContainer) -> void:
	for c in sv.get_children():
		c.queue_free()
	var p := main.player
	sv.add_child(UiKit.title_label("KARAKTER", 13, UiKit.GOLD))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 2)
	sv.add_child(g)
	var rows := [
		["CAN", "%d / %d" % [p.hp, p.max_hp()], Color("ff6b7a")],
		["HASAR", str(p.total_atk()), Color("ff9d5c")],
		["DEFANS", str(p.total_def()), Color("8fc7ff")],
		["HIZ", "%.1f" % p.total_spd(), Color("9cff9c")],
		["KRİTİK", "%d%%" % int(p.total_crit()), UiKit.GOLD],
		["ŞANS", "%d%%" % int(p.base.luck), Color("d9a6ff")],
	]
	for r in rows:
		var k := UiKit.title_label(r[0], 11, UiKit.TEXT_DIM)
		k.custom_minimum_size = Vector2(62, 0)
		g.add_child(k)
		var val := UiKit.title_label(r[1], 14, r[2])
		val.custom_minimum_size = Vector2(80, 0)
		g.add_child(val)
	var set_names: Array = p.set_bonus().names
	if not set_names.is_empty():
		sv.add_child(UiKit.label("Set: " + ", ".join(set_names), 11, false, UiKit.GOLD))
	sv.add_child(UiKit.title_label("KALICI KAZANIMLAR", 11, UiKit.PURPLE))
	var parts: PackedStringArray = []
	for k: String in ["atk", "def", "maxHp", "crit"]:
		var n: int = p.perm.get(k, 0)
		if n > 0:
			parts.append(_gain_text(k, n))
	var txt := "   ".join(parts) if not parts.is_empty() else "Henüz yok: eşya parçala, tutsak kurtar."
	var pl := UiKit.label(txt, 12, false, UiKit.TEXT if not parts.is_empty() else UiKit.TEXT_DIM)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.custom_minimum_size = Vector2(300, 0)
	sv.add_child(pl)


static func _gain_text(stat: String, n: int) -> String:
	match stat:
		"atk": return "+%d Hasar" % n
		"def": return "+%d Defans" % n
		"maxHp": return "+%d Can" % n
		"crit": return "+%d%% Kritik" % n
	return "+%d %s" % [n, stat]


func _bag_filter(item: Dictionary) -> bool:
	match bag_tab:
		"gear": return ItemData.is_gear(item)
		"shard": return item.type.begins_with("stone_shard_")
		"stone": return item.type.begins_with("stone_") and not item.type.begins_with("stone_shard_")
	return true


func refresh_bag() -> void:
	if current_name != "bag" or current == null:
		return
	_fill_equipment(current.find_child("Equip", true, false))
	_fill_stats(current.find_child("Stats", true, false))
	var grid: GridContainer = current.find_child("Grid", true, false)
	var craft: HBoxContainer = current.find_child("Craft", true, false)
	for c in grid.get_children():
		c.queue_free()
	for c in craft.get_children():
		c.queue_free()
	var inv: Array = main.player.inventory
	var shown := 0
	for i in inv.size():
		var it: Dictionary = inv[i]
		if not _bag_filter(it):
			continue
		shown += 1
		var b := Hud.SlotButton.new()
		b.item = it
		b.custom_minimum_size = Vector2(52, 52)
		b.gui_input.connect(func(e): _bag_click(e, i))
		b.mouse_entered.connect(func():
			var eq: Dictionary = main.player.equipment.get(ItemData.slot_of(it), {})
			show_tooltip(UiKit.item_tooltip(it, eq, Game.barter)))
		b.mouse_exited.connect(hide_tooltip)
		if it.get("count", 1) > 1:
			var cl := UiKit.label(str(it.count), 8, true, UiKit.GOLD)
			cl.position = Vector2(34, 38)
			b.add_child(cl)
		grid.add_child(b)
	for _i in Player.BAG_SIZE - shown if bag_tab == "all" else 0:
		var e := Hud.SlotButton.new()
		e.custom_minimum_size = Vector2(52, 52)
		e.disabled = true
		grid.add_child(e)
	for s: String in ItemData.STONES:
		var idx := _find(inv, "stone_shard_" + s)
		if idx >= 0 and inv[idx].count >= 10:
			var b := UiKit.button("10 %s → TAŞ" % ItemData.CONSUMABLES["stone_shard_" + s][0].split(" ")[0].to_upper(), 7, UiKit.PURPLE)
			b.pressed.connect(func(): _craft_stone(s))
			craft.add_child(b)
	main.hud.bag_count.text = "%d/%d" % [inv.size(), Player.BAG_SIZE]


func _find(inv: Array, type: String) -> int:
	for i in inv.size():
		if inv[i].type == type:
			return i
	return -1


func _craft_stone(s: String) -> void:
	var inv: Array = main.player.inventory
	var i := _find(inv, "stone_shard_" + s)
	inv[i].count -= 10
	if inv[i].count <= 0:
		inv.remove_at(i)
	main.player.add_to_bag(ItemData.make("stone_" + s))
	Sfx.play("soulstone")
	Log.add("Taş birleştirildi: %s" % ItemData.CONSUMABLES["stone_" + s][0], "loot")
	refresh_bag()


func _bag_click(e: InputEvent, index: int) -> void:
	if not (e is InputEventMouseButton and e.pressed):
		return
	var p := main.player
	if index >= p.inventory.size():
		return
	var it: Dictionary = p.inventory[index]
	hide_tooltip()
	if e.button_index == MOUSE_BUTTON_LEFT:
		if ItemData.is_gear(it):
			var err := p.equip(index)
			if err != "":
				main.hud.toast(err)
			else:
				Log.add("Kuşanıldı: %s" % it.name, "loot")
		elif it.type.begins_with("potion_"):
			if not p.use_consumable(index):
				main.hud.toast("CAN ZATEN DOLU")
		elif it.type.begins_with("stone_") and not it.type.begins_with("stone_shard_"):
			_socket(index)
		main.hud.refresh()
		refresh_bag()
	elif e.button_index == MOUSE_BUTTON_RIGHT:
		_item_menu(index)


func _socket(index: int) -> void:
	var p := main.player
	var it: Dictionary = p.inventory[index]
	var s: String = it.type.trim_prefix("stone_")
	var slot := "weapon" if s in ["ruby", "sapphire"] else "armor"
	var target: Dictionary = p.equipment[slot]
	if target.is_empty() or target.sockets.size() >= target.socket_limit:
		main.hud.toast("TAKILACAK YUVA YOK (efsanevi eşya gerekir)")
		return
	if s in target.sockets:
		main.hud.toast("BU TAŞ ZATEN TAKILI")
		return
	target.sockets.append(s)
	match s:
		"ruby": target.stats.atk = target.stats.get("atk", 0) + 3
		"sapphire": target.stats.crit = target.stats.get("crit", 0) + 4
		"emerald": target.stats.hp = target.stats.get("hp", 0) + 18
		"obsidian": target.stats.def = target.stats.get("def", 0) + 2
	it.count -= 1
	if it.count <= 0:
		p.inventory.remove_at(index)
	Log.add("%s takıldı: %s" % [ItemData.CONSUMABLES[it.type][0], target.name], "loot")


func _item_menu(index: int) -> void:
	var p := main.player
	var it: Dictionary = p.inventory[index]
	var parts := _center_card(Vector2(360, 0))
	var v: VBoxContainer = parts[1]
	var holder: Control = parts[0]
	_title(v, it.name, ItemData.RARITY_COLORS.get(it.rarity, UiKit.TEXT), 10)
	var price := ItemData.sell_price(it, Game.barter)
	var sell := UiKit.button("SAT (+%d altın)" % (price * it.get("count", 1)), 9, UiKit.GOLD)
	sell.pressed.connect(func():
		Game.add_gold(price * it.get("count", 1))
		p.inventory.erase(it)
		Log.add("Satıldı: %s" % it.name, "loot")
		holder.queue_free()
		refresh_bag())
	v.add_child(sell)
	if ItemData.is_gear(it):
		var salv := UiKit.button("PARÇALA (kalıcı güç)", 9, UiKit.PURPLE)
		salv.pressed.connect(func():
			var pick := _salvage(it)
			_show_salvage_gain(it, pick)
			holder.queue_free()
			main.hud.refresh()
			refresh_bag())
		v.add_child(salv)
	var cancel := UiKit.button("VAZGEÇ", 9, UiKit.TEXT_DIM)
	cancel.pressed.connect(func(): holder.queue_free())
	v.add_child(cancel)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	current.add_child(holder)


const SALVAGE_TABLE := {"common": [["atk", 1], ["def", 1]], "rare": [["atk", 2], ["def", 2], ["maxHp", 6]],
	"epic": [["atk", 2], ["def", 2], ["maxHp", 8], ["crit", 1]],
	"legendary": [["atk", 3], ["def", 3], ["maxHp", 12], ["crit", 2]], "mythic": [["atk", 5], ["def", 5], ["maxHp", 20], ["crit", 3]]}


static func _salvage_roll(it: Dictionary) -> Array:
	return SALVAGE_TABLE.get(it.rarity, SALVAGE_TABLE.common).pick_random()


## Eşyayı parçalar: rastgele kalıcı güç. Kazanç ekranın ortasında büyük yazıyla gösterilir.
func _salvage(it: Dictionary, pick: Array = []) -> Array:
	var p := main.player
	if pick.is_empty():
		pick = _salvage_roll(it)
	p.add_permanent(pick[0], pick[1])
	Sfx.play("salvage")
	p.inventory.erase(it)
	Log.add("Parçalandı: %s → kalıcı %s" % [it.name, _gain_text(pick[0], pick[1])], "level")
	return pick


func _show_salvage_gain(it: Dictionary, pick: Array) -> void:
	var g := _gain_text(pick[0], pick[1]).to_upper()
	flash("KALICI " + g, ItemData.fx_color(it.rarity))
	main.hud.toast("PARÇALANDI: KALICI " + g)


## Ekranın üst ortasında yükselip sönen büyük yazı (Cinzel). Pencerelerin üstünde görünür.
func flash(text: String, color: Color, sub := "") -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -400
	box.offset_right = 400
	box.offset_top = 70
	box.z_index = 90
	var l := UiKit.title_label(text, 30, color)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	if sub != "":
		var sl := UiKit.title_label(sub, 15, UiKit.TEXT)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(sl)
	add_child(box)
	box.scale = Vector2(1.15, 1.15)
	box.pivot_offset = Vector2(400, 20)
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2.ONE, 0.18)
	tw.tween_interval(1.2)
	tw.parallel().tween_property(box, "offset_top", 44.0, 1.5)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(box.queue_free)


# ── Toplu işlemler ───────────────────────────────────────────────────

## Toplu satış / parçalama: kuşanılmamış ekipman, efsanevi ve kızıl hariç.
func _bulk_candidates() -> Array:
	return main.player.inventory.filter(func(it): return ItemData.is_gear(it) and not it.rarity in ["legendary", "mythic"])


func _bulk_sell() -> void:
	var items := _bulk_candidates()
	if items.is_empty():
		main.hud.toast("SATILACAK EKİPMAN YOK")
		return
	var total := 0
	for it in items:
		total += ItemData.sell_price(it, Game.barter) * it.get("count", 1)
	_confirm("TÜMÜNÜ SAT", "%d ekipman satılacak.\nToplam: +%d altın" % [items.size(), total], "SAT (+%d)" % total, UiKit.GOLD, func():
		for it in items:
			main.player.inventory.erase(it)
		Game.add_gold(total)
		Sfx.play("gold")
		Log.add("Toplu satış: %d eşya → +%d altın" % [items.size(), total], "loot")
		flash("+%d ALTIN" % total, UiKit.GOLD, "%d eşya satıldı" % items.size())
		main.hud.refresh()
		refresh_bag())


func _bulk_salvage() -> void:
	var items := _bulk_candidates()
	if items.is_empty():
		main.hud.toast("PARÇALANACAK EKİPMAN YOK")
		return
	# Kazançlar önceden atılır ki onay penceresi tam sonucu gösterebilsin.
	var picks: Array = []
	var sum := {"atk": 0, "def": 0, "maxHp": 0, "crit": 0}
	for it in items:
		var pk := _salvage_roll(it)
		picks.append(pk)
		sum[pk[0]] += pk[1]
	var gains: PackedStringArray = []
	for k: String in ["atk", "def", "maxHp", "crit"]:
		if sum[k] > 0:
			gains.append(_gain_text(k, sum[k]))
	var summary := "   ".join(gains)
	_confirm("TÜMÜNÜ PARÇALA", "%d ekipman parçalanacak.\nKalıcı kazanç: %s" % [items.size(), summary], "PARÇALA", UiKit.PURPLE, func():
		for i in items.size():
			_salvage(items[i], picks[i])
		flash("KALICI GÜÇ", UiKit.PURPLE, summary)
		main.hud.toast("PARÇALANDI: %d EŞYA" % items.size())
		main.hud.refresh()
		refresh_bag())


## Çanta üstünde onay kutusu.
func _confirm(title: String, text: String, ok_text: String, color: Color, on_ok: Callable) -> void:
	var parts := _center_card(Vector2(420, 0), Color(color, 0.5))
	var v: VBoxContainer = parts[1]
	var holder: Control = parts[0]
	_title(v, title, color, 12)
	_para(v, text, 14)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var ok := UiKit.button(ok_text, 9, color)
	ok.pressed.connect(func():
		holder.queue_free()
		on_ok.call())
	row.add_child(ok)
	var cancel := UiKit.button("VAZGEÇ", 9, UiKit.TEXT_DIM)
	cancel.pressed.connect(func(): holder.queue_free())
	row.add_child(cancel)
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	current.add_child(holder)


# ── Dükkan ───────────────────────────────────────────────────────────

func show_shop() -> void:
	var m := main.merchant
	var f := Game.floor_number
	var pm := 1.0 + ((f - 1) / 10) * 0.55
	if m.stock.is_empty():
		var potion := "potion_red" if randf() < 0.6 else "potion_blue"
		m.stock.append({"item": ItemData.make(potion), "price": int((42 if m.special else 22) * pm)})
		for i in 3:
			var leg := 0.0 if f < 10 else (0.025 if f < 25 else 0.055)
			var rare := 0.22 if f < 10 else (0.32 if f < 25 else 0.42)
			var item: Dictionary
			if m.special:
				if f < 15:
					item = ItemData.gear_roll(0.0, 1.0)
				else:
					item = ItemData.gear_roll(1.0 if i == 0 else 0.45, 1.0)
			else:
				item = ItemData.gear_roll(leg, rare)
			var base: int = {"common": randi_range(34, 47), "rare": randi_range(88, 117), "legendary": randi_range(240, 329)}[item.rarity]
			m.stock.append({"item": item, "price": int(base * pm)})
	var parts := _center_card(Vector2(900, 0), Color(1, 0.84, 0, 0.45))
	var v: VBoxContainer = parts[1]
	_title(v, "GİZEMLİ SATICI" + (" (ÖZEL)" if m.special else ""), UiKit.GOLD, 16)
	var gold := UiKit.label("Altının: %d" % Game.gold, 10, true, UiKit.GOLD)
	gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gold)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for entry: Dictionary in m.stock:
		var it: Dictionary = entry.item
		var price: int = entry.price
		if Game.barter:
			price = int(price * 0.8)
		var col: Color = ItemData.RARITY_COLORS.get(it.rarity, UiKit.TEXT)
		var card := UiKit.panel(Color(0.07, 0.07, 0.1, 0.95), Color(col.r, col.g, col.b, 0.5))
		card.custom_minimum_size = Vector2(200, 0)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(cv)
		var icon := UiKit.tex_rect(Sprites.tex(ItemData.icon_key(it)), Vector2(48, 48))
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.mouse_entered.connect(func(): show_tooltip(UiKit.item_tooltip(it, main.player.equipment.get(ItemData.slot_of(it), {}), Game.barter)))
		icon.mouse_exited.connect(hide_tooltip)
		cv.add_child(icon)
		var nl := UiKit.label(it.name, 13, false, col)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nl)
		var st := UiKit.label(ItemData.stat_text(it.stats) if ItemData.is_gear(it) else it.desc, 12, false, UiKit.TEXT_DIM)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(st)
		var buy := UiKit.button("%d ALTIN" % price, 9, UiKit.GOLD)
		buy.disabled = entry.get("sold", false) or Game.gold < price
		if entry.get("sold", false):
			buy.text = "SATILDI"
		buy.pressed.connect(func():
			if Game.gold < price or not main.player.add_to_bag(it.duplicate(true)):
				main.hud.toast("ÇANTA DOLU" if Game.gold >= price else "YETERSİZ ALTIN")
				return
			Game.gold -= price
			entry.sold = true
			Log.add("Satın alındı: %s" % it.name, "loot")
			Game.changed.emit()
			show_shop())
		cv.add_child(buy)
		row.add_child(card)
	_title(v, "ALTINLA ANTRENMAN", UiKit.CYAN, 10)
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 10)
	v.add_child(trow)
	for t: Dictionary in ClassData.TRAINING:
		var cost := int(t.base * (1.0 + ((f - 1) / 10) * 0.45) * (1.0 + Game.training_purchases * 0.18))
		if Game.barter:
			cost = int(cost * 0.9)
		var b := UiKit.button("%s\n%s\n%d altın" % [t.title, t.desc, cost], 8, UiKit.CYAN)
		b.add_theme_font_override("font", UiKit.MODERN)
		b.add_theme_font_size_override("font_size", 14)
		b.custom_minimum_size = Vector2(200, 76)
		b.disabled = Game.gold < cost
		b.pressed.connect(func():
			Game.gold -= cost
			Game.training_purchases += 1
			match t.id:
				"atk": main.player.base.atk += 1
				"def": main.player.base.def += 1
				"hp":
					main.player.base.maxHp += 8
					main.player.heal(8)
				"crit": main.player.base.crit += 2
			Log.add("Antrenman: %s" % t.desc, "level")
			Game.changed.emit()
			show_shop())
		trow.add_child(b)
	var c := UiKit.button("KAPAT  [E]", 9)
	c.pressed.connect(close)
	v.add_child(c)
	_open("shop", parts[0], "shop")


# ── Demirci ──────────────────────────────────────────────────────────

func show_forge() -> void:
	if main.state != "playing" and current_name != "forge":
		return
	var p := main.player
	var parts := _center_card(Vector2(640, 0), Color(1, 0.55, 0.1, 0.5))
	var v: VBoxContainer = parts[1]
	_title(v, "DEMİRCİ OCAĞI", Color("ff9d00"), 16)
	_para(v, "Aynı nadirlikte iki ekipmanı birleştir: 2 sıradan → nadir (35 altın), 2 nadir → efsanevi (95 altın).", 13, UiKit.TEXT_DIM)
	var any := false
	for rarity in ["common", "rare"]:
		var list: Array = p.inventory.filter(func(it): return ItemData.is_gear(it) and it.rarity == rarity)
		if list.size() >= 2:
			any = true
			var cost := 35 if rarity == "common" else 95
			var b := UiKit.button("%s + %s → %s  (%d altın)" % [list[0].name, list[1].name, "NADİR" if rarity == "common" else "EFSANEVİ", cost], 8, ItemData.RARITY_COLORS[rarity])
			b.disabled = Game.gold < cost
			b.pressed.connect(func():
				Game.gold -= cost
				p.inventory.erase(list[0])
				p.inventory.erase(list[1])
				var res := ItemData.make("%s_%s" % [list[0].kind if list[0].kind != "dagger" else "sword", "rare" if rarity == "common" else "legendary"])
				p.add_to_bag(res)
				Log.add("Dövüldü: %s" % res.name, "loot")
				Sfx.play("forge")
				Game.changed.emit()
				show_forge())
			v.add_child(b)
	var mythic_cost := 1800 + Game.floor_number * 18
	var legs: Array = p.inventory.filter(func(it): return ItemData.is_gear(it) and it.rarity == "legendary")
	var stone := -1
	for i in p.inventory.size():
		var t: String = p.inventory[i].type
		if t.begins_with("stone_") and not t.begins_with("stone_shard_"):
			stone = i
	if not legs.is_empty() and stone >= 0:
		any = true
		var b := UiKit.button("KIZIL DÖVME: %s + taş → KIZIL (%d altın)" % [legs[0].name, mythic_cost], 8, ItemData.RARITY_COLORS.mythic)
		b.disabled = Game.gold < mythic_cost
		b.pressed.connect(func():
			Game.gold -= mythic_cost
			var it: Dictionary = legs[0]
			var st: Dictionary = p.inventory[stone]
			st.count -= 1
			if st.count <= 0:
				p.inventory.remove_at(stone)
			it.rarity = "mythic"
			it.name = "Kızıl " + it.name
			it.socket_limit = 2
			for k in [["atk", 6], ["def", 4], ["hp", 25], ["crit", 4]]:
				if it.stats.has(k[0]):
					it.stats[k[0]] += k[1]
			Log.add("Kızıl dövme: %s" % it.name, "level")
			Sfx.play("forge")
			Game.changed.emit()
			show_forge())
		v.add_child(b)
	if not any:
		_para(v, "Birleştirilecek eşya yok.", 14, UiKit.TEXT_DIM)
	var c := UiKit.button("KAPAT  [E]", 9)
	c.pressed.connect(close)
	v.add_child(c)
	_open("forge", parts[0], "forge")


# ── Ruh taşları (kalıcı geliştirme) ──────────────────────────────────

func show_meta() -> void:
	var parts := _center_card(Vector2(560, 0), Color(0.69, 0.15, 1, 0.5))
	var v: VBoxContainer = parts[1]
	_title(v, "RUH TAŞLARI", UiKit.PURPLE, 16)
	var cnt := UiKit.label("Ruh Taşı: %d" % Game.soul_stones, 11, true, UiKit.PURPLE)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cnt)
	for m: Dictionary in ClassData.META:
		var lvl: int = Game.meta[m.id]
		var maxed: bool = lvl >= m.max
		var b := UiKit.button("%s  (%s)  Sv %d/%d  —  %s" % [m.title, m.desc, lvl, m.max, "TAMAM" if maxed else "%d taş" % m.cost], 8, UiKit.PURPLE)
		b.disabled = maxed or Game.soul_stones < m.cost
		b.pressed.connect(func():
			Sfx.play("soulstone")
			Game.soul_stones -= m.cost
			Game.meta[m.id] += 1
			Game.save()
			show_meta())
		v.add_child(b)
	var c := UiKit.button("KAPAT", 9)
	c.pressed.connect(close)
	v.add_child(c)
	_open("meta", parts[0])


# ── Hikaye, duraklatma, final ────────────────────────────────────────

func show_story(floor_number: int) -> void:
	if not STORY.has(floor_number) or main.state != "playing":
		return
	var s: Array = STORY[floor_number]
	var parts := _center_card(Vector2(560, 0))
	var v: VBoxContainer = parts[1]
	_title(v, s[0], UiKit.CYAN, 13)
	_para(v, s[1], 16)
	main.dialogue.play_voices(["anlatici_hikaye_%d" % floor_number])
	var b := UiKit.button("DEVAM ET", 10)
	b.pressed.connect(func():
		main.dialogue.stop_voices()
		close())
	v.add_child(b)
	_open("story", parts[0], "story")


func show_pause() -> void:
	if main.state != "playing":
		return
	var parts := _center_card(Vector2(380, 0))
	var v: VBoxContainer = parts[1]
	_title(v, "DURAKLATILDI", UiKit.CYAN, 14)
	_volume_sliders(v)
	for b in [["DEVAM ET", close], ["TAM EKRAN", _toggle_fullscreen], ["ANA MENÜ", func():
			close()
			main.player.queue_free()
			main.player = null
			main.light_rect.visible = false
			show_start()]]:
		var btn := UiKit.button(b[0], 10)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(b[1])
		v.add_child(btn)
	_open("pause", parts[0], "pause")


## Ses ayarları: genel, efekt, müzik, konuşma (0–100). Değişiklik anında duyulur ve kaydedilir.
func _volume_sliders(v: VBoxContainer) -> void:
	for row in [["GENEL SES", "volume"], ["EFEKTLER", "sfx_volume"], ["MÜZİK", "music_volume"], ["KONUŞMA", "voice_volume"]]:
		var h := HBoxContainer.new()
		var l := UiKit.label(row[0], 8, true, UiKit.TEXT_DIM)
		l.custom_minimum_size = Vector2(120, 0)
		h.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 100
		sl.step = 5
		sl.value = Sfx.get(row[1]) * 100.0
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.focus_mode = Control.FOCUS_NONE
		var key: String = row[1]
		sl.value_changed.connect(func(x: float):
			Sfx.set_level(key, x / 100.0)
			if key != "music_volume":
				Sfx.play("item"))
		h.add_child(sl)
		v.add_child(h)


func show_ending_choice() -> void:
	# Arkadaki konuşma kutusu kararın önünde asılı kalmasın.
	main.dialogue.reset()
	var parts := _center_card(Vector2(620, 0), Color(1, 0.84, 0, 0.5))
	var v: VBoxContainer = parts[1]
	_title(v, "KARAR ANI", UiKit.GOLD, 18)
	_para(v, "Kârun yenildi. Dünyanın Kalbi önünde atıyor. Ne yapacaksın?", 15)
	_para(v, "Kurtarılan: %d  |  Öldürülen: %d" % [Game.run_rescues, Game.kills], 12, UiKit.TEXT_DIM)
	var opts := [
		["light", "IŞIK YOLU — Kârun'u öldürme, mühür çeliğiyle yozlaşmasını çöz", Game.run_rescues >= 3, "En az 3 tutsak kurtar"],
		["iron", "DEMİR YOLU — Kârun'u öldür, Kalp'i kendi kanınla mühürle", true, ""],
		["dark", "KARANLIK YOLU — Asayı al, Kara Taht'a otur", Game.kills >= 150, "En az 150 düşman öldür"],
	]
	var buttons: Array[Button] = []
	for o in opts:
		var b := UiKit.button(o[1] + ("" if o[2] else "  (%s)" % o[3]), 8, UiKit.GOLD if o[2] else UiKit.TEXT_DIM)
		b.custom_minimum_size = Vector2(0, 44)
		b.disabled = not o[2]
		b.pressed.connect(func():
			for x in buttons:
				x.disabled = true
			main.resolve_ending(o[0]))
		v.add_child(b)
		buttons.append(b)
	_open("ending_choice", parts[0], "ending_choice")


func show_ending(choice: String, stones: int) -> void:
	var info: Array = {
		"light": ["NÖBETÇİLERİN YENİDEN DOĞUŞU", "Kârun yaşıyor, mor sis çözüldü. Sera huzura kavuştu; Göğün Nöbetçileri yeniden kuruluyor."],
		"iron": ["SON MÜHÜR", "Kalp senin kanınla sonsuza dek mühürlendi. Zindan çöktü, nöbetçiler tarihe karıştı."],
		"dark": ["KARA TAHTIN VARİSİ", "Kalp'in mor gücü artık senin zırhında. Sera sustu. Kara Taht yeniden dolu."],
	}[choice]
	var parts := _center_card(Vector2(560, 0), Color(1, 0.84, 0, 0.5))
	var v: VBoxContainer = parts[1]
	_title(v, info[0], UiKit.GOLD, 18)
	_para(v, info[1], 15)
	# Sonun sözleri (dialogue.json ending_*) kartın içinde: arkadaki konuşma kutusu kullanılmaz.
	var lines = main.dialogue.data.events.get("ending_" + choice, [])
	main.dialogue.play_voices(lines.map(func(l): return l.get("voice", "")))
	for l in lines:
		var who: Dictionary = main.dialogue.speakers.get(l.speaker, main.dialogue.speakers.NARRATOR)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var name_l := UiKit.title_label(who.name, 11, Color(who.color))
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(name_l)
		v.add_child(row)
		var tl := _para(row, l.text, 13, UiKit.TEXT)
		tl.custom_minimum_size = Vector2(520, 0)
	_para(v, "Dövüş tarzı: %s  |  Kat: %d  |  Öldürülen: %d\nRuh Taşı: +%d" % [ClassData.STYLES[Game.style].title, Game.floor_number, Game.kills, stones], 13, UiKit.TEXT_DIM)
	var b := UiKit.button("YENİDEN OYNA", 10)
	b.pressed.connect(func():
		close()
		show_start())
	v.add_child(b)
	_open("ending", parts[0], "ending")
