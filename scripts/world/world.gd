class_name World
extends Node2D
## Zindan haritası (world.js:91-338): rastgele odalar, oda sırasına göre L koridorlar,
## her 10. katta sabit boss arenası. 48 piksellik karolar.

const TILE := 48
const TEX_TILES := 4
enum { FLOOR = 0, WALL = 1, MOSS = 2 }

var width := 32
var height := 23
var map := PackedInt32Array()
var rooms: Array[Rect2i] = []
var explored := {}
var player_spawn := Vector2.ZERO
var portal_pos := Vector2.ZERO
var enemy_spawns: Array[Vector2] = []
var chest_spawns: Array[Vector2] = []
var boss_spawn := Vector2.ZERO
## Bölge (1-10). Dokular ve eşyalar tile_*_z<bölge> / prop_z<bölge>_* varsa onlardan seçilir.
var zone := 1

var _layer: TileMapLayer
var _shade: WallShade


func _ready() -> void:
	_layer = TileMapLayer.new()
	_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_layer)
	_shade = WallShade.new()
	_shade.world = self
	add_child(_shade)


func generate(floor_number: int) -> void:
	rooms.clear()
	explored.clear()
	enemy_spawns.clear()
	chest_spawns.clear()
	_set_zone(EnemyData.zone_of(floor_number))
	if floor_number % 10 == 0:
		_generate_boss()
	else:
		_generate_normal(floor_number)
	_paint()


func _generate_normal(f: int) -> void:
	width = 30 + mini(10, f * 2)
	height = 22 + mini(8, f)
	map = PackedInt32Array()
	map.resize(width * height)
	map.fill(WALL)
	var target := 6 + mini(5, f)
	for _attempt in target * 2:
		if rooms.size() >= target:
			break
		var w := randi_range(5, 8)
		var h := randi_range(5, 8)
		var r := Rect2i(randi_range(1, width - w - 2), randi_range(1, height - h - 2), w, h)
		var overlaps := false
		for o in rooms:
			if r.intersects(o):
				overlaps = true
				break
		if overlaps:
			continue
		rooms.append(r)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_put(x, y, MOSS if randf() < 0.12 else FLOOR)
	for i in rooms.size() - 1:
		var a := _center(rooms[i])
		var b := _center(rooms[i + 1])
		for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
			_carve(x, a.y)
		for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
			_carve(b.x, y)
	player_spawn = _tile_center(_center(rooms[0]))
	portal_pos = _tile_center(_center(rooms[rooms.size() - 1]))
	for i in range(1, rooms.size()):
		var r := rooms[i]
		if randf() < 0.55:
			chest_spawns.append(_random_interior(r))
		var count := mini(5, randi_range(1, 2) + f / 12)
		for _n in count:
			enemy_spawns.append(_random_interior(r))


func _generate_boss() -> void:
	width = 24
	height = 20
	map = PackedInt32Array()
	map.resize(width * height)
	map.fill(WALL)
	var start := Rect2i(2, 8, 4, 4)
	var arena := Rect2i(9, 3, 12, 13)
	for r in [start, arena]:
		rooms.append(r)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_put(x, y, FLOOR)
	for x in range(4, 11):
		_put(x, 10, FLOOR)
	player_spawn = _tile_center(Vector2i(4, 10))
	boss_spawn = _tile_center(Vector2i(15, 9))
	portal_pos = _tile_center(Vector2i(19, 9))


## Bölgenin kendi boyalı dokusu varsa (ör. tile_floor_z2) onu, yoksa bölge 1 dokusunu döndürür.
func tile_key(base: String) -> String:
	var k := "%s_z%d" % [base, zone]
	return k if Sprites.tex(k) != null else base


## Bölgeye özel boyalı zemin var mı? (main.gd çift renklendirmeyi önlemek için bakar.)
func has_zone_tiles() -> bool:
	return tile_key("tile_floor") != "tile_floor"


## Atlas yalnızca kullanılan doku seti değişince yeniden kurulur.
func _set_zone(z: int) -> void:
	zone = z
	var keys := [tile_key("tile_floor"), tile_key("tile_wall"), tile_key("tile_floor_moss")]
	if _layer.tile_set == null or _layer.get_meta("keys", []) != keys:
		_layer.tile_set = _build_tileset(keys)
		_layer.set_meta("keys", keys)


func _carve(x: int, y: int) -> void:
	if get_tile(x, y) == WALL:
		_put(x, y, MOSS if randf() < 0.08 else FLOOR)


func _put(x: int, y: int, v: int) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		map[y * width + x] = v


func get_tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height:
		return WALL
	return map[y * width + x]


func is_walkable(p: Vector2) -> bool:
	return get_tile(floori(p.x / TILE), floori(p.y / TILE)) != WALL


## Oyuncunun 8 noktalı daire testi (world.js:319-338).
func circle_free(p: Vector2, r: float) -> bool:
	var d := r * 0.7
	for o in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r), Vector2(d, d), Vector2(-d, d), Vector2(d, -d), Vector2(-d, -d)]:
		if not is_walkable(p + o):
			return false
	return true


## X ve Y ayrı çözülür, duvar boyunca kayılır.
func move_circle(p: Vector2, delta: Vector2, r: float) -> Vector2:
	var nx := Vector2(p.x + delta.x, p.y)
	if circle_free(nx, r):
		p = nx
	var ny := Vector2(p.x, p.y + delta.y)
	if circle_free(ny, r):
		p = ny
	return p


## Düşmanlar yalnızca merkez noktasını test eder.
func move_point(p: Vector2, delta: Vector2) -> Vector2:
	var nx := Vector2(p.x + delta.x, p.y)
	if is_walkable(nx):
		p = nx
	var ny := Vector2(p.x, p.y + delta.y)
	if is_walkable(ny):
		p = ny
	return p


func room_index_at(p: Vector2) -> int:
	var t := Vector2i(floori(p.x / TILE), floori(p.y / TILE))
	for i in rooms.size():
		if rooms[i].has_point(t):
			return i
	return -1


func pixel_size() -> Vector2:
	return Vector2(width * TILE, height * TILE)


func _center(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)


func _tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + TILE / 2.0, t.y * TILE + TILE / 2.0)


func _random_interior(r: Rect2i) -> Vector2:
	var t := Vector2i(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 1, r.end.y - 2))
	return _tile_center(t)


func _paint() -> void:
	_layer.clear()
	for y in height:
		for x in width:
			# Her doku 4x4 karoluk tek bir dikişsiz resim; konuma göre parçası seçilir.
			# Yosunlu zemin ayrı doku olarak kare kare yamalar gibi görünüyordu; zeminle aynı çizilir.
			var v := WALL if map[y * width + x] == WALL else FLOOR
			_layer.set_cell(Vector2i(x, y), 0, Vector2i(v * TEX_TILES + x % TEX_TILES, y % TEX_TILES))
	_shade.queue_redraw()


## Boyalı dokulardan atlas kurar: 0 zemin, 1 duvar, 2 yosunlu zemin. Her doku TEX_TILES x TEX_TILES
## karoya bölünür, böylece taşlar 48 piksele sıkışmadan haritada kesintisiz devam eder.
func _build_tileset(keys: Array) -> TileSet:
	var block := TILE * TEX_TILES
	var atlas_img := Image.create(block * 3, block, false, Image.FORMAT_RGBA8)
	for i in keys.size():
		var img: Image = Sprites.tex(keys[i]).get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(block, block, Image.INTERPOLATE_LANCZOS)
		atlas_img.blit_rect(img, Rect2i(0, 0, block, block), Vector2i(i * block, 0))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(atlas_img)
	src.texture_region_size = Vector2i(TILE, TILE)
	for i in 3 * TEX_TILES:
		for j in TEX_TILES:
			src.create_tile(Vector2i(i, j))
	ts.add_source(src, 0)
	return ts
