extends PanelContainer

var upgrade_index: int = 0

@onready var name_label: Label = %NameLabel
@onready var cost_label: Label = %CostLabel
@onready var count_label: Label = %CountLabel
@onready var lps_label: Label = %LpsLabel
@onready var buy_button: Button = %BuyButton

func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	GameManager.lobsters_changed.connect(_on_lobsters_changed)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)
	_refresh()

func setup(index: int) -> void:
	upgrade_index = index
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	var def: Dictionary = GameManager.upgrade_defs[upgrade_index]
	name_label.text = def["name"]
	var cost := GameManager.get_upgrade_cost(upgrade_index)
	cost_label.text = "Cost: %s" % GameManager.format_number(cost)
	count_label.text = "Owned: %d" % GameManager.upgrade_counts[upgrade_index]
	lps_label.text = "+%s/sec" % str(def["lps"])
	buy_button.disabled = not GameManager.can_afford_upgrade(upgrade_index)

	# Visual feedback for affordability
	if GameManager.can_afford_upgrade(upgrade_index):
		buy_button.modulate = Color(1, 1, 1, 1)
	else:
		buy_button.modulate = Color(0.6, 0.6, 0.6, 1)

func _on_buy() -> void:
	GameManager.buy_upgrade(upgrade_index)

func _on_lobsters_changed(_total: float) -> void:
	if is_node_ready():
		buy_button.disabled = not GameManager.can_afford_upgrade(upgrade_index)
		if GameManager.can_afford_upgrade(upgrade_index):
			buy_button.modulate = Color(1, 1, 1, 1)
		else:
			buy_button.modulate = Color(0.6, 0.6, 0.6, 1)
		cost_label.text = "Cost: %s" % GameManager.format_number(GameManager.get_upgrade_cost(upgrade_index))

func _on_upgrade_purchased(index: int) -> void:
	if index == upgrade_index:
		_refresh()
