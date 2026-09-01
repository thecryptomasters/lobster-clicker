extends Control

const SKY := Color("#071725")
const HORIZON := Color("#0d2b3b")
const WATER := Color("#092332")
const WATER_LINE := Color("#1b5367")
const DOCK := Color("#08131c")
const GOLD := Color("#ffd166")
const CORAL := Color("#e9553f")
const CYAN := Color("#1dd9f2")
const SEAFOAM := Color("#55d6be")

var _elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	if not GameManager.reduced_motion:
		_elapsed = fmod(_elapsed + delta, 240.0)
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return

	# Broad horizontal bands give the harbor depth without competing with UI.
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	var horizon_y := size.y * 0.55
	draw_rect(Rect2(0, horizon_y, size.x, size.y - horizon_y), WATER)
	draw_rect(Rect2(0, horizon_y - 2.0, size.x, 3.0), HORIZON)

	var motion_time := 0.0 if GameManager.reduced_motion else _elapsed

	# A soft moon and a few restrained arcade stars give the sky depth.
	var moon_x_ratio := 0.90 if size.x < 700.0 else 0.42
	var moon_position := Vector2(size.x * moon_x_ratio, size.y * 0.16)
	draw_circle(moon_position, clampf(size.x * 0.018, 10.0, 23.0), Color("#ffe7a6"))
	draw_circle(moon_position + Vector2(6.0, -3.0), clampf(size.x * 0.017, 9.0, 22.0), SKY)
	for star_index in range(7):
		var star_x := size.x * (0.04 + float(star_index) * 0.062)
		var star_y := size.y * (0.10 + float((star_index * 7) % 17) * 0.012)
		var twinkle := 0.42 + 0.36 * (0.5 + 0.5 * sin(motion_time * 1.7 + float(star_index)))
		draw_circle(Vector2(star_x, star_y), 1.2 + float(star_index % 2), Color(CYAN, twinkle))

	# Distant waterfront silhouettes and blinking warm windows.
	var skyline: Array[Vector2] = [
		Vector2(0, horizon_y), Vector2(0, horizon_y - 44), Vector2(size.x * 0.08, horizon_y - 44),
		Vector2(size.x * 0.08, horizon_y - 72), Vector2(size.x * 0.17, horizon_y - 72),
		Vector2(size.x * 0.17, horizon_y - 35), Vector2(size.x * 0.28, horizon_y - 35),
		Vector2(size.x * 0.28, horizon_y - 58), Vector2(size.x * 0.39, horizon_y - 58),
		Vector2(size.x * 0.39, horizon_y), Vector2(size.x, horizon_y)
	]
	draw_colored_polygon(PackedVector2Array(skyline), DOCK)
	var window_ratios := [0.035, 0.105, 0.205, 0.315]
	for light_index in range(window_ratios.size()):
		var pulse := 0.62 + 0.38 * (0.5 + 0.5 * sin(motion_time * 1.2 + float(light_index) * 1.9))
		draw_circle(Vector2(size.x * float(window_ratios[light_index]), horizon_y - 24.0), 2.5, Color(GOLD, pulse))

	# Water highlights continuously drift and shimmer across the harbor.
	for i in range(7):
		var y := horizon_y + 28.0 + i * 42.0 + sin(motion_time * 1.15 + float(i)) * 2.4
		var base_start := size.x * (0.03 + float(i % 3) * 0.035)
		var length := size.x * (0.18 + float((i + 1) % 3) * 0.04)
		var travel := maxf(34.0, size.x * 0.055)
		var start := base_start + fmod(motion_time * (7.0 + float(i)), travel) - travel
		draw_line(Vector2(start, y), Vector2(start + length, y), Color(WATER_LINE, 0.34 + float(i % 2) * 0.12), 2.0)
		draw_line(Vector2(start + length + 18.0, y), Vector2(start + length + 54.0, y), Color(SEAFOAM, 0.18), 1.5)

	# A tiny working boat crosses the middle distance, its lamp blinking slowly.
	var boat_span := maxf(size.x * 0.48, 420.0)
	var boat_x := fmod(motion_time * 11.0 + 90.0, boat_span) - 54.0
	var boat_y := horizon_y + 35.0 + sin(motion_time * 1.4) * 2.0
	var hull := PackedVector2Array([
		Vector2(boat_x - 24.0, boat_y), Vector2(boat_x + 25.0, boat_y),
		Vector2(boat_x + 15.0, boat_y + 9.0), Vector2(boat_x - 16.0, boat_y + 9.0),
	])
	draw_colored_polygon(hull, Color("#c83d36"))
	draw_rect(Rect2(boat_x - 7.0, boat_y - 11.0, 18.0, 11.0), Color("#eaf8f6"))
	draw_line(Vector2(boat_x + 1.0, boat_y - 11.0), Vector2(boat_x + 1.0, boat_y - 23.0), DOCK, 2.0)
	var boat_light_alpha := 0.58 + 0.42 * (0.5 + 0.5 * sin(motion_time * 2.3))
	draw_circle(Vector2(boat_x + 1.0, boat_y - 24.0), 2.7, Color(GOLD, boat_light_alpha))
	draw_line(Vector2(boat_x - 20.0, boat_y + 13.0), Vector2(boat_x + 22.0, boat_y + 13.0), Color(CYAN, 0.28), 2.0)

	# Bobbing arcade buoys anchor the foreground water.
	for buoy_index in range(3):
		var buoy_x := size.x * (0.11 + float(buoy_index) * 0.145)
		var buoy_y := horizon_y + size.y * (0.14 + float(buoy_index % 2) * 0.075) + sin(motion_time * 1.55 + float(buoy_index) * 2.0) * 4.0
		draw_line(Vector2(buoy_x, buoy_y + 7.0), Vector2(buoy_x, buoy_y + 18.0), Color(DOCK, 0.8), 2.0)
		draw_circle(Vector2(buoy_x, buoy_y), 5.0, CORAL)
		draw_circle(Vector2(buoy_x - 1.5, buoy_y - 1.5), 1.4, Color("#ffb27f"))

	# Thin fog ribbons drift behind the claw at low opacity.
	for fog_index in range(4):
		var fog_span := maxf(size.x * 0.52, 460.0)
		var fog_x := fmod(motion_time * (3.0 + float(fog_index) * 0.35) + float(fog_index) * 140.0, fog_span) - 100.0
		var fog_y := horizon_y + 82.0 + float(fog_index) * 48.0
		draw_line(Vector2(fog_x, fog_y), Vector2(fog_x + 118.0, fog_y), Color("#8ed7df", 0.045), 9.0)
		draw_line(Vector2(fog_x + 36.0, fog_y + 8.0), Vector2(fog_x + 172.0, fog_y + 8.0), Color("#8ed7df", 0.025), 6.0)

	# Foreground dock posts frame the click zone at large sizes.
	if size.x >= 700.0:
		for ratio in [0.045, 0.405]:
			var x: float = size.x * float(ratio)
			draw_rect(Rect2(x, size.y * 0.74, 12.0, size.y * 0.26), DOCK)
			draw_circle(Vector2(x + 6.0, size.y * 0.74), 8.0, CORAL.darkened(0.48))
