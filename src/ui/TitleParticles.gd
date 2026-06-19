extends Node2D

const STAR_COUNT := 40

var _stars: Array = []
var _running := false

class Star:
	var pos: Vector2
	var size: float
	var phase: float
	var speed: float
	var color: Color

func _ready() -> void:
	set_process(false)

func start() -> void:
	var vp := get_viewport().get_visible_rect()
	var cx := vp.size.x * 0.5
	var cy := vp.size.y * 0.22
	_stars.clear()
	for i in STAR_COUNT:
		var s := Star.new()
		s.pos = Vector2(
			cx + randf_range(-480.0, 480.0),
			cy + randf_range(-110.0, 110.0)
		)
		s.size = randf_range(5.0, 14.0)
		s.phase = randf_range(0.0, TAU)
		s.speed = randf_range(1.0, 3.0)
		var warm := randf_range(0.85, 1.0)
		s.color = Color(warm, warm * 0.88, warm * 0.5, 1.0)
		_stars.append(s)
	_running = true
	set_process(true)

func _process(delta: float) -> void:
	for s: Star in _stars:
		s.phase += s.speed * delta
	queue_redraw()

func _draw() -> void:
	if not _running:
		return
	for s: Star in _stars:
		var alpha: float = sin(s.phase) * 0.5 + 0.5
		alpha = pow(alpha, 2.0)
		if alpha < 0.03:
			continue
		var sz: float = s.size * alpha
		var c := Color(s.color.r, s.color.g, s.color.b, alpha)
		_draw_star(s.pos, sz, c)

func _draw_star(center: Vector2, size: float, c: Color) -> void:
	# 五角星：外圆5顶点 + 内圆5顶点交替，顶点朝上（-PI/2 起始）
	var outer := size
	var inner := size * 0.4
	var points: PackedVector2Array = []
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		var r := outer if i % 2 == 0 else inner
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, c)
	# 中心亮点
	draw_circle(center, size * 0.15, c)
