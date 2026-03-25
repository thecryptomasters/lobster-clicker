extends PanelContainer

var building_index: int = 0

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var count_label: Label = %CountLabel
@onready var lps_label: Label = %LpsLabel
@onready var buy_button: Button = %BuyButton
@onready var total_lps_label: Label = %TotalLpsLabel

var _affordable_style: StyleBoxFlat
var _unaffordable_style: StyleBoxFlat

func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.building_purchased.connect(_on_building_purchased)
	GameManager.lps_changed.connect(_on_lps_changed)

	_affordable_style = StyleBoxFlat.new()
	_affordable_style.bg_color = Color("#2d6b4f")
	_affordable_style.corner_radius_top_left = 6
	_affordable_style.corner_radius_top_right = 6
	_affordable_style.corner_radius_bottom_left = 6
	_affordable_style.corner_radius_bottom_right = 6
	_affordable_style.content_margin_left = 8.0
	_affordable_style.content_margin_right = 8.0
	_affordable_style.content_margin_top = 4.0
	_affordable_style.content_margin_bottom = 4.0

	_unaffordable_style = StyleBoxFlat.new()
	_unaffordable_style.bg_color = Color("#333333")
	_unaffordable_style.corner_radius_top_left = 6
	_unaffordable_style.corner_radius_top_right = 6
	_unaffordable_style.corner_radius_bottom_left = 6
	_unaffordable_style.corner_radius_bottom_right = 6
	_unaffordable_style.content_margin_left = 8.0
	_unaffordable_style.content_margin_right = 8.0
	_unaffordable_style.content_margin_top = 4.0
	_unaffordable_style.content_margin_bottom = 4.0

	_refresh()

func setup(index: int) -> void:
	building_index = index
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	var def: Dictionary = GameManager.building_defs[building_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	var cost := GameManager.get_building_cost(building_index)
	cost_label.text = "Cost: %s" % GameManager.format_number(cost)
	var count := GameManager.building_counts[building_index]
	count_label.text = "x%d" % count
	var mult := GameManager.get_building_multiplier(building_index)
	var effective_lps: float = def["lps"] * mult
	if mult > 1.0:
		lps_label.text = "+%s/sec (%dx)" % [str(effective_lps), int(mult)]
	else:
		lps_label.text = "+%s/sec" % str(def["lps"])
	# Total LCPS from this building
	var total_building_lps: float = count * effective_lps
	if total_building_lps > 0:
		total_lps_label.text = "Generating: %s LCPS" % GameManager.format_number(total_building_lps)
		total_lps_label.visible = true
	else:
		total_lps_label.visible = false
	_update_buy_button_style()

func _update_buy_button_style() -> void:
	var affordable := GameManager.can_afford_building(building_index)
	buy_button.disabled = not affordable
	if affordable:
		buy_button.modulate = Color(1, 1, 1, 1)
		buy_button.add_theme_stylebox_override("normal", _affordable_style)
		buy_button.add_theme_stylebox_override("hover", _affordable_style)
		buy_button.add_theme_stylebox_override("pressed", _affordable_style)
	else:
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
		cost_label.text = "Cost: %s" % GameManager.format_number(GameManager.get_building_cost(building_index))

func _on_building_purchased(index: int) -> void:
	if index == building_index:
		_refresh()

func _on_lps_changed(_lps: float) -> void:
	if is_node_ready():
		_refresh()
