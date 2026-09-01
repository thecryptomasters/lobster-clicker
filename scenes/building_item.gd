extends PanelContainer

var building_index: int = 0

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var count_label: Label = %CountLabel
@onready var lps_label: Label = %LpsLabel
@onready var buy_button: Button = %BuyButton
@onready var total_lps_label: Label = %TotalLpsLabel
@onready var icon_badge: Label = %IconBadge

var _affordable_style: StyleBoxFlat
var _unaffordable_style: StyleBoxFlat
var _card_style: StyleBoxFlat
var _card_affordable_style: StyleBoxFlat
var _badge_style: StyleBoxFlat

func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.building_purchased.connect(_on_building_purchased)
	GameManager.lps_changed.connect(_on_lps_changed)
	GameManager.purchase_mode_changed.connect(_on_purchase_mode_changed)

	_affordable_style = StyleBoxFlat.new()
	_affordable_style.bg_color = Color("#e9553f")
	_affordable_style.border_width_left = 1
	_affordable_style.border_width_top = 1
	_affordable_style.border_width_right = 1
	_affordable_style.border_width_bottom = 1
	_affordable_style.border_color = Color("#ff846b")
	_affordable_style.corner_radius_top_left = 6
	_affordable_style.corner_radius_top_right = 6
	_affordable_style.corner_radius_bottom_left = 6
	_affordable_style.corner_radius_bottom_right = 6
	_affordable_style.content_margin_left = 8.0
	_affordable_style.content_margin_right = 8.0
	_affordable_style.content_margin_top = 4.0
	_affordable_style.content_margin_bottom = 4.0

	_unaffordable_style = StyleBoxFlat.new()
	_unaffordable_style.bg_color = Color("#173447")
	_unaffordable_style.border_width_left = 1
	_unaffordable_style.border_width_top = 1
	_unaffordable_style.border_width_right = 1
	_unaffordable_style.border_width_bottom = 1
	_unaffordable_style.border_color = Color("#31566a")
	_unaffordable_style.corner_radius_top_left = 6
	_unaffordable_style.corner_radius_top_right = 6
	_unaffordable_style.corner_radius_bottom_left = 6
	_unaffordable_style.corner_radius_bottom_right = 6
	_unaffordable_style.content_margin_left = 8.0
	_unaffordable_style.content_margin_right = 8.0
	_unaffordable_style.content_margin_top = 4.0
	_unaffordable_style.content_margin_bottom = 4.0

	_card_style = StyleBoxFlat.new()
	_card_style.bg_color = Color("#0d2232")
	_card_style.border_width_left = 1
	_card_style.border_width_top = 1
	_card_style.border_width_right = 1
	_card_style.border_width_bottom = 1
	_card_style.border_color = Color("#23495b")
	_card_style.corner_radius_top_left = 10
	_card_style.corner_radius_top_right = 10
	_card_style.corner_radius_bottom_left = 10
	_card_style.corner_radius_bottom_right = 10
	_card_style.content_margin_left = 12.0
	_card_style.content_margin_right = 12.0
	_card_style.content_margin_top = 8.0
	_card_style.content_margin_bottom = 8.0

	_card_affordable_style = _card_style.duplicate() as StyleBoxFlat
	_card_affordable_style.bg_color = Color("#102d3d")
	_card_affordable_style.border_color = Color("#3a7180")

	_badge_style = StyleBoxFlat.new()
	_badge_style.bg_color = Color("#071725")
	_badge_style.border_width_left = 1
	_badge_style.border_width_top = 1
	_badge_style.border_width_right = 1
	_badge_style.border_width_bottom = 1
	_badge_style.border_color = Color("#ffd166")
	_badge_style.corner_radius_top_left = 8
	_badge_style.corner_radius_top_right = 8
	_badge_style.corner_radius_bottom_left = 8
	_badge_style.corner_radius_bottom_right = 8
	icon_badge.add_theme_stylebox_override("normal", _badge_style)

	_refresh()

func setup(index: int) -> void:
	building_index = index
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	var def: Dictionary = GameManager.building_defs[building_index]
	icon_badge.text = "%02d" % (building_index + 1)
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	var cost := GameManager.get_selected_building_cost(building_index)
	cost_label.text = "Cost: %s" % GameManager.format_number(cost)
	var selected_amount := GameManager.get_selected_building_amount(building_index)
	if GameManager.building_purchase_mode == -1:
		buy_button.text = "BUY MAX (%d)" % selected_amount if selected_amount > 0 else "BUY MAX"
	else:
		buy_button.text = "BUY %d" % GameManager.building_purchase_mode
	var count := GameManager.building_counts[building_index]
	count_label.text = "x%d" % count
	var mult := GameManager.get_building_multiplier(building_index) * GameManager.get_shell_multiplier()
	var effective_lps: float = def["lps"] * mult
	if mult > 1.0:
		lps_label.text = "+%s/sec (%sx)" % [GameManager.format_rate(effective_lps), GameManager.format_rate(mult)]
	else:
		lps_label.text = "+%s/sec" % str(def["lps"])
	# Total LCPS from this building
	var total_building_lps: float = count * effective_lps
	if total_building_lps > 0:
		total_lps_label.text = "Generating: %s LCPS" % GameManager.format_rate(total_building_lps)
		total_lps_label.visible = true
	else:
		total_lps_label.visible = false
	_update_buy_button_style()

func _update_buy_button_style() -> void:
	var affordable := GameManager.can_afford_building(building_index)
	buy_button.disabled = not affordable
	if affordable:
		add_theme_stylebox_override("panel", _card_affordable_style)
		buy_button.modulate = Color(1, 1, 1, 1)
		buy_button.add_theme_stylebox_override("normal", _affordable_style)
		buy_button.add_theme_stylebox_override("hover", _affordable_style)
		buy_button.add_theme_stylebox_override("pressed", _affordable_style)
	else:
		add_theme_stylebox_override("panel", _card_style)
		buy_button.modulate = Color(0.7, 0.7, 0.7, 1)
		buy_button.add_theme_stylebox_override("normal", _unaffordable_style)
		buy_button.add_theme_stylebox_override("hover", _unaffordable_style)
		buy_button.add_theme_stylebox_override("pressed", _unaffordable_style)
		buy_button.add_theme_stylebox_override("disabled", _unaffordable_style)

func _on_buy() -> void:
	GameManager.buy_building(building_index)

func _on_lobsters_changed(_total: float) -> void:
	if is_node_ready():
		_update_buy_button_style()
		cost_label.text = "Cost: %s" % GameManager.format_number(GameManager.get_selected_building_cost(building_index))
		if GameManager.building_purchase_mode == -1:
			var amount := GameManager.get_selected_building_amount(building_index)
			buy_button.text = "BUY MAX (%d)" % amount if amount > 0 else "BUY MAX"

func _on_building_purchased(index: int) -> void:
	if index == building_index:
		_refresh()
		if not GameManager.reduced_motion:
			var tween := create_tween()
			modulate = Color("#ffd166")
			tween.tween_property(self, "modulate", Color.WHITE, 0.22)

func _on_lps_changed(_lps: float) -> void:
	if is_node_ready():
		_refresh()

func _on_purchase_mode_changed(_mode: int) -> void:
	if is_node_ready():
		_refresh()
