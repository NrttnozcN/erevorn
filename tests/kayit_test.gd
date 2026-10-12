extends Node
## Yarım koşu kaydı: kata inişte kaydedilir; oyun kapanıp açılınca "DEVAM ET" aynı katta, aynı oyuncuyla sürdürür.
## Oyun bitince (ölüm) kayıt silinir.

var fails := 0


func _ready() -> void:
	DeathCinematic.enabled = false
	Game.save_path = "user://test_kayit_devam.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(20)
	_check(not Game.has_run(), "başta yarım koşu yok")
	main.screens.close()
	main.start_run("mage")
	main.tutorial_step = -1
	await _wait(10)
	_check(Game.has_run(), "ilk katta kayıt alındı")
	Game.floor_number = 22
	main.next_floor()
	Game.gold = 777
	main.player.level = 9
	main.player.base.atk = 99
	main.player.add_to_bag(ItemData.make("armor_legendary"))
	var bag := main.player.inventory.size()
	main.next_floor()
	await _wait(10)
	# "Oyunu kapat": main'i at, yeni bir main aç.
	main.queue_free()
	await _wait(5)
	Game.gold = 0
	Game.floor_number = 1
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(20)
	_check(Game.has_run(), "yeniden açılışta yarım koşu var")
	_check(int(Game.saved_run().oyun.floor_number) == 24, "kayıtlı kat 24")
	main.continue_run()
	await _wait(10)
	_check(main.state == "playing", "devam edildi")
	_check(Game.floor_number == 24, "kat 24 (%d)" % Game.floor_number)
	_check(Game.style == "mage" and main.player.style == "mage", "dövüş tarzı büyücü")
	_check(Game.gold == 777, "altın 777 (%d)" % Game.gold)
	_check(main.player.level == 9 and main.player.base.atk == 99, "oyuncu seviyesi ve gücü geri geldi")
	_check(main.player.inventory.size() == bag, "çanta geri geldi")
	_check(main.boss == null and not main.enemies.is_empty(), "kat yeniden kuruldu")
	# Ölüm: koşu biter, kayıt silinir; kalıcı ruh taşları durur.
	Game.lives = 1
	main.player.died.emit()
	await _wait(2)
	_check(main.state == "gameover" and not Game.has_run(), "oyun bitince yarım koşu silindi")
	Game.load_save()
	print("KAYIT: " + ("TAMAM" if fails == 0 else "%d HATA" % fails))
	get_tree().quit(1 if fails > 0 else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  HATA ") + what)
	if not ok:
		fails += 1


func _wait(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
