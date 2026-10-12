class_name RotateHint
extends CanvasLayer
## Telefon dikey tutulursa ekranı kaplayan uyarı: oyun yatay oynanır.

var _rect: ColorRect
var _label: Label


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.03, 0.03, 0.05, 0.97)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	_label = Label.new()
	_label.text = "Telefonu yan çevir\n\nErevorn yatay oynanır."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	_rect.add_child(_label)
	visible = false


func _process(_d: float) -> void:
	var s := get_viewport().get_visible_rect().size
	visible = Main.is_touch_device() and s.y > s.x
