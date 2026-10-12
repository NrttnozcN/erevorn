class_name Actor
extends Node2D
## Tüm dünya nesnelerinin tabanı. Main her fizik karesinde (60 Hz) tick() çağırır;
## oyun duraklatıldığında (dükkan, çanta, seviye kartı...) tick çağrılmaz.

var main: Main
var removed := false


func tick() -> void:
	pass


func remove() -> void:
	removed = true
	queue_free()
