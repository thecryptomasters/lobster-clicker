extends Control

const BuildingItemScene := preload("res://scenes/building_item.tscn")
const BuildingUpgradeItemScene := preload("res://scenes/building_upgrade_item.tscn")

@onready var lobster_count_label: Label = %LobsterCountLabel
@onready var lps_label: Label = %LpsLabel
@onready var claw_button: Button = %ClawButton
@onready var left_pincer: Node2D = %LeftPincer
@onready var right_pincer: Node2D = %RightPincer
@onready var building_container: VBoxContainer = %BuildingContainer
@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var particles: CPUParticles2D = %ClickParticles
@onready var float_text_container: Node2D = %FloatTextContainer
@onready var offline_popup: PanelContainer = %OfflinePopup
@onready var offline_label: Label = %OfflineLabel
@onready var offline_ok_button: Button = %OfflineOkButton
@onready var buildings_tab: Button = %BuildingsTab
@onready var upgrades_tab: Button = %UpgradesTab
@onready var root_container: BoxContainer = %RootContainer
@onready var left_section: VBoxContainer = %LeftSection
@onready var right_panel: PanelContainer = %RightPanel

# Animation: move pincers via X position (no rotation!)
const OPEN_X := 22.0
const SHUT_X := 3.0
const SNAP_SPEED := 14.0
const OPEN_SPEED := 3.5

enum ClawState { IDLE, SNAPPING, OPENING }
var claw_state: int = ClawState.IDLE
var claw_progress: float = 0.0

enum Tab { BUILDINGS, UPGRADES }
var current_tab: int = Tab.BUILDINGS

# Flash state for upgrades tab
var _flash_timer: float = 0.0
var _flash_active: bool = false

# Responsive layout
const MOBILE_BREAKPOINT := 700  # Below this width = mobile (vertical stack)
var _is_desktop: bool = true
var _last_width: int = 0

func _ready() -> void:
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.lps_changed.connect(_on_lps_changed)
	GameManager.upgrade_unlocked.connect(_on_upgrade_unlocked)
	GameManager.building_purchased.connect(_on_building_purchased)
	claw_button.gui_input.connect(_on_claw_gui_input)
	offline_ok_button.pressed.connect(_on_offline_ok)
	buildings_tab.pressed.connect(_on_buildings_tab)
	upgrades_tab.pressed.connect(_on_upgrades_tab)

	# Set initial open position
	left_pincer.position.x = -OPEN_X
	right_pincer.position.x = OPEN_X

	# Populate buildings
	for i in range(GameManager.building_defs.size()):
		var item := BuildingItemScene.instantiate()
		building_container.add_child(item)
		item.setup(i)

	# Initial display
	_on_lobsters_changed(GameManager.total_lobsters)
	_on_lps_changed(GameManager.lobsters_per_second)
	_switch_tab(Tab.BUILDINGS)
	_refresh_upgrades()

	# Apply responsive layout
	_apply_layout()

	# Show offline popup if needed
	if SaveManager.offline_earnings > 0:
		offline_label.text = "Welcome back!\nYou earned %s lobsters\nwhile you were away!" % GameManager.format_number(SaveManager.offline_earnings)
		offline_popup.visible = true
	else:
		offline_popup.visible = false

func _process(delta: float) -> void:
	# Check for viewport resize (throttle to every 30 frames to avoid JS overhead)
	if Engine.get_process_frames() % 30 == 0:
		var real_width := _get_real_width()
		if real_width != _last_width:
			_last_width = real_width
			_apply_layout()

	# Drive claw animation every frame via position
	match claw_state:
		ClawState.SNAPPING:
			claw_progress += delta * SNAP_SPEED
			if claw_progress >= 1.0:
				claw_progress = 0.0
				claw_state = ClawState.OPENING
				left_pincer.position.x = -SHUT_X
				right_pincer.position.x = SHUT_X
			else:
				var t := claw_progress
				left_pincer.position.x = lerpf(-OPEN_X, -SHUT_X, t)
				right_pincer.position.x = lerpf(OPEN_X, SHUT_X, t)

		ClawState.OPENING:
			claw_progress += delta * OPEN_SPEED
			if claw_progress >= 1.0:
				claw_progress = 0.0
				claw_state = ClawState.IDLE
				left_pincer.position.x = -OPEN_X
				right_pincer.position.x = OPEN_X
			else:
				var t := 1.0 - pow(1.0 - claw_progress, 2.0)
				left_pincer.position.x = lerpf(-SHUT_X, -OPEN_X, t)
				right_pincer.position.x = lerpf(SHUT_X, OPEN_X, t)

	# Flash upgrades tab
	if _flash_active:
		_flash_timer += delta
		if _flash_timer > 2.0:
			_flash_active = false
			_flash_timer = 0.0
			_update_tab_styles()
		elif current_tab != Tab.UPGRADES:
			var pulse := (sin(_flash_timer * 8.0) + 1.0) / 2.0
			var col := Color("#667788").lerp(Color("#ffd766"), pulse)
			upgrades_tab.add_theme_color_override("font_color", col)

# --- Responsive Layout ---

func _get_real_width() -> int:
	# In web exports, use JS to get actual CSS pixel width (viewport lies due to stretch)
	if OS.has_feature("web"):
		var w = JavaScriptBridge.eval("window.innerWidth;")
		if w != null:
			return int(w)
	# Fallback: use actual window size, not virtual viewport
	var win_size := DisplayServer.window_get_size()
	return win_size.x

func _apply_layout() -> void:
	var real_width := _get_real_width()
	var should_be_desktop := real_width >= MOBILE_BREAKPOINT

	if should_be_desktop == _is_desktop and _last_width != 0:
		return  # No change needed

	_is_desktop = should_be_desktop

	if _is_desktop:
		# Desktop: side-by-side (HBox), claw left, buildings/upgrades right
		root_container.vertical = false
		left_section.size_flags_stretch_ratio = 1.0
		right_panel.size_flags_stretch_ratio = 1.2
		left_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		# Mobile: stacked vertically (VBox), claw compact on top, buildings get more space
		root_container.vertical = true
		left_section.size_flags_stretch_ratio = 0.6
		right_panel.size_flags_stretch_ratio = 1.0
		left_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _on_lobsters_changed(total: float) -> void:
	lobster_count_label.text = GameManager.format_number(total)

func _on_lps_changed(lps: float) -> void:
	if lps < 1.0 and lps > 0:
		lps_label.text = "%.1f lobsters/sec" % lps
	else:
		lps_label.text = "%s lobsters/sec" % GameManager.format_number(lps)

func _on_claw_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		claw_button.accept_event()
		_do_click()
		return
	if event is InputEventScreenTouch and event.pressed:
		claw_button.accept_event()
		_do_click()
		return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if claw_button and claw_button.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			_do_click()

func _do_click() -> void:
	var amount := GameManager.click()
	claw_state = ClawState.SNAPPING
	claw_progress = 0.0
	_spawn_float_text(amount)
	particles.restart()
	particles.emitting = true

func _spawn_float_text(amount: float) -> void:
	var label := Label.new()
	label.text = "+%s" % GameManager.format_number(amount)
	label.add_theme_color_override("font_color", Color("#ff6b6b"))
	label.add_theme_font_size_override("font_size", 32)
	label.position = Vector2(randf_range(-30, 30), randf_range(-20, 0))
	label.z_index = 10
	float_text_container.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

func _on_offline_ok() -> void:
	offline_popup.visible = false

# --- Tab Management ---

func _on_buildings_tab() -> void:
	_switch_tab(Tab.BUILDINGS)

func _on_upgrades_tab() -> void:
	_switch_tab(Tab.UPGRADES)
	_flash_active = false
	_flash_timer = 0.0
	_refresh_upgrades()

func _switch_tab(tab: int) -> void:
	current_tab = tab
	building_container.visible = (tab == Tab.BUILDINGS)
	upgrade_container.visible = (tab == Tab.UPGRADES)
	_update_tab_styles()

func _update_tab_styles() -> void:
	if current_tab == Tab.BUILDINGS:
		buildings_tab.add_theme_color_override("font_color", Color("#ffd766"))
		upgrades_tab.add_theme_color_override("font_color", Color("#667788"))
	else:
		buildings_tab.add_theme_color_override("font_color", Color("#667788"))
		upgrades_tab.add_theme_color_override("font_color", Color("#ffd766"))

func _on_upgrade_unlocked(_building_index: int, _tier: int) -> void:
	_flash_active = true
	_flash_timer = 0.0
	if current_tab == Tab.UPGRADES:
		_refresh_upgrades()

func _on_building_purchased(_index: int) -> void:
	if current_tab == Tab.UPGRADES:
		_refresh_upgrades()

func _refresh_upgrades() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

	var available := GameManager.get_available_upgrades()
	if available.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No upgrades available yet.\nBuy more buildings to unlock!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color("#667788"))
		empty_label.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(empty_label)
		return

	for upg in available:
		var item := BuildingUpgradeItemScene.instantiate()
		upgrade_container.add_child(item)
		item.setup(upg["building_index"], upg["tier"], upg["purchased"])
