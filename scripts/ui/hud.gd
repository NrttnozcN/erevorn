class_name Hud
extends CanvasLayer
## Oyun içi arayüz, eski düzenin aynısı: üst şerit (kat, altın, canlar), sol üstte görev ve
## mini harita, sağda savaş günlüğü, altta KARAKTER / EKİPMAN & YETENEKLER / ÇANTA panelleri.
## Savaş sırasında paneller saydamlaşır.

const TOP_H := 44.0
const BOTTOM_H := 150.0
const LOG_W := 210.0

var main: Main
var root: Control
var top: PanelContainer
var bottom: HBoxContainer
var log_panel: PanelContainer
var overlay: HudOverlay

var floor_label: Label
var gold_label: Label
var hearts_label: Hearts
var boss_box: VBoxContainer
var boss_name: Label
var boss_bar: ProgressBar
var log_text: RichTextLabel

var avatar: TextureRect
var level_label: Label
var title_label: Label
var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var xp_text: Label
var debuff_label: Label
var stat_labels := {}
var slot_buttons := {}
var skill_boxes := {}
var potion_boxes := {}
var bag_count: Label

var _toasts: Array = []
## Sade görünüm: oyun alanı açık kalsın diye günlük, ekipman yuvaları, istatistikler ve çanta
## paneli gizlenir; can, tecrübe ve yetenekler kalır. TAB ile tam görünüme geçilir.
var compact := true
var _stat_grid: Control
var _slots_row: Control
var _bag_panel: Control
var _panels: Array[Control] = []
var _full_only: Array[Control] = []


func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top()
	_build_log()
	_build_bottom()
	_build_boss()
	overlay = HudOverlay.new()
	overlay.hud = self
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	var touch := TouchControls.new()
	touch.main = main
	root.add_child(touch)
	Log.added.connect(_on_log)
	Game.changed.connect(refresh)
	set_compact(compact)
	visible = false


func set_compact(on: bool) -> void:
	compact = on
	_stat_grid.visible = not on
	_slots_row.visible = not on
	_bag_panel.visible = not on
	log_panel.visible = not on
	bottom.anchor_right = 0.0 if on else 1.0
	bottom.offset_right = 700.0 if on else -6.0
	bottom.offset_top = -98.0 if on else -BOTTOM_H
	var tsb := top.get_theme_stylebox("panel") as StyleBoxFlat
	tsb.bg_color = Color(tsb.bg_color, 0.0 if on else 0.92)
	tsb.border_color = Color(tsb.border_color, 0.0 if on else 0.12)
	for pn in _panels:
		pn.self_modulate.a = 0.6 if on else 1.0
	for n in _full_only:
		n.visible = not on


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		set_compact(not compact)
		get_viewport().set_input_as_handled()


func _build_top() -> void:
	top = UiKit.panel(Color(0.04, 0.04, 0.06, 0.92), Color(0, 0.94, 1, 0.12))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, TOP_H)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	(top.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(0)
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	var logo := UiKit.tex_rect(load("res://assets/logo_small.png"), Vector2(28, 28), true)
	row.add_child(logo)
	_full_only.append(logo)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	floor_label = _badge(row, "ZİNDAN: 1", UiKit.CYAN)
	_full_only.append(floor_label.get_parent())
	gold_label = _badge(row, "0", UiKit.GOLD)
	hearts_label = Hearts.new()
	hearts_label.set_lives(3, 3)
	row.add_child(hearts_label)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer2)
	var menu := UiKit.button("MENÜ", 8)
	menu.pressed.connect(func(): main.screens.show_pause())
	row.add_child(menu)


func _badge(parent: Control, text: String, color: Color) -> Label:
	var p := UiKit.panel(Color(0.08, 0.08, 0.12, 0.9), Color(color.r, color.g, color.b, 0.3))
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 3
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 3
	(p.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(12)
	var l := UiKit.label(text, 10, true, color)
	p.add_child(l)
	parent.add_child(p)
	return l


func _build_log() -> void:
	log_panel = UiKit.panel(Color(0.05, 0.05, 0.08, 0.85))
	log_panel.anchor_left = 1.0
	log_panel.anchor_right = 1.0
	log_panel.anchor_bottom = 1.0
	log_panel.offset_left = -LOG_W
	log_panel.offset_top = TOP_H + 6
	log_panel.offset_bottom = -BOTTOM_H - 6
	log_panel.offset_right = -6
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(log_panel)
	var v := VBoxContainer.new()
	log_panel.add_child(v)
	v.add_child(UiKit.label("SAVAŞ GÜNLÜĞÜ", 8, true, UiKit.TEXT_DIM))
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.add_theme_font_override("normal_font", UiKit.MODERN)
	log_text.add_theme_font_size_override("normal_font_size", 11)
	v.add_child(log_text)


func _on_log(text: String, color: Color) -> void:
	var parts := text.split("] ", true, 1)
	log_text.append_text("[color=#666677]%s][/color] [color=#%s]%s[/color]\n" % [parts[0], color.to_html(false), parts[1] if parts.size() > 1 else ""])
	if log_text.get_paragraph_count() > Log.MAX_LINES + 1:
		log_text.remove_paragraph(0)


func _build_bottom() -> void:
	bottom = HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -BOTTOM_H
	bottom.offset_left = 6
	bottom.offset_right = -6
	bottom.offset_bottom = -6
	bottom.add_theme_constant_override("separation", 8)
	root.add_child(bottom)

	# KARAKTER
	var cp := UiKit.panel()
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp.size_flags_stretch_ratio = 1.0
	cp.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_child(cp)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 4)
	cp.add_child(cv)
	var ct := UiKit.label("KARAKTER", 10, true)
	cv.add_child(ct)
	_full_only.append(ct)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	cv.add_child(row)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 0)
	row.add_child(av)
	avatar = UiKit.tex_rect(null, Vector2(46, 46), true)
	av.add_child(avatar)
	level_label = UiKit.title_label("LVL 1", 12, UiKit.GOLD)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(level_label)
	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 1)
	row.add_child(bars)
	var hr := HBoxContainer.new()
	bars.add_child(hr)
	var hl := UiKit.title_label("Sağlık", 13, UiKit.TEXT_DIM)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(hl)
	hp_text = UiKit.title_label("100 / 100", 13)
	hr.add_child(hp_text)
	hp_bar = UiKit.bar(Color("ff4d4d"), 8)
	bars.add_child(hp_bar)
	var xr := HBoxContainer.new()
	bars.add_child(xr)
	var xl := UiKit.title_label("Tecrübe", 13, UiKit.TEXT_DIM)
	xl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xr.add_child(xl)
	xp_text = UiKit.title_label("0 / 100", 13)
	xr.add_child(xp_text)
	xp_bar = UiKit.bar(Color("b026ff"), 5)
	bars.add_child(xp_bar)
	title_label = UiKit.label("", 10, false, UiKit.GOLD)
	debuff_label = UiKit.label("", 10, false, Color("ff9d00"))
	var tr := HBoxContainer.new()
	tr.add_child(title_label)
	tr.add_child(debuff_label)
	bars.add_child(tr)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 4)
	cv.add_child(grid)
	_stat_grid = grid
	_panels.append(cp)
	for k in [["atk", "HASAR"], ["def", "DEFANS"], ["spd", "HIZ"], ["crit", "KRİTİK"], ["luck", "ŞANS"]]:
		var cell := UiKit.panel(Color(0.1, 0.1, 0.15, 0.6), Color(1, 1, 1, 0.05))
		(cell.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 2
		(cell.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 2
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cc := VBoxContainer.new()
		cc.add_theme_constant_override("separation", 0)
		cell.add_child(cc)
		var t := UiKit.label(k[1], 6, true, UiKit.TEXT_DIM)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cc.add_child(t)
		var v := UiKit.label("0", 9, true)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cc.add_child(v)
		stat_labels[k[0]] = v
		grid.add_child(cell)

	# EKİPMAN & YETENEKLER
	var ep := UiKit.panel()
	ep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ep.size_flags_stretch_ratio = 1.4
	ep.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_child(ep)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 6)
	ep.add_child(ev)
	var et := UiKit.label("EKİPMAN & YETENEKLER", 10, true)
	ev.add_child(et)
	_full_only.append(et)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 5)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	ev.add_child(slots)
	_slots_row = slots
	_panels.append(ep)
	for s: String in ItemData.SLOTS:
		var b := SlotButton.new()
		b.slot_label = ItemData.SLOT_LABELS[s]
		b.custom_minimum_size = Vector2(46, 46)
		b.pressed.connect(func(): _unequip(s))
		b.mouse_entered.connect(func(): _hover_slot(s))
		b.mouse_exited.connect(func(): main.screens.hide_tooltip())
		slots.add_child(b)
		slot_buttons[s] = b
	var sk := HBoxContainer.new()
	sk.add_theme_constant_override("separation", 6)
	ev.add_child(sk)
	for key in ["q", "r"]:
		var box := SkillBox.new()
		box.key = key.to_upper()
		box.custom_minimum_size = Vector2(0, 28)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sk.add_child(box)
		skill_boxes[key] = box
	for pk in [["1", "potion_red"], ["2", "potion_blue"]]:
		var pb := PotionBox.new()
		pb.key = pk[0]
		pb.type = pk[1]
		pb.custom_minimum_size = Vector2(54, 28)
		pb.tooltip_text = ItemData.CONSUMABLES[pk[1]][0]
		sk.add_child(pb)
		potion_boxes[pk[0]] = pb

	# ÇANTA
	var bp := UiKit.panel()
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp.size_flags_stretch_ratio = 1.0
	bp.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_child(bp)
	_bag_panel = bp
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	bp.add_child(bv)
	var bh := HBoxContainer.new()
	bv.add_child(bh)
	var bt := UiKit.label("ÇANTA", 10, true)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(bt)
	bag_count = UiKit.label("0/30", 8, true, UiKit.TEXT_DIM)
	bh.add_child(bag_count)
	var open := UiKit.button("ÇANTAYI AÇ  [I]", 9)
	open.custom_minimum_size = Vector2(0, 36)
	open.pressed.connect(func(): main.screens.show_bag())
	bv.add_child(open)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 8)
	bv.add_child(tools)
	var forge := UiKit.button("DEMİRCİ", 8, UiKit.GOLD)
	forge.pressed.connect(func(): main.screens.show_forge())
	tools.add_child(forge)
	var meta := UiKit.button("SIRALA", 8, UiKit.TEXT_DIM)
	meta.pressed.connect(sort_bag)
	tools.add_child(meta)


func _build_boss() -> void:
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_top = TOP_H + 8
	boss_box.offset_left = -230
	boss_box.offset_right = 230
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	boss_name = UiKit.title_label("ZİNDAN MUHAFIZI", 18, Color("ff4d4d"))
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_name)
	boss_bar = UiKit.bar(Color("ff3b30"), 12)
	boss_box.add_child(boss_bar)
	boss_box.visible = false


func show_boss(on: bool) -> void:
	boss_box.visible = on


func _unequip(slot: String) -> void:
	if main.player and main.player.unequip(slot):
		main.screens.hide_tooltip()
		refresh_bag()
	elif slot == "weapon":
		toast("SİLAH ÇIKARILAMAZ")


func _hover_slot(slot: String) -> void:
	if main.player == null:
		return
	var it: Dictionary = main.player.equipment[slot]
	if not it.is_empty():
		main.screens.show_tooltip(UiKit.item_tooltip(it, {}, Game.barter) + "\n[color=#a0a0b5]Tık: çıkar[/color]")


func sort_bag() -> void:
	if main.player == null:
		return
	main.player.inventory.sort_custom(func(a, b):
		var ca := 1 if ItemData.is_gear(a) else 0
		var cb := 1 if ItemData.is_gear(b) else 0
		if ca != cb:
			return ca > cb
		return ItemData.RARITY_ORDER.get(a.rarity, 9) < ItemData.RARITY_ORDER.get(b.rarity, 9))
	refresh_bag()


func refresh_bag() -> void:
	if main.player:
		bag_count.text = "%d/%d" % [main.player.inventory.size(), Player.BAG_SIZE]
	main.screens.refresh_bag()


func toast(text: String) -> void:
	_toasts.append([text, 180])


## Fare bir arayüz paneli üzerinde değilse true (saldırı tıklaması dünyaya gider).
func mouse_over_world() -> bool:
	var h := root.get_viewport().gui_get_hovered_control()
	return h == null or h == root or h == overlay


func refresh() -> void:
	if main.player == null:
		return
	floor_label.text = "ZİNDAN: %d" % Game.floor_number
	gold_label.text = str(Game.gold)
	hearts_label.set_lives(Game.lives, maxi(3, Game.max_lives))
	avatar.texture = Sprites.tex(Game.style + "_idle1")
	refresh_bag()


func _process(_delta: float) -> void:
	if not visible or main.player == null:
		return
	var p := main.player
	hp_bar.max_value = p.max_hp()
	hp_bar.value = p.hp
	hp_text.text = "%d / %d" % [p.hp, p.max_hp()]
	xp_bar.max_value = p.next_xp
	xp_bar.value = p.xp
	xp_text.text = "%d / %d" % [p.xp, p.next_xp]
	level_label.text = "LVL %d" % p.level
	title_label.text = Game.title()
	var d := ""
	if p.burn > 0: d += " YANIK %d ·" % ceili(p.burn / 60.0)
	if p.poison > 0: d += " ZEHİR %d ·" % ceili(p.poison / 60.0)
	if p.slow > 0: d += " YAVAŞ %d ·" % ceili(p.slow / 60.0)
	if p.frozen > 0: d += " DONDU ·"
	elif p.frost > 0: d += " BUZ %d/%d ·" % [p.frost, Player.FROST_MAX]
	if p.rooted > 0: d += " KÖK ·"
	if p.void_burn > 0: d += " YOKLUK %d ·" % ceili(p.void_burn / 60.0)
	if p.blood_mark > 0: d += " KAN İŞARETİ ·"
	if p.heavy > 0: d += " AĞIR ·"
	if p.warp > 0: d += " ÇARPIK ·"
	if p.crystal > 0: d += " KRİSTAL %d ·" % p.crystal
	if p.shrine_left > 0: d += " SUNAK %d ·" % ceili(p.shrine_left / 60.0)
	if p.speed_potion > 0: d += " HIZ %d ·" % ceili(p.speed_potion / 60.0)
	debuff_label.text = d.trim_suffix(" ·")
	stat_labels.atk.text = str(p.total_atk())
	stat_labels.def.text = str(p.total_def())
	stat_labels.spd.text = "%.1f" % p.total_spd()
	stat_labels.crit.text = "%d%%" % int(p.total_crit())
	stat_labels.luck.text = "%d%%" % int(p.base.luck)
	for s: String in slot_buttons:
		slot_buttons[s].item = p.equipment[s]
		slot_buttons[s].queue_redraw()
	var st: Dictionary = ClassData.STYLES[p.style]
	skill_boxes.q.setup(st.q, p.q_cd, p.q_cd_max)
	skill_boxes.r.setup(st.r, p.r_cd, p.r_cd_max)
	for pk: String in potion_boxes:
		potion_boxes[pk].set_count(p.potion_count(potion_boxes[pk].type))
	var b := main.boss
	if b and is_instance_valid(b):
		boss_name.text = b.display_name + ("" if b.phase == 1 else " — FAZ %d" % b.phase)
		boss_bar.max_value = b.max_hp
		boss_bar.value = maxi(0, b.hp)
		(boss_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Boss.PHASE_COLORS[b.phase - 1]
	var fade := main.combat_bonus
	top.modulate.a = lerpf(1.0, 0.25, fade)
	log_panel.modulate.a = lerpf(1.0, 0.08, fade)
	bottom.modulate.a = lerpf(1.0, 0.18, fade)
	for t in _toasts:
		t[1] -= 1
	_toasts = _toasts.filter(func(t): return t[1] > 0)
	overlay.queue_redraw()


# ── İç sınıflar ──────────────────────────────────────────────────────

class SlotButton extends Button:
	var item := {}
	var slot_label := ""

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		flat = true
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c := Color(1, 1, 1, 0.12)
		if not item.is_empty():
			c = ItemData.RARITY_COLORS.get(item.rarity, Color.WHITE)
		draw_rect(r, Color(0.08, 0.08, 0.12, 0.9))
		if not item.is_empty() and item.rarity != "common":
			draw_rect(r.grow(-2), Color(c.r, c.g, c.b, 0.15))
		_dashed(r, c)
		if item.is_empty():
			var w := UiKit.PIXEL.get_string_size(slot_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
			draw_string(UiKit.PIXEL, Vector2((size.x - w) / 2, size.y / 2 + 3), slot_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 1, 0.25))
		else:
			var t := Sprites.tex(ItemData.icon_key(item))
			if t:
				draw_texture_rect(t, r.grow(-6), false)

	func _dashed(r: Rect2, c: Color) -> void:
		draw_rect(r, Color(c.r, c.g, c.b, 0.6), false, 1.0)


class SkillBox extends Control:
	var key := "Q"
	var title := ""
	var cd := 0
	var cd_max := 1

	func setup(t: String, c: int, m: int) -> void:
		title = t
		cd = c
		cd_max = maxi(1, m)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.08, 0.08, 0.12, 0.9))
		draw_rect(r, Color(0.85, 0.66, 0.35, 0.22), false, 1.0)
		draw_rect(Rect2(6, 6, 16, 16), Color(0.25, 0.25, 0.32))
		draw_string(UiKit.TITLE, Vector2(9, 20), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.GOLD)
		draw_string(UiKit.TITLE, Vector2(30, 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.TEXT if cd == 0 else UiKit.TEXT_DIM)
		if cd > 0:
			var k := float(cd) / cd_max
			draw_rect(Rect2(0, 0, size.x * k, size.y), Color(0, 0, 0, 0.55))
			var s := "%d" % ceili(cd / 60.0)
			draw_string(UiKit.TITLE, Vector2(size.x - 26, 20), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.GOLD)


## İksir kısayolu rozeti: tuş (1 / 2), iksir simgesi ve adet.
class PotionBox extends Control:
	var key := "1"
	var type := "potion_red"
	var count := 0

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func set_count(n: int) -> void:
		if n != count:
			count = n
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.08, 0.08, 0.12, 0.9))
		draw_rect(r, Color(0.85, 0.66, 0.35, 0.22), false, 1.0)
		draw_string(UiKit.TITLE, Vector2(6, 20), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.GOLD)
		var t := Sprites.tex("item_" + type)
		if t:
			draw_texture_rect(t, Rect2(17, 3, 22, 22), false, Color(1, 1, 1, 1.0 if count > 0 else 0.3))
		draw_string(UiKit.TITLE, Vector2(38, 21), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.TEXT if count > 0 else UiKit.TEXT_DIM)
