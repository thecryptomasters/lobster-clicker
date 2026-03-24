extends Control

const BuildingItemScene := preload("res://scenes/building_item.tscn")
const BuildingUpgradeItemScene := preload("res://scenes/building_upgrade_item.tscn")

@onready var farm_name_button: Button = %FarmNameButton
@onready var farm_name_edit: LineEdit = %FarmNameEdit
@onready var lobster_count_label: Label = %LobsterCountLabel
@onready var lps_label: Label = %LpsLabel
@onready var lifetime_label: Label = %LifetimeLabel
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
	farm_name_button.pressed.connect(_on_farm_name_clicked)
	farm_name_edit.text_submitted.connect(_on_farm_name_submitted)
	farm_name_edit.focus_exited.connect(_on_farm_name_focus_lost)
	buildings_tab.pressed.connect(_on_buildings_tab)
	upgrades_tab.pressed.connect(_on_upgrades_tab)

	# Load farm name
	farm_name_button.text = GameManager.farm_name

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
	# Check for new click upgrades (throttle)
	if Engine.get_process_frames() % 60 == 0:
		_check_click_upgrades()

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
		left_section.size_flags_stretch_ratio = 0.5
		right_panel.size_flags_stretch_ratio = 1.2
		left_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _on_lobsters_changed(total: float) -> void:
	lobster_count_label.text = GameManager.format_number(total)
	lifetime_label.text = "%s lifetime" % GameManager.format_number(GameManager.lifetime_lobsters)

func _on_lps_changed(lps: float) -> void:
	if lps < 1.0 and lps > 0:
		lps_label.text = "%.1f lobsters/sec" % lps
	else:
		lps_label.text = "%s lobsters/sec" % GameManager.format_number(lps)

var _click_debounce: float = 0.0
const CLICK_DEBOUNCE_TIME := 0.05  # 50ms debounce to prevent double-fire

func _on_claw_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		claw_button.accept_event()
		_try_click()
		return
	if event is InputEventScreenTouch and event.pressed:
		claw_button.accept_event()
		_try_click()
		return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if claw_button and claw_button.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			_try_click()

func _try_click() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _click_debounce < CLICK_DEBOUNCE_TIME:
		return  # Ignore duplicate within debounce window
	_click_debounce = now
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

# --- Farm Name ---

func _on_farm_name_clicked() -> void:
	farm_name_button.visible = false
	farm_name_edit.visible = true
	farm_name_edit.text = GameManager.farm_name
	farm_name_edit.grab_focus()
	farm_name_edit.select_all()

func _on_farm_name_submitted(new_name: String) -> void:
	_apply_farm_name(new_name)

func _on_farm_name_focus_lost() -> void:
	_apply_farm_name(farm_name_edit.text)

func _apply_farm_name(new_name: String) -> void:
	new_name = new_name.strip_edges()
	# Secret dev menu trigger
	if new_name.to_lower() == "/lobster_raviolli":
		farm_name_edit.visible = false
		farm_name_button.visible = true
		_show_dev_menu()
		return
	if new_name.is_empty():
		new_name = "My Lobster Farm"
	GameManager.farm_name = new_name
	farm_name_button.text = new_name
	farm_name_edit.visible = false
	farm_name_button.visible = true

# --- Dev Menu ---

var _dev_popup: PanelContainer

func _show_dev_menu() -> void:
	if _dev_popup and is_instance_valid(_dev_popup):
		_dev_popup.queue_free()

	_dev_popup = PanelContainer.new()
	_dev_popup.layout_mode = 1
	_dev_popup.anchors_preset = Control.PRESET_CENTER
	_dev_popup.anchor_left = 0.05
	_dev_popup.anchor_right = 0.95
	_dev_popup.anchor_top = 0.1
	_dev_popup.anchor_bottom = 0.9
	_dev_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dev_popup.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.97)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#ff6b6b")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_dev_popup.add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dev_popup.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🔧 DEV MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ff6b6b"))
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "🤫"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#667788"))
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)

	# --- Add Lobsters ---
	_dev_add_section(vbox, "Add Current Lobsters")
	var lobster_amounts := [1000, 10000, 100000, 1000000, 10000000]
	var lobster_row := HBoxContainer.new()
	lobster_row.add_theme_constant_override("separation", 6)
	vbox.add_child(lobster_row)
	for amt in lobster_amounts:
		var btn := _dev_make_button("+%s" % GameManager.format_number(amt))
		btn.pressed.connect(func(): GameManager.total_lobsters += amt; GameManager.lobsters_changed.emit(GameManager.total_lobsters))
		lobster_row.add_child(btn)

	# --- Add Lifetime Lobsters ---
	_dev_add_section(vbox, "Add Lifetime Lobsters")
	var lifetime_row := HBoxContainer.new()
	lifetime_row.add_theme_constant_override("separation", 6)
	vbox.add_child(lifetime_row)
	for amt in lobster_amounts:
		var btn := _dev_make_button("+%s" % GameManager.format_number(amt))
		btn.pressed.connect(func(): GameManager.lifetime_lobsters += amt; GameManager.total_lobsters += amt; GameManager.lobsters_changed.emit(GameManager.total_lobsters))
		lifetime_row.add_child(btn)

	# --- Set LPS ---
	_dev_add_section(vbox, "Set Lobsters/sec")
	var lps_row := HBoxContainer.new()
	lps_row.add_theme_constant_override("separation", 6)
	vbox.add_child(lps_row)
	var lps_amounts := [0, 10, 100, 1000, 10000]
	for amt in lps_amounts:
		var label_text := str(amt) if amt > 0 else "0"
		var btn := _dev_make_button(label_text)
		btn.pressed.connect(func():
			GameManager.lobsters_per_second = float(amt)
			GameManager.lps_changed.emit(GameManager.lobsters_per_second))
		lps_row.add_child(btn)

	# --- Unlock All Upgrades ---
	_dev_add_section(vbox, "Upgrades")
	var unlock_row := HBoxContainer.new()
	unlock_row.add_theme_constant_override("separation", 6)
	vbox.add_child(unlock_row)

	var unlock_click_btn := _dev_make_button("All Click Upg.")
	unlock_click_btn.pressed.connect(func():
		for i in range(GameManager.click_upgrades_purchased.size()):
			GameManager.click_upgrades_purchased[i] = true
		for i in range(GameManager.cps_click_upgrades_purchased.size()):
			GameManager.cps_click_upgrades_purchased[i] = true
		GameManager._recalculate_click_power()
		GameManager.lobsters_changed.emit(GameManager.total_lobsters))
	unlock_row.add_child(unlock_click_btn)

	var unlock_bldg_btn := _dev_make_button("All Bldg Upg.")
	unlock_bldg_btn.pressed.connect(func():
		for bi in range(GameManager.building_upgrades.size()):
			for tier in range(GameManager.building_upgrades[bi].size()):
				GameManager.building_upgrades[bi][tier] = true
		GameManager._recalculate_lps()
		GameManager.lobsters_changed.emit(GameManager.total_lobsters))
	unlock_row.add_child(unlock_bldg_btn)

	# --- Set Buildings ---
	_dev_add_section(vbox, "Set All Buildings To")
	var bldg_row := HBoxContainer.new()
	bldg_row.add_theme_constant_override("separation", 6)
	vbox.add_child(bldg_row)
	var bldg_amounts := [0, 10, 25, 50, 100]
	for amt in bldg_amounts:
		var btn := _dev_make_button(str(amt))
		btn.pressed.connect(func():
			for i in range(GameManager.building_counts.size()):
				GameManager.building_counts[i] = amt
			GameManager._recalculate_lps()
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)
			# Refresh building list
			for child in building_container.get_children():
				if child.has_method("_refresh"):
					child._refresh())
		bldg_row.add_child(btn)

	# --- Reset ---
	_dev_add_section(vbox, "⚠️ Danger Zone")
	var reset_btn := _dev_make_button("RESET ALL PROGRESS")
	reset_btn.add_theme_color_override("font_color", Color("#ff4444"))
	reset_btn.pressed.connect(func():
		GameManager.total_lobsters = 0.0
		GameManager.lifetime_lobsters = 0.0
		GameManager.lobsters_per_click = 1.0
		GameManager.lobsters_per_second = 0.0
		GameManager.farm_name = "My Lobster Farm"
		GameManager.building_counts.fill(0)
		GameManager.click_upgrades_purchased.fill(false)
		GameManager.cps_click_upgrades_purchased.fill(false)
		GameManager._init_building_upgrades()
		GameManager._recalculate_lps()
		GameManager._recalculate_click_power()
		GameManager.lobsters_changed.emit(0.0)
		GameManager.lps_changed.emit(0.0)
		farm_name_button.text = "My Lobster Farm"
		SaveManager.save_game()
		for child in building_container.get_children():
			if child.has_method("_refresh"):
				child._refresh()
		if current_tab == Tab.UPGRADES:
			_refresh_upgrades()
		_dev_popup.queue_free())
	vbox.add_child(reset_btn)

	# --- Close ---
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)
	var close_btn := _dev_make_button("CLOSE")
	close_btn.pressed.connect(func(): _dev_popup.queue_free())
	vbox.add_child(close_btn)

	add_child(_dev_popup)

func _dev_add_section(parent: VBoxContainer, title: String) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color("#334455"))
	parent.add_child(sep)
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", Color("#aabbcc"))
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)

func _dev_make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a2a3a")
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", style)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#2a3a4a")
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	hover.content_margin_left = 6.0
	hover.content_margin_right = 6.0
	hover.content_margin_top = 4.0
	hover.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	return btn

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

# Periodically check if new click upgrades unlocked (every 60 frames)
var _last_click_upgrade_count: int = 0
func _check_click_upgrades() -> void:
	var count := GameManager.get_available_click_upgrades().size()
	if count > _last_click_upgrade_count:
		_last_click_upgrade_count = count
		_flash_active = true
		_flash_timer = 0.0
		if current_tab == Tab.UPGRADES:
			_refresh_upgrades()

func _refresh_upgrades() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

	var has_any := false

	# Click upgrades first (flat multipliers + CPS-based)
	var click_upgrades := GameManager.get_available_click_upgrades()
	var cps_click_upgrades := GameManager.get_available_cps_click_upgrades()
	if not click_upgrades.is_empty() or not cps_click_upgrades.is_empty():
		has_any = true
		var header := Label.new()
		header.text = "🦞 CLICK POWER"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_color_override("font_color", Color("#ff6b6b"))
		header.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(header)
		for upg in click_upgrades:
			var item := BuildingUpgradeItemScene.instantiate()
			upgrade_container.add_child(item)
			item.setup_click_upgrade(upg["index"], upg["purchased"])
		for upg in cps_click_upgrades:
			var item := BuildingUpgradeItemScene.instantiate()
			upgrade_container.add_child(item)
			item.setup_cps_click_upgrade(upg["index"], upg["purchased"])

	# Building upgrades
	var building_upgrades := GameManager.get_available_upgrades()
	if not building_upgrades.is_empty():
		has_any = true
		var header := Label.new()
		header.text = "🏗️ BUILDING UPGRADES"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_color_override("font_color", Color("#ffd766"))
		header.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(header)
		for upg in building_upgrades:
			var item := BuildingUpgradeItemScene.instantiate()
			upgrade_container.add_child(item)
			item.setup(upg["building_index"], upg["tier"], upg["purchased"])

	if not has_any:
		var empty_label := Label.new()
		empty_label.text = "No upgrades available yet.\nBuy more buildings to unlock!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color("#667788"))
		empty_label.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(empty_label)
