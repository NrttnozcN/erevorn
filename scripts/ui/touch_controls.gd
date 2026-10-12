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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()


func _layout() -> void:
	var vs := size
	_buttons = {
		"attack": [Vector2(vs.x - 110, vs.y - 230), 56.0, "SALDIRI"],
		"q": [Vector2(vs.x - 230, vs.y - 270), 34.0, "Q"],
		"r": [Vector2(vs.x - 200, vs.y - 350), 34.0, "R"],
		"e": [Vector2(vs.x - 100, vs.y - 350), 34.0, "E"],
		"dash": [Vector2(vs.x - 240, vs.y - 180), 34.0, "ATIL"],
	}


func _input(event: InputEvent) -> void:
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
			if event.position.x < size.x * 0.4 and _stick_touch < 0:
				_stick_touch = event.index
				_stick_center = event.position
				_stick_pos = event.position
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
	if _stick_touch >= 0:
		draw_circle(_stick_center, STICK_R, Color(1, 1, 1, 0.08))
		draw_arc(_stick_center, STICK_R, 0, TAU, 40, Color(0, 0.94, 1, 0.4), 2)
		draw_circle(_stick_pos, 26, Color(0, 0.94, 1, 0.35))
	else:
		var c := Vector2(150, size.y - 220)
		draw_arc(c, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.12), 2)
	for k: String in _buttons:
		var b: Array = _buttons[k]
		var on := _held.has(k)
		draw_circle(b[0], b[1], Color(0, 0.94, 1, 0.35 if on else 0.15))
		draw_arc(b[0], b[1], 0, TAU, 32, Color(0, 0.94, 1, 0.6), 2)
		var w := UiKit.PIXEL.get_string_size(b[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(UiKit.PIXEL, b[0] + Vector2(-w / 2, 4), b[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
