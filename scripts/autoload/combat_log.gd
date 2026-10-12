extends Node
## Sağdaki "SAVAŞ GÜNLÜĞÜ". En fazla 40 satır tutar.

signal added(text: String, color: Color)

const MAX_LINES := 40
const COLORS := {"system": Color("8a8a9a"), "hit": Color("00f0ff"), "hurt": Color("ff5a8a"),
	"loot": Color("ffd700"), "level": Color("b026ff"), "death": Color("ff3b30")}

var lines: Array = []


func add(text: String, kind := "system") -> void:
	var stamp := Time.get_time_string_from_system()
	var color: Color = COLORS.get(kind, COLORS.system)
	lines.append([stamp, text, color])
	if lines.size() > MAX_LINES:
		lines.pop_front()
	added.emit("[%s] %s" % [stamp, text], color)


func clear() -> void:
	lines.clear()
