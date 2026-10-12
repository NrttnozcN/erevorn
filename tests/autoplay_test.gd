extends Node
## Otomatik oynayan test: her dövüş tarzıyla birkaç kat iner (yakın düşmana yürür, saldırır,
## yetenek kullanır, sandık açar, portala girer). Çalışma hatası çıkmamalı.

var main: Main


func _ready() -> void:
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var reached := {}
	for style in ["warrior", "ranger", "mage"]:
		main.start_run(style)
		main.player.god_mode = true
		for frame in 5000:
			await get_tree().physics_frame
			_settle()
			_drive()
			if Game.floor_number >= 4:
				break
		reached[style] = Game.floor_number
		print(style, ": kat ", Game.floor_number, ", seviye ", main.player.level, ", öldürme ", Game.kills, ", altın ", Game.gold, ", çanta ", main.player.inventory.size())
	var ok := reached.values().all(func(f): return f >= 3)
	print("SONUÇ: ", "GEÇTİ" if ok else "KALDI")
	get_tree().quit(0 if ok else 1)


func _settle() -> void:
	if main.state == "upgrade":
		main.player.apply_upgrade("atk")
		main.screens.close()
	elif main.state in ["story", "shop", "bag", "forge"]:
		main.screens.close()
	if main.dialogue.is_open():
		main.dialogue.advance()


func _drive() -> void:
	if main.state != "playing":
		return
	var p := main.player
	var targets := main.targets()
	if targets.is_empty():
		for o in main.others:
			if not is_instance_valid(o):
				continue
			if o is Chest and not o.opened and not o.locked:
				p.position = o.position + Vector2(10, 0)
				main.interact()
		p.position = main.portal.position + Vector2(6, 0)
		main.interact()
		return
	var t: Node2D = targets[0]
	var d := p.position.distance_to(t.position)
	main.aim_override = true
	main.touch_aim = t.position - p.position
	if d > 60:
		main.touch_move = (t.position - p.position).normalized()
		if Engine.get_physics_frames() % 240 == 0:
			p.position = t.position + Vector2(-50, 0)
	else:
		main.touch_move = Vector2.ZERO
	main.touch_attack = d < 300
	main.touch_q = Engine.get_physics_frames() % 200 == 0
	main.touch_r = Engine.get_physics_frames() % 330 == 0
