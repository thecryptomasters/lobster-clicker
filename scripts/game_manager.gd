extends Node

signal lobsters_changed(total: float)
signal lps_changed(lps: float)
signal building_purchased(index: int)
signal upgrade_unlocked(building_index: int, tier: int)

var total_lobsters: float = 0.0
var lobsters_per_click: float = 1.0
var lobsters_per_second: float = 0.0
var last_save_time: int = 0

# Building definitions (formerly "upgrades")
var building_defs: Array = [
	{"name": "Lobster Trap", "base_cost": 15, "lps": 0.1, "desc": "A simple trap baited with fish heads."},
	{"name": "Fishing Net", "base_cost": 100, "lps": 1.0, "desc": "Cast a wide net for more lobsters."},
	{"name": "Fishing Boat", "base_cost": 1100, "lps": 8.0, "desc": "A sturdy boat for deep-sea lobstering."},
	{"name": "Seafood Restaurant", "base_cost": 12000, "lps": 47.0, "desc": "Lobsters come to you!"},
	{"name": "Fish Market", "base_cost": 130000, "lps": 260.0, "desc": "Control the lobster supply chain."},
	{"name": "Ocean Farm", "base_cost": 1400000, "lps": 1400.0, "desc": "Industrial-scale lobster farming."},
]

var building_counts: Array[int] = []

const COST_MULTIPLIER: float = 1.15
const UPGRADE_THRESHOLDS := [10, 25, 50, 100]
const TIER_NAMES := ["I", "II", "III", "IV"]

# Track which upgrades are purchased per building: building_upgrades[building_idx][tier] = bool
var building_upgrades: Array = []

func _ready() -> void:
	building_counts.resize(building_defs.size())
	building_counts.fill(0)
	_init_building_upgrades()

func _init_building_upgrades() -> void:
	building_upgrades.clear()
	for i in range(building_defs.size()):
		var tiers: Array[bool] = []
		tiers.resize(UPGRADE_THRESHOLDS.size())
		tiers.fill(false)
		building_upgrades.append(tiers)

func get_building_multiplier(index: int) -> float:
	var mult := 1.0
	if index < building_upgrades.size():
		for tier in range(building_upgrades[index].size()):
			if building_upgrades[index][tier]:
				mult *= 2.0
	return mult

func click() -> float:
	total_lobsters += lobsters_per_click
	lobsters_changed.emit(total_lobsters)
	return lobsters_per_click

func _process(delta: float) -> void:
	if lobsters_per_second > 0:
		total_lobsters += lobsters_per_second * delta
		lobsters_changed.emit(total_lobsters)

func get_building_cost(index: int) -> float:
	var base: float = building_defs[index]["base_cost"]
	var count: int = building_counts[index]
	return floor(base * pow(COST_MULTIPLIER, count))

func can_afford_building(index: int) -> bool:
	return total_lobsters >= get_building_cost(index)

func buy_building(index: int) -> bool:
	var cost := get_building_cost(index)
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	var old_count := building_counts[index]
	building_counts[index] += 1
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	building_purchased.emit(index)
	# Check if a new upgrade threshold was crossed
	for tier in range(UPGRADE_THRESHOLDS.size()):
		if old_count < UPGRADE_THRESHOLDS[tier] and building_counts[index] >= UPGRADE_THRESHOLDS[tier]:
			upgrade_unlocked.emit(index, tier)
	return true

func _recalculate_lps() -> void:
	lobsters_per_second = 0.0
	for i in range(building_defs.size()):
		lobsters_per_second += building_counts[i] * building_defs[i]["lps"] * get_building_multiplier(i)
	lps_changed.emit(lobsters_per_second)

# --- Milestone Upgrades ---

func get_upgrade_cost_for(building_index: int, tier: int) -> float:
	return building_defs[building_index]["base_cost"] * UPGRADE_THRESHOLDS[tier] * 10

func get_available_upgrades() -> Array:
	var result: Array = []
	for bi in range(building_defs.size()):
		for tier in range(UPGRADE_THRESHOLDS.size()):
			if building_counts[bi] >= UPGRADE_THRESHOLDS[tier]:
				var cost := get_upgrade_cost_for(bi, tier)
				var purchased: bool = building_upgrades[bi][tier]
				result.append({
					"building_index": bi,
					"tier": tier,
					"cost": cost,
					"purchased": purchased,
					"name": "%s Tier %s" % [building_defs[bi]["name"], TIER_NAMES[tier]],
					"desc": "Doubles %s production. (Requires %d %ss)" % [building_defs[bi]["name"], UPGRADE_THRESHOLDS[tier], building_defs[bi]["name"]],
				})
	return result

func can_afford_building_upgrade(building_index: int, tier: int) -> bool:
	return total_lobsters >= get_upgrade_cost_for(building_index, tier)

func buy_building_upgrade(building_index: int, tier: int) -> bool:
	if building_upgrades[building_index][tier]:
		return false
	var cost := get_upgrade_cost_for(building_index, tier)
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	building_upgrades[building_index][tier] = true
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	return true

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
	# Convert building_upgrades to serializable format
	var upgrades_data: Array = []
	for bi in range(building_upgrades.size()):
		var tiers: Array = []
		for tier in range(building_upgrades[bi].size()):
			tiers.append(building_upgrades[bi][tier])
		upgrades_data.append(tiers)
	return {
		"total_lobsters": total_lobsters,
		"building_counts": building_counts,
		"building_upgrades": upgrades_data,
		"last_save_time": Time.get_unix_time_from_system(),
	}

func load_save_data(data: Dictionary) -> void:
	total_lobsters = data.get("total_lobsters", 0.0)
	# Backward compat: support old "upgrade_counts" key
	var counts = data.get("building_counts", data.get("upgrade_counts", []))
	for i in range(mini(counts.size(), building_counts.size())):
		building_counts[i] = counts[i]
	# Load building upgrades (backward compat: default all false)
	var upgrades_data = data.get("building_upgrades", [])
	for bi in range(building_upgrades.size()):
		if bi < upgrades_data.size():
			var tiers = upgrades_data[bi]
			for tier in range(building_upgrades[bi].size()):
				if tier < tiers.size():
					building_upgrades[bi][tier] = tiers[tier]
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	last_save_time = data.get("last_save_time", 0)
