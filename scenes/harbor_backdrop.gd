extends Control

const HARBOR_PAINTING := preload("res://assets/art/environment/harbor_diorama.png")

const SKY := Color("#071725")
const HORIZON := Color("#0d2b3b")
const WATER := Color("#092332")
const WATER_LINE := Color("#1b5367")
const DOCK := Color("#08131c")
const GOLD := Color("#ffd166")
const CORAL := Color("#e9553f")
const CYAN := Color("#1dd9f2")
const SEAFOAM := Color("#55d6be")
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

	# Water highlights continuously drift and shimmer across the harbor.
	for i in range(7):
		var y := horizon_y + 28.0 + i * 42.0 + sin(motion_time * 1.15 + float(i)) * 2.4
		var base_start := size.x * (0.03 + float(i % 3) * 0.035)
		var length := size.x * (0.18 + float((i + 1) % 3) * 0.04)
		var travel := maxf(34.0, size.x * 0.055)
		var start := base_start + fmod(motion_time * (7.0 + float(i)), travel) - travel
		draw_line(Vector2(start, y), Vector2(start + length, y), Color(WATER_LINE, 0.34 + float(i % 2) * 0.12), 2.0)
		draw_line(Vector2(start + length + 18.0, y), Vector2(start + length + 54.0, y), Color(SEAFOAM, 0.18), 1.5)

	# Every owned building leaves a visible footprint in the harbor. The empire
	# grows from a few traps into an absurd neon-industrial skyline without
	# changing the save format or adding another progression system.
	_draw_harbor_empire(size, horizon_y, motion_time)

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
	draw_line(Vector2(boat_x - 28.0, boat_y + 10.0), Vector2(boat_x - 52.0, boat_y + 14.0), Color(SEAFOAM, 0.17), 1.5)
	draw_line(Vector2(boat_x - 31.0, boat_y + 14.0), Vector2(boat_x - 65.0, boat_y + 20.0), Color(CYAN, 0.10), 1.0)

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
		var dock_post_positions: Array[float] = []
		for ratio in [0.045, 0.405]:
			var x: float = size.x * float(ratio)
			dock_post_positions.append(x + 6.0)
			draw_rect(Rect2(x, size.y * 0.74, 12.0, size.y * 0.26), DOCK)
			draw_circle(Vector2(x + 6.0, size.y * 0.74), 8.0, CORAL.darkened(0.48))
			draw_line(Vector2(x + 3.0, size.y * 0.77), Vector2(x + 3.0, size.y * 0.98), Color("#244352", 0.34), 2.0)
		# A sagging mooring rope frames the interaction space like a tiny arcade diorama.
		var rope_y := size.y * 0.765
		var rope_points := 18
		for rope_index in range(rope_points):
			var rope_t := float(rope_index) / float(rope_points - 1)
			var next_t := float(rope_index + 1) / float(rope_points - 1)
			if rope_index == rope_points - 1:
				break
			var rope_start := Vector2(lerpf(dock_post_positions[0], dock_post_positions[1], rope_t), rope_y + sin(rope_t * PI) * 24.0)
			var rope_end := Vector2(lerpf(dock_post_positions[0], dock_post_positions[1], next_t), rope_y + sin(next_t * PI) * 24.0)
			draw_line(rope_start, rope_end, Color("#815d3d", 0.60), 2.2)

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
	var active := 0
	for count in GameManager.building_counts:
		if count > 0:
			active += 1
	return active

func _building_count(index: int) -> int:
	if index < 0 or index >= GameManager.building_counts.size():
		return 0
	return GameManager.building_counts[index]

func _draw_harbor_empire(size: Vector2, horizon_y: float, motion_time: float) -> void:
	if GameManager.building_counts.is_empty():
		return
	var harbor_width := size.x if size.x < 700.0 else size.x * 0.455
	var landmark_scale := clampf(harbor_width / 580.0, 0.62, 1.08)
	var base_y := horizon_y - 2.0

	# Coin Collecting: trap floats and the occasional golden catch.
	if _building_count(0) > 0:
		var collector_x := harbor_width * 0.08
		var collector_bob := sin(motion_time * 1.8) * 2.5
		draw_line(Vector2(collector_x, horizon_y + 5.0), Vector2(collector_x, horizon_y + 23.0 + collector_bob), Color("#7b583a", 0.8), 1.5)
		draw_circle(Vector2(collector_x, horizon_y + 24.0 + collector_bob), 5.0 * landmark_scale, CORAL)
		var coin_pulse := 0.45 + 0.45 * (0.5 + 0.5 * sin(motion_time * 2.4))
		draw_circle(Vector2(collector_x + 10.0, horizon_y + 18.0 + collector_bob), 2.4 * landmark_scale, Color(GOLD, coin_pulse))

	# Lobster Memes: a deliberately silly neon billboard wakes up.
	if _building_count(1) > 0:
		var meme_x := harbor_width * 0.17
		var meme_rect := Rect2(meme_x - 17.0 * landmark_scale, base_y - 48.0 * landmark_scale, 34.0 * landmark_scale, 21.0 * landmark_scale)
		draw_rect(meme_rect, Color("#102536"))
		draw_rect(meme_rect, Color(CORAL, 0.82), false, 2.0)
		draw_circle(meme_rect.get_center(), 5.5 * landmark_scale, Color(CYAN, 0.28 + 0.18 * sin(motion_time * 2.0)))
		draw_line(Vector2(meme_x - 8.0, base_y - 27.0 * landmark_scale), Vector2(meme_x - 8.0, base_y), DOCK, 2.0)
		draw_line(Vector2(meme_x + 8.0, base_y - 27.0 * landmark_scale), Vector2(meme_x + 8.0, base_y), DOCK, 2.0)

	# Fishcord Server: antenna and packets blinking into the night.
	if _building_count(2) > 0:
		var server_x := harbor_width * 0.27
		draw_rect(Rect2(server_x - 12.0 * landmark_scale, base_y - 28.0 * landmark_scale, 24.0 * landmark_scale, 28.0 * landmark_scale), Color("#102637"))
		for rack_index in range(3):
			var rack_y := base_y - (7.0 + float(rack_index) * 7.0) * landmark_scale
			draw_line(Vector2(server_x - 8.0 * landmark_scale, rack_y), Vector2(server_x + 8.0 * landmark_scale, rack_y), Color(CYAN, 0.45), 1.2)
		draw_line(Vector2(server_x, base_y - 28.0 * landmark_scale), Vector2(server_x, base_y - 49.0 * landmark_scale), Color("#7895a0"), 1.5)
		var packet_y := base_y - (37.0 + fmod(motion_time * 10.0, 15.0)) * landmark_scale
		draw_circle(Vector2(server_x, packet_y), 2.0 * landmark_scale, Color(CYAN, 0.75))

	# Seafood Restaurant: warm awning and window light.
	if _building_count(3) > 0:
		var diner_x := harbor_width * 0.38
		draw_rect(Rect2(diner_x - 21.0 * landmark_scale, base_y - 24.0 * landmark_scale, 42.0 * landmark_scale, 24.0 * landmark_scale), Color("#39252b"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(diner_x - 24.0 * landmark_scale, base_y - 24.0 * landmark_scale), Vector2(diner_x + 24.0 * landmark_scale, base_y - 24.0 * landmark_scale),
			Vector2(diner_x + 16.0 * landmark_scale, base_y - 35.0 * landmark_scale), Vector2(diner_x - 16.0 * landmark_scale, base_y - 35.0 * landmark_scale),
		]), CORAL.darkened(0.12))
		for window_index in range(3):
			var window_x := diner_x + (-12.0 + float(window_index) * 12.0) * landmark_scale
			draw_rect(Rect2(window_x - 3.5 * landmark_scale, base_y - 17.0 * landmark_scale, 7.0 * landmark_scale, 9.0 * landmark_scale), Color(GOLD, 0.70))

	# Lobster Anime: a marquee that cycles coral, cyan, and violet.
	if _building_count(4) > 0:
		var arcade_x := harbor_width * 0.48
		var arcade_palette: Array[Color] = [CORAL, CYAN, Color("#a56de2")]
		var arcade_color: Color = arcade_palette[int(floor(motion_time * 1.4)) % 3]
		draw_rect(Rect2(arcade_x - 15.0 * landmark_scale, base_y - 31.0 * landmark_scale, 30.0 * landmark_scale, 31.0 * landmark_scale), Color("#10182c"))
		draw_rect(Rect2(arcade_x - 17.0 * landmark_scale, base_y - 38.0 * landmark_scale, 34.0 * landmark_scale, 10.0 * landmark_scale), Color(arcade_color, 0.82))
		draw_circle(Vector2(arcade_x, base_y - 16.0 * landmark_scale), 6.0 * landmark_scale, Color(arcade_color, 0.24))

	# Bitclaw: a compact mining derrick with a rotating energy wheel.
	if _building_count(5) > 0:
		var mine_x := harbor_width * 0.57
		draw_line(Vector2(mine_x - 16.0 * landmark_scale, base_y), Vector2(mine_x, base_y - 43.0 * landmark_scale), Color("#5c7180"), 2.2)
		draw_line(Vector2(mine_x + 16.0 * landmark_scale, base_y), Vector2(mine_x, base_y - 43.0 * landmark_scale), Color("#5c7180"), 2.2)
		draw_line(Vector2(mine_x - 10.0 * landmark_scale, base_y - 16.0 * landmark_scale), Vector2(mine_x + 10.0 * landmark_scale, base_y - 16.0 * landmark_scale), Color("#5c7180"), 1.4)
		var wheel_center := Vector2(mine_x, base_y - 28.0 * landmark_scale)
		draw_circle(wheel_center, 6.0 * landmark_scale, Color(GOLD, 0.26))
		draw_line(wheel_center + Vector2.from_angle(motion_time * 1.6) * 6.0 * landmark_scale, wheel_center - Vector2.from_angle(motion_time * 1.6) * 6.0 * landmark_scale, GOLD, 1.6)

	# Clamazon: warehouse, cargo, and a moving crane hook.
	if _building_count(6) > 0:
		var warehouse_x := harbor_width * 0.66
		draw_rect(Rect2(warehouse_x - 22.0 * landmark_scale, base_y - 26.0 * landmark_scale, 44.0 * landmark_scale, 26.0 * landmark_scale), Color("#173448"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(warehouse_x - 25.0 * landmark_scale, base_y - 26.0 * landmark_scale), Vector2(warehouse_x, base_y - 39.0 * landmark_scale),
			Vector2(warehouse_x + 25.0 * landmark_scale, base_y - 26.0 * landmark_scale),
		]), Color("#31566a"))
		for crate_index in range(2):
			draw_rect(Rect2(warehouse_x + (-12.0 + float(crate_index) * 14.0) * landmark_scale, base_y - 10.0 * landmark_scale, 10.0 * landmark_scale, 10.0 * landmark_scale), Color("#a66d3f"))
		var hook_y := base_y - (28.0 + 4.0 * sin(motion_time * 1.1)) * landmark_scale
		draw_line(Vector2(warehouse_x + 20.0 * landmark_scale, base_y - 48.0 * landmark_scale), Vector2(warehouse_x + 20.0 * landmark_scale, hook_y), GOLD.darkened(0.25), 1.2)
		draw_circle(Vector2(warehouse_x + 20.0 * landmark_scale, hook_y), 2.0 * landmark_scale, GOLD)

	# Lobster AI: a holographic tower whose orbit never quite settles.
	if _building_count(7) > 0:
		var ai_x := harbor_width * 0.76
		draw_colored_polygon(PackedVector2Array([
			Vector2(ai_x - 12.0 * landmark_scale, base_y), Vector2(ai_x + 12.0 * landmark_scale, base_y),
			Vector2(ai_x + 5.0 * landmark_scale, base_y - 45.0 * landmark_scale), Vector2(ai_x - 5.0 * landmark_scale, base_y - 45.0 * landmark_scale),
		]), Color("#113649"))
		draw_line(Vector2(ai_x, base_y - 8.0 * landmark_scale), Vector2(ai_x, base_y - 42.0 * landmark_scale), Color(CYAN, 0.75), 2.0)
		var orbit_center := Vector2(ai_x, base_y - 36.0 * landmark_scale)
		var orbit_point := orbit_center + Vector2.from_angle(motion_time * 1.3) * 11.0 * landmark_scale
		draw_circle(orbit_point, 2.2 * landmark_scale, Color(SEAFOAM, 0.85))
		draw_arc(orbit_center, 11.0 * landmark_scale, 0.0, TAU, 24, Color(CYAN, 0.22), 1.2)

	# Immortality: an offshore shell-energy shrine, the late-game visual crown.
	if _building_count(8) > 0:
		var shrine_x := harbor_width * 0.85
		var shrine_center := Vector2(shrine_x, base_y - 22.0 * landmark_scale)
		draw_colored_polygon(PackedVector2Array([
			Vector2(shrine_x - 18.0 * landmark_scale, base_y), Vector2(shrine_x + 18.0 * landmark_scale, base_y),
			Vector2(shrine_x + 11.0 * landmark_scale, base_y - 10.0 * landmark_scale), Vector2(shrine_x - 11.0 * landmark_scale, base_y - 10.0 * landmark_scale),
		]), Color("#4a385c"))
		var shrine_pulse := 0.5 + 0.5 * sin(motion_time * 1.5)
		for ring_index in range(2):
			draw_arc(shrine_center, (8.0 + float(ring_index) * 7.0 + shrine_pulse * 2.0) * landmark_scale, 0.0, TAU, 28, Color("#b989ff", 0.38 - float(ring_index) * 0.10), 1.8)
		draw_circle(shrine_center, 5.0 * landmark_scale, Color(GOLD, 0.70 + shrine_pulse * 0.25))
