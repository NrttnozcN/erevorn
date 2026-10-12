class_name ClassData
## Arktan'ın üç dövüş tarzı (eski oyundaki sınıflar, game.js:369-408) ve seviye kartları.

const STYLES := {
	"warrior": {
		"title": "SAVAŞÇI", "desc": "Dayanıklı yakın dövüş ustası", "color": Color("ff4d4d"),
		"bonus": {"def": 8, "atk": 5, "maxHp": 20},
		"weapon": "sword_common", "armor": "shield_common",
		"dash": [52, 9, 2.8], "draw_scale": 1.65, "camera_lerp": 0.09,
		"q": "KIRICI SAVURMA", "r": "GÖK KILICI",
		"bars": [["GÜÇ", 0.8], ["DAYANIKLILIK", 1.0], ["CAN", 0.8]],
	},
	"ranger": {
		"title": "OKÇU", "desc": "Çevik ve hızlı menzilli savaşçı", "color": Color("39d353"),
		"bonus": {"crit": 12, "spd": 0.6, "atk": 4},
		"weapon": "bow_common", "armor": "",
		"dash": [26, 5, 4.5], "draw_scale": 1.65, "camera_lerp": 0.96,
		"q": "DELİCİ OK", "r": "OK YAĞMURU",
		"bars": [["ÇEVİKLİK", 1.0], ["KRİTİK", 0.8], ["UZAKLIK", 0.8]],
	},
	"mage": {
		"title": "BÜYÜCÜ", "desc": "Gizemli büyülerin hakimi", "color": Color("b26bff"),
		"bonus": {"atk": 9, "crit": 6, "maxHp": 25},
		"weapon": "staff_common", "armor": "",
		"dash": [60, 7, 2.6], "draw_scale": 1.22, "camera_lerp": 0.16,
		"q": "ATEŞ TOPU", "r": "METEOR",
		"bars": [["ZEKÂ", 1.0], ["BÜYÜ GÜCÜ", 1.0], ["MANA", 1.0]],
	},
}

## Seviye atlayınca çıkan 16 kart (game.js:1221-1359).
const UPGRADES := [
	{"id": "atk", "title": "ALEV GÜCÜ", "desc": "+4 Hasar", "rarity": "rare"},
	{"id": "def", "title": "ÇELİK DERİ", "desc": "+3 Defans", "rarity": "rare"},
	{"id": "hp", "title": "DEV YÜREĞİ", "desc": "+25 Maks Can ve tam iyileşme", "rarity": "legendary"},
	{"id": "spd", "title": "RÜZGAR ADIMI", "desc": "+0.4 Hız", "rarity": "epic"},
	{"id": "crit", "title": "TAVŞAN AYAĞI", "desc": "+7% Kritik", "rarity": "legendary"},
	{"id": "lifesteal", "title": "VAMPİR DOKUNUŞU", "desc": "Her öldürmede +3 can", "rarity": "legendary"},
	{"id": "atkspd", "title": "EL ÇABUKLUĞU", "desc": "Saldırılar daha hızlı", "rarity": "rare"},
	{"id": "balanced", "title": "DENGELİ GÜÇ", "desc": "+2 Hasar, +2 Defans, +10 Can", "rarity": "rare"},
	{"id": "ironheart", "title": "DEMİR YÜREK", "desc": "+40 Maks Can, -0.1 Hız", "rarity": "epic"},
	{"id": "lethal", "title": "ÖLÜMCÜL DARBE", "desc": "+5 Hasar, +5% Kritik", "rarity": "legendary"},
	{"id": "berserker", "title": "BERK ÇILGINLIK", "desc": "+6 Hasar, -10 Maks Can", "rarity": "epic"},
	{"id": "turtle", "title": "KAPLUMBAĞA ZIRHI", "desc": "+5 Defans, -0.2 Hız", "rarity": "rare"},
	{"id": "fullheal", "title": "KUTSAL İYİLEŞME", "desc": "Tam iyileşme, zehir ve yanık temizlenir", "rarity": "legendary"},
	{"id": "dashmaster", "title": "GÖLGE ADIMI", "desc": "Atılma beklemesi çok kısalır", "rarity": "epic"},
	{"id": "barter", "title": "PAZARLIKÇI", "desc": "Dükkan %20 ucuz, satışlar %20 pahalı", "rarity": "rare"},
	{"id": "luck", "title": "ŞANS TANRISI", "desc": "+10 Şans", "rarity": "rare"},
]

## Ruh taşı kalıcı geliştirmeleri (game.js:1123-1211).
const META := [
	{"id": "atk", "title": "Güçlü Başlangıç", "desc": "+2 Hasar", "cost": 20, "max": 5},
	{"id": "def", "title": "Demir Deri", "desc": "+2 Defans", "cost": 20, "max": 5},
	{"id": "hp", "title": "Kahraman Yüreği", "desc": "+20 Maks Can", "cost": 25, "max": 4},
	{"id": "crit", "title": "Keskin Göz", "desc": "+3% Kritik", "cost": 30, "max": 3},
	{"id": "life", "title": "Ekstra Can", "desc": "+1 başlangıç canı", "cost": 50, "max": 1},
]

## Dükkandaki "altınla antrenman" kartları.
const TRAINING := [
	{"id": "atk", "title": "Kılıç Talimi", "desc": "+1 Hasar", "base": 75},
	{"id": "def", "title": "Kalkan Talimi", "desc": "+1 Defans", "base": 80},
	{"id": "hp", "title": "Dayanıklılık", "desc": "+8 Maks Can", "base": 90},
	{"id": "crit", "title": "Odak Talimi", "desc": "+2% Kritik", "base": 115},
]
