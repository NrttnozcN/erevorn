extends Node
## Ekransız duman testi: her dövüş tarzıyla bir koşu başlatır, katı temizler, portaldan iner,
## boss katına atlar, bossu öldürür ve ölüm akışını dener. Çalıştırma:
## godot --headless --path . res://tests/smoke_test.tscn

var main: Main
var errors: Array = []


func _ready() -> void:
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	for style in ["warrior", "ranger", "mage"]:
		await _run(style)
	print("SONUÇ: ", "GEÇTİ" if errors.is_empty() else "KALDI " + str(errors))
	get_tree().quit(0 if errors.is_empty() else 1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		errors.append(msg)
		print("HATA: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		_settle()


## Seviye kartı ya da hikaye penceresi açıldıysa kapatıp oyuna döner.
func _settle() -> void:
	if main.state in ["upgrade", "story"]:
		main.screens.close()


func _run(style: String) -> void:
	main.screens.close()
	main.start_run(style)
	await _frames(5)
	_check(main.state == "playing", style + ": oyun başlamadı")
	_check(main.enemies.size() > 0, style + ": düşman yok")
	_check(main.world.is_walkable(main.player.position), style + ": oyuncu duvarda")
	# Temel saldırı ve yetenekler hata vermeden çalışmalı
	var e: Enemy = main.enemies[0]
	main.player.position = e.position + Vector2(-30, 0)
	main.player.q_cd = 0
	main.player.r_cd = 0
	main.player.use_q()
	main.player.use_r()
	main.player._try_attack()
	await _frames(120)
	# Kalan düşmanları öldür, portal açılmalı
	for en in main.enemies.duplicate():
		if is_instance_valid(en) and not en.removed:
			en.take_damage(99999)
	await _frames(3)
	_check(main.enemies.is_empty(), style + ": düşmanlar silinmedi")
	_check(main.portal.active, style + ": portal açılmadı")
	main.player.position = main.portal.position
	main.interact()
	await _frames(3)
	_check(Game.floor_number == 2, style + ": 2. kata inilmedi (kat %d, durum %s)" % [Game.floor_number, main.state])
	# Boss katı
	Game.floor_number = 9
	main.next_floor()
	main.screens.close()
	main.state = "playing"
	await _frames(3)
	_check(main.boss != null, style + ": boss yok")
	_kill_non_boss()
	_check(Game.quest.id == "hunter" and not Game.quest.done, style + ": boss görevi boss ölmeden tamamlandı")
	if main.boss:
		main.boss.take_damage(int(main.boss.max_hp * 0.6))
		await _frames(2)
		# Bölge muhafızlarının kendi faz eşikleri var (%50 / %20): %60 hasarda en az faz 2.
		_check(main.boss.phase >= 2, style + ": boss faz atlamadı (%d)" % main.boss.phase)
		main.boss.take_damage(999999)
		await _frames(3)
		_check(main.boss == null and main.portal.active, style + ": boss ölümü portalı açmadı")
		_check(Game.quest.done, style + ": boss ölünce boss görevi tamamlanmadı")
	if style == "warrior":
		await _all_boss_floors()
	# Dükkan, çanta ve demirci açılıp kapanmalı
	main.state = "playing"
	main.screens.show_shop()
	_check(main.state == "shop", style + ": dükkan açılmadı")
	main.screens.close()
	main.screens.show_bag()
	_check(main.state == "bag", style + ": çanta açılmadı")
	main.screens.close()
	main.screens.show_forge()
	main.screens.close()
	main.player.add_to_bag(ItemData.make("ring_rare"))
	_check(main.player.equip(main.player.inventory.size() - 1) == "", style + ": yüzük kuşanılamadı")
	# Ölüm: canlar bitince oyun sonu
	Game.lives = 1
	main.player.invincible = 0
	main.player.take_damage(999999)
	await _frames(3)
	_check(main.state == "gameover", style + ": oyun sonu ekranı gelmedi (%s)" % main.state)


## Katın bossu dışındaki tüm düşmanları (normal + çağrılmış yardımcılar) öldürür.
func _kill_non_boss() -> void:
	for e in main.enemies.duplicate():
		if is_instance_valid(e) and not e.removed:
			main.on_enemy_killed(e)


## Her boss katında (10-100) BOSS AVCISI görevi yalnızca boss ölünce tamamlanmalı.
func _all_boss_floors() -> void:
	for f in range(20, 101, 10):
		Game.floor_number = f - 1
		main.next_floor()
		main.screens.close()
		main.state = "playing"
		await _frames(3)
		_check(main.boss != null, "kat %d: boss yok" % f)
		if main.boss == null:
			continue
		# Faz 2'ye sok: Ignis gibi bosslar burada yardımcı çağırır.
		main.boss.take_damage(int(main.boss.max_hp * 0.6))
		await _frames(3)
		var minions := main.enemies.filter(func(e): return is_instance_valid(e) and e.is_minion).size()
		_kill_non_boss()
		_check(not Game.quest.done, "kat %d: boss görevi boss ölmeden tamamlandı" % f)
		main.boss.take_damage(999999)
		await _frames(3)
		_check(Game.quest.done, "kat %d: boss ölünce görev tamamlanmadı" % f)
		print("kat %d boss görevi: tamam (öldürülen yardımcı: %d)" % [f, minions])
