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
@onready var boost_aura: CPUParticles2D = %BoostAura
@onready var building_container: VBoxContainer = %BuildingContainer
@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var particles: CPUParticles2D = %ClickParticles
@onready var float_text_container: Node2D = %FloatTextContainer
@onready var offline_popup: PanelContainer = %OfflinePopup
@onready var offline_label: Label = %OfflineLabel
@onready var offline_ok_button: Button = %OfflineOkButton
@onready var buildings_tab: Button = %BuildingsTab
@onready var upgrades_tab: Button = %UpgradesTab
@onready var consumables_tab: Button = %ConsumablesTab
@onready var consumables_container: VBoxContainer = %ConsumablesContainer
@onready var gacha_cost_label: Label = %GachaCostLabel
@onready var buy_capsule_button: Button = %BuyCapsuleButton
@onready var result_panel: VBoxContainer = %ResultPanel
@onready var rarity_label: Label = %RarityLabel
@onready var boost_name_label: Label = %BoostNameLabel
@onready var boost_desc_label: Label = %BoostDescLabel
@onready var timer_label: Label = %TimerLabel
@onready var boost_hud_label: Label = %BoostHudLabel
@onready var scroll_up_btn: Button = %ScrollUpButton
@onready var scroll_down_btn: Button = %ScrollDownButton
@onready var root_container: BoxContainer = %RootContainer
@onready var left_section: VBoxContainer = %LeftSection
@onready var right_panel: PanelContainer = %RightPanel
@onready var premium_cost_label: Label = %PremiumCostLabel
@onready var buy_premium_button: Button = %BuyPremiumButton
@onready var premium_options_container: VBoxContainer = %PremiumOptionsContainer
@onready var music_player: AudioStreamPlayer = %MusicPlayer

# Animation: move pincers via X position (no rotation!)
const OPEN_X := 22.0
const SHUT_X := 3.0
const SNAP_SPEED := 14.0
const OPEN_SPEED := 3.5

enum ClawState { IDLE, SNAPPING, OPENING }
var claw_state: int = ClawState.IDLE
var claw_progress: float = 0.0

enum Tab { BUILDINGS, UPGRADES, CONSUMABLES }
var current_tab: int = Tab.BUILDINGS

# Gacha animation state
var _gacha_opening: bool = false
var _gacha_opening_timer: float = 0.0

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
	consumables_tab.pressed.connect(_on_consumables_tab)
	buy_capsule_button.pressed.connect(_on_buy_capsule)
	buy_premium_button.pressed.connect(_on_buy_premium)
	GameManager.boost_activated.connect(_on_boost_activated)
	GameManager.boost_expired.connect(_on_boost_expired)
	GameManager.premium_boost_activated.connect(_on_premium_boost_activated)
	_style_buy_capsule_button()
	_style_buy_premium_button()
	consumables_tab.visible = GameManager.lifetime_lobsters >= 2500

	# Scroll buttons
	var sc: ScrollContainer = %RightPanel.get_node("VBox/ScrollContainer")
	scroll_up_btn.pressed.connect(func(): sc.scroll_vertical = max(0, sc.scroll_vertical - 150))
	scroll_down_btn.pressed.connect(func(): sc.scroll_vertical += 150)

	_start_music()

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
		offline_label.text = "Welcome back!\nYou earned %s Lobster Coins\nwhile you were away!" % GameManager.format_number(SaveManager.offline_earnings)
		offline_popup.visible = true
	else:
		offline_popup.visible = false

func _process(delta: float) -> void:
	# Hold-to-click: auto-fire clicks while holding
	if _is_holding and GameManager.is_hold_click_unlocked():
		_hold_timer += delta
		if _hold_timer > 0.3:  # 300ms grace period before auto-click starts
			var rate := GameManager.get_hold_click_rate()
			_hold_click_accumulator += delta * rate
			while _hold_click_accumulator >= 1.0:
				_hold_click_accumulator -= 1.0
				_do_click()

	# Update boost HUD and consumables timer
	_update_boost_hud(delta)

	# Gacha opening animation
	if _gacha_opening:
		_gacha_opening_timer -= delta
		if _gacha_opening_timer <= 0:
			_gacha_opening = false
			_finish_gacha_roll()

	# Check consumables tab visibility
	if not consumables_tab.visible and GameManager.lifetime_lobsters >= 2500:
		consumables_tab.visible = true

	# Update gacha cost display when on consumables tab
	if current_tab == Tab.CONSUMABLES and Engine.get_process_frames() % 30 == 0:
		_update_gacha_cost()

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
		scroll_up_btn.visible = false
		scroll_down_btn.visible = false
	else:
		# Mobile: stacked vertically (VBox), claw compact on top, buildings get more space
		root_container.vertical = true
		left_section.size_flags_stretch_ratio = 0.5
		right_panel.size_flags_stretch_ratio = 1.2
		left_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_up_btn.visible = true
		scroll_down_btn.visible = true

func _on_lobsters_changed(total: float) -> void:
	lobster_count_label.text = GameManager.format_number(total)
	lifetime_label.text = "%s lifetime LC" % GameManager.format_number(GameManager.lifetime_lobsters)

func _on_lps_changed(_lps: float) -> void:
	_update_lps_display()

func _update_lps_display() -> void:
	var base_lps := GameManager.lobsters_per_second
	var boost_mult := GameManager.get_gacha_boost_multiplier("building_mult")
	var effective_lps := base_lps * boost_mult
	# Add single building boost bonus to display
	if GameManager.single_building_boost_time > 0 and GameManager.single_building_boost_index >= 0:
		var bi := GameManager.single_building_boost_index
		var boosted_lps: float = GameManager.building_counts[bi] * float(GameManager.building_defs[bi]["lps"]) * GameManager.get_building_multiplier(bi)
		effective_lps += boosted_lps * (GameManager.single_building_boost_mult - 1.0) * boost_mult
	if effective_lps < 1.0 and effective_lps > 0:
		lps_label.text = "%.1f LCPS" % effective_lps
	else:
		lps_label.text = "%s LCPS" % GameManager.format_number(effective_lps)
	if boost_mult > 1.0 or GameManager.single_building_boost_time > 0:
		lps_label.add_theme_color_override("font_color", Color("#f39c12"))
	else:
		lps_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.8, 1))

var _click_debounce: float = 0.0
const CLICK_DEBOUNCE_TIME := 0.05

# Hold-to-click state
var _is_holding: bool = false
var _hold_timer: float = 0.0
var _hold_click_accumulator: float = 0.0

func _on_claw_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			claw_button.accept_event()
			_try_click()
			_is_holding = true
			_hold_timer = 0.0
			_hold_click_accumulator = 0.0
		else:
			_is_holding = false
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			claw_button.accept_event()
			_try_click()
			_is_holding = true
			_hold_timer = 0.0
			_hold_click_accumulator = 0.0
		else:
			_is_holding = false
		return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if claw_button and claw_button.get_global_rect().has_point(event.position):
				get_viewport().set_input_as_handled()
				_try_click()
				_is_holding = true
				_hold_timer = 0.0
				_hold_click_accumulator = 0.0
		else:
			_is_holding = false

func _start_music() -> void:
	if music_player and not music_player.playing:
		music_player.play()

func _try_click() -> void:
	_start_music()
	var now := Time.get_ticks_msec() / 1000.0
	if now - _click_debounce < CLICK_DEBOUNCE_TIME:
		return
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
	_dev_add_section(vbox, "Add Current LC")
	var lobster_amounts := [1000, 10000, 100000, 1000000, 10000000]
	var lobster_row := HBoxContainer.new()
	lobster_row.add_theme_constant_override("separation", 6)
	vbox.add_child(lobster_row)
	for amt in lobster_amounts:
		var btn := _dev_make_button("+%s" % GameManager.format_number(amt))
		btn.pressed.connect(func(): GameManager.total_lobsters += amt; GameManager.lobsters_changed.emit(GameManager.total_lobsters))
		lobster_row.add_child(btn)

	# --- Add Lifetime Lobsters ---
	_dev_add_section(vbox, "Add Lifetime LC")
	var lifetime_row := HBoxContainer.new()
	lifetime_row.add_theme_constant_override("separation", 6)
	vbox.add_child(lifetime_row)
	for amt in lobster_amounts:
		var btn := _dev_make_button("+%s" % GameManager.format_number(amt))
		btn.pressed.connect(func(): GameManager.lifetime_lobsters += amt; GameManager.total_lobsters += amt; GameManager.lobsters_changed.emit(GameManager.total_lobsters))
		lifetime_row.add_child(btn)

	# --- Set LPS ---
	_dev_add_section(vbox, "Set LCPS")
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
		GameManager.active_boost = {}
		GameManager.boost_time_remaining = 0.0
		GameManager.hold_click_purchased.fill(false)
		GameManager.gacha_cooldown_upgrades_purchased.fill(false)
		GameManager.offline_rate_purchased.fill(false)
		GameManager.offline_duration_purchased.fill(false)
		GameManager.gacha_cooldown_remaining = 0.0
		GameManager.flat_lcps_bonus = 0.0
		GameManager.single_building_boost_index = -1
		GameManager.single_building_boost_mult = 1.0
		GameManager.single_building_boost_time = 0.0
		GameManager._init_building_upgrades()
		GameManager._recalculate_lps()
		GameManager._recalculate_click_power()
		GameManager.lobsters_changed.emit(0.0)
		GameManager.lps_changed.emit(0.0)
		farm_name_button.text = "My Lobster Farm"
		consumables_tab.visible = false
		_switch_tab(Tab.BUILDINGS)
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
	consumables_container.visible = (tab == Tab.CONSUMABLES)
	_update_tab_styles()
	if tab == Tab.CONSUMABLES:
		_update_gacha_cost()
		_update_capsule_button_affordability()
		_update_premium_button_affordability()

func _update_tab_styles() -> void:
	var active_color := Color("#ffd766")
	var inactive_color := Color("#667788")
	buildings_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.BUILDINGS else inactive_color)
	upgrades_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.UPGRADES else inactive_color)
	consumables_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.CONSUMABLES else inactive_color)

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

var _hide_purchased: bool = false
var _collapsed_sections: Dictionary = {}  # section_name -> bool

func _refresh_upgrades() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

	# Hide purchased toggle
	var toggle_btn := Button.new()
	toggle_btn.text = "Show all upgrades" if _hide_purchased else "Show only available upgrades"
	toggle_btn.flat = true
	toggle_btn.add_theme_color_override("font_color", Color("#88aacc"))
	toggle_btn.add_theme_font_size_override("font_size", 16)
	toggle_btn.pressed.connect(func():
		_hide_purchased = not _hide_purchased
		_refresh_upgrades())
	upgrade_container.add_child(toggle_btn)

	var has_any := false

	# Click upgrades
	var click_items: Array = []
	for upg in GameManager.get_available_click_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			click_items.append(func(item): item.setup_click_upgrade(upg["index"], upg["purchased"]))
	for upg in GameManager.get_available_cps_click_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			click_items.append(func(item): item.setup_cps_click_upgrade(upg["index"], upg["purchased"]))
	for upg in GameManager.get_available_hold_click_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			click_items.append(func(item): item.setup_hold_click_upgrade(upg["index"], upg["purchased"]))
	if not click_items.is_empty():
		has_any = true
		_add_collapsible_section("🦞 CLICK POWER", "click_power", Color("#ff6b6b"), click_items)

	# Building upgrades
	var bldg_items: Array = []
	for upg in GameManager.get_available_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			bldg_items.append(func(item): item.setup(upg["building_index"], upg["tier"], upg["purchased"]))
	if not bldg_items.is_empty():
		has_any = true
		_add_collapsible_section("🏗️ BUILDING UPGRADES", "building_upgrades", Color("#ffd766"), bldg_items)

	# Offline upgrades (rate + duration combined)
	var offline_items: Array = []
	for upg in GameManager.get_available_offline_rate_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			offline_items.append(func(item): item.setup_offline_rate_upgrade(upg["index"], upg["purchased"]))
	for upg in GameManager.get_available_offline_duration_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			offline_items.append(func(item): item.setup_offline_duration_upgrade(upg["index"], upg["purchased"]))
	if not offline_items.is_empty():
		has_any = true
		_add_collapsible_section("🌙 OFFLINE PRODUCTION", "offline", Color("#5dade2"), offline_items)

	# Gacha cooldown upgrades
	var gacha_items: Array = []
	for upg in GameManager.get_available_gacha_cooldown_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			gacha_items.append(func(item): item.setup_gacha_cd_upgrade(upg["index"], upg["purchased"]))
	if not gacha_items.is_empty():
		has_any = true
		_add_collapsible_section("🎰 GACHA UPGRADES", "gacha", Color("#e67e22"), gacha_items)

	if not has_any:
		var empty_label := Label.new()
		if _hide_purchased:
			empty_label.text = "All available upgrades purchased! 🎉"
		else:
			empty_label.text = "No upgrades available yet.\nBuy more buildings to unlock!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color("#667788"))
		empty_label.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(empty_label)

func _add_collapsible_section(title: String, key: String, color: Color, items: Array) -> void:
	var is_collapsed: bool = _collapsed_sections.get(key, false)

	# Header button
	var header_btn := Button.new()
	header_btn.text = ("▶ " if is_collapsed else "▼ ") + title
	header_btn.flat = true
	header_btn.add_theme_color_override("font_color", color)
	header_btn.add_theme_font_size_override("font_size", 18)
	header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Items container
	var items_box := VBoxContainer.new()
	items_box.add_theme_constant_override("separation", 6)
	items_box.visible = not is_collapsed

	header_btn.pressed.connect(func():
		_collapsed_sections[key] = not _collapsed_sections.get(key, false)
		items_box.visible = not _collapsed_sections[key]
		header_btn.text = ("▶ " if _collapsed_sections[key] else "▼ ") + title)

	upgrade_container.add_child(header_btn)
	upgrade_container.add_child(items_box)

	for setup_fn in items:
		var item := BuildingUpgradeItemScene.instantiate()
		items_box.add_child(item)
		setup_fn.call(item)

# --- Consumables / Gacha ---

func _on_consumables_tab() -> void:
	_switch_tab(Tab.CONSUMABLES)

func _style_buy_capsule_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e67e22")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	buy_capsule_button.add_theme_stylebox_override("normal", style)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#d35400")
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	hover.content_margin_left = 12.0
	hover.content_margin_right = 12.0
	hover.content_margin_top = 8.0
	hover.content_margin_bottom = 8.0
	buy_capsule_button.add_theme_stylebox_override("hover", hover)
	buy_capsule_button.add_theme_stylebox_override("pressed", hover)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#555555")
	disabled.corner_radius_top_left = 8
	disabled.corner_radius_top_right = 8
	disabled.corner_radius_bottom_left = 8
	disabled.corner_radius_bottom_right = 8
	disabled.content_margin_left = 12.0
	disabled.content_margin_right = 12.0
	disabled.content_margin_top = 8.0
	disabled.content_margin_bottom = 8.0
	buy_capsule_button.add_theme_stylebox_override("disabled", disabled)

func _update_gacha_cost() -> void:
	var cost := GameManager.get_gacha_cost()
	gacha_cost_label.text = "Capsule Cost: %s" % GameManager.format_number(cost)
	premium_cost_label.text = "Card Cost: %s" % GameManager.format_number(GameManager.get_premium_cost())
	_update_capsule_button_affordability()
	_update_premium_button_affordability()

func _update_capsule_button_affordability() -> void:
	var cost := GameManager.get_gacha_cost()
	var can_afford := GameManager.total_lobsters >= cost
	var on_cooldown := GameManager.is_gacha_on_cooldown()
	buy_capsule_button.disabled = not can_afford or _gacha_opening or on_cooldown
	if on_cooldown and not _gacha_opening:
		buy_capsule_button.text = "⏳ %ds" % ceili(GameManager.get_gacha_wait_time())
	elif not _gacha_opening:
		buy_capsule_button.text = "🎲 BUY CAPSULE"

var _pending_gacha_result: Dictionary = {}

func _on_buy_capsule() -> void:
	if _gacha_opening:
		return
	var result := GameManager.roll_gacha()
	if result.is_empty():
		return
	_pending_gacha_result = result
	# Show opening animation
	_gacha_opening = true
	_gacha_opening_timer = 0.6
	result_panel.visible = true
	rarity_label.text = "Opening..."
	rarity_label.add_theme_color_override("font_color", Color("#ffffff"))
	boost_name_label.text = "🎲 🎲 🎲"
	boost_name_label.add_theme_color_override("font_color", Color("#ffffff"))
	boost_desc_label.text = ""
	timer_label.text = ""
	_update_gacha_cost()

func _finish_gacha_roll() -> void:
	var result := _pending_gacha_result
	if result.is_empty():
		return
	var rarity: String = result["rarity"]
	var color := Color(GameManager.RARITY_COLORS[rarity])
	var rarity_display := rarity.to_upper()
	if rarity == "legendary":
		rarity_label.text = "★ %s ★" % rarity_display
	elif rarity == "rare":
		rarity_label.text = "◆ %s ◆" % rarity_display
	elif rarity == "uncommon":
		rarity_label.text = "● %s ●" % rarity_display
	else:
		rarity_label.text = rarity_display
	rarity_label.add_theme_color_override("font_color", color)
	boost_name_label.text = result["name"]
	boost_name_label.add_theme_color_override("font_color", color)
	boost_desc_label.text = "%s for %ds" % [result["desc"], int(result["duration"])]
	_update_gacha_cost()

const RARITY_COLORS := {
	"common": Color(0.9, 0.9, 0.9, 0.85),
	"uncommon": Color(0.3, 0.65, 0.95, 0.9),
	"rare": Color(0.7, 0.4, 0.85, 0.9),
	"legendary": Color(1.0, 0.75, 0.1, 0.95),
}

func _on_boost_activated(boost: Dictionary) -> void:
	_update_boost_hud_display()
	_update_lps_display()
	# Activate aura
	var rarity: String = boost.get("rarity", "common")
	var aura_color: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	boost_aura.color = aura_color
	# Scale intensity by rarity
	if rarity == "legendary":
		boost_aura.amount = 60
		boost_aura.scale_amount_min = 10.0
		boost_aura.scale_amount_max = 20.0
		boost_aura.initial_velocity_max = 70.0
		boost_aura.emission_sphere_radius = 100.0
	elif rarity == "rare":
		boost_aura.amount = 50
		boost_aura.scale_amount_min = 8.0
		boost_aura.scale_amount_max = 16.0
		boost_aura.initial_velocity_max = 60.0
		boost_aura.emission_sphere_radius = 90.0
	elif rarity == "uncommon":
		boost_aura.amount = 40
		boost_aura.scale_amount_min = 6.0
		boost_aura.scale_amount_max = 14.0
		boost_aura.initial_velocity_max = 50.0
		boost_aura.emission_sphere_radius = 80.0
	else:
		boost_aura.amount = 35
		boost_aura.scale_amount_min = 5.0
		boost_aura.scale_amount_max = 12.0
		boost_aura.initial_velocity_max = 45.0
		boost_aura.emission_sphere_radius = 75.0
	boost_aura.restart()
	boost_aura.emitting = true

func _on_boost_expired() -> void:
	_update_boost_hud_display()
	_update_lps_display()
	if GameManager.active_boost.is_empty() and GameManager.boost_time_remaining <= 0:
		boost_aura.emitting = false
	if result_panel.visible and GameManager.boost_time_remaining <= 0:
		timer_label.text = "Expired!"
		timer_label.add_theme_color_override("font_color", Color("#667788"))

func _update_boost_hud(delta: float) -> void:
	if (GameManager.boost_time_remaining > 0 and not GameManager.active_boost.is_empty()) or GameManager.single_building_boost_time > 0:
		_update_boost_hud_display()
		_update_lps_display()
		# Update timer in result panel
		if result_panel.visible and GameManager.boost_time_remaining > 0:
			timer_label.text = "%.1fs remaining" % GameManager.boost_time_remaining
			timer_label.add_theme_color_override("font_color", Color("#ffd766"))
	# Update capsule button affordability periodically
	if current_tab == Tab.CONSUMABLES:
		_update_capsule_button_affordability()
		_update_premium_button_affordability()

func _update_boost_hud_display() -> void:
	var lines: Array = []
	if not GameManager.active_boost.is_empty() and GameManager.boost_time_remaining > 0:
		var b := GameManager.active_boost
		lines.append("%s — %sx %s (%.0fs)" % [b["name"], str(b["mult"]), "buildings" if b["type"] == "building_mult" else "clicks", GameManager.boost_time_remaining])
	if GameManager.single_building_boost_time > 0 and GameManager.single_building_boost_index >= 0:
		var bname: String = GameManager.building_defs[GameManager.single_building_boost_index]["name"]
		lines.append("⚡ %s — %sx (%.0fs)" % [bname, str(GameManager.single_building_boost_mult), GameManager.single_building_boost_time])
	if lines.is_empty():
		boost_hud_label.visible = false
		return
	boost_hud_label.visible = true
	boost_hud_label.text = "\n".join(lines)
	if not GameManager.active_boost.is_empty() and GameManager.boost_time_remaining > 0:
		var b := GameManager.active_boost
		boost_hud_label.add_theme_color_override("font_color", Color(GameManager.RARITY_COLORS[b["rarity"]]))
	else:
		boost_hud_label.add_theme_color_override("font_color", Color("#f39c12"))

# --- Lobster Cards ---

func _style_buy_premium_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#9b59b6")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	buy_premium_button.add_theme_stylebox_override("normal", style)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#8e44ad")
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	hover.content_margin_left = 12.0
	hover.content_margin_right = 12.0
	hover.content_margin_top = 8.0
	hover.content_margin_bottom = 8.0
	buy_premium_button.add_theme_stylebox_override("hover", hover)
	buy_premium_button.add_theme_stylebox_override("pressed", hover)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#555555")
	disabled.corner_radius_top_left = 8
	disabled.corner_radius_top_right = 8
	disabled.corner_radius_bottom_left = 8
	disabled.corner_radius_bottom_right = 8
	disabled.content_margin_left = 12.0
	disabled.content_margin_right = 12.0
	disabled.content_margin_top = 8.0
	disabled.content_margin_bottom = 8.0
	buy_premium_button.add_theme_stylebox_override("disabled", disabled)

func _update_premium_button_affordability() -> void:
	var cost := GameManager.get_premium_cost()
	var can_afford := GameManager.total_lobsters >= cost
	var on_cooldown := GameManager.is_gacha_on_cooldown()
	buy_premium_button.disabled = not can_afford or on_cooldown or premium_options_container.visible
	if on_cooldown and not premium_options_container.visible:
		buy_premium_button.text = "⏳ %ds" % ceili(GameManager.get_gacha_wait_time())
	elif not premium_options_container.visible:
		buy_premium_button.text = "🃏 DRAW CARDS"

func _on_buy_premium() -> void:
	if GameManager.is_gacha_on_cooldown():
		return
	var cost := GameManager.get_premium_cost()
	if GameManager.total_lobsters < cost:
		return
	GameManager.total_lobsters -= cost
	GameManager.lobsters_changed.emit(GameManager.total_lobsters)
	var options := GameManager.roll_premium_options()
	_show_premium_options(options)

func _show_premium_options(options: Array) -> void:
	# Clear previous options
	for child in premium_options_container.get_children():
		child.queue_free()
	premium_options_container.visible = true
	buy_premium_button.disabled = true

	for opt in options:
		var card := _create_option_card(opt)
		premium_options_container.add_child(card)

func _create_option_card(boost: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var rarity: String = boost["rarity"]
	var rarity_color := Color(GameManager.RARITY_COLORS[rarity])

	var style := StyleBoxFlat.new()
	style.bg_color = Color(rarity_color, 0.1)
	style.border_width_left = 3
	style.border_color = rarity_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Rarity badge
	var rarity_lbl := Label.new()
	var rarity_display := rarity.to_upper()
	if rarity == "legendary":
		rarity_lbl.text = "★ %s ★" % rarity_display
	elif rarity == "rare":
		rarity_lbl.text = "◆ %s ◆" % rarity_display
	elif rarity == "uncommon":
		rarity_lbl.text = "● %s ●" % rarity_display
	else:
		rarity_lbl.text = rarity_display
	rarity_lbl.add_theme_color_override("font_color", rarity_color)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(rarity_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = boost["name"]
	name_lbl.add_theme_color_override("font_color", rarity_color)
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = boost["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "SELECT"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.add_theme_font_size_override("font_size", 18)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = rarity_color.darkened(0.3)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.content_margin_left = 8.0
	btn_style.content_margin_right = 8.0
	btn_style.content_margin_top = 4.0
	btn_style.content_margin_bottom = 4.0
	select_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = rarity_color.darkened(0.1)
	btn_hover.corner_radius_top_left = 6
	btn_hover.corner_radius_top_right = 6
	btn_hover.corner_radius_bottom_left = 6
	btn_hover.corner_radius_bottom_right = 6
	btn_hover.content_margin_left = 8.0
	btn_hover.content_margin_right = 8.0
	btn_hover.content_margin_top = 4.0
	btn_hover.content_margin_bottom = 4.0
	select_btn.add_theme_stylebox_override("hover", btn_hover)
	select_btn.add_theme_stylebox_override("pressed", btn_hover)
	select_btn.pressed.connect(_on_premium_option_selected.bind(boost))
	vbox.add_child(select_btn)

	return card

func _on_premium_option_selected(boost: Dictionary) -> void:
	GameManager.activate_premium_boost(boost)
	premium_options_container.visible = false
	_update_gacha_cost()

func _on_premium_boost_activated(boost: Dictionary) -> void:
	var btype: String = boost["type"]
	# Show result in the gacha result panel for timed boosts
	if btype == "building_mult" or btype == "click_mult":
		result_panel.visible = true
		var rarity: String = boost["rarity"]
		var color := Color(GameManager.RARITY_COLORS[rarity])
		rarity_label.text = "★ %s ★" % rarity.to_upper() if rarity == "legendary" else rarity.to_upper()
		rarity_label.add_theme_color_override("font_color", color)
		boost_name_label.text = boost["name"]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = "%s for %ds" % [boost["desc"], int(boost["duration"])]
	elif btype == "flat_lcps":
		result_panel.visible = true
		var color := Color(GameManager.RARITY_COLORS[boost["rarity"]])
		rarity_label.text = "PERMANENT"
		rarity_label.add_theme_color_override("font_color", color)
		boost_name_label.text = boost["name"]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = boost["desc"]
		timer_label.text = "Applied! Total flat bonus: +%s LCPS" % GameManager.format_number(GameManager.flat_lcps_bonus)
		timer_label.add_theme_color_override("font_color", Color("#2ecc71"))
	elif btype == "free_building":
		result_panel.visible = true
		var color := Color(GameManager.RARITY_COLORS[boost["rarity"]])
		rarity_label.text = "FREE BUILDING"
		rarity_label.add_theme_color_override("font_color", color)
		boost_name_label.text = boost["name"]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = boost["desc"]
		timer_label.text = "Added!"
		timer_label.add_theme_color_override("font_color", Color("#2ecc71"))
		# Refresh building list
		for child in building_container.get_children():
			if child.has_method("_refresh"):
				child._refresh()
	elif btype == "single_building_boost":
		var bname: String = GameManager.building_defs[GameManager.single_building_boost_index]["name"]
		result_panel.visible = true
		var color := Color(GameManager.RARITY_COLORS[boost["rarity"]])
		rarity_label.text = rarity_label.text if not rarity_label.text.is_empty() else boost["rarity"].to_upper()
		rarity_label.add_theme_color_override("font_color", color)
		boost_name_label.text = "%s → %s" % [boost["name"], bname]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = "%sx %s for %ds" % [str(boost["mult"]), bname, int(boost["duration"])]
		timer_label.text = ""
	_update_lps_display()
