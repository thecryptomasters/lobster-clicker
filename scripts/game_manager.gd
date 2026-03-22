extends Node

signal lobsters_changed(total: float)
signal lps_changed(lps: float)
signal upgrade_purchased(index: int)

var total_lobsters: float = 0.0
var lobsters_per_click: float = 1.0
var lobsters_per_second: float = 0.0
var last_save_time: int = 0

# Upgrade definitions: [name, base_cost, base_lps, description]
var upgrade_defs: Array = [
	{"name": "Lobster Trap", "base_cost": 15, "lps": 0.1, "desc": "A simple trap baited with fish heads."},
	{"name": "Fishing Net", "base_cost": 100, "lps": 1.0, "desc": "Cast a wide net for more lobsters."},
	{"name": "Fishing Boat", "base_cost": 1100, "lps": 8.0, "desc": "A sturdy boat for deep-sea lobstering."},
	{"name": "Seafood Restaurant", "base_cost": 12000, "lps": 47.0, "desc": "Lobsters come to you!"},
	{"name": "Fish Market", "base_cost": 130000, "lps": 260.0, "desc": "Control the lobster supply chain."},
	{"name": "Ocean Farm", "base_cost": 1400000, "lps": 1400.0, "desc": "Industrial-scale lobster farming."},
]

var upgrade_counts: Array[int] = []

const COST_MULTIPLIER: float = 1.15

func _ready() -> void:
	upgrade_counts.resize(upgrade_defs.size())
	upgrade_counts.fill(0)

func click() -> float:
	total_lobsters += lobsters_per_click
	lobsters_changed.emit(total_lobsters)
	return lobsters_per_click

func _process(delta: float) -> void:
	if lobsters_per_second > 0:
		total_lobsters += lobsters_per_second * delta
		lobsters_changed.emit(total_lobsters)

func get_upgrade_cost(index: int) -> float:
	var base: float = upgrade_defs[index]["base_cost"]
	var count: int = upgrade_counts[index]
	return floor(base * pow(COST_MULTIPLIER, count))

func can_afford_upgrade(index: int) -> bool:
	return total_lobsters >= get_upgrade_cost(index)

func buy_upgrade(index: int) -> bool:
	var cost := get_upgrade_cost(index)
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	upgrade_counts[index] += 1
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	upgrade_purchased.emit(index)
	return true

func _recalculate_lps() -> void:
	lobsters_per_second = 0.0
	for i in range(upgrade_defs.size()):
		lobsters_per_second += upgrade_counts[i] * upgrade_defs[i]["lps"]
	lps_changed.emit(lobsters_per_second)

func format_number(n: float) -> String:
	var num := int(floor(n))
	var s := str(num)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func get_save_data() -> Dictionary:
	return {
		"total_lobsters": total_lobsters,
		"upgrade_counts": upgrade_counts,
		"last_save_time": Time.get_unix_time_from_system(),
	}

func load_save_data(data: Dictionary) -> void:
	total_lobsters = data.get("total_lobsters", 0.0)
	var counts = data.get("upgrade_counts", [])
	for i in range(mini(counts.size(), upgrade_counts.size())):
		upgrade_counts[i] = counts[i]
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	last_save_time = data.get("last_save_time", 0)
