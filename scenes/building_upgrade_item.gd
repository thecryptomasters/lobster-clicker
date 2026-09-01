extends PanelContainer

const ClawPowerIcon := preload("res://assets/art/ui/medallions/claw_power.png")
const BuildingPowerIcon := preload("res://assets/art/ui/medallions/building_power.png")
const OfflinePowerIcon := preload("res://assets/art/ui/medallions/offline_power.png")
const BoostPowerIcon := preload("res://assets/art/ui/medallions/boost_power.png")

var building_index: int = 0
var tier: int = 0
var is_purchased: bool = false

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var buy_button: Button = %BuyButton
@onready var type_badge: Label = %TypeBadge
@onready var icon_texture: TextureRect = %IconTexture

var _affordable_style: StyleBoxFlat
var _unaffordable_style: StyleBoxFlat
var _owned_style: StyleBoxFlat
var _card_style: StyleBoxFlat
var _card_affordable_style: StyleBoxFlat
var _card_owned_style: StyleBoxFlat
var _badge_style: StyleBoxFlat

func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	GameManager.lobsters_changed.connect(_on_lobsters_changed)

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
	_unaffordable_style.corner_radius_top_left = 6
	_unaffordable_style.corner_radius_top_right = 6
	_unaffordable_style.corner_radius_bottom_left = 6
	_unaffordable_style.corner_radius_bottom_right = 6
	_unaffordable_style.content_margin_left = 8.0
	_unaffordable_style.content_margin_right = 8.0
	_unaffordable_style.content_margin_top = 4.0
	_unaffordable_style.content_margin_bottom = 4.0

	_owned_style = StyleBoxFlat.new()
	_owned_style.bg_color = Color("#174b43")
	_owned_style.corner_radius_top_left = 6
	_owned_style.corner_radius_top_right = 6
	_owned_style.corner_radius_bottom_left = 6
	_owned_style.corner_radius_bottom_right = 6
	_owned_style.content_margin_left = 8.0
	_owned_style.content_margin_right = 8.0
	_owned_style.content_margin_top = 4.0
	_owned_style.content_margin_bottom = 4.0

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
	add_theme_stylebox_override("panel", _card_style)

	_card_affordable_style = _card_style.duplicate() as StyleBoxFlat
	_card_affordable_style.bg_color = Color("#102d3b")
	_card_affordable_style.border_width_left = 3
	_card_affordable_style.border_color = Color("#55d6be")
	_card_affordable_style.shadow_color = Color(0.11, 0.85, 0.95, 0.16)
	_card_affordable_style.shadow_size = 4

	_card_owned_style = _card_style.duplicate() as StyleBoxFlat
	_card_owned_style.bg_color = Color("#102f2d")
	_card_owned_style.border_width_left = 3
	_card_owned_style.border_color = Color("#55d6be")

	_badge_style = StyleBoxFlat.new()
	_badge_style.bg_color = Color("#071725")
	_badge_style.border_width_left = 1
	_badge_style.border_width_top = 1
	_badge_style.border_width_right = 1
	_badge_style.border_width_bottom = 1
	_badge_style.border_color = Color("#a56de2")
	_badge_style.corner_radius_top_left = 7
	_badge_style.corner_radius_top_right = 7
	_badge_style.corner_radius_bottom_left = 7
	_badge_style.corner_radius_bottom_right = 7
	type_badge.add_theme_stylebox_override("normal", _badge_style)

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

var is_gacha_cd_upgrade: bool = false
var gacha_cd_upgrade_index: int = 0

var is_offline_rate_upgrade: bool = false
var offline_rate_upgrade_index: int = 0

var is_offline_duration_upgrade: bool = false
var offline_duration_upgrade_index: int = 0

func setup_offline_duration_upgrade(index: int, purchased: bool) -> void:
	offline_duration_upgrade_index = index
	is_offline_duration_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_offline_duration_upgrade()

func setup_offline_rate_upgrade(index: int, purchased: bool) -> void:
	offline_rate_upgrade_index = index
	is_offline_rate_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_offline_rate_upgrade()

func setup_gacha_cd_upgrade(index: int, purchased: bool) -> void:
	gacha_cd_upgrade_index = index
	is_gacha_cd_upgrade = true
	is_purchased = purchased
	if is_node_ready():
		_refresh_gacha_cd_upgrade()

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
	icon_texture.texture = BuildingPowerIcon
	var tier_names := ["I", "II", "III", "IV"]
	type_badge.text = "TIER %s" % tier_names[tier]
	_set_badge_accent(Color("#ffd166"))
	var def: Dictionary = GameManager.building_defs[building_index]
	name_label.text = "%s Tier %s" % [def["name"], tier_names[tier]]
	var threshold: int = GameManager.UPGRADE_THRESHOLDS[tier]
	var mult: int = GameManager.TIER_MULTIPLIERS[tier]
	desc_label.text = "%dx %s production. (Requires %d %ss)" % [mult, def["name"], threshold, def["name"]]
	var cost := GameManager.get_upgrade_cost_for(building_index, tier)

	if is_purchased:
		_set_card_state(false, true)
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
	_set_card_state(affordable, false)
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

func _set_badge_accent(color: Color) -> void:
	_badge_style.border_color = color
	type_badge.add_theme_color_override("font_color", color)
	type_badge.add_theme_stylebox_override("normal", _badge_style)

func _set_card_state(affordable: bool, owned: bool) -> void:
	if owned:
		add_theme_stylebox_override("panel", _card_owned_style)
	elif affordable:
		add_theme_stylebox_override("panel", _card_affordable_style)
	else:
		add_theme_stylebox_override("panel", _card_style)

func _refresh_click_upgrade() -> void:
	icon_texture.texture = ClawPowerIcon
	type_badge.text = "CLAW"
	_set_badge_accent(Color("#ff846b"))
	var def: Dictionary = GameManager.click_upgrade_defs[click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
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
	icon_texture.texture = ClawPowerIcon
	type_badge.text = "POWER"
	_set_badge_accent(Color("#ffd166"))
	var def: Dictionary = GameManager.cps_click_upgrade_defs[cps_click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
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
	_set_card_state(affordable, false)
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
	icon_texture.texture = ClawPowerIcon
	type_badge.text = "AUTO"
	_set_badge_accent(Color("#1dd9f2"))
	var def: Dictionary = GameManager.hold_click_defs[hold_click_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
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
	_set_card_state(affordable, false)
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

func _refresh_gacha_cd_upgrade() -> void:
	icon_texture.texture = BoostPowerIcon
	type_badge.text = "BOOST"
	_set_badge_accent(Color("#a56de2"))
	var def: Dictionary = GameManager.gacha_cooldown_upgrade_defs[gacha_cd_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_gacha_cd_button_style()

func _update_gacha_cd_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_gacha_cooldown_upgrade(gacha_cd_upgrade_index)
	_set_card_state(affordable, false)
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

func _refresh_offline_rate_upgrade() -> void:
	icon_texture.texture = OfflinePowerIcon
	type_badge.text = "TIDE"
	_set_badge_accent(Color("#55d6be"))
	var def: Dictionary = GameManager.offline_rate_defs[offline_rate_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_offline_rate_button_style()

func _update_offline_rate_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_offline_rate_upgrade(offline_rate_upgrade_index)
	_set_card_state(affordable, false)
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

func _refresh_offline_duration_upgrade() -> void:
	icon_texture.texture = OfflinePowerIcon
	type_badge.text = "TIME"
	_set_badge_accent(Color("#94b8c7"))
	var def: Dictionary = GameManager.offline_duration_defs[offline_duration_upgrade_index]
	name_label.text = def["name"]
	desc_label.text = def["desc"]
	if is_purchased:
		_set_card_state(false, true)
		cost_label.text = "OWNED"
		cost_label.add_theme_color_override("font_color", Color("#66cc88"))
		buy_button.text = "OWNED"
		buy_button.disabled = true
		buy_button.add_theme_stylebox_override("normal", _owned_style)
		buy_button.add_theme_stylebox_override("disabled", _owned_style)
		buy_button.modulate = Color(0.8, 1.0, 0.8, 1)
	else:
		cost_label.text = "Cost: %s" % GameManager.format_number(def["cost"])
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1))
		buy_button.text = "BUY"
		_update_offline_duration_button_style()

func _update_offline_duration_button_style() -> void:
	if is_purchased:
		return
	var affordable := GameManager.can_afford_offline_duration_upgrade(offline_duration_upgrade_index)
	_set_card_state(affordable, false)
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
	if is_offline_duration_upgrade:
		if GameManager.buy_offline_duration_upgrade(offline_duration_upgrade_index):
			is_purchased = true
			_refresh_offline_duration_upgrade()
	elif is_offline_rate_upgrade:
		if GameManager.buy_offline_rate_upgrade(offline_rate_upgrade_index):
			is_purchased = true
			_refresh_offline_rate_upgrade()
	elif is_gacha_cd_upgrade:
		if GameManager.buy_gacha_cooldown_upgrade(gacha_cd_upgrade_index):
			is_purchased = true
			_refresh_gacha_cd_upgrade()
	elif is_hold_click_upgrade:
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
		if is_offline_duration_upgrade:
			_update_offline_duration_button_style()
		elif is_offline_rate_upgrade:
			_update_offline_rate_button_style()
		elif is_gacha_cd_upgrade:
			_update_gacha_cd_button_style()
		elif is_hold_click_upgrade:
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
	_set_card_state(affordable, false)
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
