extends Control

const UpgradeItemScene := preload("res://scenes/upgrade_item.tscn")

@onready var lobster_count_label: Label = %LobsterCountLabel
@onready var lps_label: Label = %LpsLabel
@onready var claw_button: Button = %ClawButton
@onready var top_pincer_pivot: Node2D = %TopPincerPivot
@onready var bottom_pincer_pivot: Node2D = %BottomPincerPivot
@onready var upgrade_container: VBoxContainer = %UpgradeContainer
@onready var particles: CPUParticles2D = %ClickParticles
@onready var float_text_container: Node2D = %FloatTextContainer
@onready var offline_popup: PanelContainer = %OfflinePopup
@onready var offline_label: Label = %OfflineLabel
@onready var offline_ok_button: Button = %OfflineOkButton

# Manual animation state (no tweens - they break in web export)
const OPEN_ANGLE := 0.52       # ~30 degrees open (resting)
const SHUT_ANGLE := 0.087      # ~5 degrees (snap overshoot)
const SNAP_SPEED := 12.0       # radians/sec for snap shut
const OPEN_SPEED := 3.0        # radians/sec for open back

enum ClawState { IDLE, SNAPPING, OPENING }
var claw_state: int = ClawState.IDLE
var claw_progress: float = 0.0  # 0 = start of anim, 1 = end

func _ready() -> void:
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.lps_changed.connect(_on_lps_changed)
	claw_button.gui_input.connect(_on_claw_gui_input)
	offline_ok_button.pressed.connect(_on_offline_ok)

	# Set initial open position
	if top_pincer_pivot:
		top_pincer_pivot.rotation = -OPEN_ANGLE
	if bottom_pincer_pivot:
		bottom_pincer_pivot.rotation = OPEN_ANGLE

	# Populate upgrades
	for i in range(GameManager.upgrade_defs.size()):
		var item := UpgradeItemScene.instantiate()
		upgrade_container.add_child(item)
		item.setup(i)

	# Initial display
	_on_lobsters_changed(GameManager.total_lobsters)
	_on_lps_changed(GameManager.lobsters_per_second)

	# Show offline popup if needed
	if SaveManager.offline_earnings > 0:
		offline_label.text = "Welcome back!\nYou earned %s lobsters\nwhile you were away!" % GameManager.format_number(SaveManager.offline_earnings)
		offline_popup.visible = true
	else:
		offline_popup.visible = false

func _on_lobsters_changed(total: float) -> void:
	lobster_count_label.text = GameManager.format_number(total)

func _on_lps_changed(lps: float) -> void:
	if lps < 1.0 and lps > 0:
		lps_label.text = "%.1f lobsters/sec" % lps
	else:
		lps_label.text = "%s lobsters/sec" % GameManager.format_number(lps)

func _process(delta: float) -> void:
	# Drive claw animation manually every frame (tweens don't work in web export)
	match claw_state:
		ClawState.SNAPPING:
			claw_progress += delta * SNAP_SPEED
			if claw_progress >= 1.0:
				claw_progress = 0.0
				claw_state = ClawState.OPENING
				# Set to fully shut position
				top_pincer_pivot.rotation = SHUT_ANGLE
				bottom_pincer_pivot.rotation = -SHUT_ANGLE
			else:
				# Lerp from open to shut
				var t := claw_progress
				top_pincer_pivot.rotation = lerpf(-OPEN_ANGLE, SHUT_ANGLE, t)
				bottom_pincer_pivot.rotation = lerpf(OPEN_ANGLE, -SHUT_ANGLE, t)

		ClawState.OPENING:
			claw_progress += delta * OPEN_SPEED
			if claw_progress >= 1.0:
				claw_progress = 0.0
				claw_state = ClawState.IDLE
				top_pincer_pivot.rotation = -OPEN_ANGLE
				bottom_pincer_pivot.rotation = OPEN_ANGLE
			else:
				# Ease out (decelerate)
				var t := 1.0 - pow(1.0 - claw_progress, 2.0)
				top_pincer_pivot.rotation = lerpf(SHUT_ANGLE, -OPEN_ANGLE, t)
				bottom_pincer_pivot.rotation = lerpf(-SHUT_ANGLE, OPEN_ANGLE, t)

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
	# Start snap animation (interrupts current animation)
	claw_state = ClawState.SNAPPING
	claw_progress = 0.0
	_spawn_float_text(amount)
	particles.restart()
	particles.emitting = true

func _spawn_float_text(amount: float) -> void:
	var label := Label.new()
	label.text = "+%s" % GameManager.format_number(amount)
	label.add_theme_color_override("font_color", Color("#ff6b6b"))
	label.add_theme_font_size_override("font_size", 28)
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
