extends Control

const HARBOR_PAINTING := preload("res://assets/art/environment/harbor_environment_clean.png")

const SKY := Color("#071725")
const GOLD := Color("#ffd166")
const CYAN := Color("#1dd9f2")
const HARBOR_HAZE := Color("#153f4f")

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

	# The painted diorama supplies the material detail that the hero claw and
	# building cabinets already have. The right-hand slice intentionally avoids
	# the trophy claw in the source key art while retaining the lighthouse,
	# waterfront businesses, reflections, dock clutter, and neon skyline.
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	_draw_painted_diorama(size)
	var horizon_y := size.y * 0.55
	for band_index in range(5):
		var band_height := size.y * 0.075
		var band_y := horizon_y - band_height * float(5 - band_index)
		draw_rect(Rect2(0.0, band_y, size.x, band_height + 1.0), Color(HARBOR_HAZE, 0.025 + float(band_index) * 0.018))

	var motion_time := 0.0 if GameManager.reduced_motion else _elapsed

	# Sparse animated stars keep the painting alive without competing with the UI.
	for star_index in range(7):
		var star_x := size.x * (0.04 + float(star_index) * 0.062)
		var star_y := size.y * (0.10 + float((star_index * 7) % 17) * 0.012)
		var twinkle := 0.42 + 0.36 * (0.5 + 0.5 * sin(motion_time * 1.7 + float(star_index)))
		draw_circle(Vector2(star_x, star_y), 1.2 + float(star_index % 2), Color(CYAN, twinkle))
	if size.x >= 700.0:
		# Tiny gull silhouettes keep the sky nautical without turning it into a focal point.
		for gull_index in range(2):
			var gull_origin := Vector2(size.x * (0.30 + float(gull_index) * 0.055), size.y * (0.22 + float(gull_index) * 0.035))
			draw_line(gull_origin + Vector2(-5.0, 1.5), gull_origin, Color("#8db3be", 0.36), 1.4)
			draw_line(gull_origin, gull_origin + Vector2(5.0, 1.5), Color("#8db3be", 0.36), 1.4)

	# Blinking windows and broken reflections sit on top of the painted shops.
	var window_ratios := [0.035, 0.105, 0.205, 0.315]
	for light_index in range(window_ratios.size()):
		var pulse := 0.62 + 0.38 * (0.5 + 0.5 * sin(motion_time * 1.2 + float(light_index) * 1.9))
		var light_x := size.x * float(window_ratios[light_index])
		draw_circle(Vector2(light_x, horizon_y - 24.0), 2.5, Color(GOLD, pulse))
		# Broken vertical reflections make every dock light feel seated in the water.
		for reflection_index in range(3):
			var reflection_y := horizon_y + 8.0 + float(reflection_index) * 10.0
			var reflection_width := 8.0 + float(reflection_index) * 5.0
			draw_line(Vector2(light_x - reflection_width * 0.5, reflection_y), Vector2(light_x + reflection_width * 0.5, reflection_y), Color(GOLD, pulse * (0.22 - float(reflection_index) * 0.045)), 1.4)

	# Thin fog ribbons drift behind the claw at low opacity.
	for fog_index in range(4):
		var fog_span := maxf(size.x * 0.52, 460.0)
		var fog_x := fmod(motion_time * (3.0 + float(fog_index) * 0.35) + float(fog_index) * 140.0, fog_span) - 100.0
		var fog_y := horizon_y + 82.0 + float(fog_index) * 48.0
		draw_line(Vector2(fog_x, fog_y), Vector2(fog_x + 118.0, fog_y), Color("#8ed7df", 0.045), 9.0)
		draw_line(Vector2(fog_x + 36.0, fog_y + 8.0), Vector2(fog_x + 172.0, fog_y + 8.0), Color("#8ed7df", 0.025), 6.0)

func _draw_painted_diorama(size: Vector2) -> void:
	var visible_width := size.x if size.x < 700.0 else size.x * 0.455
	var destination := Rect2(0.0, 0.0, visible_width, size.y)
	var texture_size := HARBOR_PAINTING.get_size()
	var destination_aspect := visible_width / maxf(size.y, 1.0)
	var right_slice_width := texture_size.x * 0.35
	var source_size := Vector2.ZERO

	if destination_aspect >= right_slice_width / texture_size.y:
		source_size.x = right_slice_width
		source_size.y = right_slice_width / destination_aspect
	else:
		source_size.y = texture_size.y
		source_size.x = texture_size.y * destination_aspect

	var source_origin := Vector2(
		texture_size.x - source_size.x,
		(texture_size.y - source_size.y) * 0.5
	)
	draw_texture_rect_region(HARBOR_PAINTING, destination, Rect2(source_origin, source_size))
	# A navy glaze keeps labels and the bright hero silhouette readable while
	# preserving the painting's coral, cyan, violet, and warm-window detail.
	draw_rect(destination, Color("#04111d", 0.24))
func get_active_landmark_count() -> int:
	# Retained as the progression-facing count used by milestone QA. The painted
	# diorama now carries the visual world; old flat landmark drawings were
	# intentionally removed so they cannot sit on top of the finished artwork.
	var active := 0
	for count in GameManager.building_counts:
		if count > 0:
			active += 1
	return active
