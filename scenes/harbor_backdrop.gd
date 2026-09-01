extends Control

const SKY := Color("#071725")
const HORIZON := Color("#0d2b3b")
const WATER := Color("#092332")
const WATER_LINE := Color("#1b5367")
const DOCK := Color("#08131c")
const GOLD := Color("#ffd166")
const CORAL := Color("#e9553f")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var size := get_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# Broad horizontal bands give the harbor depth without competing with UI.
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	var horizon_y := size.y * 0.55
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), WATER)
	draw_rect(Rect2(0, horizon_y - 2.0, size.x, 3.0), HORIZON)

	# Distant waterfront silhouettes and warm windows.
	var skyline: Array[Vector2] = [
		Vector2(0, horizon_y), Vector2(0, horizon_y - 44), Vector2(size.x * 0.08, horizon_y - 44),
		Vector2(size.x * 0.08, horizon_y - 72), Vector2(size.x * 0.17, horizon_y - 72),
		Vector2(size.x * 0.17, horizon_y - 35), Vector2(size.x * 0.28, horizon_y - 35),
		Vector2(size.x * 0.28, horizon_y - 58), Vector2(size.x * 0.39, horizon_y - 58),
		Vector2(size.x * 0.39, horizon_y), Vector2(size.x, horizon_y)
	]
	draw_colored_polygon(PackedVector2Array(skyline), DOCK)
	for ratio in [0.035, 0.105, 0.205, 0.315]:
		draw_circle(Vector2(size.x * ratio, horizon_y - 24.0), 2.5, GOLD)

	# Quiet water lines create a cozy, illustrated night-harbor texture.
	for i in range(7):
		var y := horizon_y + 28.0 + i * 42.0
		var start := size.x * (0.03 + float(i % 3) * 0.035)
		var length := size.x * (0.18 + float((i + 1) % 3) * 0.04)
		draw_line(Vector2(start, y), Vector2(start + length, y), Color(WATER_LINE, 0.42), 2.0)

	# Foreground dock posts frame the click zone at large sizes.
	if size.x >= 700.0:
		for ratio in [0.045, 0.405]:
			var x: float = size.x * float(ratio)
			draw_rect(Rect2(x, size.y * 0.74, 12.0, size.y * 0.26), DOCK)
			draw_circle(Vector2(x + 6.0, size.y * 0.74), 8.0, CORAL.darkened(0.48))
