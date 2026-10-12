class_name TouchControls
extends Control
## Dokunmatik kontroller (mobile.js): solda sanal joystick, sağda SALDIRI, Q, R, E ve atılma düğmeleri.
## Yalnızca dokunmatik ekranlı cihazlarda görünür.

const STICK_R := 70.0

var main: Main
var _stick_touch := -1
var _stick_center := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _held := {}
var _buttons := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = Main.is_touch_device()


func _layout() -> void:
	# Ebeveyn boyutu sıfır kalabiliyor: düğmeler doğrudan görünür ekran boyutuna yerleşir.
	size = get_viewport_rect().size
	var vs := size
	# Sağ alt köşede başparmak kümesi: SALDIRI en büyük, çevresinde yetenekler; E ve F biraz solda.
	_buttons = {
		"attack": [Vector2(vs.x - 110, vs.y - 110), 58.0, "SALDIRI"],
		"dash": [Vector2(vs.x - 240, vs.y - 60), 34.0, "ATIL"],
		"q": [Vector2(vs.x - 250, vs.y - 160), 34.0, "Q"],
		"r": [Vector2(vs.x - 170, vs.y - 235), 34.0, "R"],
		"v": [Vector2(vs.x - 70, vs.y - 245), 34.0, "T"],
		"f": [Vector2(vs.x - 330, vs.y - 110), 32.0, "F"],
		"e": [Vector2(vs.x - 330, vs.y - 200), 32.0, "E"],
	}



## Joystick'in yuvası: sol alt, alttaki can panelinin üstünde.
func stick_home() -> Vector2:
	return Vector2(150, size.y - 190)


func _input(event: InputEvent) -> void:
	# Açılışta dokunmatik algılanamadıysa ilk dokunuşta kontroller açılır (bazı tarayıcılar geç bildirir).
	if event is InputEventScreenTouch and event.pressed and not visible:
		visible = true
		main.use_touch_layout()
	if not visible or main.state != "playing":
		return
	_layout()
	if event is InputEventScreenTouch:
		if event.pressed:
			for k: String in _buttons:
				var b: Array = _buttons[k]
				if event.position.distance_to(b[0]) < b[1] + 10:
					_press(k, event.index)
					get_viewport().set_input_as_handled()
					return
			# Konuşma kutusuna dokunmak metni ilerletir (klavyedeki E).
			var dr: Rect2 = main.hud.overlay.dialogue_rect
			if dr.has_area() and dr.grow(12).has_point(event.position) and main.dialogue.waiting_for_input():
				main.dialogue.advance()
				get_viewport().set_input_as_handled()
				return
			if event.position.x < size.x * 0.4 and _stick_touch < 0:
				# Sabit joystick: yuvasına yakın dokunuş yuvadan başlar; sol yarıda başka yer de olur (kayan).
				_stick_touch = event.index
				_stick_center = stick_home() if event.position.distance_to(stick_home()) < STICK_R * 1.8 else event.position
				_stick_pos = _stick_center + (event.position - _stick_center).limit_length(STICK_R)
				var v0 := (_stick_pos - _stick_center) / STICK_R
				main.touch_move = v0 if v0.length() > 0.22 else Vector2.ZERO
		else:
			if event.index == _stick_touch:
				_stick_touch = -1
				main.touch_move = Vector2.ZERO
			for k: String in _held.keys():
				if _held[k] == event.index:
					_held.erase(k)
			main.touch_attack = _held.has("attack")
	elif event is InputEventScreenDrag and event.index == _stick_touch:
		_stick_pos = _stick_center + (event.position - _stick_center).limit_length(STICK_R)
		var v := (_stick_pos - _stick_center) / STICK_R
		main.touch_move = v if v.length() > 0.22 else Vector2.ZERO
	queue_redraw()


func _press(k: String, index: int) -> void:
	_held[k] = index
	match k:
		"attack":
			main.touch_attack = true
			_aim_nearest()
		"q":
			_aim_nearest()
			main.touch_q = true
		"r":
			_aim_nearest()
			main.touch_r = true
		"f":
			_aim_nearest()
			main.touch_f = true
		"v":
			_aim_nearest()
			main.touch_v = true
		"e":
			if main.dialogue.waiting_for_input():
				main.dialogue.advance()
			else:
				main.interact()
		"dash":
			main.player._try_dash(main.touch_move if main.touch_move != Vector2.ZERO else Vector2.from_angle(main.player.aim))


## Dokunmatikte nişan: en yakın düşmana, yoksa yürüme yönüne.
func _aim_nearest() -> void:
	var best: Node2D = null
	var bd := 400.0
	for e in main.targets():
		var d: float = e.position.distance_to(main.player.position)
		if d < bd:
			bd = d
			best = e
	main.aim_override = true
	if best:
		main.touch_aim = best.position - main.player.position
	elif main.touch_move != Vector2.ZERO:
		main.touch_aim = main.touch_move * 100
	else:
		main.touch_aim = Vector2.from_angle(main.player.aim) * 100


func _process(_d: float) -> void:
	if visible:
		if main.touch_attack:
			_aim_nearest()
		queue_redraw()


func _draw() -> void:
	if main == null or main.state != "playing":
		return
	_layout()
	# Joystick her zaman görünür: taban, halka ve topuz (dokunulunca topuz parmağı izler).
	var c := _stick_center if _stick_touch >= 0 else stick_home()
	var knob := _stick_pos if _stick_touch >= 0 else c
	draw_circle(c, STICK_R, Color(1, 1, 1, 0.1 if _stick_touch >= 0 else 0.06))
	draw_arc(c, STICK_R, 0, TAU, 48, Color(0, 0.94, 1, 0.5 if _stick_touch >= 0 else 0.3), 2.5, true)
	draw_circle(knob, 28, Color(0, 0.94, 1, 0.4 if _stick_touch >= 0 else 0.22))
	draw_arc(knob, 28, 0, TAU, 32, Color(0.7, 0.97, 1, 0.6), 1.5, true)
	for k: String in _buttons:
		var b: Array = _buttons[k]
		var on := _held.has(k)
		draw_circle(b[0], b[1], Color(0, 0.94, 1, 0.35 if on else 0.15))
		draw_arc(b[0], b[1], 0, TAU, 32, Color(0, 0.94, 1, 0.6), 2)
		var w := UiKit.PIXEL.get_string_size(b[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(UiKit.PIXEL, b[0] + Vector2(-w / 2, 4), b[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
