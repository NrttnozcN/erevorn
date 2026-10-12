class_name ItemData
## Eşya tanımları ve üretimi (entities.js:230-526). Eşyalar sözlük olarak taşınır:
## {type, kind, rarity, name, desc, stats{}, effect{}, count, sockets[], socket_limit}

const SLOTS := ["helmet", "necklace", "earrings", "ring", "weapon", "armor", "gloves", "boots"]
const SLOT_LABELS := {"helmet": "MİĞFER", "necklace": "KOLYE", "earrings": "KÜPE", "ring": "YÜZÜK",
	"weapon": "SİLAH", "armor": "ZIRH", "gloves": "ELDİVEN", "boots": "ÇİZME"}
const GEAR_KINDS := ["sword", "bow", "staff", "shield", "armor", "helmet", "necklace", "earrings", "ring", "gloves", "boots"]
const RARITY_COLORS := {"common": Color("8e9297"), "rare": Color("00b0ff"), "epic": Color("a020f0"),
	"legendary": Color("ff8c00"), "mythic": Color("ff1f3d")}
const RARITY_LABELS := {"common": "SIRADAN", "rare": "NADİR", "epic": "DESTANSI", "legendary": "EFSANEVİ", "mythic": "KIZIL"}
const RARITY_ORDER := {"mythic": 0, "legendary": 1, "epic": 2, "rare": 3, "common": 4}
const STONES := ["ruby", "sapphire", "emerald", "obsidian"]

const DEFS := {
	"sword_common": ["Paslı Kılıç", {"atk": 3}, {}, "Eski bir askerden kalma basit demir kılıç."],
	"sword_rare": ["Buzul Kılıcı", {"atk": 7}, {"type": "frost", "chance": 0.35, "duration": 45}, "Düşmanları donduran soğuk buzul çeliği."],
	"sword_legendary": ["Efsanevi Alev Kılıcı", {"atk": 15}, {"type": "burn", "chance": 0.45, "duration": 240}, "Cehennem ateşinde dövülmüş, dokunanı yakan kılıç!"],
	"bow_common": ["Sıradan Avcı Yayı", {"atk": 4, "crit": 2}, {}, "Esnek ahşap avcı yayı."],
	"bow_rare": ["Kadim Buzul Yayı", {"atk": 8, "crit": 4}, {"type": "frost", "chance": 0.28, "duration": 36}, "Düşmana çarptığında buz saçan donmuş yay."],
	"bow_legendary": ["Efsanevi Alev Yayı", {"atk": 17, "crit": 7}, {"type": "burn", "chance": 0.35, "duration": 220}, "Göklerden alevli oklar saçan kadim yay!"],
	"staff_common": ["Tahta Asa", {"atk": 4, "hp": 10}, {"type": "focus", "chance": 0.25, "q": 12, "w": 18}, "Büyü enerjisi yayan tahta asa."],
	"staff_rare": ["Kristal Asa", {"atk": 9, "hp": 25, "def": 2}, {"type": "focus", "chance": 0.45, "q": 22, "w": 32}, "Mavi kristal büyü asası."],
	"staff_legendary": ["Efsanevi Ejderha Asası", {"atk": 16, "hp": 50, "def": 4, "crit": 5}, {"type": "burn_focus", "chance": 0.55, "duration": 220, "q": 28, "w": 42}, "Ejder gözü taşıyan efsanevi sihir asası!"],
	"shield_common": ["Tahta Kalkan", {"def": 4, "hp": 8}, {}, "Basit tahta kalkan."],
	"shield_rare": ["Demir Kale Kalkanı", {"def": 9, "hp": 20}, {}, "Ağır demir savunma kalkanı."],
	"shield_legendary": ["Efsanevi Titan Kalkanı", {"def": 16, "hp": 40, "atk": 2}, {}, "Devlerin zırhından dökülen ezeli kalkan!"],
	"armor_common": ["Deri Yelek", {"def": 2}, {}, "Hafif ve basit deri koruma."],
	"armor_rare": ["Şövalye Zırhı", {"def": 6}, {}, "Demirden yapılmış dayanıklı şövalye zırhı."],
	"armor_legendary": ["Kraliyet Zırhı", {"def": 13}, {}, "Efsanevi kralların kuşanıp savaştığı kutsal zırh!"],
	"helmet_common": ["Deri Kapşon", {"def": 1}, {}, "Hafif deri miğfer."],
	"helmet_rare": ["Çelik Vizörlü Miğfer", {"def": 3}, {}, "Tüm yüzü kaplayan ağır demir kask."],
	"helmet_legendary": ["Efsanevi Güneş Tacı", {"def": 6, "crit": 5}, {}, "Kutsal ışıkla parıldayan kraliyet tacı."],
	"necklace_common": ["Kemik Kolye", {"hp": 12}, {}, "Kemik parçalarından yapılmış basit tılsım."],
	"necklace_rare": ["Safir Koruyucu Kolye", {"hp": 25, "def": 1}, {}, "Göz alıcı mavi safir kolye."],
	"necklace_legendary": ["Efsanevi Ejder Amuleti", {"hp": 50, "atk": 3}, {}, "Ortasında ejderha kanı parıldayan muska!"],
	"earrings_common": ["Bronz Halka Küpe", {"crit": 2}, {}, "Sıradan bronz halkalar."],
	"earrings_rare": ["Zümrüt Damla Küpe", {"crit": 5, "spd": 0.1}, {}, "Zarif zümrütten yeşil küpeler."],
	"earrings_legendary": ["Efsanevi Kozmik Küpe", {"crit": 9, "spd": 0.25}, {}, "Yıldız tozuyla şekillenmiş rünlü takılar!"],
	"ring_common": ["Bakır Mühür Yüzüğü", {"atk": 1}, {}, "Basit bakır halka."],
	"ring_rare": ["Safir Rün Yüzüğü", {"atk": 3, "crit": 3}, {}, "Mavi büyü rünleri işlenmiş yüzük."],
	"ring_legendary": ["Efsanevi Kaos Yüzüğü", {"atk": 6, "crit": 6, "def": 2}, {}, "Boyutlar arası gücü taşıyan kaos rünü!"],
	"gloves_common": ["Deri Bileklik Eldiven", {"atk": 1}, {}, "Basit deri bilek koruyucular."],
	"gloves_rare": ["Çelik Plakalı Eldiven", {"atk": 2, "def": 2}, {}, "Plakalarla kaplı koruyucu eldiven."],
	"gloves_legendary": ["Efsanevi Titan Pençesi", {"atk": 5, "def": 3, "crit": 3}, {}, "Kadim devlerin gücüyle kuşanmış pençeler!"],
	"boots_common": ["Köylü Çizmesi", {"spd": 0.15}, {}, "Yıpranmış deri seyahat botları."],
	"boots_rare": ["Gezgin Çelik Dizlikleri", {"spd": 0.35, "def": 2}, {}, "Hem korur hem hızlandırır."],
	"boots_legendary": ["Efsanevi Hermes Kanatları", {"spd": 0.7, "crit": 4}, {}, "Havada süzülüyormuş gibi hissettiren botlar!"],
}

const CONSUMABLES := {
	"gold": ["Altın Para", "common", ""],
	"potion_red": ["Sağlık İksiri", "rare", "Sağlığını anında +30 yeniler."],
	"potion_blue": ["Hız İksiri", "rare", "10 saniyeliğine hızını %35 artırır."],
	"gold_key": ["Altın Anahtar", "legendary", "Kilitli hazine sandığını açar."],
	"stone_shard_ruby": ["Yakut Parçası", "rare", "10 parça birleşince güç taşı olur."],
	"stone_shard_sapphire": ["Safir Parçası", "rare", "10 parça birleşince güç taşı olur."],
	"stone_shard_emerald": ["Zümrüt Parçası", "rare", "10 parça birleşince güç taşı olur."],
	"stone_shard_obsidian": ["Obsidyen Parçası", "rare", "10 parça birleşince güç taşı olur."],
	"stone_ruby": ["Yakut Taşı", "epic", "Silaha takılır. +3 saldırı."],
	"stone_sapphire": ["Safir Taşı", "epic", "Silaha takılır. +4% kritik."],
	"stone_emerald": ["Zümrüt Taşı", "epic", "Zırha takılır. +18 maksimum can."],
	"stone_obsidian": ["Obsidyen Taşı", "epic", "Zırha takılır. +2 defans."],
}

const ENCHANTS := [
	["Kan Emici", "lifesteal", 1], ["Keskin", "atk", 2], ["Sağlam", "def", 2], ["Hız Rünü", "spd", 0.2],
	["Canlılık", "hp", 15], ["Kâhin", "crit", 4], ["Demir Yumruk", "atk", 3], ["Aslan Yüreği", "hp", 25],
]

const STAT_LABELS := {"atk": "Hasar", "def": "Defans", "hp": "Can", "crit": "% Kritik", "spd": "Hız"}


## Yeni eşya üretir. Ekipmanlarda %30 efsun şansı var (eski oyundaki gibi).
static func make(type: String, enchant := true) -> Dictionary:
	var item := {"type": type, "count": 1, "stats": {}, "effect": {}, "sockets": [], "socket_limit": 0}
	if DEFS.has(type):
		var d: Array = DEFS[type]
		var parts := type.split("_")
		item.kind = parts[0]
		item.rarity = parts[1]
		item.name = d[0]
		item.stats = (d[1] as Dictionary).duplicate()
		item.effect = (d[2] as Dictionary).duplicate()
		item.desc = d[3]
		item.socket_limit = 1 if item.rarity == "legendary" else 0
	elif CONSUMABLES.has(type):
		var c: Array = CONSUMABLES[type]
		item.kind = type
		item.name = c[0]
		item.rarity = c[1]
		item.desc = c[2]
	else:
		push_warning("Bilinmeyen eşya: %s" % type)
		item.kind = type
		item.name = type
		item.rarity = "common"
		item.desc = ""
	if enchant and is_gear(item) and randf() <= 0.30:
		_enchant(item)
	return item


static func _enchant(item: Dictionary) -> void:
	var e: Array = ENCHANTS.pick_random()
	item.name = "[%s] %s" % [e[0], item.name]
	item.enchanted = true
	if e[1] == "lifesteal":
		if item.kind in ["sword", "bow", "staff"]:
			item.effect = {"type": "lifesteal", "chance": 0.35, "rate": 0.10}
	else:
		item.stats[e[1]] = item.stats.get(e[1], 0) + e[2]


static func is_gear(item: Dictionary) -> bool:
	return item.get("kind", "") in GEAR_KINDS or item.get("kind", "") == "dagger"


static func slot_of(item: Dictionary) -> String:
	match item.get("kind", ""):
		"sword", "bow", "staff", "dagger":
			return "weapon"
		"shield", "armor":
			return "armor"
		"helmet", "necklace", "earrings", "ring", "gloves", "boots":
			return item.kind
	return ""


static func is_stackable(item: Dictionary) -> bool:
	var t: String = item.get("type", "")
	return t.begins_with("potion_") or t == "gold_key" or t.begins_with("stone_")


## Normal saldırı efektinin rengi: silahın nadirliği.
const FX_COLORS := {
	"common": Color(0.92, 0.94, 1.0),
	"rare": Color(0.45, 0.72, 1.0),
	"epic": Color(0.76, 0.45, 1.0),
	"legendary": Color(1.0, 0.78, 0.3),
	"mythic": Color(1.0, 0.2, 0.24),
}


static func fx_color(rarity: String) -> Color:
	return FX_COLORS.get(rarity, FX_COLORS.common)


## Eşyanın simgesi (game.js:1555-1576).
static func icon_key(item: Dictionary) -> String:
	var t: String = item.get("type", "")
	if t.begins_with("stone_") and ResourceLoader.exists("res://assets/sprites/item_%s.png" % t):
		return "item_" + t
	if t.begins_with("stone_shard_") or t == "gold_key" or t == "gold":
		return "item_gold"
	if t.begins_with("stone_"):
		return "item_ring_legendary"
	if t.begins_with("potion_"):
		return "item_" + t
	if is_gear(item):
		var r: String = item.rarity
		if r == "mythic" and not ResourceLoader.exists("res://assets/sprites/item_%s_mythic.png" % item.kind):
			r = "legendary"
		return "item_%s_%s" % [item.kind, r]
	return "item_gold"


## Rastgele ekipman: kat ve şansa göre nadirlik (entities.js:1391-1468).
static func random_gear(floor_number: int, luck: float) -> Dictionary:
	var kind: String = GEAR_KINDS.pick_random()
	var leg := 0.0
	var rare := 0.16
	if floor_number >= 50:
		leg = 0.04; rare = 0.34
	elif floor_number >= 25:
		leg = 0.025; rare = 0.28
	elif floor_number >= 10:
		leg = 0.01; rare = 0.22
	if floor_number >= 10:
		leg += luck / 2200.0
	rare += luck / 800.0
	return gear_roll(leg, rare, kind)


static func gear_roll(leg: float, rare: float, kind := "") -> Dictionary:
	if kind == "":
		kind = GEAR_KINDS.pick_random()
	var roll := randf()
	var rarity := "common"
	if roll < leg:
		rarity = "legendary"
	elif roll < rare:
		rarity = "rare"
	return make("%s_%s" % [kind, rarity])


static func sell_price(item: Dictionary, barter: bool) -> int:
	var t: String = item.get("type", "")
	if t.begins_with("potion_"):
		return 4
	if t.begins_with("stone_shard_"):
		return 2
	if t.begins_with("stone_"):
		return 35
	var base: int = {"common": 3, "rare": 8, "epic": 14, "legendary": 22, "mythic": 60}.get(item.get("rarity", "common"), 3)
	return int(base * 1.2) if barter else base


static func stat_text(stats: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k: String in ["atk", "def", "hp", "crit", "spd"]:
		if stats.has(k) and stats[k] != 0:
			var v = stats[k]
			var s := ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".") if v is float else str(v)
			parts.append("+%s %s" % [s, STAT_LABELS[k]])
	return ", ".join(parts)


static func effect_text(effect: Dictionary) -> String:
	if effect.is_empty():
		return ""
	var ch := int(round(effect.get("chance", 0) * 100))
	match effect.type:
		"frost": return "Buz: %%%d şansla dondurur" % ch
		"burn": return "Alev: %%%d şansla yakar" % ch
		"focus": return "Odak: %%%d şansla yetenek beklemesini kısaltır" % ch
		"burn_focus": return "Alev Odağı: %%%d şansla yakar ve beklemeyi kısaltır" % ch
		"lifesteal": return "Kan Emici: %%%d şansla vurduğunun %%10'unu emer" % ch
	return ""
