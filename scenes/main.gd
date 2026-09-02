extends Control

const BuildingItemScene := preload("res://scenes/building_item.tscn")
const BuildingUpgradeItemScene := preload("res://scenes/building_upgrade_item.tscn")
const ClawSnapSfx := preload("res://assets/sfx/claw_snap.wav")
const PurchaseSfx := preload("res://assets/sfx/purchase.wav")
const AchievementSfx := preload("res://assets/sfx/achievement.wav")
const DiscoSfx := preload("res://assets/sfx/disco.wav")
const MoltSfx := preload("res://assets/sfx/molt.wav")
const UiFont := preload("res://assets/fonts/atkinson-hyperlegible/AtkinsonHyperlegible-Regular.ttf")
const UiBoldFont := preload("res://assets/fonts/atkinson-hyperlegible/AtkinsonHyperlegible-Bold.ttf")
const DisplayFont := preload("res://assets/fonts/bungee/Bungee-Regular.ttf")
const ClawPowerIcon := preload("res://assets/art/ui/medallions/claw_power.png")
const BuildingPowerIcon := preload("res://assets/art/ui/medallions/building_power.png")
const OfflinePowerIcon := preload("res://assets/art/ui/medallions/offline_power.png")
const BoostPowerIcon := preload("res://assets/art/ui/medallions/boost_power.png")
const AchievementMedalIcon := preload("res://assets/art/ui/medallions/achievement_medal.png")
const ClawPinchFrames: Array[Texture2D] = [
	preload("res://assets/art/ui/claw_animation/claw_pinch_0.png"),
	preload("res://assets/art/ui/claw_animation/claw_pinch_1.png"),
	preload("res://assets/art/ui/claw_animation/claw_pinch_2.png"),
	preload("res://assets/art/ui/claw_animation/claw_pinch_3.png"),
	preload("res://assets/art/ui/claw_animation/claw_pinch_4.png"),
	preload("res://assets/art/ui/claw_animation/claw_pinch_5.png"),
]

const DEEP_HARBOR := Color("#071725")
const DOCK_NAVY := Color("#10283a")
const LOBSTER_CORAL := Color("#e9553f")
const SHELL_HIGHLIGHT := Color("#ff846b")
const COIN_GOLD := Color("#ffd166")
const SEAFOAM := Color("#55d6be")
const FOAM_WHITE := Color("#eaf6f8")
const MIST_BLUE := Color("#94b8c7")

@onready var farm_name_button: Button = %FarmNameButton
@onready var farm_name_edit: LineEdit = %FarmNameEdit
@onready var lobster_count_label: Label = %LobsterCountLabel
@onready var score_panel: PanelContainer = %ScorePanel
@onready var score_header: Label = %ScoreHeader
@onready var lobster_word: Label = %LobsterWord
@onready var lps_label: Label = %LpsLabel
@onready var lifetime_label: Label = %LifetimeLabel
@onready var claw_button: Button = %ClawButton
@onready var hero_claw: TextureRect = %HeroClaw
@onready var left_pincer: Node2D = %LeftPincer
@onready var right_pincer: Node2D = %RightPincer
@onready var boost_aura: CPUParticles2D = %BoostAura
@onready var building_container: VBoxContainer = %BuildingContainer
@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var click_effects: Node2D = %ClickEffects
@onready var float_text_container: Node2D = %FloatTextContainer
@onready var offline_popup: PanelContainer = %OfflinePopup
@onready var offline_icon: TextureRect = %OfflineIcon
@onready var offline_title: Label = %OfflineTitle
@onready var offline_label: Label = %OfflineLabel
@onready var offline_ok_button: Button = %OfflineOkButton
@onready var buildings_tab: Button = %BuildingsTab
@onready var upgrades_tab: Button = %UpgradesTab
@onready var consumables_tab: Button = %ConsumablesTab
@onready var molt_tab: Button = %MoltTab
@onready var consumables_container: VBoxContainer = %ConsumablesContainer
@onready var molt_container: VBoxContainer = %MoltContainer
@onready var shell_count_label: Label = %ShellCountLabel
@onready var molt_bonus_label: Label = %MoltBonusLabel
@onready var molt_progress_label: Label = %MoltProgressLabel
@onready var molt_progress_bar: ProgressBar = %MoltProgressBar
@onready var molt_next_label: Label = %MoltNextLabel
@onready var molt_button: Button = %MoltButton
@onready var gacha_cost_label: Label = %GachaCostLabel
@onready var buy_capsule_button: Button = %BuyCapsuleButton
@onready var result_panel: PanelContainer = %ResultPanel
@onready var capsule_machine_frame: PanelContainer = %CapsuleMachineFrame
@onready var capsule_machine: TextureRect = %CapsuleMachine
@onready var rarity_label: Label = %RarityLabel
@onready var boost_name_label: Label = %BoostNameLabel
@onready var boost_desc_label: Label = %BoostDescLabel
@onready var timer_label: Label = %TimerLabel
@onready var boost_hud_label: Label = %BoostHudLabel
@onready var scroll_up_btn: Button = %ScrollUpButton
@onready var scroll_down_btn: Button = %ScrollDownButton
@onready var content_scroll: ScrollContainer = %ScrollContainer
@onready var root_container: BoxContainer = %RootContainer
@onready var left_section: VBoxContainer = %LeftSection
@onready var right_panel: PanelContainer = %RightPanel
@onready var premium_cost_label: Label = %PremiumCostLabel
@onready var buy_premium_button: Button = %BuyPremiumButton
@onready var premium_options_container: VBoxContainer = %PremiumOptionsContainer
@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var objective_label: Label = %ClickHint
@onready var buy_one_button: Button = %BuyOneButton
@onready var buy_ten_button: Button = %BuyTenButton
@onready var buy_max_button: Button = %BuyMaxButton
@onready var bulk_buy_row: HBoxContainer = %BulkBuyRow
@onready var title_label: Label = %Title

var mute_button: Button
var settings_button: Button
var milestones_button: Button
var _music_muted: bool = false
var _toast_panel: PanelContainer
var _toast_tween: Tween
var _toast_queue: Array[Dictionary] = []
var _celebration_layer: Control
var _celebration_tween: Tween
var _score_pulse_tween: Tween
var _boost_ui_timer: float = 0.0
var _claw_bump_tween: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player: int = 0

# Hand-drawn animation timing: anticipation, close, impact, recoil, recovery, idle.
const CLAW_FRAME_SEQUENCE: Array[int] = [1, 2, 3, 4, 5, 0]
const CLAW_FRAME_DURATIONS: Array[float] = [0.055, 0.045, 0.075, 0.055, 0.07, 0.0]

enum ClawState { IDLE, SNAPPING, OPENING }
var claw_state: int = ClawState.IDLE
var claw_progress: float = 0.0
var _claw_animation_index: int = 0

enum Tab { BUILDINGS, UPGRADES, CONSUMABLES, MOLT }
var current_tab: int = Tab.BUILDINGS

# Gacha animation state
var _gacha_opening: bool = false
var _gacha_opening_timer: float = 0.0

# Flash state for upgrades tab
var _flash_timer: float = 0.0
var _flash_active: bool = false

# Responsive layout
const MOBILE_BREAKPOINT := 700  # Below this width = mobile (vertical stack)
const DESKTOP_LEFT_PANEL_SHARE := 1.0 / 2.2
var _is_desktop: bool = true
var _last_width: int = 0

func _ready() -> void:
	_install_accessible_focus_theme()
	_install_visual_polish()
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
	molt_tab.pressed.connect(_on_molt_tab)
	molt_button.pressed.connect(_show_molt_confirmation)
	buy_capsule_button.pressed.connect(_on_buy_capsule)
	buy_premium_button.pressed.connect(_on_buy_premium)
	GameManager.boost_activated.connect(_on_boost_activated)
	GameManager.boost_expired.connect(_on_boost_expired)
	GameManager.premium_boost_activated.connect(_on_premium_boost_activated)
	GameManager.achievement_unlocked.connect(_on_achievement_unlocked)
	GameManager.objective_changed.connect(_on_objective_changed)
	GameManager.molt_completed.connect(_on_molt_completed)
	SaveManager.offline_earnings_calculated.connect(_show_offline_report)
	buy_one_button.pressed.connect(func(): GameManager.set_building_purchase_mode(1))
	buy_ten_button.pressed.connect(func(): GameManager.set_building_purchase_mode(10))
	buy_max_button.pressed.connect(func(): GameManager.set_building_purchase_mode(-1))
	GameManager.purchase_mode_changed.connect(_update_bulk_buy_styles)
	_music_muted = GameManager.music_muted
	_create_mute_button()
	_create_settings_button()
	_create_milestones_button()
	_create_sfx_pool()
	_style_buy_capsule_button()
	_style_buy_premium_button()
	_style_boost_station()
	consumables_tab.visible = GameManager.lifetime_lobsters >= 2500

	# Scroll buttons
	var sc: ScrollContainer = %RightPanel.get_node("VBox/ScrollContainer")
	scroll_up_btn.pressed.connect(func(): sc.scroll_vertical = max(0, sc.scroll_vertical - 150))
	scroll_down_btn.pressed.connect(func(): sc.scroll_vertical += 150)

	_start_music()
	_apply_audio_settings()
	_update_mute_button()

	# Load farm name
	farm_name_button.text = GameManager.farm_name

	hero_claw.texture = ClawPinchFrames[0]

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
	_on_objective_changed(GameManager.get_current_objective())
	if not GameManager.pending_premium_options.is_empty():
		_show_premium_options(GameManager.pending_premium_options)
	_update_bulk_buy_styles(GameManager.building_purchase_mode)
	_refresh_molt()

	# Apply responsive layout
	_apply_layout()
	claw_button.grab_focus()

	# Show offline popup if needed
	if SaveManager.offline_earnings > 0:
		_show_offline_report(SaveManager.offline_earnings, SaveManager.offline_elapsed_seconds)
	else:
		offline_popup.visible = false

func _exit_tree() -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	if _claw_bump_tween and _claw_bump_tween.is_valid():
		_claw_bump_tween.kill()
	if _celebration_tween and _celebration_tween.is_valid():
		_celebration_tween.kill()
	if _score_pulse_tween and _score_pulse_tween.is_valid():
		_score_pulse_tween.kill()
	if music_player:
		music_player.stop()
		music_player.stream = null
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_sfx_players.clear()

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
	if current_tab == Tab.MOLT and Engine.get_process_frames() % 30 == 0:
		_refresh_molt()

	# Check for new click upgrades (throttle)
	if Engine.get_process_frames() % 60 == 0:
		_check_click_upgrades()

	# Check for viewport resize (throttle to every 30 frames to avoid JS overhead)
	if Engine.get_process_frames() % 30 == 0:
		var real_width := _get_real_width()
		if real_width != _last_width:
			_last_width = real_width
			_apply_layout()

	_update_claw_animation(delta)

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
		right_panel.custom_minimum_size.y = 0.0
		content_scroll.custom_minimum_size.y = 0.0
		title_label.add_theme_font_size_override("font_size", 28)
		objective_label.add_theme_font_size_override("font_size", 18)
		for tab_button in [buildings_tab, upgrades_tab, consumables_tab, molt_tab]:
			tab_button.add_theme_font_size_override("font_size", 22)
		claw_button.custom_minimum_size = Vector2(300, 350)
		claw_button.pivot_offset = claw_button.custom_minimum_size * 0.5
		_layout_corner_buttons(true)
	else:
		# Mobile: reserve a real touch-sized inventory drawer. The old UP/DOWN
		# buttons consumed almost half of the useful list viewport on short phones;
		# native swipe scrolling is both clearer and substantially easier to use.
		root_container.vertical = true
		left_section.size_flags_stretch_ratio = 0.7
		right_panel.size_flags_stretch_ratio = 1.3
		left_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_panel.custom_minimum_size.y = 380.0
		content_scroll.custom_minimum_size.y = 252.0
		scroll_up_btn.visible = false
		scroll_down_btn.visible = false
		title_label.add_theme_font_size_override("font_size", 18)
		objective_label.add_theme_font_size_override("font_size", 14)
		for tab_button in [buildings_tab, upgrades_tab, consumables_tab, molt_tab]:
			tab_button.add_theme_font_size_override("font_size", 15)
		claw_button.custom_minimum_size = Vector2(220, 235)
		claw_button.pivot_offset = claw_button.custom_minimum_size * 0.5
		_layout_corner_buttons(false)
	var report_half_width := 220.0 if _is_desktop else maxf(148.0, minf(220.0, float(real_width) * 0.5 - 12.0))
	offline_popup.offset_left = -report_half_width
	offline_popup.offset_right = report_half_width
	offline_popup.offset_top = -172.0
	offline_popup.offset_bottom = 172.0

func _layout_corner_buttons(desktop: bool) -> void:
	# On desktop, keep mute inside the left play panel so it never covers the
	# right panel's Molt tab. Mobile keeps it against the viewport edge.
	var right_anchor := DESKTOP_LEFT_PANEL_SHARE if desktop else 1.0
	var button_width := 96.0 if desktop else 72.0
	settings_button.custom_minimum_size.x = button_width
	settings_button.offset_left = 12.0 if desktop else 8.0
	settings_button.offset_right = settings_button.offset_left + button_width
	settings_button.add_theme_font_size_override("font_size", 13 if desktop else 10)
	var milestone_width := 116.0 if desktop else 88.0
	milestones_button.custom_minimum_size.x = milestone_width
	milestones_button.offset_left = settings_button.offset_right + (8.0 if desktop else 6.0)
	milestones_button.offset_right = milestones_button.offset_left + milestone_width
	milestones_button.add_theme_font_size_override("font_size", 12 if desktop else 9)
	mute_button.custom_minimum_size.x = button_width
	mute_button.anchor_left = right_anchor
	mute_button.anchor_right = right_anchor
	mute_button.offset_right = -12.0 if desktop else -8.0
	mute_button.offset_left = mute_button.offset_right - button_width
	mute_button.add_theme_font_size_override("font_size", 13 if desktop else 10)

func _on_lobsters_changed(total: float) -> void:
	lobster_count_label.text = GameManager.format_number(total)
	var shell_word := "Shell" if GameManager.shells == 1 else "Shells"
	lifetime_label.text = "%s lifetime LC | %d %s" % [GameManager.format_number(GameManager.lifetime_lobsters), GameManager.shells, shell_word]

func _on_lps_changed(_lps: float) -> void:
	_update_lps_display()

func _update_lps_display() -> void:
	var base_lps := GameManager.lobsters_per_second
	var boost_mult := GameManager.get_gacha_boost_multiplier("building_mult")
	var effective_lps := base_lps * boost_mult
	# Add single building boost bonus to display
	if GameManager.single_building_boost_time > 0 and GameManager.single_building_boost_index >= 0:
		var bi := GameManager.single_building_boost_index
		var boosted_lps: float = GameManager.building_counts[bi] * float(GameManager.building_defs[bi]["lps"]) * GameManager.get_building_multiplier(bi) * GameManager.get_shell_multiplier()
		effective_lps += boosted_lps * (GameManager.single_building_boost_mult - 1.0) * boost_mult
	if effective_lps < 1.0 and effective_lps > 0:
		lps_label.text = "%.1f LCPS" % effective_lps
	else:
		lps_label.text = "%s LCPS" % GameManager.format_number(effective_lps)
	if boost_mult > 1.0 or GameManager.single_building_boost_time > 0:
		lps_label.add_theme_color_override("font_color", COIN_GOLD)
	else:
		lps_label.add_theme_color_override("font_color", SEAFOAM)

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
	var focused := get_viewport().gui_get_focus_owner()
	if event is InputEventKey and event.pressed and not event.echo and not (focused is LineEdit):
		if event.keycode == KEY_Q or event.keycode == KEY_BRACKETLEFT:
			get_viewport().set_input_as_handled()
			_cycle_tab(-1)
			return
		if event.keycode == KEY_E or event.keycode == KEY_BRACKETRIGHT:
			get_viewport().set_input_as_handled()
			_cycle_tab(1)
			return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			get_viewport().set_input_as_handled()
			_cycle_tab(-1)
			return
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			get_viewport().set_input_as_handled()
			_cycle_tab(1)
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if not (focused is LineEdit) and (not (focused is Button) or focused == claw_button):
			get_viewport().set_input_as_handled()
			_try_click()
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		if not (focused is Button) or focused == claw_button:
			get_viewport().set_input_as_handled()
			_try_click()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_is_holding = false
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

func _install_accessible_focus_theme() -> void:
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0, 0, 0, 0)
	focus_style.border_width_left = 3
	focus_style.border_width_top = 3
	focus_style.border_width_right = 3
	focus_style.border_width_bottom = 3
	focus_style.border_color = Color("#ffd766")
	focus_style.corner_radius_top_left = 7
	focus_style.corner_radius_top_right = 7
	focus_style.corner_radius_bottom_left = 7
	focus_style.corner_radius_bottom_right = 7
	var focus_theme := Theme.new()
	focus_theme.default_font = UiFont
	focus_theme.default_font_size = 16
	for control_type in ["Button", "CheckButton", "HSlider", "LineEdit"]:
		focus_theme.set_stylebox("focus", control_type, focus_style)
	theme = focus_theme

func _make_style(bg: Color, border: Color, radius: int = 8, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _install_visual_polish() -> void:
	# A small, explicit design system keeps dynamically-created controls in the
	# same visual language as authored scene controls.
	theme.set_color("font_color", "Label", FOAM_WHITE)
	theme.set_color("font_color", "Button", FOAM_WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(MIST_BLUE, 0.55))
	theme.set_font("font", "Button", UiBoldFont)
	theme.set_stylebox("normal", "Button", _make_style(Color("#173447"), Color("#31566a")))
	theme.set_stylebox("hover", "Button", _make_style(Color("#20465a"), SHELL_HIGHLIGHT, 8, 2))
	theme.set_stylebox("pressed", "Button", _make_style(LOBSTER_CORAL.darkened(0.18), SHELL_HIGHLIGHT, 8, 2))
	theme.set_stylebox("disabled", "Button", _make_style(Color("#102331"), Color("#274555")))

	title_label.add_theme_font_override("font", DisplayFont)
	lobster_count_label.add_theme_font_override("font", DisplayFont)
	lobster_count_label.add_theme_constant_override("outline_size", 5)
	lobster_count_label.add_theme_color_override("font_outline_color", Color("#5d2348"))
	lobster_count_label.add_theme_constant_override("shadow_offset_x", 0)
	lobster_count_label.add_theme_constant_override("shadow_offset_y", 4)
	lobster_count_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.95, 1.0, 0.32))
	score_header.add_theme_font_override("font", UiBoldFont)
	lobster_word.add_theme_font_override("font", UiBoldFont)
	var score_style := _make_style(Color("#06131f"), Color("#1dd9f2"), 5, 2)
	score_style.content_margin_left = 18.0
	score_style.content_margin_right = 18.0
	score_style.content_margin_top = 8.0
	score_style.content_margin_bottom = 9.0
	score_style.shadow_color = Color(0.11, 0.85, 0.95, 0.22)
	score_style.shadow_size = 7
	score_panel.add_theme_stylebox_override("panel", score_style)
	# Keep the current objective readable over every painted-harbor crop. This
	# behaves like a compact arcade instruction plate instead of bare text laid
	# directly over the brightest water and storefront highlights.
	var objective_style := _make_style(Color(0.025, 0.075, 0.115, 0.92), Color(0.11, 0.58, 0.68, 0.82), 8, 1)
	objective_style.content_margin_left = 14.0
	objective_style.content_margin_right = 14.0
	objective_style.content_margin_top = 8.0
	objective_style.content_margin_bottom = 8.0
	objective_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	objective_style.shadow_size = 5
	objective_label.add_theme_stylebox_override("normal", objective_style)
	objective_label.add_theme_font_override("font", UiBoldFont)
	objective_label.add_theme_color_override("font_color", FOAM_WHITE)
	objective_label.add_theme_color_override("font_outline_color", Color("#03101a"))
	objective_label.add_theme_constant_override("outline_size", 2)
	shell_count_label.add_theme_font_override("font", UiBoldFont)
	var molt_title := get_node_or_null("RootContainer/RightPanel/VBox/ScrollContainer/MoltContainer/MoltTitle") as Label
	if molt_title:
		molt_title.add_theme_font_override("font", DisplayFont)
	for display_label_name in ["GachaTitle", "PremiumTitle"]:
		var display_label := find_child(display_label_name, true, false) as Label
		if display_label:
			display_label.add_theme_font_override("font", DisplayFont)
	offline_title.add_theme_font_override("font", DisplayFont)
	var offline_style := _make_style(Color("#071725", 0.985), Color("#1dd9f2"), 14, 2)
	offline_style.content_margin_left = 20.0
	offline_style.content_margin_right = 20.0
	offline_style.content_margin_top = 16.0
	offline_style.content_margin_bottom = 16.0
	offline_style.shadow_color = Color("#1dd9f2", 0.22)
	offline_style.shadow_size = 12
	offline_popup.add_theme_stylebox_override("panel", offline_style)
	offline_ok_button.add_theme_stylebox_override("normal", _make_style(LOBSTER_CORAL.darkened(0.18), SHELL_HIGHLIGHT, 8, 2))
	offline_ok_button.add_theme_stylebox_override("hover", _make_style(LOBSTER_CORAL, COIN_GOLD, 8, 2))

	var tab_normal := _make_style(Color("#0b2130"), Color("#23495b"), 6)
	var tab_hover := _make_style(Color("#173b4d"), Color("#3a7180"), 6)
	for tab_button in [buildings_tab, upgrades_tab, consumables_tab, molt_tab]:
		tab_button.flat = false
		tab_button.add_theme_stylebox_override("normal", tab_normal)
		tab_button.add_theme_stylebox_override("hover", tab_hover)
		tab_button.add_theme_stylebox_override("pressed", tab_hover)

	var progress_bg := _make_style(Color("#071725"), Color("#31566a"), 8)
	progress_bg.content_margin_top = 0.0
	progress_bg.content_margin_bottom = 0.0
	var progress_fill := _make_style(SEAFOAM.darkened(0.12), SEAFOAM, 8)
	progress_fill.content_margin_top = 0.0
	progress_fill.content_margin_bottom = 0.0
	molt_progress_bar.add_theme_stylebox_override("background", progress_bg)
	molt_progress_bar.add_theme_stylebox_override("fill", progress_fill)

	var claw_focus := _make_style(Color(LOBSTER_CORAL, 0.06), COIN_GOLD, 18, 3)
	claw_button.add_theme_stylebox_override("focus", claw_focus)
	hero_claw.tooltip_text = "Catch Lobster Coins"

func _start_music() -> void:
	if _music_muted:
		return
	if music_player and not music_player.playing:
		music_player.play()
	if music_player:
		music_player.stream_paused = false

func _volume_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return lerpf(-40.0, 0.0, clampf(value, 0.0, 1.0))

func _apply_audio_settings() -> void:
	if music_player:
		music_player.volume_db = _volume_to_db(GameManager.music_volume)
		music_player.stream_paused = GameManager.music_muted
	_music_muted = GameManager.music_muted
	_update_mute_button()

func _create_sfx_pool() -> void:
	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_sfx_players.append(player)

func _play_sfx(stream: AudioStream) -> void:
	if not stream or GameManager.sfx_volume <= 0.0 or _sfx_players.is_empty():
		return
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = _volume_to_db(GameManager.sfx_volume)
	player.play()

func _create_mute_button() -> void:
	mute_button = Button.new()
	mute_button.name = "MuteButton"
	mute_button.text = "MUTE"
	mute_button.tooltip_text = "Mute music"
	mute_button.custom_minimum_size = Vector2(96, 34)
	mute_button.focus_mode = Control.FOCUS_ALL
	mute_button.flat = false
	mute_button.z_index = 20
	mute_button.anchor_left = 1.0
	mute_button.anchor_right = 1.0
	mute_button.anchor_top = 0.0
	mute_button.anchor_bottom = 0.0
	mute_button.offset_left = -108.0
	mute_button.offset_right = -12.0
	mute_button.offset_top = 10.0
	mute_button.offset_bottom = 44.0
	mute_button.add_theme_font_size_override("font_size", 13)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.10, 0.18, 0.72)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.22, 0.42, 0.52, 0.9)
	normal.corner_radius_top_left = 9
	normal.corner_radius_top_right = 9
	normal.corner_radius_bottom_left = 9
	normal.corner_radius_bottom_right = 9
	mute_button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.18, 0.28, 0.88)
	mute_button.add_theme_stylebox_override("hover", hover)
	mute_button.add_theme_stylebox_override("pressed", hover)

	mute_button.pressed.connect(_on_mute_button_pressed)
	add_child(mute_button)

func _create_settings_button() -> void:
	settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "SETTINGS"
	settings_button.tooltip_text = "Audio and accessibility settings"
	settings_button.custom_minimum_size = Vector2(96, 34)
	settings_button.focus_mode = Control.FOCUS_ALL
	settings_button.z_index = 20
	settings_button.anchor_left = 0.0
	settings_button.anchor_right = 0.0
	settings_button.anchor_top = 0.0
	settings_button.anchor_bottom = 0.0
	settings_button.offset_left = 12.0
	settings_button.offset_right = 108.0
	settings_button.offset_top = 10.0
	settings_button.offset_bottom = 44.0
	settings_button.add_theme_font_size_override("font_size", 13)
	settings_button.pressed.connect(_show_settings_dialog)
	add_child(settings_button)

func _create_milestones_button() -> void:
	milestones_button = Button.new()
	milestones_button.name = "MilestonesButton"
	milestones_button.text = "MILESTONES"
	milestones_button.tooltip_text = "View earned and locked milestones"
	milestones_button.custom_minimum_size = Vector2(116, 34)
	milestones_button.focus_mode = Control.FOCUS_ALL
	milestones_button.z_index = 20
	milestones_button.anchor_left = 0.0
	milestones_button.anchor_right = 0.0
	milestones_button.anchor_top = 0.0
	milestones_button.anchor_bottom = 0.0
	milestones_button.offset_left = 116.0
	milestones_button.offset_right = 232.0
	milestones_button.offset_top = 10.0
	milestones_button.offset_bottom = 44.0
	milestones_button.add_theme_font_size_override("font_size", 12)
	milestones_button.pressed.connect(_show_milestones_dialog)
	add_child(milestones_button)

func _show_milestones_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.name = "MilestonesDialog"
	dialog.title = "Milestones"
	dialog.ok_button_text = "DONE"
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	var earned_count := 0
	for achievement in GameManager.ACHIEVEMENT_DEFS:
		if GameManager.achievements.get(achievement["id"], false):
			earned_count += 1
	var progress := Label.new()
	progress.name = "MilestoneProgress"
	progress.text = "%d / %d EARNED" % [earned_count, GameManager.ACHIEVEMENT_DEFS.size()]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_override("font", DisplayFont)
	progress.add_theme_font_size_override("font_size", 22)
	progress.add_theme_color_override("font_color", COIN_GOLD)
	outer.add_child(progress)

	var intro := Label.new()
	intro.text = "Your permanent Harbor Hall of Fame"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", SEAFOAM)
	outer.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.name = "MilestoneScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, minf(440.0, get_viewport_rect().size.y - 180.0))
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "MilestoneList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for achievement in GameManager.ACHIEVEMENT_DEFS:
		var earned: bool = GameManager.achievements.get(achievement["id"], false)
		var card := PanelContainer.new()
		card.name = "Milestone_%s" % achievement["id"]
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.06, 0.11, 0.19, 0.97) if earned else Color(0.035, 0.055, 0.09, 0.94)
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.border_color = COIN_GOLD if earned else Color(0.20, 0.29, 0.36, 0.9)
		card_style.corner_radius_top_left = 9
		card_style.corner_radius_top_right = 9
		card_style.corner_radius_bottom_left = 9
		card_style.corner_radius_bottom_right = 9
		card_style.content_margin_left = 10.0
		card_style.content_margin_right = 10.0
		card_style.content_margin_top = 8.0
		card_style.content_margin_bottom = 8.0
		card.add_theme_stylebox_override("panel", card_style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var medal := TextureRect.new()
		medal.texture = AchievementMedalIcon
		medal.custom_minimum_size = Vector2(58, 58)
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.modulate = Color.WHITE if earned else Color(0.25, 0.31, 0.38, 0.6)
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(medal)
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = achievement["title"]
		name_label.add_theme_font_override("font", UiBoldFont)
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.add_theme_color_override("font_color", COIN_GOLD if earned else Color("#8aa0ad"))
		text_box.add_child(name_label)
		var detail := Label.new()
		detail.text = achievement["desc"] if earned else achievement["hint"]
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 13)
		detail.add_theme_color_override("font_color", Color("#d8edf4") if earned else Color("#78909c"))
		text_box.add_child(detail)
		row.add_child(text_box)
		var state := Label.new()
		state.text = "EARNED" if earned else "LOCKED"
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state.add_theme_font_override("font", UiBoldFont)
		state.add_theme_font_size_override("font_size", 12)
		state.add_theme_color_override("font_color", SEAFOAM if earned else Color("#667788"))
		row.add_child(state)
		card.add_child(row)
		list.add_child(card)

	dialog.add_child(outer)
	add_child(dialog)
	var viewport_size := get_viewport_rect().size
	dialog.popup_centered(Vector2i(mini(620, int(viewport_size.x) - 24), mini(620, int(viewport_size.y) - 32)))
	dialog.get_ok_button().grab_focus()

func _show_settings_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Settings"
	dialog.ok_button_text = "DONE"
	dialog.min_size = Vector2i(440, 430)
	dialog.confirmed.connect(SaveManager.save_game)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.close_requested.connect(SaveManager.save_game)
	dialog.close_requested.connect(dialog.queue_free)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	var music_label := Label.new()
	music_label.text = "Music volume: %d%%" % int(round(GameManager.music_volume * 100.0))
	box.add_child(music_label)
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	music_slider.value = GameManager.music_volume * 100.0
	music_slider.custom_minimum_size = Vector2(360, 34)
	music_slider.value_changed.connect(func(value: float):
		GameManager.music_volume = value / 100.0
		music_label.text = "Music volume: %d%%" % int(value)
		_apply_audio_settings())
	music_slider.drag_ended.connect(func(_changed: bool): SaveManager.save_game())
	box.add_child(music_slider)

	var sfx_label := Label.new()
	sfx_label.text = "Sound effects volume: %d%%" % int(round(GameManager.sfx_volume * 100.0))
	box.add_child(sfx_label)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	sfx_slider.value = GameManager.sfx_volume * 100.0
	sfx_slider.custom_minimum_size = Vector2(360, 34)
	sfx_slider.value_changed.connect(func(value: float):
		GameManager.sfx_volume = value / 100.0
		sfx_label.text = "Sound effects volume: %d%%" % int(value))
	sfx_slider.drag_ended.connect(func(_changed: bool):
		_play_sfx(PurchaseSfx)
		SaveManager.save_game())
	box.add_child(sfx_slider)

	var mute_toggle := CheckButton.new()
	mute_toggle.text = "Mute music"
	mute_toggle.button_pressed = GameManager.music_muted
	mute_toggle.toggled.connect(func(enabled: bool):
		GameManager.music_muted = enabled
		_apply_audio_settings()
		SaveManager.save_game())
	box.add_child(mute_toggle)

	var motion_toggle := CheckButton.new()
	motion_toggle.text = "Reduce motion and particles"
	motion_toggle.button_pressed = GameManager.reduced_motion
	motion_toggle.toggled.connect(func(enabled: bool):
		GameManager.reduced_motion = enabled
		if enabled:
			for active_effect in click_effects.get_children():
				active_effect.queue_free()
			boost_aura.emitting = false
		SaveManager.save_game())
	box.add_child(motion_toggle)

	var controls_hint := Label.new()
	controls_hint.text = "Controls: Space/A clicks · Tab/D-pad moves focus · Q/E or LB/RB changes tabs"
	controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint.add_theme_color_override("font_color", Color("#b9d7e5"))
	controls_hint.add_theme_font_size_override("font_size", 13)
	box.add_child(controls_hint)

	var credits_button := Button.new()
	credits_button.text = "CREDITS & LICENSES"
	credits_button.pressed.connect(func():
		SaveManager.save_game()
		dialog.hide()
		dialog.queue_free()
		call_deferred("_show_credits_dialog"))
	box.add_child(credits_button)

	var reset_button := Button.new()
	reset_button.text = "RESET ALL PROGRESS"
	reset_button.add_theme_color_override("font_color", Color("#ff6b6b"))
	reset_button.pressed.connect(func():
		SaveManager.save_game()
		dialog.hide()
		dialog.queue_free()
		call_deferred("_show_reset_confirmation"))
	box.add_child(reset_button)

	dialog.add_child(box)
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 480))
	music_slider.grab_focus()

func _show_credits_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Credits & Licenses"
	dialog.ok_button_text = "DONE"
	dialog.dialog_text = "LOBSTER CLICKER\n\nGame design, code, interface, and code-drawn artwork\nCreated for Lobster Clicker by the project team.\n\nMusic and sound effects\nOriginal synthesized audio generated for this project.\n\nEngine\nBuilt with Godot Engine, licensed under the MIT License.\nFull third-party notices are included with the game files."
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 430))

func _on_mute_button_pressed() -> void:
	_music_muted = not _music_muted
	GameManager.music_muted = _music_muted
	if music_player:
		if _music_muted:
			music_player.stream_paused = true
		else:
			if not music_player.playing:
				music_player.play()
			music_player.stream_paused = false
	_update_mute_button()
	SaveManager.save_game()

func _update_mute_button() -> void:
	if not mute_button:
		return
	mute_button.text = "UNMUTE" if _music_muted else "MUTE"
	mute_button.tooltip_text = "Unmute music" if _music_muted else "Mute music"

func _try_click() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _click_debounce < CLICK_DEBOUNCE_TIME:
		return
	_click_debounce = now
	_do_click()

func _do_click() -> void:
	var amount := GameManager.click()
	_play_sfx(ClawSnapSfx)
	_pulse_score_panel()
	if GameManager.reduced_motion:
		return
	_start_claw_animation()
	_spawn_float_text(amount)
	_schedule_claw_snap_effect()
	if _claw_bump_tween and _claw_bump_tween.is_valid():
		_claw_bump_tween.kill()

func _schedule_claw_snap_effect() -> void:
	# Anticipation + closing ends at the exact contact frame.
	var impact_timer := get_tree().create_timer(CLAW_FRAME_DURATIONS[0] + CLAW_FRAME_DURATIONS[1])
	impact_timer.timeout.connect(_spawn_claw_snap_effect)

func _spawn_claw_snap_effect() -> void:
	if not is_instance_valid(click_effects) or GameManager.reduced_motion:
		return
	var burst := Node2D.new()
	burst.name = "ClawSnapBurst"
	# The texture is aspect-fitted inside the button. This normalized anchor is
	# the meeting point of the painted pincers at both responsive sizes.
	burst.position = Vector2(claw_button.size.x * 0.5, claw_button.size.y * 0.27)
	burst.z_index = 12
	click_effects.add_child(burst)

	var ring := Line2D.new()
	ring.name = "ImpactRing"
	ring.width = 3.5
	ring.default_color = COIN_GOLD
	ring.antialiased = true
	ring.closed = true
	for point_index in range(17):
		var angle := TAU * float(point_index) / 16.0
		ring.add_point(Vector2.from_angle(angle) * 13.0)
	ring.scale = Vector2(0.45, 0.45)
	burst.add_child(ring)

	var flash := Polygon2D.new()
	flash.name = "PinchFlash"
	flash.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(5, -3), Vector2(11, 0), Vector2(5, 3),
		Vector2(0, 8), Vector2(-5, 3), Vector2(-11, 0), Vector2(-5, -3),
	])
	flash.color = FOAM_WHITE
	burst.add_child(flash)

	var palette: Array[Color] = [COIN_GOLD, LOBSTER_CORAL, FOAM_WHITE, SHELL_HIGHLIGHT]
	for ray_index in range(8):
		var ray := Polygon2D.new()
		ray.name = "SnapRay%d" % ray_index
		ray.polygon = PackedVector2Array([
			Vector2(-2.5, -4), Vector2(2.5, -4), Vector2(1.4, -18), Vector2(-1.4, -18),
		])
		ray.color = palette[ray_index % palette.size()]
		ray.rotation = TAU * float(ray_index) / 8.0
		ray.position = Vector2.from_angle(ray.rotation - PI * 0.5) * 5.0
		burst.add_child(ray)
		var ray_destination := Vector2.from_angle(ray.rotation - PI * 0.5) * 18.0
		var ray_tween := create_tween().set_parallel(true)
		ray_tween.tween_property(ray, "position", ray_destination, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ray_tween.tween_property(ray, "modulate:a", 0.0, 0.17).set_delay(0.06)
		ray_tween.tween_property(ray, "scale", Vector2(0.72, 1.18), 0.20)

	var burst_tween := create_tween().set_parallel(true)
	burst_tween.tween_property(ring, "scale", Vector2(1.55, 1.55), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(ring, "modulate:a", 0.0, 0.18).set_delay(0.07)
	burst_tween.tween_property(flash, "scale", Vector2(0.55, 0.55), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(flash, "modulate:a", 0.0, 0.14).set_delay(0.04)
	burst_tween.chain().tween_callback(burst.queue_free)

func _start_claw_animation() -> void:
	_claw_animation_index = 0
	claw_progress = 0.0
	claw_state = ClawState.SNAPPING
	hero_claw.texture = ClawPinchFrames[CLAW_FRAME_SEQUENCE[0]]

func _update_claw_animation(delta: float) -> void:
	if claw_state == ClawState.IDLE:
		return
	claw_progress += delta
	while claw_state != ClawState.IDLE and claw_progress >= CLAW_FRAME_DURATIONS[_claw_animation_index]:
		claw_progress -= CLAW_FRAME_DURATIONS[_claw_animation_index]
		_claw_animation_index += 1
		if _claw_animation_index >= CLAW_FRAME_SEQUENCE.size():
			_claw_animation_index = 0
			claw_progress = 0.0
			claw_state = ClawState.IDLE
			hero_claw.texture = ClawPinchFrames[0]
			return
		if _claw_animation_index >= 3:
			claw_state = ClawState.OPENING
		hero_claw.texture = ClawPinchFrames[CLAW_FRAME_SEQUENCE[_claw_animation_index]]

func _spawn_float_text(amount: float) -> void:
	var label := Label.new()
	label.text = "+%s LC" % GameManager.format_number(amount)
	label.add_theme_font_override("font", DisplayFont)
	label.add_theme_color_override("font_color", COIN_GOLD if randi() % 2 == 0 else SEAFOAM)
	label.add_theme_color_override("font_outline_color", Color("#071725"))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 29)
	label.position = Vector2(randf_range(-54, 20), randf_range(-24, 0))
	label.z_index = 10
	float_text_container.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "position:y", label.position.y - 94.0, 0.72)
	tween.tween_property(label, "scale", Vector2(1.14, 1.14), 0.18)
	tween.tween_property(label, "modulate:a", 0.0, 0.72).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)

func _pulse_score_panel() -> void:
	if GameManager.reduced_motion or not score_panel:
		return
	if _score_pulse_tween and _score_pulse_tween.is_valid():
		_score_pulse_tween.kill()
	score_panel.pivot_offset = score_panel.size * 0.5
	score_panel.scale = Vector2.ONE
	_score_pulse_tween = create_tween()
	_score_pulse_tween.tween_property(score_panel, "scale", Vector2(1.025, 1.025), 0.055).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_score_pulse_tween.tween_property(score_panel, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_offline_ok() -> void:
	offline_popup.visible = false

func _format_shift_duration(seconds: float) -> String:
	var total_minutes := maxi(1, int(round(seconds / 60.0)))
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	if hours > 0 and minutes > 0:
		return "%dh %dm" % [hours, minutes]
	if hours > 0:
		return "%dh" % hours
	return "%dm" % minutes

func _show_offline_report(earned: float, elapsed_seconds: float) -> void:
	if earned <= 0.0:
		return
	offline_icon.texture = OfflinePowerIcon
	offline_title.text = "NIGHT SHIFT REPORT"
	offline_label.text = "YOUR CREW KEPT THE HARBOR RUNNING\n\n+%s LOBSTER COINS\n%s worked  ·  %d%% efficiency\nCurrent fleet: %s LCPS" % [
		GameManager.format_number(earned),
		_format_shift_duration(elapsed_seconds),
		int(round(GameManager.get_offline_rate() * 100.0)),
		GameManager.format_number(GameManager.lobsters_per_second),
	]
	offline_popup.visible = true
	offline_popup.move_to_front()

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
	if OS.is_debug_build() and new_name.to_lower() == "/lobster_raviolli":
		farm_name_edit.visible = false
		farm_name_button.visible = true
		_show_dev_menu()
		return
	if new_name.is_empty():
		new_name = "My Lobster Farm"
	new_name = new_name.left(32)
	GameManager.farm_name = new_name
	farm_name_button.text = new_name
	farm_name_edit.visible = false
	farm_name_button.visible = true
	SaveManager.save_game()

func _on_objective_changed(text: String) -> void:
	if objective_label:
		objective_label.text = text

func _update_bulk_buy_styles(mode: int) -> void:
	buy_one_button.disabled = mode == 1
	buy_ten_button.disabled = mode == 10
	buy_max_button.disabled = mode == -1

func _on_achievement_unlocked(id: String, title: String, desc: String) -> void:
	_play_sfx(DiscoSfx if id == "disco_lobster" else AchievementSfx)
	var is_harbor_milestone := id in ["harbor_lights", "neon_empire", "full_harbor", "century_wharf"]
	_show_toast(("HARBOR MILESTONE" if is_harbor_milestone else "ACHIEVEMENT") + "  •  %s" % title.to_upper(), desc, AchievementMedalIcon)
	if not GameManager.reduced_motion:
		_spawn_arcade_sparks(self, get_viewport_rect().size * Vector2(0.5, 0.18), 28 if is_harbor_milestone else 18, [COIN_GOLD, SEAFOAM, LOBSTER_CORAL], 190.0 if is_harbor_milestone else 150.0)
		_pulse_score_panel()

func _show_toast(title: String, desc: String, icon: Texture2D = AchievementMedalIcon) -> void:
	if _toast_panel and is_instance_valid(_toast_panel):
		_toast_queue.append({"title": title, "desc": desc, "icon": icon})
		return
	_build_toast(title, desc, icon)

func _build_toast(title: String, desc: String, icon: Texture2D) -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "MilestonePopup"
	_toast_panel.z_index = 100
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var toast_width := minf(380.0, get_viewport_rect().size.x - 24.0)
	_toast_panel.position = Vector2(-toast_width / 2.0, 18)
	_toast_panel.custom_minimum_size = Vector2(toast_width, 108)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.22, 0.97)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#ffd766")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	_toast_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(74, 74)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", UiBoldFont)
	title_label.add_theme_color_override("font_color", Color("#ffd766"))
	title_label.add_theme_font_size_override("font_size", 20)
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color("#b9d7e5"))
	desc_label.add_theme_font_size_override("font_size", 14)
	box.add_child(title_label)
	box.add_child(desc_label)
	row.add_child(box)
	var close_button := Button.new()
	close_button.name = "CloseMilestoneButton"
	close_button.text = "X"
	close_button.tooltip_text = "Close milestone"
	close_button.custom_minimum_size = Vector2(44, 44)
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.add_theme_font_override("font", UiBoldFont)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color("#ffd766"))
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.add_theme_color_override("font_pressed_color", LOBSTER_CORAL)
	close_button.pressed.connect(_dismiss_toast)
	row.add_child(close_button)
	_toast_panel.add_child(row)
	add_child(_toast_panel)
	if GameManager.reduced_motion:
		_toast_panel.modulate.a = 1.0
		return
	_toast_panel.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.18)

func _dismiss_toast() -> void:
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast_panel and is_instance_valid(_toast_panel):
		_toast_panel.queue_free()
	_toast_panel = null
	if not _toast_queue.is_empty():
		var next_toast: Dictionary = _toast_queue.pop_front()
		call_deferred("_build_toast", next_toast["title"], next_toast["desc"], next_toast["icon"])

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
	title.text = "DEV MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ff6b6b"))
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Internal testing tools"
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
	_dev_add_section(vbox, "Danger Zone")
	var reset_btn := _dev_make_button("RESET ALL PROGRESS")
	reset_btn.add_theme_color_override("font_color", Color("#ff4444"))
	reset_btn.pressed.connect(_show_reset_confirmation)
	vbox.add_child(reset_btn)

	# --- Close ---
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)
	var close_btn := _dev_make_button("CLOSE")
	close_btn.pressed.connect(func(): _dev_popup.queue_free())
	vbox.add_child(close_btn)

	add_child(_dev_popup)

func _show_reset_confirmation() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reset all progress?"
	dialog.dialog_text = "This permanently resets LC, buildings, upgrades, boosts, achievements, and the farm name."
	dialog.ok_button_text = "RESET"
	dialog.cancel_button_text = "CANCEL"
	dialog.confirmed.connect(func():
		GameManager.reset_progress()
		farm_name_button.text = "My Lobster Farm"
		consumables_tab.visible = false
		_switch_tab(Tab.BUILDINGS)
		for child in building_container.get_children():
			if child.has_method("_refresh"):
				child._refresh()
		_refresh_upgrades()
		if _dev_popup and is_instance_valid(_dev_popup):
			_dev_popup.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(460, 220))

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
	molt_container.visible = (tab == Tab.MOLT)
	bulk_buy_row.visible = (tab == Tab.BUILDINGS)
	_update_tab_styles()
	if tab == Tab.CONSUMABLES:
		_update_gacha_cost()
		_update_capsule_button_affordability()
		_update_premium_button_affordability()
	elif tab == Tab.MOLT:
		_refresh_molt()

func _cycle_tab(direction: int) -> void:
	var available_tabs: Array[int] = [Tab.BUILDINGS, Tab.UPGRADES]
	if consumables_tab.visible:
		available_tabs.append(Tab.CONSUMABLES)
	available_tabs.append(Tab.MOLT)
	var current_index := available_tabs.find(current_tab)
	if current_index < 0:
		current_index = 0
	var next_index := posmod(current_index + direction, available_tabs.size())
	var next_tab := available_tabs[next_index]
	_switch_tab(next_tab)
	match next_tab:
		Tab.BUILDINGS: buildings_tab.grab_focus()
		Tab.UPGRADES: upgrades_tab.grab_focus()
		Tab.CONSUMABLES: consumables_tab.grab_focus()
		Tab.MOLT: molt_tab.grab_focus()

func _update_tab_styles() -> void:
	var active_color := COIN_GOLD
	var inactive_color := MIST_BLUE.darkened(0.2)
	buildings_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.BUILDINGS else inactive_color)
	upgrades_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.UPGRADES else inactive_color)
	consumables_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.CONSUMABLES else inactive_color)
	molt_tab.add_theme_color_override("font_color", active_color if current_tab == Tab.MOLT else inactive_color)
	for entry in [[buildings_tab, Tab.BUILDINGS], [upgrades_tab, Tab.UPGRADES], [consumables_tab, Tab.CONSUMABLES], [molt_tab, Tab.MOLT]]:
		var button: Button = entry[0]
		var active: bool = current_tab == int(entry[1])
		button.add_theme_stylebox_override("normal", _make_style(Color("#173b4d") if active else Color("#0b2130"), SEAFOAM if active else Color("#23495b"), 6, 2 if active else 1))

func _on_molt_tab() -> void:
	_switch_tab(Tab.MOLT)

func _refresh_molt() -> void:
	if not shell_count_label:
		return
	var pending := GameManager.get_pending_shells()
	var current_bonus := int(round((GameManager.get_shell_multiplier() - 1.0) * 100.0))
	shell_count_label.text = "%d SHELLS" % GameManager.shells
	molt_bonus_label.text = "Permanent production bonus: +%d%%" % current_bonus
	molt_progress_label.text = "This run: %s / %s LC" % [GameManager.format_number(GameManager.run_lobsters), GameManager.format_number(GameManager.MOLTING_THRESHOLD)]
	molt_progress_bar.value = clampf(GameManager.run_lobsters / GameManager.MOLTING_THRESHOLD * 100.0, 0.0, 100.0)
	if pending > 0:
		var future_bonus := int(round((GameManager.get_shell_multiplier() + pending * GameManager.SHELL_BONUS_PER_SHELL - 1.0) * 100.0))
		molt_button.text = "MOLT FOR %d SHELL%s" % [pending, "" if pending == 1 else "S"]
		molt_button.disabled = not GameManager.can_molt()
		molt_button.add_theme_stylebox_override("normal", _make_style(SEAFOAM.darkened(0.35), SEAFOAM, 10, 2))
		molt_button.add_theme_stylebox_override("hover", _make_style(SEAFOAM.darkened(0.18), Color.WHITE, 10, 2))
		molt_next_label.text = "After molting: +%d%% permanent production. Next extra Shell at %s run LC." % [future_bonus, GameManager.format_number(GameManager.get_next_shell_target())]
		if GameManager.building_counts[GameManager.MOLTING_BUILDING_INDEX] < 1:
			molt_next_label.text = "Build at least 1 Immortality to complete this run."
		elif not GameManager.pending_premium_options.is_empty():
			molt_next_label.text = "Choose your paid Lobster Card before molting."
	else:
		molt_button.text = "MOLT LOCKED"
		molt_button.disabled = true
		molt_next_label.text = "%s run LC remaining until your next Shell." % GameManager.format_number(maxf(0.0, GameManager.MOLTING_THRESHOLD - GameManager.run_lobsters))

func _show_molt_confirmation() -> void:
	if not GameManager.can_molt():
		return
	var gained := GameManager.get_pending_shells()
	var future_shells := GameManager.shells + gained
	var future_bonus := int(round(float(future_shells) * GameManager.SHELL_BONUS_PER_SHELL * 100.0))
	var dialog := ConfirmationDialog.new()
	dialog.title = "Molt this farm?"
	dialog.dialog_text = "Gain %d Shell%s for +%d%% permanent production.\n\nResets: LC, buildings, ordinary upgrades, and active boosts.\nKeeps: farm name, settings, achievements, lifetime LC, permanent card income, and Shells." % [gained, "" if gained == 1 else "s", future_bonus]
	dialog.ok_button_text = "MOLT"
	dialog.cancel_button_text = "KEEP GROWING"
	dialog.confirmed.connect(func(): GameManager.molt())
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 300))

func _on_molt_completed(gained: int, total_shells: int) -> void:
	_play_sfx(MoltSfx)
	for child in building_container.get_children():
		if child.has_method("_refresh"):
			child._refresh()
	_refresh_upgrades()
	_refresh_molt()
	_switch_tab(Tab.BUILDINGS)
	_show_molt_celebration(gained, total_shells)
	_show_toast("Molting Complete", "+%d Shell%s. %d total — every catch is stronger." % [gained, "" if gained == 1 else "s", total_shells])

func _show_molt_celebration(gained: int, total_shells: int) -> void:
	if GameManager.reduced_motion:
		return
	_clear_celebration_layer()
	_celebration_layer = Control.new()
	_celebration_layer.name = "MoltCelebration"
	_celebration_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_celebration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_layer.z_index = 90
	add_child(_celebration_layer)

	var blackout := ColorRect.new()
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color(DEEP_HARBOR, 0.88)
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_layer.add_child(blackout)

	for ring_index in range(2):
		var ring := Panel.new()
		ring.name = "EnergyRing%d" % ring_index
		ring.set_anchors_preset(Control.PRESET_CENTER)
		ring.position = Vector2(-58, -58)
		ring.size = Vector2(116, 116)
		ring.pivot_offset = ring.size * 0.5
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ring_style := _make_style(Color(SEAFOAM, 0.0), SEAFOAM if ring_index == 0 else COIN_GOLD, 58, 4)
		ring.add_theme_stylebox_override("panel", ring_style)
		_celebration_layer.add_child(ring)
		var ring_tween := create_tween()
		ring_tween.set_parallel(true)
		ring_tween.tween_property(ring, "scale", Vector2(8.0, 8.0), 0.92 + ring_index * 0.18).set_delay(ring_index * 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring_tween.tween_property(ring, "modulate:a", 0.0, 0.72).set_delay(0.24 + ring_index * 0.14)
		ring_tween.chain().tween_callback(ring.queue_free)

	var panel := PanelContainer.new()
	panel.name = "MoltMarquee"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var viewport_size := get_viewport_rect().size
	var narrow_celebration := viewport_size.x < 560.0
	var panel_width := minf(520.0, viewport_size.x - 28.0)
	var panel_height := 220.0 if narrow_celebration else 264.0
	panel.position = Vector2(-panel_width * 0.5, -panel_height * 0.5)
	panel.size = Vector2(panel_width, panel_height)
	panel.pivot_offset = panel.size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := _make_style(Color("#071725e8"), SEAFOAM, 12, 4)
	panel_style.shadow_color = Color(SEAFOAM, 0.42)
	panel_style.shadow_size = 18
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	_celebration_layer.add_child(panel)

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	panel.add_child(copy)
	copy.add_child(_make_celebration_label("NEW RUN  •  PERMANENT POWER", UiBoldFont, 13 if narrow_celebration else 15, COIN_GOLD))
	copy.add_child(_make_celebration_label("MOLT COMPLETE", DisplayFont, 27 if narrow_celebration else 34, FOAM_WHITE))
	copy.add_child(_make_celebration_label("+%d SHELL%s" % [gained, "" if gained == 1 else "S"], DisplayFont, 35 if narrow_celebration else 42, SEAFOAM))
	copy.add_child(_make_celebration_label("%d TOTAL  •  +%d%% PRODUCTION" % [total_shells, int(round(total_shells * GameManager.SHELL_BONUS_PER_SHELL * 100.0))], UiBoldFont, 14 if narrow_celebration else 17, MIST_BLUE))

	_spawn_arcade_sparks(_celebration_layer, get_viewport_rect().size * 0.5, 42, [SEAFOAM, COIN_GOLD, LOBSTER_CORAL, FOAM_WHITE], 310.0)
	panel.scale = Vector2(0.72, 0.72)
	panel.modulate.a = 0.0
	_celebration_tween = create_tween()
	_celebration_tween.set_parallel(true)
	_celebration_tween.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_celebration_tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	_celebration_tween.tween_property(_celebration_layer, "modulate:a", 0.0, 0.48).set_delay(2.05)
	_celebration_tween.chain().tween_callback(_clear_celebration_layer)

func _make_celebration_label(text_value: String, label_font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", label_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", DEEP_HARBOR)
	label.add_theme_constant_override("outline_size", 4)
	return label

func _clear_celebration_layer() -> void:
	if _celebration_layer and is_instance_valid(_celebration_layer):
		_celebration_layer.queue_free()
	_celebration_layer = null

func _spawn_arcade_sparks(parent: Control, origin: Vector2, count: int, palette: Array, radius: float) -> void:
	for index in range(count):
		var spark := ColorRect.new()
		spark.name = "ArcadeSpark%d" % index
		spark.color = palette[index % palette.size()]
		var spark_size := randf_range(5.0, 11.0)
		spark.size = Vector2(spark_size, spark_size * randf_range(0.45, 1.0))
		spark.pivot_offset = spark.size * 0.5
		spark.position = origin - spark.pivot_offset
		spark.rotation = randf_range(-PI, PI)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(spark)
		var angle := TAU * float(index) / float(count) + randf_range(-0.16, 0.16)
		var distance := randf_range(radius * 0.48, radius)
		var destination := spark.position + Vector2.from_angle(angle) * distance
		var spark_tween := create_tween()
		spark_tween.set_parallel(true)
		spark_tween.tween_property(spark, "position", destination, randf_range(0.62, 1.05)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.tween_property(spark, "rotation", spark.rotation + randf_range(-4.0, 4.0), 0.9)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.42).set_delay(randf_range(0.35, 0.58))
		spark_tween.chain().tween_callback(spark.queue_free)

func _on_upgrade_unlocked(_building_index: int, _tier: int) -> void:
	_flash_active = true
	_flash_timer = 0.0
	if current_tab == Tab.UPGRADES:
		_refresh_upgrades()

func _on_building_purchased(_index: int) -> void:
	_play_sfx(PurchaseSfx)
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
		_add_collapsible_section("CLICK POWER", "click_power", LOBSTER_CORAL, click_items)

	# Building upgrades
	var bldg_items: Array = []
	for upg in GameManager.get_available_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			bldg_items.append(func(item): item.setup(upg["building_index"], upg["tier"], upg["purchased"]))
	if not bldg_items.is_empty():
		has_any = true
		_add_collapsible_section("BUILDING UPGRADES", "building_upgrades", COIN_GOLD, bldg_items)

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
		_add_collapsible_section("OFFLINE PRODUCTION", "offline", SEAFOAM, offline_items)

	# Gacha cooldown upgrades
	var gacha_items: Array = []
	for upg in GameManager.get_available_gacha_cooldown_upgrades():
		if not _hide_purchased or not upg["purchased"]:
			gacha_items.append(func(item): item.setup_gacha_cd_upgrade(upg["index"], upg["purchased"]))
	if not gacha_items.is_empty():
		has_any = true
		_add_collapsible_section("BOOST UPGRADES", "gacha", Color("#a56de2"), gacha_items)

	if not has_any:
		var empty_label := Label.new()
		if _hide_purchased:
			empty_label.text = "All available upgrades purchased!"
		else:
			empty_label.text = "No upgrades available yet.\nBuy more buildings to unlock!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color("#667788"))
		empty_label.add_theme_font_size_override("font_size", 18)
		upgrade_container.add_child(empty_label)

func _add_collapsible_section(title: String, key: String, color: Color, items: Array) -> void:
	var is_collapsed: bool = _collapsed_sections.get(key, false)
	var item_count := items.size()

	# Cabinet-style section marquee with an at-a-glance item count.
	var header_btn := Button.new()
	header_btn.text = ("+  " if is_collapsed else "-  ") + title + "  ·  %d" % item_count
	header_btn.flat = false
	header_btn.add_theme_color_override("font_color", color)
	header_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	header_btn.add_theme_font_size_override("font_size", 18)
	header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var header_style := _make_style(Color("#081a28"), Color(color, 0.72), 5, 1)
	header_style.border_width_left = 4
	header_style.content_margin_left = 12.0
	var header_hover := header_style.duplicate() as StyleBoxFlat
	header_hover.bg_color = Color("#102d3b")
	header_hover.border_color = color
	header_hover.shadow_color = Color(color, 0.16)
	header_hover.shadow_size = 4
	header_btn.add_theme_stylebox_override("normal", header_style)
	header_btn.add_theme_stylebox_override("hover", header_hover)
	header_btn.add_theme_stylebox_override("pressed", header_hover)

	# Items container
	var items_box := VBoxContainer.new()
	items_box.add_theme_constant_override("separation", 6)
	items_box.visible = not is_collapsed

	header_btn.pressed.connect(func():
		_collapsed_sections[key] = not _collapsed_sections.get(key, false)
		items_box.visible = not _collapsed_sections[key]
		header_btn.text = ("+  " if _collapsed_sections[key] else "-  ") + title + "  ·  %d" % item_count)

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
	style.bg_color = Color("#7146a3")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#a56de2")
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
	hover.bg_color = Color("#8658b7")
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color("#d7b6ff")
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
	disabled.bg_color = Color("#172633")
	disabled.corner_radius_top_left = 8
	disabled.corner_radius_top_right = 8
	disabled.corner_radius_bottom_left = 8
	disabled.corner_radius_bottom_right = 8
	disabled.content_margin_left = 12.0
	disabled.content_margin_right = 12.0
	disabled.content_margin_top = 8.0
	disabled.content_margin_bottom = 8.0
	buy_capsule_button.add_theme_stylebox_override("disabled", disabled)

func _style_boost_station() -> void:
	var machine_style := _make_style(Color("#06131f"), Color("#a56de2"), 10, 2)
	machine_style.content_margin_left = 8.0
	machine_style.content_margin_right = 8.0
	machine_style.content_margin_top = 5.0
	machine_style.content_margin_bottom = 5.0
	machine_style.shadow_color = Color(0.65, 0.43, 0.89, 0.2)
	machine_style.shadow_size = 7
	capsule_machine_frame.add_theme_stylebox_override("panel", machine_style)
	capsule_machine.tooltip_text = "The Capsule Catcher"
	capsule_machine.resized.connect(func(): capsule_machine.pivot_offset = capsule_machine.size * 0.5)
	capsule_machine.pivot_offset = capsule_machine.size * 0.5
	_apply_result_rarity_style(Color("#1dd9f2"), "READY")

func _apply_result_rarity_style(color: Color, status: String) -> void:
	var result_style := _make_style(Color("#071725"), color, 8, 2)
	result_style.border_width_left = 5
	result_style.content_margin_left = 14.0
	result_style.content_margin_right = 14.0
	result_style.content_margin_top = 10.0
	result_style.content_margin_bottom = 10.0
	result_style.shadow_color = Color(color, 0.22)
	result_style.shadow_size = 6
	result_panel.add_theme_stylebox_override("panel", result_style)
	rarity_label.text = status
	rarity_label.add_theme_color_override("font_color", color)

func _animate_capsule_machine() -> void:
	if GameManager.reduced_motion:
		return
	capsule_machine.pivot_offset = capsule_machine.size * 0.5
	capsule_machine.rotation_degrees = 0.0
	capsule_machine.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(capsule_machine, "rotation_degrees", -3.5, 0.07)
	tween.tween_property(capsule_machine, "rotation_degrees", 3.5, 0.08)
	tween.tween_property(capsule_machine, "rotation_degrees", -2.0, 0.07)
	tween.tween_property(capsule_machine, "rotation_degrees", 2.0, 0.07)
	tween.tween_property(capsule_machine, "rotation_degrees", 0.0, 0.08)
	var pulse := create_tween().set_parallel(true)
	pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(capsule_machine, "scale", Vector2(1.06, 1.06), 0.18)
	pulse.tween_property(capsule_machine, "modulate", Color("#fff1a8"), 0.18)
	pulse.chain().tween_property(capsule_machine, "scale", Vector2.ONE, 0.22)
	pulse.parallel().tween_property(capsule_machine, "modulate", Color.WHITE, 0.22)

func _animate_result_reveal(color: Color) -> void:
	if GameManager.reduced_motion:
		return
	result_panel.pivot_offset = result_panel.size * 0.5
	result_panel.scale = Vector2(0.88, 0.88)
	result_panel.modulate = Color(color, 0.72)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_panel, "scale", Vector2.ONE, 0.3)
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.24)

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
		buy_capsule_button.text = "WAIT %ds" % ceili(GameManager.get_gacha_wait_time())
	elif not _gacha_opening:
		buy_capsule_button.text = "BUY CAPSULE"

var _pending_gacha_result: Dictionary = {}

func _on_buy_capsule() -> void:
	if _gacha_opening:
		return
	var result := GameManager.roll_gacha()
	if result.is_empty():
		return
	_pending_gacha_result = result
	if GameManager.reduced_motion:
		result_panel.visible = true
		_finish_gacha_roll()
		return
	# Show opening animation
	_gacha_opening = true
	_gacha_opening_timer = 0.6
	result_panel.visible = true
	_apply_result_rarity_style(Color("#1dd9f2"), "CAPSULE SPINNING...")
	boost_name_label.text = "OPENING..."
	boost_name_label.add_theme_color_override("font_color", Color("#ffffff"))
	boost_desc_label.text = ""
	timer_label.text = ""
	_animate_capsule_machine()
	_update_gacha_cost()

func _finish_gacha_roll() -> void:
	var result := _pending_gacha_result
	if result.is_empty():
		return
	var rarity: String = result["rarity"]
	var color := Color(GameManager.RARITY_COLORS[rarity])
	var rarity_display := rarity.to_upper()
	_apply_result_rarity_style(color, "%s · BOOST ACQUIRED" % rarity_display)
	boost_name_label.text = result["name"]
	boost_name_label.add_theme_color_override("font_color", color)
	boost_desc_label.text = "%s for %ds" % [result["desc"], int(result["duration"])]
	_animate_result_reveal(color)
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
	if boost.get("name", "") != "Disco Lobster":
		_play_sfx(AchievementSfx)
	if GameManager.reduced_motion:
		boost_aura.emitting = false
		return
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
	_boost_ui_timer += delta
	if _boost_ui_timer < 0.1:
		return
	_boost_ui_timer = 0.0
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
		lines.append("%s - %sx %s (%.0fs)" % [b["name"], str(b["mult"]), "buildings" if b["type"] == "building_mult" else "clicks", GameManager.boost_time_remaining])
	if GameManager.single_building_boost_time > 0 and GameManager.single_building_boost_index >= 0:
		var bname: String = GameManager.building_defs[GameManager.single_building_boost_index]["name"]
		lines.append("BOOST: %s - %sx (%.0fs)" % [bname, str(GameManager.single_building_boost_mult), GameManager.single_building_boost_time])
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
	style.bg_color = Color("#7c4aad")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#a56de2")
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
	hover.bg_color = Color("#925cc2")
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color("#d7b6ff")
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
	disabled.bg_color = Color("#172633")
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
		buy_premium_button.text = "WAIT %ds" % ceili(GameManager.get_gacha_wait_time())
	elif not premium_options_container.visible:
		buy_premium_button.text = "DRAW CARDS"

func _on_buy_premium() -> void:
	var options := GameManager.start_premium_draw()
	if not options.is_empty():
		_show_premium_options(options)

func _show_premium_options(options: Array) -> void:
	# Clear previous options
	for child in premium_options_container.get_children():
		child.queue_free()
	premium_options_container.visible = true
	buy_premium_button.disabled = true
	var pick_label := Label.new()
	pick_label.text = "PICK 1 OF 3"
	pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_label.add_theme_font_override("font", UiBoldFont)
	pick_label.add_theme_font_size_override("font_size", 16)
	pick_label.add_theme_color_override("font_color", Color("#d7b6ff"))
	premium_options_container.add_child(pick_label)

	for opt in options:
		var card := _create_option_card(opt)
		premium_options_container.add_child(card)

func _create_option_card(boost: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size.y = 166.0
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
	style.shadow_color = Color(rarity_color, 0.18)
	style.shadow_size = 5
	card.add_theme_stylebox_override("panel", style)
	card.tooltip_text = "%s %s card" % [rarity.capitalize(), boost["name"]]

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	var card_icon := TextureRect.new()
	card_icon.texture = _card_icon_for_boost(boost)
	card_icon.custom_minimum_size = Vector2(70, 70)
	card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_row.add_child(card_icon)
	var header_copy := VBoxContainer.new()
	header_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_copy)
	vbox.add_child(header_row)

	# Rarity badge
	var rarity_lbl := Label.new()
	var rarity_display := rarity.to_upper()
	rarity_lbl.text = "%s · LOBSTER CARD" % rarity_display
	rarity_lbl.add_theme_color_override("font_color", rarity_color)
	rarity_lbl.add_theme_font_override("font", UiBoldFont)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	header_copy.add_child(rarity_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = boost["name"]
	name_lbl.add_theme_color_override("font_color", rarity_color)
	name_lbl.add_theme_font_override("font", UiBoldFont)
	name_lbl.add_theme_font_size_override("font_size", 20)
	header_copy.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = boost["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "PLAY THIS CARD"
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

func _card_icon_for_boost(boost: Dictionary) -> Texture2D:
	match str(boost.get("type", "")):
		"click_mult":
			return ClawPowerIcon
		"building_mult", "single_building_boost", "free_building":
			return BuildingPowerIcon
		"flat_lcps":
			return OfflinePowerIcon
		_:
			return BoostPowerIcon

func _on_premium_option_selected(boost: Dictionary) -> void:
	if GameManager.activate_premium_boost(boost):
		premium_options_container.visible = false
		_update_gacha_cost()

func _on_premium_boost_activated(boost: Dictionary) -> void:
	var btype: String = boost["type"]
	var result_color := Color(GameManager.RARITY_COLORS[boost.get("rarity", "common")])
	# Show result in the gacha result panel for timed boosts
	if btype == "building_mult" or btype == "click_mult":
		result_panel.visible = true
		var rarity: String = boost["rarity"]
		var color := Color(GameManager.RARITY_COLORS[rarity])
		_apply_result_rarity_style(color, "%s · CARD SELECTED" % rarity.to_upper())
		boost_name_label.text = boost["name"]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = "%s for %ds" % [boost["desc"], int(boost["duration"])]
	elif btype == "flat_lcps":
		result_panel.visible = true
		var color := Color(GameManager.RARITY_COLORS[boost["rarity"]])
		_apply_result_rarity_style(color, "PERMANENT · CARD SELECTED")
		boost_name_label.text = boost["name"]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = boost["desc"]
		timer_label.text = "Applied! Total flat bonus: +%s LCPS" % GameManager.format_number(GameManager.flat_lcps_bonus)
		timer_label.add_theme_color_override("font_color", Color("#2ecc71"))
	elif btype == "free_building":
		result_panel.visible = true
		var color := Color(GameManager.RARITY_COLORS[boost["rarity"]])
		_apply_result_rarity_style(color, "FREE BUILDING · CARD SELECTED")
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
		_apply_result_rarity_style(color, "%s · CARD SELECTED" % boost["rarity"].to_upper())
		boost_name_label.text = "%s -> %s" % [boost["name"], bname]
		boost_name_label.add_theme_color_override("font_color", color)
		boost_desc_label.text = "%sx %s for %ds" % [str(boost["mult"]), bname, int(boost["duration"])]
		timer_label.text = ""
	if result_panel.visible:
		_animate_result_reveal(result_color)
	_update_lps_display()
