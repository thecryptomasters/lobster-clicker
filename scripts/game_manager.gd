extends Node

signal lobsters_changed(total: float)
signal lps_changed(lps: float)
signal building_purchased(index: int)
signal upgrade_unlocked(building_index: int, tier: int)
signal boost_activated(boost: Dictionary)
signal boost_expired()

var total_lobsters: float = 0.0
var lobsters_per_click: float = 1.0
var farm_name: String = "My Lobster Farm"
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
	{"name": "Research Lab", "base_cost": 20000000, "lps": 7800.0, "desc": "Genetically engineer the ultimate lobster."},
	{"name": "Lobster Portal", "base_cost": 330000000, "lps": 44000.0, "desc": "Opens a rift to the Lobster Dimension."},
	{"name": "Time Machine", "base_cost": 5100000000, "lps": 260000.0, "desc": "Harvest lobsters from every era in history."},
]

var building_counts: Array[int] = []

const COST_MULTIPLIER: float = 1.15
const UPGRADE_THRESHOLDS := [10, 25, 50, 100]
const TIER_NAMES := ["I", "II", "III", "IV"]
const TIER_MULTIPLIERS := [2, 3, 5, 10]  # Tier I=2x, II=3x, III=5x, IV=10x

# Track which upgrades are purchased per building: building_upgrades[building_idx][tier] = bool
var building_upgrades: Array = []

# Click upgrades: unlock at lifetime lobster thresholds, each doubles click power
# {threshold, cost, name, desc}
var click_upgrade_defs: Array = [
	{"threshold": 500, "cost": 500, "multiplier": 2, "name": "Iron Claws", "desc": "2x lobsters per click. (500 lifetime lobsters)"},
	{"threshold": 5000, "cost": 5000, "multiplier": 5, "name": "Steel Claws", "desc": "5x lobsters per click. (5,000 lifetime lobsters)"},
	{"threshold": 250000, "cost": 250000, "multiplier": 10, "name": "Diamond Claws", "desc": "10x lobsters per click. (250,000 lifetime lobsters)"},
]
var click_upgrades_purchased: Array[bool] = [false, false, false]
var lifetime_lobsters: float = 0.0  # Total lobsters ever generated (never decreases)

# Offline production rate upgrades (base 5%)
var offline_rate_defs: Array = [
	{"threshold": 25000, "cost": 15000, "rate": 0.10, "name": "Lobster Lookout", "desc": "Offline production: 10%. (25,000 lifetime lobsters)"},
	{"threshold": 500000, "cost": 300000, "rate": 0.225, "name": "Night Shift", "desc": "Offline production: 22.5%. (500,000 lifetime lobsters)"},
	{"threshold": 5000000, "cost": 3000000, "rate": 0.50, "name": "Automated Traps", "desc": "Offline production: 50%. (5,000,000 lifetime lobsters)"},
	{"threshold": 50000000, "cost": 30000000, "rate": 0.85, "name": "Deep Sea Drones", "desc": "Offline production: 85%. (50,000,000 lifetime lobsters)"},
]
var offline_rate_purchased: Array[bool] = [false, false, false, false]

# Offline duration cap upgrades (base 1 hour)
var offline_duration_defs: Array = [
	{"threshold": 50000, "cost": 30000, "hours": 3, "name": "Extended Nets", "desc": "Offline cap: 3 hours. (50,000 lifetime lobsters)"},
	{"threshold": 1000000, "cost": 600000, "hours": 8, "name": "Overnight Crew", "desc": "Offline cap: 8 hours. (1,000,000 lifetime lobsters)"},
	{"threshold": 10000000, "cost": 6000000, "hours": 16, "name": "Double Shift", "desc": "Offline cap: 16 hours. (10,000,000 lifetime lobsters)"},
	{"threshold": 100000000, "cost": 60000000, "hours": 24, "name": "24/7 Operations", "desc": "Offline cap: 24 hours. (100,000,000 lifetime lobsters)"},
]
var offline_duration_purchased: Array[bool] = [false, false, false, false]

func get_offline_max_seconds() -> float:
	var hours := 1.0
	for i in range(offline_duration_purchased.size()):
		if offline_duration_purchased[i]:
			hours = offline_duration_defs[i]["hours"]
	return hours * 3600.0

func get_available_offline_duration_upgrades() -> Array:
	var result: Array = []
	for i in range(offline_duration_defs.size()):
		if lifetime_lobsters >= offline_duration_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": offline_duration_defs[i]["name"],
				"desc": offline_duration_defs[i]["desc"],
				"cost": offline_duration_defs[i]["cost"],
				"purchased": offline_duration_purchased[i],
			})
	return result

func can_afford_offline_duration_upgrade(index: int) -> bool:
	return total_lobsters >= offline_duration_defs[index]["cost"]

func buy_offline_duration_upgrade(index: int) -> bool:
	if offline_duration_purchased[index]:
		return false
	var cost: float = offline_duration_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	offline_duration_purchased[index] = true
	lobsters_changed.emit(total_lobsters)
	return true

func get_offline_rate() -> float:
	# Return highest unlocked rate, or base 5%
	var rate := 0.05
	for i in range(offline_rate_purchased.size()):
		if offline_rate_purchased[i]:
			rate = offline_rate_defs[i]["rate"]
	return rate

func get_available_offline_rate_upgrades() -> Array:
	var result: Array = []
	for i in range(offline_rate_defs.size()):
		if lifetime_lobsters >= offline_rate_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": offline_rate_defs[i]["name"],
				"desc": offline_rate_defs[i]["desc"],
				"cost": offline_rate_defs[i]["cost"],
				"purchased": offline_rate_purchased[i],
			})
	return result

func can_afford_offline_rate_upgrade(index: int) -> bool:
	return total_lobsters >= offline_rate_defs[index]["cost"]

func buy_offline_rate_upgrade(index: int) -> bool:
	if offline_rate_purchased[index]:
		return false
	var cost: float = offline_rate_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	offline_rate_purchased[index] = true
	lobsters_changed.emit(total_lobsters)
	return true

# Gacha boost system
const GACHA_BOOSTS := [
	# Common (50% total)
	{"name": "Tiny Tide", "desc": "2x building production", "type": "building_mult", "mult": 2.0, "duration": 30.0, "rarity": "common", "weight": 25},
	{"name": "Quick Pinch", "desc": "3x clicking power", "type": "click_mult", "mult": 3.0, "duration": 20.0, "rarity": "common", "weight": 25},
	# Uncommon (30% total)
	{"name": "Rising Tide", "desc": "5x building production", "type": "building_mult", "mult": 5.0, "duration": 30.0, "rarity": "uncommon", "weight": 15},
	{"name": "Power Pinch", "desc": "10x clicking power", "type": "click_mult", "mult": 10.0, "duration": 15.0, "rarity": "uncommon", "weight": 15},
	# Rare (15% total)
	{"name": "Tidal Wave", "desc": "10x building production", "type": "building_mult", "mult": 10.0, "duration": 20.0, "rarity": "rare", "weight": 8},
	{"name": "Mega Pinch", "desc": "50x clicking power", "type": "click_mult", "mult": 50.0, "duration": 10.0, "rarity": "rare", "weight": 7},
	# Legendary (5% total)
	{"name": "TSUNAMI", "desc": "25x building production", "type": "building_mult", "mult": 25.0, "duration": 15.0, "rarity": "legendary", "weight": 2},
	{"name": "LOBSTER FRENZY", "desc": "100x clicking power", "type": "click_mult", "mult": 100.0, "duration": 10.0, "rarity": "legendary", "weight": 3},
]

const RARITY_COLORS := {
	"common": "#aaaaaa",
	"uncommon": "#3498db",
	"rare": "#9b59b6",
	"legendary": "#f39c12",
}

var active_boost: Dictionary = {}
var boost_time_remaining: float = 0.0

# CPS-to-click upgrades: add a percentage of LPS to each click
var cps_click_upgrade_defs: Array = [
	{"threshold": 50000, "cost": 25000, "percent": 1, "name": "Reinforced Grip", "desc": "+1% of LPS added per click. (50,000 lifetime lobsters)"},
	{"threshold": 250000, "cost": 125000, "percent": 2, "name": "Vice Grip", "desc": "+2% of LPS added per click. (250,000 lifetime lobsters)"},
	{"threshold": 2000000, "cost": 1000000, "percent": 5, "name": "Hydraulic Crusher", "desc": "+5% of LPS added per click. (2,000,000 lifetime lobsters)"},
]
var cps_click_upgrades_purchased: Array[bool] = [false, false, false]

# Hold-to-click: unlocks continuous clicking while holding, with speed upgrades
# Base rate = 3 clicks/sec, each speed upgrade increases it
var hold_click_defs: Array = [
	{"threshold": 5000, "cost": 2500, "name": "Steady Grip", "desc": "Hold to auto-click! (3 clicks/sec). 5,000 lifetime lobsters.", "cps": 3.0},
	{"threshold": 25000, "cost": 12000, "name": "Rapid Grip", "desc": "Hold auto-click speed: 6/sec. 25,000 lifetime lobsters.", "cps": 6.0},
	{"threshold": 150000, "cost": 75000, "name": "Turbo Grip", "desc": "Hold auto-click speed: 10/sec. 150,000 lifetime lobsters.", "cps": 10.0},
	{"threshold": 750000, "cost": 400000, "name": "Machine Grip", "desc": "Hold auto-click speed: 16/sec. 750,000 lifetime lobsters.", "cps": 16.0},
]
var hold_click_purchased: Array[bool] = [false, false, false, false]

func is_hold_click_unlocked() -> bool:
	return hold_click_purchased[0]

func get_hold_click_rate() -> float:
	# Return the highest unlocked rate
	var rate := 0.0
	for i in range(hold_click_defs.size()):
		if hold_click_purchased[i]:
			rate = hold_click_defs[i]["cps"]
	return rate

func get_available_hold_click_upgrades() -> Array:
	var result: Array = []
	for i in range(hold_click_defs.size()):
		if lifetime_lobsters >= hold_click_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": hold_click_defs[i]["name"],
				"desc": hold_click_defs[i]["desc"],
				"cost": hold_click_defs[i]["cost"],
				"purchased": hold_click_purchased[i],
			})
	return result

func can_afford_hold_click_upgrade(index: int) -> bool:
	return total_lobsters >= hold_click_defs[index]["cost"]

func buy_hold_click_upgrade(index: int) -> bool:
	if hold_click_purchased[index]:
		return false
	var cost: float = hold_click_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	hold_click_purchased[index] = true
	lobsters_changed.emit(total_lobsters)
	return true

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
				mult *= TIER_MULTIPLIERS[tier]
	return mult

func get_click_value() -> float:
	var base := lobsters_per_click
	var cps_bonus_percent := 0.0
	for i in range(cps_click_upgrades_purchased.size()):
		if cps_click_upgrades_purchased[i]:
			cps_bonus_percent += cps_click_upgrade_defs[i]["percent"]
	if cps_bonus_percent > 0 and lobsters_per_second > 0:
		base += lobsters_per_second * (cps_bonus_percent / 100.0)
	base *= get_gacha_boost_multiplier("click_mult")
	return base

func click() -> float:
	var value := get_click_value()
	total_lobsters += value
	lifetime_lobsters += value
	lobsters_changed.emit(total_lobsters)
	return value

func _process(delta: float) -> void:
	# Tick gacha cooldown
	if gacha_cooldown_remaining > 0:
		gacha_cooldown_remaining -= delta
		if gacha_cooldown_remaining < 0:
			gacha_cooldown_remaining = 0.0

	# Tick boost timer
	if boost_time_remaining > 0:
		boost_time_remaining -= delta
		if boost_time_remaining <= 0:
			boost_time_remaining = 0.0
			active_boost = {}
			boost_expired.emit()

	if lobsters_per_second > 0:
		var earned := lobsters_per_second * get_gacha_boost_multiplier("building_mult") * delta
		total_lobsters += earned
		lifetime_lobsters += earned
		lobsters_changed.emit(total_lobsters)

func _recalculate_click_power() -> void:
	lobsters_per_click = 1.0
	for i in range(click_upgrades_purchased.size()):
		if click_upgrades_purchased[i]:
			lobsters_per_click *= click_upgrade_defs[i]["multiplier"]

# --- Click Upgrades ---

func get_available_click_upgrades() -> Array:
	var result: Array = []
	for i in range(click_upgrade_defs.size()):
		if lifetime_lobsters >= click_upgrade_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": click_upgrade_defs[i]["name"],
				"desc": click_upgrade_defs[i]["desc"],
				"cost": click_upgrade_defs[i]["cost"],
				"purchased": click_upgrades_purchased[i],
			})
	return result

func can_afford_click_upgrade(index: int) -> bool:
	return total_lobsters >= click_upgrade_defs[index]["cost"]

func buy_click_upgrade(index: int) -> bool:
	if click_upgrades_purchased[index]:
		return false
	var cost: float = click_upgrade_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	click_upgrades_purchased[index] = true
	_recalculate_click_power()
	lobsters_changed.emit(total_lobsters)
	return true

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
					"desc": "%dx %s production. (Requires %d %ss)" % [TIER_MULTIPLIERS[tier], building_defs[bi]["name"], UPGRADE_THRESHOLDS[tier], building_defs[bi]["name"]],
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

func get_available_cps_click_upgrades() -> Array:
	var result: Array = []
	for i in range(cps_click_upgrade_defs.size()):
		if lifetime_lobsters >= cps_click_upgrade_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": cps_click_upgrade_defs[i]["name"],
				"desc": cps_click_upgrade_defs[i]["desc"],
				"cost": cps_click_upgrade_defs[i]["cost"],
				"purchased": cps_click_upgrades_purchased[i],
			})
	return result

func can_afford_cps_click_upgrade(index: int) -> bool:
	return total_lobsters >= cps_click_upgrade_defs[index]["cost"]

func buy_cps_click_upgrade(index: int) -> bool:
	if cps_click_upgrades_purchased[index]:
		return false
	var cost: float = cps_click_upgrade_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	cps_click_upgrades_purchased[index] = true
	lobsters_changed.emit(total_lobsters)
	return true

# --- Gacha Boost System ---

var gacha_cooldown_remaining: float = 0.0
const GACHA_BASE_COOLDOWN := 60.0

# Gacha cooldown reduction upgrades
var gacha_cooldown_upgrade_defs: Array = [
	{"threshold": 10000, "cost": 5000, "reduction": 10, "name": "Quick Draw", "desc": "Gacha cooldown -10s. (10,000 lifetime lobsters)"},
	{"threshold": 100000, "cost": 50000, "reduction": 10, "name": "Faster Crank", "desc": "Gacha cooldown -10s. (100,000 lifetime lobsters)"},
	{"threshold": 500000, "cost": 250000, "reduction": 10, "name": "Turbo Capsule", "desc": "Gacha cooldown -10s. (500,000 lifetime lobsters)"},
]
var gacha_cooldown_upgrades_purchased: Array[bool] = [false, false, false]

func get_gacha_cooldown() -> float:
	var cd := GACHA_BASE_COOLDOWN
	for i in range(gacha_cooldown_upgrades_purchased.size()):
		if gacha_cooldown_upgrades_purchased[i]:
			cd -= gacha_cooldown_upgrade_defs[i]["reduction"]
	return cd

func get_available_gacha_cooldown_upgrades() -> Array:
	var result: Array = []
	for i in range(gacha_cooldown_upgrade_defs.size()):
		if lifetime_lobsters >= gacha_cooldown_upgrade_defs[i]["threshold"]:
			result.append({
				"index": i,
				"name": gacha_cooldown_upgrade_defs[i]["name"],
				"desc": gacha_cooldown_upgrade_defs[i]["desc"],
				"cost": gacha_cooldown_upgrade_defs[i]["cost"],
				"purchased": gacha_cooldown_upgrades_purchased[i],
			})
	return result

func can_afford_gacha_cooldown_upgrade(index: int) -> bool:
	return total_lobsters >= gacha_cooldown_upgrade_defs[index]["cost"]

func buy_gacha_cooldown_upgrade(index: int) -> bool:
	if gacha_cooldown_upgrades_purchased[index]:
		return false
	var cost: float = gacha_cooldown_upgrade_defs[index]["cost"]
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	gacha_cooldown_upgrades_purchased[index] = true
	lobsters_changed.emit(total_lobsters)
	return true

func get_gacha_cost() -> float:
	return maxf(5000.0, floor(lobsters_per_second * 30.0))

func is_gacha_on_cooldown() -> bool:
	return gacha_cooldown_remaining > 0.0 or boost_time_remaining > 0.0

func get_gacha_wait_time() -> float:
	return maxf(gacha_cooldown_remaining, boost_time_remaining)

func get_gacha_boost_multiplier(type: String) -> float:
	if not active_boost.is_empty() and boost_time_remaining > 0 and active_boost["type"] == type:
		return active_boost["mult"]
	return 1.0

func roll_gacha() -> Dictionary:
	if gacha_cooldown_remaining > 0 or boost_time_remaining > 0:
		return {}
	var cost := get_gacha_cost()
	if total_lobsters < cost:
		return {}
	total_lobsters -= cost
	# Weighted random selection
	var total_weight := 0
	for b in GACHA_BOOSTS:
		total_weight += b["weight"]
	var roll := randi() % total_weight
	var cumulative := 0
	for b in GACHA_BOOSTS:
		cumulative += b["weight"]
		if roll < cumulative:
			active_boost = b.duplicate()
			boost_time_remaining = b["duration"]
			gacha_cooldown_remaining = get_gacha_cooldown()
			boost_activated.emit(active_boost)
			lobsters_changed.emit(total_lobsters)
			return active_boost
	# Fallback
	active_boost = GACHA_BOOSTS[0].duplicate()
	boost_time_remaining = GACHA_BOOSTS[0]["duration"]
	boost_activated.emit(active_boost)
	lobsters_changed.emit(total_lobsters)
	return active_boost

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
	var click_data: Array = []
	for i in range(click_upgrades_purchased.size()):
		click_data.append(click_upgrades_purchased[i])
	var cps_click_data: Array = []
	for i in range(cps_click_upgrades_purchased.size()):
		cps_click_data.append(cps_click_upgrades_purchased[i])
	return {
		"total_lobsters": total_lobsters,
		"lifetime_lobsters": lifetime_lobsters,
		"building_counts": building_counts,
		"building_upgrades": upgrades_data,
		"click_upgrades": click_data,
		"cps_click_upgrades": cps_click_data,
		"hold_click_upgrades": Array(hold_click_purchased),
		"gacha_cooldown_upgrades": Array(gacha_cooldown_upgrades_purchased),
		"offline_rate_upgrades": Array(offline_rate_purchased),
		"offline_duration_upgrades": Array(offline_duration_purchased),
		"farm_name": farm_name,
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
	# Load click upgrades
	lifetime_lobsters = data.get("lifetime_lobsters", total_lobsters)
	var click_data = data.get("click_upgrades", [])
	for i in range(mini(click_data.size(), click_upgrades_purchased.size())):
		click_upgrades_purchased[i] = click_data[i]
	var cps_click_data = data.get("cps_click_upgrades", [])
	for i in range(mini(cps_click_data.size(), cps_click_upgrades_purchased.size())):
		cps_click_upgrades_purchased[i] = cps_click_data[i]
	var hold_data = data.get("hold_click_upgrades", [])
	for i in range(mini(hold_data.size(), hold_click_purchased.size())):
		hold_click_purchased[i] = hold_data[i]
	var gacha_cd_data = data.get("gacha_cooldown_upgrades", [])
	for i in range(mini(gacha_cd_data.size(), gacha_cooldown_upgrades_purchased.size())):
		gacha_cooldown_upgrades_purchased[i] = gacha_cd_data[i]
	var offline_data = data.get("offline_rate_upgrades", [])
	for i in range(mini(offline_data.size(), offline_rate_purchased.size())):
		offline_rate_purchased[i] = offline_data[i]
	var offline_dur_data = data.get("offline_duration_upgrades", [])
	for i in range(mini(offline_dur_data.size(), offline_duration_purchased.size())):
		offline_duration_purchased[i] = offline_dur_data[i]
	farm_name = data.get("farm_name", "My Lobster Farm")
	_recalculate_lps()
	_recalculate_click_power()
	lobsters_changed.emit(total_lobsters)
	last_save_time = data.get("last_save_time", 0)
