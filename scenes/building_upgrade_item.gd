extends PanelContainer

var building_index: int = 0
var tier: int = 0
var is_purchased: bool = false

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton

var _affordable_style: StyleBoxFlat
var _unaffordable_style: StyleBoxFlat
var _owned_style: StyleBoxFlat

func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	GameManager.lobsters_changed.connect(_on_lobsters_changed)

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

	_owned_style = StyleBoxFlat.new()
	_owned_style.bg_color = Color("#1a4a3a")
	_owned_style.corner_radius_top_left = 6
	_owned_style.corner_radius_top_right = 6
	_owned_style.corner_radius_bottom_left = 6
	_owned_style.corner_radius_bottom_right = 6
	_owned_style.content_margin_left = 8.0
	_owned_style.content_margin_right = 8.0
	_owned_style.content_margin_top = 4.0
	_owned_style.content_margin_bottom = 4.0

	_refresh()

var is_click_upgrade: bool = false
var click_upgrade_index: int = 0

func setup(b_index: int, t: int, purchased: bool) -> void:
	building_index = b_index
	tier = t
	is_purchased = purchased
	is_click_upgrade = false
	if is_node_ready():
		_refresh()

var is_cps_click_upgrade: bool = false
var cps_click_upgrade_index: int = 0

func setup_click_upgrade(index: int, purchased: bool) -> void:
	click_upgrade_index = index
	is_click_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_click_upgrade()

var is_hold_click_upgrade: bool = false
var hold_click_upgrade_index: int = 0

func setup_hold_click_upgrade(index: int, purchased: bool) -> void:
	hold_click_upgrade_index = index
	is_hold_click_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_hold_click_upgrade()

func setup_cps_click_upgrade(index: int, purchased: bool) -> void:
	cps_click_upgrade_index = index
	is_cps_click_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_cps_click_upgrade()

func _refresh() -> void:
	var tier_names := ["I", "II", "III", "IV"]
	var def: Dictionary = GameManager.building_defs[building_index]
	name_label.text = "%s Tier %s" % [def["name"], tier_names[tier]]
	var threshold: int = GameManager.UPGRADE_THRESHOLDS[tier]
	desc_label.text = "Doubles %s production. (Requires %d %ss)" % [def["name"], threshold, def["name"]]
	var cost := GameManager.get_upgrade_cost_for(building_index, tier)

	if is_purchased:
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED \u2713"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(cost)
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_buy_button_style()

func _update_buy_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_building_upgrade(building_index, tier)
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

func _refresh_click_upgrade() -> void:
	var def: Dictionary = GameManager.click_upgrade_defs[click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED ✓"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_buy_button_style()

func _refresh_cps_click_upgrade() -> void:
	var def: Dictionary = GameManager.cps_click_upgrade_defs[cps_click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED ✓"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_cps_click_button_style()

func _update_cps_click_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_cps_click_upgrade(cps_click_upgrade_index)
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

func _refresh_hold_click_upgrade() -> void:
	var def: Dictionary = GameManager.hold_click_defs[hold_click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED ✓"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_hold_click_button_style()

func _update_hold_click_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_hold_click_upgrade(hold_click_upgrade_index)
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
	if is_hold_click_upgrade:
		if GameManager.buy_hold_click_upgrade(hold_click_upgrade_index):
			is_purchased = true
			_refresh_hold_click_upgrade()
	elif is_cps_click_upgrade:
		if GameManager.buy_cps_click_upgrade(cps_click_upgrade_index):
			is_purchased = true
			_refresh_cps_click_upgrade()
	elif is_click_upgrade:
		if GameManager.buy_click_upgrade(click_upgrade_index):
			is_purchased = true
			_refresh_click_upgrade()
	else:
		if GameManager.buy_building_upgrade(building_index, tier):
			is_purchased = true
			_refresh()

func _on_lobsters_changed(_total: float) -> void:
	if is_node_ready() and not is_purchased:
		if is_hold_click_upgrade:
			_update_hold_click_button_style()
		elif is_cps_click_upgrade:
			_update_cps_click_button_style()
		elif is_click_upgrade:
			_update_buy_button_style_click()
		else:
			_update_buy_button_style()

func _update_buy_button_style_click() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_click_upgrade(click_upgrade_index)
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
