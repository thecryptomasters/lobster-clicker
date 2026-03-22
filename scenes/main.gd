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

var claw_tween: Tween
var is_claw_animating := false

func _ready() -> void:
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.lps_changed.connect(_on_lps_changed)
	claw_button.pressed.connect(_on_claw_clicked)
	offline_ok_button.pressed.connect(_on_offline_ok)

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

func _on_claw_clicked() -> void:
	var amount := GameManager.click()
	_animate_claw()
	_spawn_float_text(amount)
	particles.restart()
	particles.emitting = true

func _animate_claw() -> void:
	if claw_tween:
		claw_tween.kill()

	# Resting open angle: ~13 degrees each side (≈0.227 rad set in scene)
	var open_angle := 13.0

	# Snap shut (fast) + scale squeeze
	claw_tween = create_tween()
	claw_tween.set_parallel(true)
	claw_tween.tween_property(top_pincer_pivot, "rotation_degrees", 0.0, 0.08)
	claw_tween.tween_property(bottom_pincer_pivot, "rotation_degrees", 0.0, 0.08)
	claw_tween.tween_property(claw_button, "scale", Vector2(0.95, 0.95), 0.08)

	# Open back (slower, ease out) + scale restore
	claw_tween.chain().set_parallel(true)
	claw_tween.tween_property(top_pincer_pivot, "rotation_degrees", -open_angle, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	claw_tween.tween_property(bottom_pincer_pivot, "rotation_degrees", open_angle, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	claw_tween.tween_property(claw_button, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT)

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
