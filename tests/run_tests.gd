extends Node

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FAIL: %s" % message)

func _run() -> void:
	GameManager.reset_progress()
	_expect(GameManager.format_rate(0.1) == "0.1", "fractional LCPS remains visible")
	_expect(GameManager.format_number(1250000.0) == "1.25M", "large values use compact readable notation")

	GameManager.click()
	_expect(GameManager.achievements.get("first_catch", false), "first click unlocks First Catch")

	GameManager.total_lobsters = 99.0
	GameManager.lifetime_lobsters = 99.0
	GameManager.click()
	_expect(GameManager.first_rare_event_seen, "100 lifetime LC triggers Disco Lobster")
	_expect(GameManager.active_boost.get("name", "") == "Disco Lobster", "Disco Lobster activates its boost")
	_expect(GameManager.achievements.get("disco_lobster", false), "Disco Lobster achievement persists in state")

	var disco_save := GameManager.get_save_data()
	GameManager.reset_progress()
	GameManager.load_save_data(disco_save)
	_expect(GameManager.first_rare_event_seen, "Disco event state survives save/load")
	_expect(GameManager.boost_time_remaining > 0.0, "active timed boost survives save/load")

	GameManager.reset_progress()
	GameManager.total_lobsters = 15000.0
	GameManager.lifetime_lobsters = 2500.0
	var options := GameManager.start_premium_draw()
	_expect(options.size() == 3, "paid card draw returns three choices")
	_expect(GameManager.total_lobsters == 0.0, "card draw charges exactly once")
	for option in options:
		_expect(option.get("type", "") != "single_building_boost", "unowned-building draw excludes unusable rewards")
	var pending_save := GameManager.get_save_data()
	GameManager.reset_progress()
	GameManager.load_save_data(pending_save)
	_expect(GameManager.pending_premium_options.size() == 3, "unselected paid card draw survives save/load")
	_expect(GameManager.start_premium_draw().size() == 3, "restored draw does not charge again")
	_expect(not GameManager.activate_premium_boost({"name": "not offered", "type": "flat_lcps"}), "unoffered card cannot be activated")
	var selected_option: Dictionary = GameManager.pending_premium_options[0]
	_expect(GameManager.activate_premium_boost(selected_option), "a restored offered card can be activated")
	_expect(GameManager.pending_premium_options.is_empty(), "successful card selection clears pending transaction")

	GameManager.music_muted = true
	var settings_save := GameManager.get_save_data()
	GameManager.music_muted = false
	GameManager.load_save_data(settings_save)
	_expect(GameManager.music_muted, "music setting survives save/load")

	GameManager.reset_progress()
	_expect(GameManager.pending_premium_options.is_empty(), "reset clears pending card choices")
	_expect(GameManager.boost_time_remaining == 0.0, "reset clears active boost timer")
	_expect(GameManager.gacha_cooldown_remaining == 0.0, "reset clears cooldown timer")
	_expect(GameManager.single_building_boost_time == 0.0, "reset clears single-building timer")

	_expect(SaveManager._decode_save("not json").is_empty(), "invalid JSON is rejected")
	_expect(SaveManager._decode_save("[]").is_empty(), "non-dictionary save is rejected")
	_expect(SaveManager._decode_save('{"total_lobsters":"bad"}').is_empty(), "invalid currency type is rejected")
	_expect(SaveManager._decode_save('{"save_version":999,"total_lobsters":1}').is_empty(), "unsupported future save version is rejected")
	_expect(SaveManager._decode_save('{"total_lobsters":1,"building_counts":["bad"]}').is_empty(), "invalid building data is rejected")

	GameManager.reset_progress()
	GameManager.set_building_purchase_mode(10)
	GameManager.total_lobsters = GameManager.get_bulk_building_cost(0, 10)
	_expect(GameManager.buy_building(0), "Buy 10 completes as one transaction")
	_expect(GameManager.building_counts[0] == 10, "Buy 10 adds ten buildings")
	_expect(GameManager.achievements.get("ten_on_deck", false), "bulk purchase triggers crossed milestones")
	GameManager.reset_progress()
	GameManager.set_building_purchase_mode(-1)
	GameManager.total_lobsters = GameManager.get_bulk_building_cost(0, 3)
	_expect(GameManager.buy_building(0), "Buy Max completes")
	_expect(GameManager.building_counts[0] == 3, "Buy Max purchases every affordable building")

	# Molting resets ordinary progression while preserving permanent state.
	GameManager.reset_progress()
	GameManager.farm_name = "Test Reef"
	GameManager.music_muted = true
	GameManager.achievements["legacy_test"] = true
	GameManager.flat_lcps_bonus = 100.0
	GameManager.total_lobsters = GameManager.MOLTING_THRESHOLD
	GameManager.run_lobsters = GameManager.MOLTING_THRESHOLD
	GameManager.lifetime_lobsters = GameManager.MOLTING_THRESHOLD + 123.0
	GameManager.building_counts[0] = 10
	GameManager.click_upgrades_purchased[0] = true
	GameManager._recalculate_click_power()
	GameManager._recalculate_lps()
	_expect(GameManager.get_pending_shells() == 1, "first Molt awards one Shell at 10B run LC")
	_expect(not GameManager.can_molt(), "Molt still requires the final Immortality building")
	GameManager.building_counts[GameManager.MOLTING_BUILDING_INDEX] = 1
	_expect(GameManager.can_molt(), "Molt unlocks at the threshold")
	var pre_molt_lifetime := GameManager.lifetime_lobsters
	_expect(GameManager.molt() == 1, "Molt completes and reports Shell gain")
	_expect(GameManager.shells == 1 and GameManager.molt_count == 1, "Molt records permanent Shell and count")
	_expect(GameManager.total_lobsters == 0.0 and GameManager.run_lobsters == 0.0, "Molt resets current and run LC")
	_expect(GameManager.lifetime_lobsters == pre_molt_lifetime, "Molt retains global lifetime LC")
	_expect(GameManager.building_counts[0] == 0 and not GameManager.click_upgrades_purchased[0], "Molt resets buildings and ordinary upgrades")
	_expect(GameManager.farm_name == "Test Reef" and GameManager.music_muted, "Molt retains farm identity and settings")
	_expect(GameManager.achievements.get("legacy_test", false), "Molt retains achievements")
	_expect(GameManager.flat_lcps_bonus == 100.0, "Molt retains permanent card income")
	_expect(is_equal_approx(GameManager.get_click_value(), 1.1), "Shell bonus applies to clicking")
	_expect(is_equal_approx(GameManager.lobsters_per_second, 110.0), "Shell bonus applies to all passive production")
	var molt_save := GameManager.get_save_data()
	GameManager.reset_progress()
	GameManager.load_save_data(molt_save)
	_expect(GameManager.shells == 1 and GameManager.molt_count == 1, "Molting state survives save/load")

	GameManager.run_lobsters = GameManager.MOLTING_THRESHOLD * 4.0
	GameManager.building_counts[GameManager.MOLTING_BUILDING_INDEX] = 1
	_expect(GameManager.get_pending_shells() == 2, "longer runs award multiple Shells on square-root curve")
	GameManager.pending_premium_options = [{"name": "Paid Choice"}]
	_expect(not GameManager.can_molt(), "unfinished paid card choice blocks Molting")
	GameManager.pending_premium_options.clear()

	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"shells":-1}').is_empty(), "negative Shell count is rejected")

	if failures.is_empty():
		print("PASS: Lobster Clicker regression suite")
		get_tree().quit(0)
	else:
		print("FAILURES: %d" % failures.size())
		get_tree().quit(1)
