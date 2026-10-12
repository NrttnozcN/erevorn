class_name MalakorRest
extends Actor
## Malakor'un ölümü (bölge 7): kuzeydeki yokluk portalı iblisi geri çeker. Malakor portala doğru sürüklenir, küçülüp
## mor dumana karışır; sonra portalın girdabı söner ve kemer kapanır. Düğüm portalın tabanında durur.
## İlerde her boss için kısa ölüm sinematikleri gelecek; bu oyun içi kısa geçiştir.

const DRAG := 100
const CLOSE := 70
const VOID := Color(0.62, 0.28, 1.0)

var died_at := Vector2.ZERO
var flip := false
var portal: Sprite2D
var t := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(GlowLayer.make(_paint))


func tick() -> void:
	t += 1
	if t % 10 == 0 and t < DRAG:
		var at := _body_at()
		main.burst(position + at + Vector2(0, -40), 22, VOID)
	if t == DRAG:
		main.shake(10)
		main.burst(position + Vector2(0, -150), 90, VOID)
	if portal and t > DRAG:
		var k := clampf(float(t - DRAG) / CLOSE, 0.0, 1.0)
		portal.modulate = Color.WHITE.lerp(Color(0.32, 0.28, 0.34), k)
		for c in portal.get_children():
			if c is PointLight2D:
				c.energy = 0.9 * (1.0 - k)
	if t == DRAG + CLOSE:
		main.float_text(position + Vector2(0, -230), "Mor sis komutanı kapının ardına çekti", VOID.lightened(0.4))
	queue_redraw()


## Sürüklenen beden: ölüm yerinden portalın ağzına (düğüme göre).
func _body_at() -> Vector2:
	var u := clampf(float(t) / DRAG, 0.0, 1.0)
	return (died_at - position).lerp(Vector2(0, -60), u * u)


func _draw() -> void:
	if t >= DRAG:
		return
	var u := clampf(float(t) / DRAG, 0.0, 1.0)
	var tex := Sprites.tex("boss_z7_pull")
	if tex == null:
		return
	var s := Boss.MK_SCALE * (1.0 - 0.75 * u * u)
	var at := _body_at()
	var size := Boss.MK_CANVAS * s
	var b := Rect2(at + Vector2(-Boss.MK_ANCHOR.x * s, -Boss.MK_ANCHOR.y * s), size)
	if flip:
		b.position.x = at.x - (Boss.MK_CANVAS.x - Boss.MK_ANCHOR.x) * s
	Sprites.draw_actor(self, "boss_z7_pull", b, flip, false, false, Color(0.75 + 0.25 * (1.0 - u), 0.6, 1.0, 1.0 - u * u))


func _paint(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if t < DRAG:
		# Portalın ağzından bedene uzanan çekim girdabı.
		var at := _body_at() + Vector2(0, -60)
		var mouth := Vector2(0, -150)
		for j in 14:
			var q := fmod(now * 1.6 + j / 14.0, 1.0)
			g.glow(at.lerp(mouth, q) + Vector2(sin(j * 2.0 + now * 3.0) * 12.0, 0), 6.0, Color(VOID, 0.5 * (1.0 - q)))
		g.glow(mouth, 50.0, Color(VOID, 0.3))
	elif t < DRAG + CLOSE:
		var k := 1.0 - float(t - DRAG) / CLOSE
		g.glow(Vector2(0, -150), 70.0 * k, Color(VOID, 0.4 * k))
