extends Node

signal lobsters_changed(total: float)
signal lps_changed(lps: float)
signal building_purchased(index: int)
signal upgrade_unlocked(building_index: int, tier: int)
signal boost_activated(boost: Dictionary)
signal boost_expired()
signal premium_options_ready(options: Array)
signal premium_boost_activated(boost: Dictionary)
signal transaction_completed()
signal achievement_unlocked(id: String, title: String, desc: String)
signal objective_changed(text: String)
signal rare_event_triggered(event: Dictionary)
signal purchase_mode_changed(mode: int)
signal molt_completed(shells_gained: int, total_shells: int)

const SAVE_VERSION := 3
const MOLTING_THRESHOLD := 10000000000.0
const SHELL_BONUS_PER_SHELL := 0.10
const MOLTING_BUILDING_INDEX := 8

var total_lobsters: float = 0.0
var lobsters_per_click: float = 1.0
var farm_name: String = "My Lobster Farm"
var lobsters_per_second: float = 0.0
var last_save_time: int = 0
var music_muted: bool = false
var music_volume: float = 0.60
var sfx_volume: float = 0.80
var reduced_motion: bool = false

var achievements: Dictionary = {}
var first_rare_event_seen: bool = false
var pending_premium_options: Array = []
var pending_premium_cost: float = 0.0
var _last_objective: String = ""
var _passive_ui_timer: float = 0.0
var building_purchase_mode: int = 1  # 1, 10, or -1 for max affordable

# Building definitions (formerly "upgrades")
var building_defs: Array = [
	{"name": "Coin Collecting", "base_cost": 15, "lps": 0.1, "desc": "Every entrepreneur starts somewhere!"},
	{"name": "Lobster Memes", "base_cost": 100, "lps": 1.0, "desc": "Only Gigachads and Galaxy Brains understand."},
	{"name": "Fishcord Server", "base_cost": 1100, "lps": 8.0, "desc": "Data breaches now tri-monthly."},
	{"name": "Seafood Restaurant", "base_cost": 12000, "lps": 47.0, "desc": "\"What? I was hungry!\""},
	{"name": "Lobster Anime", "base_cost": 130000, "lps": 260.0, "desc": "wHatS ThE SaUcE?!?"},
	{"name": "Bitclaw", "base_cost": 1400000, "lps": 1400.0, "desc": "Like money, but useless."},
	{"name": "Clamazon", "base_cost": 20000000, "lps": 7800.0, "desc": "One-day delivery from Pacific to Atlantic."},
	{"name": "Lobster AI", "base_cost": 330000000, "lps": 44000.0, "desc": "LLM = Lots of Lobster Money!"},
	{"name": "Immortality", "base_cost": 5100000000, "lps": 260000.0, "desc": "Because who can afford healthcare?"},
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
	{"threshold": 500, "cost": 500, "multiplier": 2, "name": "Iron Claws", "desc": "2x LC per click. (500 lifetime LC)"},
	{"threshold": 5000, "cost": 5000, "multiplier": 5, "name": "Steel Claws", "desc": "5x LC per click. (5,000 lifetime LC)"},
	{"threshold": 250000, "cost": 250000, "multiplier": 10, "name": "Diamond Claws", "desc": "10x LC per click. (250,000 lifetime LC)"},
]
var click_upgrades_purchased: Array[bool] = [false, false, false]
var lifetime_lobsters: float = 0.0  # Total lobsters ever generated (never decreases)
var run_lobsters: float = 0.0  # Lobsters generated since the last molt
var shells: int = 0
var molt_count: int = 0

# Offline production rate upgrades (base 5%)
var offline_rate_defs: Array = [
	{"threshold": 25000, "cost": 15000, "rate": 0.10, "name": "Lobster Lookout", "desc": "Offline production: 10%. (25,000 lifetime LC)"},
	{"threshold": 500000, "cost": 300000, "rate": 0.225, "name": "Night Shift", "desc": "Offline production: 22.5%. (500,000 lifetime LC)"},
	{"threshold": 5000000, "cost": 3000000, "rate": 0.50, "name": "Automated Traps", "desc": "Offline production: 50%. (5,000,000 lifetime LC)"},
	{"threshold": 50000000, "cost": 30000000, "rate": 0.85, "name": "Deep Sea Drones", "desc": "Offline production: 85%. (50,000,000 lifetime LC)"},
]
var offline_rate_purchased: Array[bool] = [false, false, false, false]

# Offline duration cap upgrades (base 1 hour)
var offline_duration_defs: Array = [
	{"threshold": 50000, "cost": 30000, "hours": 3, "name": "Extended Nets", "desc": "Offline cap: 3 hours. (50,000 lifetime LC)"},
	{"threshold": 1000000, "cost": 600000, "hours": 8, "name": "Overnight Crew", "desc": "Offline cap: 8 hours. (1,000,000 lifetime LC)"},
	{"threshold": 10000000, "cost": 6000000, "hours": 16, "name": "Double Shift", "desc": "Offline cap: 16 hours. (10,000,000 lifetime LC)"},
	{"threshold": 100000000, "cost": 60000000, "hours": 24, "name": "24/7 Operations", "desc": "Offline cap: 24 hours. (100,000,000 lifetime LC)"},
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
	transaction_completed.emit()
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
	transaction_completed.emit()
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

const PREMIUM_BOOSTS := [
	# All gacha boosts
	{"name": "Tiny Tide", "desc": "2x building production", "type": "building_mult", "mult": 2.0, "duration": 30.0, "rarity": "common", "weight": 25},
	{"name": "Quick Pinch", "desc": "3x clicking power", "type": "click_mult", "mult": 3.0, "duration": 20.0, "rarity": "common", "weight": 25},
	{"name": "Rising Tide", "desc": "5x building production", "type": "building_mult", "mult": 5.0, "duration": 30.0, "rarity": "uncommon", "weight": 15},
	{"name": "Power Pinch", "desc": "10x clicking power", "type": "click_mult", "mult": 10.0, "duration": 15.0, "rarity": "uncommon", "weight": 15},
	{"name": "Tidal Wave", "desc": "10x building production", "type": "building_mult", "mult": 10.0, "duration": 20.0, "rarity": "rare", "weight": 8},
	{"name": "Mega Pinch", "desc": "50x clicking power", "type": "click_mult", "mult": 50.0, "duration": 10.0, "rarity": "rare", "weight": 7},
	{"name": "TSUNAMI", "desc": "25x building production", "type": "building_mult", "mult": 25.0, "duration": 15.0, "rarity": "legendary", "weight": 2},
	{"name": "LOBSTER FRENZY", "desc": "100x clicking power", "type": "click_mult", "mult": 100.0, "duration": 10.0, "rarity": "legendary", "weight": 3},
	# Permanent flat LCPS
	{"name": "Tidal Income I", "desc": "+10 LCPS permanently", "type": "flat_lcps", "amount": 10.0, "rarity": "uncommon", "weight": 12},
	{"name": "Tidal Income II", "desc": "+100 LCPS permanently", "type": "flat_lcps", "amount": 100.0, "rarity": "rare", "weight": 6},
	{"name": "Tidal Income III", "desc": "+250 LCPS permanently", "type": "flat_lcps", "amount": 250.0, "rarity": "legendary", "weight": 2},
	# Free buildings
	{"name": "Free Coin Collecting", "desc": "Adds 1 Coin Collecting for free!", "type": "free_building", "building_index": 0, "rarity": "common", "weight": 15},
	{"name": "Free Lobster Memes", "desc": "Adds 1 Lobster Memes for free!", "type": "free_building", "building_index": 1, "rarity": "uncommon", "weight": 10},
	{"name": "Free Fishcord Server", "desc": "Adds 1 Fishcord Server for free!", "type": "free_building", "building_index": 2, "rarity": "rare", "weight": 5},
	# Single random building boost
	{"name": "Focused Training", "desc": "2x production for a random building", "type": "single_building_boost", "mult": 2.0, "duration": 45.0, "rarity": "common", "weight": 20},
	{"name": "Specialized Boost", "desc": "5x production for a random building", "type": "single_building_boost", "mult": 5.0, "duration": 30.0, "rarity": "uncommon", "weight": 12},
	{"name": "Expert Training", "desc": "15x production for a random building", "type": "single_building_boost", "mult": 15.0, "duration": 20.0, "rarity": "rare", "weight": 6},
	{"name": "MEGA FOCUS", "desc": "50x production for a random building", "type": "single_building_boost", "mult": 50.0, "duration": 15.0, "rarity": "legendary", "weight": 2},
]

const RARITY_COLORS := {
	"common": "#aaaaaa",
	"uncommon": "#3498db",
	"rare": "#9b59b6",
	"legendary": "#f39c12",
}

var active_boost: Dictionary = {}
var boost_time_remaining: float = 0.0
var _boost_end_time: float = 0.0  # Unix timestamp when boost expires

# Premium boost state
var premium_boost_cost_multiplier := 3.0
var flat_lcps_bonus: float = 0.0
var single_building_boost_index: int = -1
var single_building_boost_mult: float = 1.0
var single_building_boost_time: float = 0.0
var _single_boost_end_time: float = 0.0

var _cooldown_end_time: float = 0.0  # Unix timestamp when cooldown expires

# CPS-to-click upgrades: add a percentage of LPS to each click
var cps_click_upgrade_defs: Array = [
	{"threshold": 50000, "cost": 25000, "percent": 1, "name": "Reinforced Grip", "desc": "+1% of LCPS added per click. (50,000 lifetime LC)"},
	{"threshold": 250000, "cost": 125000, "percent": 2, "name": "Vice Grip", "desc": "+2% of LCPS added per click. (250,000 lifetime LC)"},
	{"threshold": 2000000, "cost": 1000000, "percent": 5, "name": "Hydraulic Crusher", "desc": "+5% of LCPS added per click. (2,000,000 lifetime LC)"},
]
var cps_click_upgrades_purchased: Array[bool] = [false, false, false]

# Hold-to-click: unlocks continuous clicking while holding, with speed upgrades
# Base rate = 3 clicks/sec, each speed upgrade increases it
var hold_click_defs: Array = [
	{"threshold": 5000, "cost": 2500, "name": "Steady Grip", "desc": "Hold to auto-click! (3 clicks/sec). 5,000 lifetime LC.", "cps": 3.0},
	{"threshold": 25000, "cost": 12000, "name": "Rapid Grip", "desc": "Hold auto-click speed: 6/sec. 25,000 lifetime LC.", "cps": 6.0},
	{"threshold": 150000, "cost": 75000, "name": "Turbo Grip", "desc": "Hold auto-click speed: 10/sec. 150,000 lifetime LC.", "cps": 10.0},
	{"threshold": 750000, "cost": 400000, "name": "Machine Grip", "desc": "Hold auto-click speed: 16/sec. 750,000 lifetime LC.", "cps": 16.0},
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
	transaction_completed.emit()
	return true

func _ready() -> void:
	building_counts.resize(building_defs.size())
	building_counts.fill(0)
	_init_building_upgrades()
	_emit_objective()

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

func get_shell_multiplier() -> float:
	return 1.0 + float(shells) * SHELL_BONUS_PER_SHELL

func get_click_value() -> float:
	var base := lobsters_per_click
	var cps_bonus_percent := 0.0
	for i in range(cps_click_upgrades_purchased.size()):
		if cps_click_upgrades_purchased[i]:
			cps_bonus_percent += cps_click_upgrade_defs[i]["percent"]
	if cps_bonus_percent > 0 and lobsters_per_second > 0:
		# LCPS already includes the Shell bonus; divide it out before applying
		# the Shell multiplier to the completed click value below.
		base += (lobsters_per_second / get_shell_multiplier()) * (cps_bonus_percent / 100.0)
	base *= get_gacha_boost_multiplier("click_mult")
	base *= get_shell_multiplier()
	return base

func _unlock_achievement(id: String, title: String, desc: String) -> bool:
	if achievements.get(id, false):
		return false
	achievements[id] = true
	achievement_unlocked.emit(id, title, desc)
	transaction_completed.emit()
	return true

func unlock_offline_achievement() -> void:
	_unlock_achievement("night_shift", "Night Shift", "Your crew kept working while you were away.")

func get_current_objective() -> String:
	if not achievements.get("first_catch", false):
		return "Tap the claw and catch your first Lobster Coin."
	if not achievements.get("tiny_fleet", false):
		return "Catch 15 LC and buy Coin Collecting."
	if building_counts[0] < 10:
		return "Build a fleet: buy 10 Coin Collecting (%d/10)." % building_counts[0]
	if not building_upgrades[0][0]:
		return "Upgrade ready: make Coin Collecting 2x stronger."
	if not first_rare_event_seen:
		return "Keep pinching. Something strange is stirring..."
	if get_pending_shells() > 0 and building_counts[MOLTING_BUILDING_INDEX] < 1:
		return "Molting energy reached. Build Immortality to complete the run."
	if can_molt():
		return "Molting ready: shed the old farm and return permanently stronger."
	return "Earn %s LC this run to unlock Molting." % format_number(MOLTING_THRESHOLD)

func _emit_objective() -> void:
	var objective := get_current_objective()
	if objective == _last_objective:
		return
	_last_objective = objective
	objective_changed.emit(objective)

func _get_cheapest_building_cost() -> float:
	var cheapest := INF
	for i in range(building_defs.size()):
		cheapest = minf(cheapest, get_building_cost(i))
	return cheapest

func _trigger_disco_lobster() -> void:
	if first_rare_event_seen:
		return
	first_rare_event_seen = true
	var next_cost := _get_cheapest_building_cost()
	var bonus := maxf(25.0, next_cost - total_lobsters)
	total_lobsters += bonus
	lifetime_lobsters += bonus
	run_lobsters += bonus
	active_boost = {
		"name": "Disco Lobster",
		"desc": "3x clicking power",
		"type": "click_mult",
		"mult": 3.0,
		"duration": 20.0,
		"rarity": "rare",
		"weight": 0,
	}
	_set_boost_timer(20.0)
	boost_activated.emit(active_boost)
	_unlock_achievement("disco_lobster", "Disco Lobster Found!", "The beat boosts your claw and funds the next purchase.")
	rare_event_triggered.emit({"id": "disco_lobster", "bonus": bonus, "duration": 20.0})
	lobsters_changed.emit(total_lobsters)
	_emit_objective()

func _check_first_session_milestones() -> void:
	if lifetime_lobsters > 0:
		_unlock_achievement("first_catch", "First Catch", "The lobster empire begins.")
	if not first_rare_event_seen and lifetime_lobsters >= 100.0:
		_trigger_disco_lobster()
	_emit_objective()

func click() -> float:
	var value := get_click_value()
	total_lobsters += value
	lifetime_lobsters += value
	run_lobsters += value
	lobsters_changed.emit(total_lobsters)
	_check_first_session_milestones()
	return value

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()

	# Update cooldown from timestamp
	if _cooldown_end_time > 0:
		gacha_cooldown_remaining = maxf(0.0, _cooldown_end_time - now)
		if gacha_cooldown_remaining <= 0:
			_cooldown_end_time = 0.0

	# Update boost timer from timestamp
	if _boost_end_time > 0:
		var remaining := _boost_end_time - now
		if remaining <= 0:
			boost_time_remaining = 0.0
			_boost_end_time = 0.0
			active_boost = {}
			boost_expired.emit()
		else:
			boost_time_remaining = maxf(0.0, remaining)

	# Update single building boost from timestamp
	if _single_boost_end_time > 0:
		var remaining := _single_boost_end_time - now
		if remaining <= 0:
			single_building_boost_time = 0.0
			_single_boost_end_time = 0.0
			single_building_boost_index = -1
			single_building_boost_mult = 1.0
			boost_expired.emit()
		else:
			single_building_boost_time = maxf(0.0, remaining)

	if lobsters_per_second > 0:
		var base_production := lobsters_per_second * get_gacha_boost_multiplier("building_mult") * delta
		# Add single building boost bonus
		if single_building_boost_time > 0 and single_building_boost_index >= 0:
			var boosted_building_lps: float = building_counts[single_building_boost_index] * float(building_defs[single_building_boost_index]["lps"]) * get_building_multiplier(single_building_boost_index) * get_shell_multiplier()
			var bonus: float = boosted_building_lps * (single_building_boost_mult - 1.0)
			base_production += bonus * get_gacha_boost_multiplier("building_mult") * delta
		total_lobsters += base_production
		lifetime_lobsters += base_production
		run_lobsters += base_production
		_passive_ui_timer += delta
		if _passive_ui_timer >= 0.1:
			_passive_ui_timer = 0.0
			lobsters_changed.emit(total_lobsters)
			_check_first_session_milestones()

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
	transaction_completed.emit()
	return true

func get_building_cost(index: int) -> float:
	var base: float = building_defs[index]["base_cost"]
	var count: int = building_counts[index]
	return floor(base * pow(COST_MULTIPLIER, count))

func set_building_purchase_mode(mode: int) -> void:
	if mode not in [1, 10, -1]:
		return
	building_purchase_mode = mode
	purchase_mode_changed.emit(mode)

func get_bulk_building_cost(index: int, amount: int) -> float:
	var total := 0.0
	var base: float = building_defs[index]["base_cost"]
	var start_count: int = building_counts[index]
	for offset in range(amount):
		total += floor(base * pow(COST_MULTIPLIER, start_count + offset))
	return total

func get_max_affordable_buildings(index: int) -> int:
	var remaining := total_lobsters
	var amount := 0
	var base: float = building_defs[index]["base_cost"]
	var start_count: int = building_counts[index]
	while amount < 10000:
		var cost: float = floor(base * pow(COST_MULTIPLIER, start_count + amount))
		if remaining < cost:
			break
		remaining -= cost
		amount += 1
	return amount

func get_selected_building_amount(index: int) -> int:
	if building_purchase_mode == -1:
		return get_max_affordable_buildings(index)
	return building_purchase_mode

func get_selected_building_cost(index: int) -> float:
	var amount := get_selected_building_amount(index)
	if amount <= 0:
		return get_building_cost(index)
	return get_bulk_building_cost(index, amount)

func can_afford_building(index: int) -> bool:
	var amount := get_selected_building_amount(index)
	return amount > 0 and total_lobsters >= get_bulk_building_cost(index, amount)

func buy_building(index: int) -> bool:
	var amount := get_selected_building_amount(index)
	if amount <= 0:
		return false
	var cost := get_bulk_building_cost(index, amount)
	if total_lobsters < cost:
		return false
	total_lobsters -= cost
	var old_count := building_counts[index]
	building_counts[index] += amount
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	building_purchased.emit(index)
	_unlock_achievement("tiny_fleet", "Tiny Fleet", "Your first automated collector is on deck.")
	if building_counts[index] >= 10:
		_unlock_achievement("ten_on_deck", "Ten on Deck", "Ten %s are working the waters." % building_defs[index]["name"])
	# Check if a new upgrade threshold was crossed
	for tier in range(UPGRADE_THRESHOLDS.size()):
		if old_count < UPGRADE_THRESHOLDS[tier] and building_counts[index] >= UPGRADE_THRESHOLDS[tier]:
			upgrade_unlocked.emit(index, tier)
	transaction_completed.emit()
	_emit_objective()
	return true

func _recalculate_lps() -> void:
	lobsters_per_second = 0.0
	for i in range(building_defs.size()):
		lobsters_per_second += building_counts[i] * building_defs[i]["lps"] * get_building_multiplier(i)
	lobsters_per_second += flat_lcps_bonus
	lobsters_per_second *= get_shell_multiplier()
	lps_changed.emit(lobsters_per_second)

# --- Molting / Prestige ---

func get_pending_shells() -> int:
	if run_lobsters < MOLTING_THRESHOLD:
		return 0
	return maxi(1, int(floor(sqrt(run_lobsters / MOLTING_THRESHOLD))))

func can_molt() -> bool:
	return get_pending_shells() > 0 and building_counts[MOLTING_BUILDING_INDEX] > 0 and pending_premium_options.is_empty()

func get_next_shell_target() -> float:
	var next_shell_count := get_pending_shells() + 1
	return MOLTING_THRESHOLD * float(next_shell_count * next_shell_count)

func molt() -> int:
	if not can_molt():
		return 0
	var gained := get_pending_shells()
	shells += gained
	molt_count += 1

	# Reset run progression. Permanent card income, identity, settings,
	# achievements, global lifetime LC, and Shells survive.
	total_lobsters = 0.0
	run_lobsters = 0.0
	lobsters_per_click = 1.0
	building_counts.fill(0)
	click_upgrades_purchased.fill(false)
	cps_click_upgrades_purchased.fill(false)
	hold_click_purchased.fill(false)
	gacha_cooldown_upgrades_purchased.fill(false)
	offline_rate_purchased.fill(false)
	offline_duration_purchased.fill(false)
	active_boost = {}
	boost_time_remaining = 0.0
	_boost_end_time = 0.0
	gacha_cooldown_remaining = 0.0
	_cooldown_end_time = 0.0
	single_building_boost_index = -1
	single_building_boost_mult = 1.0
	single_building_boost_time = 0.0
	_single_boost_end_time = 0.0
	building_purchase_mode = 1
	_last_objective = ""
	_init_building_upgrades()
	_recalculate_click_power()
	_recalculate_lps()
	lobsters_changed.emit(total_lobsters)
	purchase_mode_changed.emit(building_purchase_mode)
	_unlock_achievement("first_molt", "Fresh Shell", "The farm begins again, stronger than before.")
	molt_completed.emit(gained, shells)
	transaction_completed.emit()
	_emit_objective()
	return gained

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
	transaction_completed.emit()
	_emit_objective()
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
	transaction_completed.emit()
	return true

# --- Gacha Boost System ---

var gacha_cooldown_remaining: float = 0.0
const GACHA_BASE_COOLDOWN := 60.0

# Gacha cooldown reduction upgrades
var gacha_cooldown_upgrade_defs: Array = [
	{"threshold": 10000, "cost": 5000, "reduction": 10, "name": "Quick Draw", "desc": "Boost cooldown -10s. (10,000 lifetime LC)"},
	{"threshold": 100000, "cost": 50000, "reduction": 10, "name": "Faster Crank", "desc": "Boost cooldown -10s. (100,000 lifetime LC)"},
	{"threshold": 500000, "cost": 250000, "reduction": 10, "name": "Turbo Capsule", "desc": "Boost cooldown -10s. (500,000 lifetime LC)"},
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
	transaction_completed.emit()
	return true

func _set_cooldown(duration: float) -> void:
	gacha_cooldown_remaining = duration
	_cooldown_end_time = Time.get_unix_time_from_system() + duration

func _set_boost_timer(duration: float) -> void:
	boost_time_remaining = duration
	_boost_end_time = Time.get_unix_time_from_system() + duration

func _set_single_boost_timer(duration: float) -> void:
	single_building_boost_time = duration
	_single_boost_end_time = Time.get_unix_time_from_system() + duration

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
			_set_boost_timer(b["duration"])
			_set_cooldown(get_gacha_cooldown())
			boost_activated.emit(active_boost)
			lobsters_changed.emit(total_lobsters)
			transaction_completed.emit()
			return active_boost
	# Fallback
	active_boost = GACHA_BOOSTS[0].duplicate()
	_set_boost_timer(GACHA_BOOSTS[0]["duration"])
	_set_cooldown(get_gacha_cooldown())
	boost_activated.emit(active_boost)
	lobsters_changed.emit(total_lobsters)
	transaction_completed.emit()
	return active_boost

# --- Premium Boost System ---

func get_premium_cost() -> float:
	return get_gacha_cost() * premium_boost_cost_multiplier

func _get_eligible_premium_boosts() -> Array:
	var eligible: Array = []
	var owns_building := false
	for count in building_counts:
		if count > 0:
			owns_building = true
			break
	for boost in PREMIUM_BOOSTS:
		if boost["type"] == "single_building_boost" and not owns_building:
			continue
		eligible.append(boost)
	return eligible

func roll_premium_options() -> Array:
	var pool := _get_eligible_premium_boosts()
	var total_weight := 0
	for b in pool:
		total_weight += b["weight"]
	var options: Array = []
	var used_names: Array = []
	while options.size() < 3:
		var roll := randi() % total_weight
		var cumulative := 0
		for b in pool:
			cumulative += b["weight"]
			if roll < cumulative:
				if b["name"] not in used_names:
					options.append(b.duplicate())
					used_names.append(b["name"])
				break
	premium_options_ready.emit(options)
	return options

func start_premium_draw() -> Array:
	if not pending_premium_options.is_empty():
		return pending_premium_options.duplicate(true)
	if is_gacha_on_cooldown():
		return []
	var cost := get_premium_cost()
	if total_lobsters < cost:
		return []
	total_lobsters -= cost
	pending_premium_cost = cost
	pending_premium_options = roll_premium_options()
	if pending_premium_options.is_empty():
		total_lobsters += pending_premium_cost
		pending_premium_cost = 0.0
		return []
	lobsters_changed.emit(total_lobsters)
	transaction_completed.emit()
	return pending_premium_options.duplicate(true)

func activate_premium_boost(boost: Dictionary) -> bool:
	if pending_premium_options.is_empty():
		return false
	var is_pending_option := false
	for option in pending_premium_options:
		if option.get("name", "") == boost.get("name", ""):
			is_pending_option = true
			break
	if not is_pending_option:
		return false
	var btype: String = boost["type"]
	if btype == "building_mult" or btype == "click_mult":
		active_boost = boost.duplicate()
		_set_boost_timer(boost["duration"])
		_set_cooldown(get_gacha_cooldown())
		boost_activated.emit(active_boost)
	elif btype == "flat_lcps":
		flat_lcps_bonus += boost["amount"]
		_set_cooldown(get_gacha_cooldown())
		_recalculate_lps()
	elif btype == "free_building":
		var bi: int = boost["building_index"]
		var old_count := building_counts[bi]
		building_counts[bi] += 1
		_recalculate_lps()
		_set_cooldown(get_gacha_cooldown())
		building_purchased.emit(bi)
		for tier in range(UPGRADE_THRESHOLDS.size()):
			if old_count < UPGRADE_THRESHOLDS[tier] and building_counts[bi] >= UPGRADE_THRESHOLDS[tier]:
				upgrade_unlocked.emit(bi, tier)
	elif btype == "single_building_boost":
		# Pick a random owned building
		var owned: Array = []
		for i in range(building_counts.size()):
			if building_counts[i] > 0:
				owned.append(i)
		if owned.is_empty():
			return false
		single_building_boost_index = owned[randi() % owned.size()]
		single_building_boost_mult = boost["mult"]
		_set_single_boost_timer(boost["duration"])
		_set_cooldown(get_gacha_cooldown())
	else:
		return false
	pending_premium_options.clear()
	pending_premium_cost = 0.0
	premium_boost_activated.emit(boost)
	lobsters_changed.emit(total_lobsters)
	transaction_completed.emit()
	_emit_objective()
	return true

func format_number(n: float) -> String:
	var absolute := absf(n)
	if absolute >= 1000000000000000.0:
		return _format_compact(n / 1000000000000000.0, "Q")
	if absolute >= 1000000000000.0:
		return _format_compact(n / 1000000000000.0, "T")
	if absolute >= 1000000000.0:
		return _format_compact(n / 1000000000.0, "B")
	if absolute >= 1000000.0:
		return _format_compact(n / 1000000.0, "M")
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

func _format_compact(value: float, suffix: String) -> String:
	var formatted := "%.2f" % value
	formatted = formatted.trim_suffix("0").trim_suffix("0").trim_suffix(".")
	return formatted + suffix

func format_rate(n: float) -> String:
	if n == 0:
		return "0"
	if absf(n) < 1.0:
		return ("%.2f" % n).trim_suffix("0").trim_suffix(".")
	if absf(n) < 100.0 and not is_equal_approx(n, floor(n)):
		return ("%.1f" % n).trim_suffix("0").trim_suffix(".")
	return format_number(n)

func reset_progress() -> void:
	total_lobsters = 0.0
	lifetime_lobsters = 0.0
	run_lobsters = 0.0
	shells = 0
	molt_count = 0
	lobsters_per_click = 1.0
	lobsters_per_second = 0.0
	farm_name = "My Lobster Farm"
	building_counts.fill(0)
	click_upgrades_purchased.fill(false)
	cps_click_upgrades_purchased.fill(false)
	hold_click_purchased.fill(false)
	gacha_cooldown_upgrades_purchased.fill(false)
	offline_rate_purchased.fill(false)
	offline_duration_purchased.fill(false)
	flat_lcps_bonus = 0.0
	active_boost = {}
	boost_time_remaining = 0.0
	_boost_end_time = 0.0
	gacha_cooldown_remaining = 0.0
	_cooldown_end_time = 0.0
	single_building_boost_index = -1
	single_building_boost_mult = 1.0
	single_building_boost_time = 0.0
	_single_boost_end_time = 0.0
	pending_premium_options.clear()
	pending_premium_cost = 0.0
	achievements.clear()
	first_rare_event_seen = false
	_last_objective = ""
	_init_building_upgrades()
	_recalculate_lps()
	_recalculate_click_power()
	lobsters_changed.emit(total_lobsters)
	lps_changed.emit(lobsters_per_second)
	transaction_completed.emit()
	_emit_objective()

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
		"save_version": SAVE_VERSION,
		"total_lobsters": total_lobsters,
		"lifetime_lobsters": lifetime_lobsters,
		"run_lobsters": run_lobsters,
		"shells": shells,
		"molt_count": molt_count,
		"building_counts": building_counts,
		"building_upgrades": upgrades_data,
		"click_upgrades": click_data,
		"cps_click_upgrades": cps_click_data,
		"hold_click_upgrades": Array(hold_click_purchased),
		"gacha_cooldown_upgrades": Array(gacha_cooldown_upgrades_purchased),
		"offline_rate_upgrades": Array(offline_rate_purchased),
		"offline_duration_upgrades": Array(offline_duration_purchased),
		"farm_name": farm_name,
		"flat_lcps_bonus": flat_lcps_bonus,
		"music_muted": music_muted,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"reduced_motion": reduced_motion,
		"achievements": achievements.duplicate(true),
		"first_rare_event_seen": first_rare_event_seen,
		"pending_premium_options": pending_premium_options.duplicate(true),
		"pending_premium_cost": pending_premium_cost,
		"active_boost": active_boost.duplicate(true),
		"boost_end_time": _boost_end_time,
		"cooldown_end_time": _cooldown_end_time,
		"single_building_boost_index": single_building_boost_index,
		"single_building_boost_mult": single_building_boost_mult,
		"single_boost_end_time": _single_boost_end_time,
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
	run_lobsters = data.get("run_lobsters", lifetime_lobsters)
	shells = maxi(0, int(data.get("shells", 0)))
	molt_count = maxi(0, int(data.get("molt_count", 0)))
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
	farm_name = str(data.get("farm_name", "My Lobster Farm")).strip_edges().left(32)
	if farm_name.is_empty():
		farm_name = "My Lobster Farm"
	flat_lcps_bonus = data.get("flat_lcps_bonus", 0.0)
	music_muted = data.get("music_muted", false)
	music_volume = clampf(float(data.get("music_volume", 0.60)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", 0.80)), 0.0, 1.0)
	reduced_motion = bool(data.get("reduced_motion", false))
	achievements = data.get("achievements", {}).duplicate(true)
	first_rare_event_seen = data.get("first_rare_event_seen", false)
	pending_premium_options = data.get("pending_premium_options", []).duplicate(true)
	pending_premium_cost = data.get("pending_premium_cost", 0.0)
	active_boost = data.get("active_boost", {}).duplicate(true)
	_boost_end_time = data.get("boost_end_time", 0.0)
	_cooldown_end_time = data.get("cooldown_end_time", 0.0)
	single_building_boost_index = data.get("single_building_boost_index", -1)
	single_building_boost_mult = data.get("single_building_boost_mult", 1.0)
	_single_boost_end_time = data.get("single_boost_end_time", 0.0)
	var now := Time.get_unix_time_from_system()
	boost_time_remaining = maxf(0.0, _boost_end_time - now)
	gacha_cooldown_remaining = maxf(0.0, _cooldown_end_time - now)
	single_building_boost_time = maxf(0.0, _single_boost_end_time - now)
	if boost_time_remaining <= 0:
		active_boost = {}
		_boost_end_time = 0.0
	if single_building_boost_time <= 0:
		single_building_boost_index = -1
		single_building_boost_mult = 1.0
		_single_boost_end_time = 0.0
	_recalculate_lps()
	_recalculate_click_power()
	lobsters_changed.emit(total_lobsters)
	last_save_time = data.get("last_save_time", 0)
	_last_objective = ""
	_emit_objective()
