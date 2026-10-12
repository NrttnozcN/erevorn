class_name EnemyData
## Eski oyundaki düşman tabloları (entities.js:792-1192, game.js:525-553).
## Değerler eski oyunla aynı: hız piksel/kare, bekleme süreleri kare (60 kare = 1 sn).

# hp, atk, spd, xp, gold [rand_çarpanı, taban], debuff, cd (saldırı bekleme), size, sprite
# İsteğe bağlı: ranged (uzaktan), draw (çizim büyüklüğü çarpanı; çarpışmayı etkilemez)
const TYPES := {
	"slime":        {"name": "Jöle Balçık",       "hp": 15,  "atk": 5,  "spd": 0.9,  "xp": 10,  "gold": [3, 3],   "debuff": "slow",   "cd": 90,  "size": 48, "sprite": "slime"},
	"slime_fire":   {"name": "Lav Balçığı",       "hp": 25,  "atk": 12, "spd": 1.2,  "xp": 20,  "gold": [4, 5],   "debuff": "burn",   "cd": 90,  "size": 48, "sprite": "slime_fire"},
	"slime_shadow": {"name": "Gölge Balçığı",     "hp": 40,  "atk": 18, "spd": 1.5,  "xp": 35,  "gold": [5, 7],   "debuff": "poison", "cd": 90,  "size": 48, "sprite": "slime_shadow", "draw": 1.7},
	"skeleton":     {"name": "Yitik Muhafız",     "hp": 30,  "atk": 10, "spd": 1.1,  "xp": 25,  "gold": [4, 4],   "debuff": "",       "cd": 90,  "size": 48, "sprite": "skeleton"},
	# Bölge 1'in muhafız ailesi (yeni kanon): kalkanlı ağır, okçu uzaktan, çürümüş zehirli.
	"muhafiz_kalkan": {"name": "Kalkanlı Muhafız", "hp": 45, "atk": 8,  "spd": 0.75, "xp": 28,  "gold": [4, 5],   "debuff": "slow",   "cd": 100, "size": 52, "sprite": "muhafiz_kalkan"},
	"muhafiz_okcu":   {"name": "Okçu Muhafız",     "hp": 18, "atk": 7,  "spd": 1.0,  "xp": 22,  "gold": [4, 4],   "debuff": "",       "cd": 120, "size": 48, "sprite": "muhafiz_okcu", "ranged": true},
	"muhafiz_curuk":  {"name": "Çürümüş Muhafız",  "hp": 26, "atk": 11, "spd": 1.25, "xp": 24,  "gold": [3, 5],   "debuff": "poison", "cd": 90,  "size": 48, "sprite": "muhafiz_curuk"},
	# Bölge 2'nin (Gölge Mağarası) yeni düşmanları: uzaktan büyücü ve sıçrayan kristal örümcek.
	"cultist":        {"name": "Tarikat Müridi",   "hp": 24, "atk": 11, "spd": 0.9,  "xp": 32,  "gold": [5, 6],   "debuff": "slow",   "cd": 130, "size": 48, "sprite": "cultist", "ranged": true},
	"crystal_spider": {"name": "Kristal Örümceği", "hp": 34, "atk": 14, "spd": 1.25, "xp": 34,  "gold": [5, 6],   "debuff": "poison", "cd": 90,  "size": 52, "sprite": "crystal_spider"},
	# Bölge 3'ün (Goblin Yurdu) yeni düşmanları: totem diken şaman, bomba atan bombacı, zincirli dev kölebaşı.
	# totem: şamanın diktiği kemik totemi (hareket etmez, 2 vuruşta kırılır; ödül vermez).
	"goblin_saman":   {"name": "Goblin Şamanı",    "hp": 30, "atk": 12, "spd": 0.95, "xp": 38,  "gold": [5, 7],   "debuff": "poison", "cd": 140, "size": 48, "sprite": "goblin_saman", "ranged": true},
	"goblin_bombaci": {"name": "Goblin Bombacısı", "hp": 28, "atk": 16, "spd": 1.25, "xp": 36,  "gold": [5, 7],   "debuff": "poison", "cd": 150, "size": 48, "sprite": "goblin_bombaci", "ranged": true},
	"kolebasi":       {"name": "Kölebaşı",         "hp": 120, "atk": 22, "spd": 0.6, "xp": 75,  "gold": [7, 9],   "debuff": "slow",   "cd": 110, "size": 60, "sprite": "kolebasi", "draw": 1.45},
	# Bölge 4'ün (Alev Krallığı) yeni düşmanları: zikzak uçup atılan kor impi, yere vurup lav gölü bırakan
	# ve vurduktan sonra soğuyup sertleşen lav golemi, rün dairelerinden alev sütunu çıkaran kül rahibi.
	"kor_impi":       {"name": "Kor İmpi",         "hp": 14, "atk": 10, "spd": 1.9,  "xp": 22,  "gold": [3, 5],   "debuff": "burn",   "cd": 100, "size": 40, "sprite": "kor_impi", "draw": 1.25},
	"lav_golemi":     {"name": "Lav Golemi",       "hp": 150, "atk": 24, "spd": 0.5, "xp": 85,  "gold": [7, 9],   "debuff": "burn",   "cd": 120, "size": 60, "sprite": "lav_golemi", "draw": 1.45},
	"kul_rahibi":     {"name": "Kül Rahibi",       "hp": 36, "atk": 14, "spd": 0.85, "xp": 44,  "gold": [5, 7],   "debuff": "burn",   "cd": 170, "size": 48, "sprite": "kul_rahibi", "ranged": true, "draw": 1.35},
	# Bölge 5'in (Donmuş Tundra) yeni düşmanları: pençesiyle kırağı yığını biriktiren buz zombisi, okları geri
	# yansıtan ayna kabuklu ve ağ atan buz aynası örümceği, önü zırhlı ve hücum eden buz ayısı.
	"buz_zombisi":    {"name": "Buz Zombisi",      "hp": 30, "atk": 12, "spd": 0.7,  "xp": 30,  "gold": [4, 5],   "debuff": "frost",  "cd": 100, "size": 48, "sprite": "buz_zombisi", "draw": 1.3},
	"buz_aynasi":     {"name": "Buz Aynası Örümceği", "hp": 44, "atk": 15, "spd": 1.0, "xp": 48, "gold": [5, 7],   "debuff": "frost",  "cd": 100, "size": 52, "sprite": "buz_aynasi", "draw": 1.55},
	"buz_ayisi":      {"name": "Buz Ayısı",        "hp": 150, "atk": 24, "spd": 0.75, "xp": 90, "gold": [7, 9],   "debuff": "frost",  "cd": 120, "size": 60, "sprite": "buz_ayisi", "draw": 1.6},
	# Bölge 6'nın (Orman Tapınağı) yeni düşmanları: kuşatıp atılan diken tazısı, spor bulutu salan mantar, kök tuzağı
	# kuran ve kök salıp yenilenen muhafız, diken tohumu atan ve müttefiklerine sarmaşık kalkanı ören rahibe.
	"diken_tazisi":   {"name": "Diken Tazısı",     "hp": 26, "atk": 14, "spd": 1.6,  "xp": 30,  "gold": [4, 5],   "debuff": "poison", "cd": 100, "size": 44, "sprite": "diken_tazisi", "draw": 1.35},
	"spor_mantari":   {"name": "Spor Mantarı",     "hp": 48, "atk": 10, "spd": 0.55, "xp": 42,  "gold": [5, 6],   "debuff": "poison", "cd": 120, "size": 52, "sprite": "spor_mantari", "draw": 1.45},
	"kok_muhafizi":   {"name": "Kök Muhafızı",     "hp": 170, "atk": 26, "spd": 0.6, "xp": 95,  "gold": [7, 9],   "debuff": "poison", "cd": 120, "size": 60, "sprite": "kok_muhafizi", "draw": 1.6},
	"diken_rahibesi": {"name": "Diken Rahibesi",   "hp": 38, "atk": 15, "spd": 0.85, "xp": 46,  "gold": [5, 7],   "debuff": "poison", "cd": 160, "size": 48, "sprite": "diken_rahibesi", "ranged": true, "draw": 1.35},
	# Bölge 7'nin (Şeytan Kalesi) yeni düşmanları: oyuncunun arkasında portal açıp çıkan gölge yürüyücü, kan işareti
	# koyan yazıcı, taş uykusundan uyanıp pike dalan gargoyl. Debuff: yokluk yanığı (iyileşmeyi keser).
	"golge_yuruyucu": {"name": "Sis Tutsağı",   "hp": 40, "atk": 20, "spd": 1.25, "xp": 48,  "gold": [5, 7],   "debuff": "void",   "cd": 110, "size": 48, "sprite": "golge_yuruyucu", "draw": 1.5},
	"kan_yazicisi":   {"name": "Valen Sorgucusu",     "hp": 44, "atk": 16, "spd": 0.85, "xp": 52,  "gold": [6, 8],   "debuff": "void",   "cd": 260, "size": 48, "sprite": "kan_yazicisi", "ranged": true, "draw": 1.4},
	"gargoyl":        {"name": "Kaynamış Asker",          "hp": 120, "atk": 28, "spd": 0.9, "xp": 90,  "gold": [7, 9],   "debuff": "void",   "cd": 120, "size": 56, "sprite": "gargoyl", "draw": 1.55},
	# Bölge 8'in (Gökyüzü Kalesi) yeni düşmanları: ışık mızrakları ve ayna kopyalı bilge, yerçekimi rünlü ve önden
	# kalkanlı rün bekçisi, rüzgârla iten ve süzülen gök muhafızı. Debuff: ağırlık (yavaşlık + atılamama).
	"konsey_bilgesi": {"name": "Konsey Bilgesi",   "hp": 46, "atk": 20, "spd": 0.8,  "xp": 60,  "gold": [6, 8],   "debuff": "",       "cd": 200, "size": 48, "sprite": "konsey_bilgesi", "ranged": true, "draw": 1.5},
	"run_bekcisi":    {"name": "Rün Bekçisi",      "hp": 200, "atk": 30, "spd": 0.55, "xp": 110, "gold": [8, 10], "debuff": "heavy",  "cd": 130, "size": 60, "sprite": "run_bekcisi", "draw": 1.6},
	"gok_muhafizi":   {"name": "Gök Muhafızı",     "hp": 70, "atk": 24, "spd": 1.2,  "xp": 70,  "gold": [6, 8],   "debuff": "",       "cd": 110, "size": 52, "sprite": "gok_muhafizi", "draw": 1.55},
	# Bölge 9'un (Yokluk Alemi) yeni düşmanları: taş halkası fırlatan yörünge taşı, çarpıtan bakışlı göz, yırtıktan
	# fırlayıp ısıran boşluk yiyici. Debuff: çarpıklık (yön tuşları ters). Zaman Yankısı burada Arktan'ın Yansıması olur.
	"yorunge_tasi":   {"name": "Yörünge Taşı",     "hp": 90, "atk": 28, "spd": 0.7,  "xp": 80,  "gold": [7, 9],   "debuff": "",       "cd": 120, "size": 56, "sprite": "yorunge_tasi", "draw": 1.5},
	"yokluk_gozu":    {"name": "Yokluk Gözü",      "hp": 40, "atk": 22, "spd": 0.9,  "xp": 55,  "gold": [6, 8],   "debuff": "warp",   "cd": 200, "size": 44, "sprite": "yokluk_gozu", "ranged": true, "draw": 1.3},
	"bosluk_yiyici":  {"name": "Boşluk Yiyici",    "hp": 110, "atk": 32, "spd": 1.0, "xp": 95,  "gold": [7, 9],   "debuff": "warp",   "cd": 120, "size": 56, "sprite": "bosluk_yiyici", "draw": 1.55},
	# Bölge 10'un (Kara Taht) düşmanları: Kârun'un rün klonları (Lore Bible: taht odasında yalnızca onlar bulunur).
	# Kılıçlı hızlı atılır, büyücü rün küresi yelpazesi atar, dev kristal hattı açar ve kristal kabuğa bürünür.
	"run_klon_kilic": {"name": "Rün Klonu: Kılıç", "hp": 70, "atk": 34, "spd": 1.4,  "xp": 90,  "gold": [8, 10], "debuff": "crystal", "cd": 100, "size": 48, "sprite": "run_klon_kilic", "draw": 1.5},
	"run_klon_buyucu": {"name": "Rün Klonu: Büyücü", "hp": 60, "atk": 30, "spd": 0.85, "xp": 95, "gold": [8, 10], "debuff": "crystal", "cd": 170, "size": 48, "sprite": "run_klon_buyucu", "ranged": true, "draw": 1.5},
	"run_klon_dev":   {"name": "Rün Klonu: Dev",   "hp": 240, "atk": 40, "spd": 0.6, "xp": 140, "gold": [9, 11], "debuff": "crystal", "cd": 130, "size": 60, "sprite": "run_klon_dev", "draw": 1.65},
	# Lore Bible, bölge 2: ruhları sökülmüş kütüphane hizmetkârları. Bölge 4: ateşe teslim olmuş eski nöbetçi demirci.
	"ruhsuz_katip":   {"name": "Ruhsuz Kâtip",     "hp": 22, "atk": 10, "spd": 0.9,  "xp": 28,  "gold": [4, 6],   "debuff": "slow",   "cd": 150, "size": 48, "sprite": "ruhsuz_katip", "ranged": true, "draw": 1.35},
	"zincirli_arsivci": {"name": "Zincirli Arşivci", "hp": 60, "atk": 15, "spd": 0.6, "xp": 45,  "gold": [5, 7],   "debuff": "slow",   "cd": 120, "size": 54, "sprite": "zincirli_arsivci", "draw": 1.5},
	"murekkep_hayaleti": {"name": "Mürekkep Hayaleti", "hp": 20, "atk": 12, "spd": 1.7, "xp": 26, "gold": [3, 5],   "debuff": "slow",   "cd": 100, "size": 44, "sprite": "murekkep_hayaleti", "draw": 1.3},
	"ocak_nobetcisi": {"name": "Ocak Nöbetçisi",   "hp": 130, "atk": 26, "spd": 0.55, "xp": 85, "gold": [7, 9],   "debuff": "burn",   "cd": 120, "size": 58, "sprite": "ocak_nobetcisi", "draw": 1.55},
	"totem":          {"name": "Kemik Totemi",     "hp": 2,  "atk": 0,  "spd": 0.0,  "xp": 0,   "gold": [0, 0],   "debuff": "",       "cd": 999, "size": 40, "sprite": "prop_z3_totem"},
	"goblin":       {"name": "Goblin Savaşçısı",  "hp": 22,  "atk": 9,  "spd": 1.7,  "xp": 20,  "gold": [4, 5],   "debuff": "",       "cd": 90,  "size": 48, "sprite": "goblin"},
	"zombie":       {"name": "Çürümüş Zombi",     "hp": 50,  "atk": 14, "spd": 0.65, "xp": 30,  "gold": [4, 5],   "debuff": "poison", "cd": 90,  "size": 48, "sprite": "zombie"},
	"spider":       {"name": "Zehir Örümceği",    "hp": 28,  "atk": 8,  "spd": 1.9,  "xp": 22,  "gold": [3, 4],   "debuff": "poison", "cd": 90,  "size": 48, "sprite": "spider"},
	"troll":        {"name": "Kaya Trolü",        "hp": 90,  "atk": 24, "spd": 0.6,  "xp": 60,  "gold": [6, 8],   "debuff": "slow",   "cd": 120, "size": 56, "sprite": "troll"},
	"witch":        {"name": "Gölge Cadısı",      "hp": 36,  "atk": 17, "spd": 0.85, "xp": 42,  "gold": [5, 7],   "debuff": "burn",   "cd": 90,  "size": 48, "sprite": "witch"},
	"ice_golem":    {"name": "Buz Golemi",        "hp": 75,  "atk": 19, "spd": 0.75, "xp": 52,  "gold": [6, 8],   "debuff": "slow",   "cd": 90,  "size": 56, "sprite": "ice_golem"},
	"demon":        {"name": "Alev Şeytanı",      "hp": 58,  "atk": 25, "spd": 1.4,  "xp": 65,  "gold": [7, 9],   "debuff": "burn",   "cd": 90,  "size": 48, "sprite": "demon"},
	"void_wraith":  {"name": "Yokluk Hayaleti",   "hp": 50,  "atk": 21, "spd": 2.1,  "xp": 70,  "gold": [7, 9],   "debuff": "poison", "cd": 90,  "size": 48, "sprite": "void_wraith"},
	"dragon_spawn": {"name": "Ejder Yavrusu",     "hp": 88,  "atk": 36, "spd": 1.7,  "xp": 98,  "gold": [10, 11], "debuff": "burn",   "cd": 90,  "size": 56, "sprite": "dragon_spawn"},
	"abyss_lord":   {"name": "Uçurum Lordu",      "hp": 100, "atk": 35, "spd": 1.6,  "xp": 110, "gold": [10, 12], "debuff": "poison", "cd": 55,  "size": 48, "sprite": "abyss_lord"},
	"time_echo":    {"name": "ZAMAN YANKISI",     "hp": 0,   "atk": 0,  "spd": 1.6,  "xp": 150, "gold": [10, 15], "debuff": "slow",   "cd": 70,  "size": 48, "sprite": "skeleton"},
}

## Her bölgede çıkan türler (game.js:525-536). Bölge 1 yeni kanonda Yitik Muhafızlar; bölge 2 Gölge Mağarası;
## bölge 3 Goblin Yurdu (zombi ve örümcek temaya uymadığı için çıkarıldı); bölge 4 Alev Krallığı
## (örümcek, trol ve cadı temaya uymadığı için çıkarıldı; boyalı Alev Şeytanı kaldı); bölge 5 Donmuş Tundra
## (trol ve cadı çıkarıldı, Buz Golemi kaldı); bölge 6 Orman Tapınağı (eski golem, şeytan ve cadı çıkarıldı).
const ZONE_POOLS := [
	["skeleton", "skeleton", "muhafiz_kalkan", "muhafiz_okcu", "muhafiz_curuk"],
	["ruhsuz_katip", "ruhsuz_katip", "cultist", "zincirli_arsivci", "murekkep_hayaleti", "crystal_spider"],
	["goblin", "goblin", "goblin_saman", "goblin_bombaci", "kolebasi"],
	["kor_impi", "kor_impi", "lav_golemi", "kul_rahibi", "ocak_nobetcisi"],
	["buz_zombisi", "buz_zombisi", "buz_aynasi", "buz_ayisi", "ice_golem"],
	["diken_tazisi", "diken_tazisi", "spor_mantari", "kok_muhafizi", "diken_rahibesi"],
	["golge_yuruyucu", "golge_yuruyucu", "kan_yazicisi", "gargoyl", "demon"],
	["konsey_bilgesi", "konsey_bilgesi", "run_bekcisi", "gok_muhafizi", "gok_muhafizi"],
	["yorunge_tasi", "yokluk_gozu", "yokluk_gozu", "bosluk_yiyici", "yorunge_tasi"],
	["run_klon_kilic", "run_klon_kilic", "run_klon_buyucu", "run_klon_buyucu", "run_klon_dev"],
]

const BOSS_NAMES := [
	"KARDEŞ — KAPININ ÖNÜNDE BIRAKILAN",
	"GÖLGE DOKUYUCU — KÂRUN'UN ÇIRAĞI",
	"KÖLE EFENDİSİ — OCAKLARIN ŞEFİ",
	"ATEŞ KOMUTANI — İLK OCAĞIN BEKÇİSİ",
	"DONMUŞ HAN — BUZUN LANETİ",
	"LYRA — DİKENLERİN BEKÇİSİ",
	"YANIK YÜZLÜ KOMUTAN — VALEN'İN ZİNDANCISI",
	"DEMİR MASKELİ USTA — KÖR ADALET",
	"BOŞLUK — KAPININ ÖTESİNDEKİ İRADE",
	"GÖK BÖRÜ — KALBİN BEKÇİSİ",
]
const KARUN_NAME := "KÂRUN — SONSUZLUĞUN EFENDİSİ"

const ZONE_NAMES := [
	"Mühür Kuyusu", "Fısıltı Tünelleri", "Demir Kölelerinin Ocakları", "İlk Ocak", "Ak Buz Kurganları",
	"Ulu Kayın", "Valen'in Kara Zindanları", "Gök Kurultayı", "Kapının Ötesi", "Kara Taht",
]

## Bölge atmosfer rengi ve nabız (world.js:377-388).
const ZONE_TINT := [
	[Color8(80, 0, 120, 20), false], [Color8(40, 0, 80, 36), true], [Color8(100, 60, 0, 26), false],
	[Color8(200, 85, 20, 38), true], [Color8(100, 180, 220, 31), false], [Color8(80, 60, 110, 16), false],
	[Color8(20, 0, 20, 46), true], [Color8(200, 200, 255, 18), false], [Color8(60, 0, 100, 51), true],
	[Color8(180, 100, 0, 41), true],
]

const DEBUFF_COLORS := {"burn": Color("ff6a00"), "poison": Color("9cff2e"), "slow": Color("b026ff"), "frost": Color("8fd8ff"), "": Color("ffdddd")}


static func zone_of(floor_number: int) -> int:
	return clampi(ceili(floor_number / 10.0), 1, 10)


## Goblin Yurdu ailesi: totem bunları iyileştirir, şaman yanında bunlardan biri yoksa kaçar.
const GOBLIN_KIN := ["goblin", "goblin_saman", "goblin_bombaci", "kolebasi"]


static func pool_for_floor(floor_number: int) -> Array:
	return ZONE_POOLS[zone_of(floor_number) - 1]


static func scale_for_floor(floor_number: int) -> float:
	return minf(5.0, 1.0 + sqrt(maxf(0.0, floor_number - 1)) * 0.4)


static func boss_scale(floor_number: int) -> float:
	return minf(8.0, 1.0 + sqrt(maxf(0.0, floor_number - 1)) * 0.65)
