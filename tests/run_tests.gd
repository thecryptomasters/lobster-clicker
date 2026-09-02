extends Node

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FAIL: %s" % message)

func _verify_purchase(label: String, cost: float, purchase: Callable) -> void:
	GameManager.total_lobsters = cost
	var before := GameManager.total_lobsters
	_expect(bool(purchase.call()), "%s succeeds when exactly affordable" % label)
	_expect(is_equal_approx(GameManager.total_lobsters, before - cost), "%s charges the exact displayed cost" % label)
	var after := GameManager.total_lobsters
	_expect(not bool(purchase.call()), "%s cannot be purchased twice" % label)
	_expect(is_equal_approx(GameManager.total_lobsters, after), "rejected duplicate %s does not consume LC" % label)

func _run() -> void:
	GameManager.reset_progress()
	_expect(GameManager.format_rate(0.1) == "0.1", "fractional LCPS remains visible")
	_expect(GameManager.format_number(1250000.0) == "1.25M", "large values use compact readable notation")

	# Every direct upgrade purchase is atomic: exact debit, reward, and duplicate protection.
	GameManager.reset_progress()
	_verify_purchase("click upgrade", GameManager.click_upgrade_defs[0]["cost"], func(): return GameManager.buy_click_upgrade(0))
	GameManager.reset_progress()
	_verify_purchase("CPS click upgrade", GameManager.cps_click_upgrade_defs[0]["cost"], func(): return GameManager.buy_cps_click_upgrade(0))
	GameManager.reset_progress()
	_verify_purchase("hold-click upgrade", GameManager.hold_click_defs[0]["cost"], func(): return GameManager.buy_hold_click_upgrade(0))
	GameManager.reset_progress()
	_verify_purchase("offline-rate upgrade", GameManager.offline_rate_defs[0]["cost"], func(): return GameManager.buy_offline_rate_upgrade(0))
	GameManager.reset_progress()
	_verify_purchase("offline-duration upgrade", GameManager.offline_duration_defs[0]["cost"], func(): return GameManager.buy_offline_duration_upgrade(0))
	GameManager.reset_progress()
	_verify_purchase("gacha cooldown upgrade", GameManager.gacha_cooldown_upgrade_defs[0]["cost"], func(): return GameManager.buy_gacha_cooldown_upgrade(0))
	GameManager.reset_progress()
	GameManager.building_counts[0] = GameManager.UPGRADE_THRESHOLDS[0]
	_verify_purchase("building upgrade", GameManager.get_upgrade_cost_for(0, 0), func(): return GameManager.buy_building_upgrade(0, 0))

	GameManager.reset_progress()
	GameManager.click_upgrades_purchased.fill(true)
	GameManager._recalculate_click_power()
	_expect(is_equal_approx(GameManager.lobsters_per_click, 100.0), "click upgrade descriptions match multiplicative 2x, 5x, 10x stacking")
	GameManager.reset_progress()

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
	GameManager.music_volume = 0.42
	GameManager.sfx_volume = 0.73
	GameManager.reduced_motion = true
	var settings_save := GameManager.get_save_data()
	GameManager.music_muted = false
	GameManager.music_volume = 0.0
	GameManager.sfx_volume = 0.0
	GameManager.reduced_motion = false
	GameManager.load_save_data(settings_save)
	_expect(GameManager.music_muted, "music setting survives save/load")
	_expect(is_equal_approx(GameManager.music_volume, 0.42), "music volume survives save/load")
	_expect(is_equal_approx(GameManager.sfx_volume, 0.73), "SFX volume survives save/load")
	_expect(GameManager.reduced_motion, "reduced-motion setting survives save/load")

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
	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"music_volume":2}').is_empty(), "out-of-range volume is rejected")
	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"reduced_motion":"yes"}').is_empty(), "invalid reduced-motion setting is rejected")
	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"click_upgrades":[1]}').is_empty(), "non-boolean upgrade state is rejected")
	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"building_upgrades":[["yes"]]}').is_empty(), "corrupt building-upgrade tier is rejected")
	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"pending_premium_options":[{"name":"Broken"}]}').is_empty(), "malformed paid-card choice is rejected")
	var valid_primary := '{"save_version":3,"total_lobsters":7}'
	var valid_backup := '{"save_version":3,"total_lobsters":9}'
	_expect(float(SaveManager.select_recoverable_save(valid_primary, valid_backup).get("total_lobsters", 0)) == 7.0, "valid primary save is preferred")
	_expect(float(SaveManager.select_recoverable_save("corrupt", valid_backup).get("total_lobsters", 0)) == 9.0, "corrupted primary recovers from backup")
	_expect(SaveManager.select_recoverable_save("corrupt", "also corrupt").is_empty(), "two invalid saves fail safely into a fresh state")

	_expect(is_equal_approx(SaveManager.calculate_offline_earnings(100.0, 3600.0, 3600.0, 0.05), 18000.0), "base offline earnings calculate correctly")
	_expect(is_equal_approx(SaveManager.calculate_offline_earnings(100.0, 7200.0, 3600.0, 0.50), 180000.0), "offline duration cap is enforced")
	_expect(SaveManager.calculate_offline_earnings(100.0, -60.0, 3600.0, 0.50) == 0.0, "future save timestamps cannot subtract currency")
	GameManager.reset_progress()
	for i in range(GameManager.offline_rate_defs.size()):
		GameManager.offline_rate_purchased[i] = true
		_expect(is_equal_approx(GameManager.get_offline_rate(), float(GameManager.offline_rate_defs[i]["rate"])), "offline rate tier %d applies its documented rate" % (i + 1))
	GameManager.reset_progress()
	for i in range(GameManager.offline_duration_defs.size()):
		GameManager.offline_duration_purchased[i] = true
		_expect(is_equal_approx(GameManager.get_offline_max_seconds(), float(GameManager.offline_duration_defs[i]["hours"]) * 3600.0), "offline duration tier %d applies its documented cap" % (i + 1))

	GameManager.reset_progress()
	GameManager.load_save_data({"save_version": 2, "total_lobsters": 12.0, "lifetime_lobsters": 34.0})
	_expect(GameManager.run_lobsters == 34.0, "v2 saves migrate lifetime progress into the first Molting run")
	_expect(GameManager.shells == 0 and GameManager.molt_count == 0, "v2 saves migrate with clean Molting state")

	GameManager.reset_progress()
	GameManager.set_building_purchase_mode(10)
	GameManager.total_lobsters = GameManager.get_bulk_building_cost(0, 10)
	_expect(GameManager.buy_building(0), "Buy 10 completes as one transaction")
	_expect(GameManager.building_counts[0] == 10, "Buy 10 adds ten buildings")
	_expect(GameManager.achievements.get("ten_on_deck", false), "bulk purchase triggers crossed milestones")
	GameManager.building_counts.fill(1)
	GameManager._check_harbor_empire_milestones()
	_expect(GameManager.achievements.get("harbor_lights", false), "four active businesses unlock Harbor Lights")
	_expect(GameManager.achievements.get("neon_empire", false), "seven active businesses unlock Neon Empire")
	_expect(GameManager.achievements.get("full_harbor", false), "all building families unlock Full Harbor")
	GameManager.building_counts.fill(12)
	GameManager._check_harbor_empire_milestones()
	_expect(GameManager.achievements.get("century_wharf", false), "one hundred total operations unlock Century Wharf")
	GameManager.reset_progress()
	GameManager.set_building_purchase_mode(-1)
	GameManager.total_lobsters = GameManager.get_bulk_building_cost(0, 3)
	_expect(GameManager.buy_building(0), "Buy Max completes")
	_expect(GameManager.building_counts[0] == 3, "Buy Max purchases every affordable building")
	var max_after_purchase := GameManager.total_lobsters
	_expect(not GameManager.buy_building(0), "Buy Max rejects an empty purchase")
	_expect(is_equal_approx(GameManager.total_lobsters, max_after_purchase), "rejected Buy Max does not consume LC")

	GameManager.reset_progress()
	GameManager.total_lobsters = GameManager.get_gacha_cost()
	_expect(not GameManager.roll_gacha().is_empty(), "capsule purchase always delivers a boost")
	_expect(is_equal_approx(GameManager.total_lobsters, 0.0), "capsule purchase charges its exact cost")
	var after_gacha := GameManager.total_lobsters
	_expect(GameManager.roll_gacha().is_empty(), "active capsule cooldown rejects another purchase")
	_expect(is_equal_approx(GameManager.total_lobsters, after_gacha), "rejected capsule purchase does not consume LC")

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

	# Accelerated prestige audit: every square-root reward boundary is exact.
	var molt_boundary_cases := [
		[GameManager.MOLTING_THRESHOLD - 1.0, 0],
		[GameManager.MOLTING_THRESHOLD, 1],
		[GameManager.MOLTING_THRESHOLD * 4.0 - 1.0, 1],
		[GameManager.MOLTING_THRESHOLD * 4.0, 2],
		[GameManager.MOLTING_THRESHOLD * 9.0 - 1.0, 2],
		[GameManager.MOLTING_THRESHOLD * 9.0, 3],
	]
	for boundary in molt_boundary_cases:
		GameManager.run_lobsters = boundary[0]
		_expect(GameManager.get_pending_shells() == boundary[1], "Molting reward boundary at %s run LC is exact" % GameManager.format_number(boundary[0]))

	# A second accelerated Molt compounds permanent progression and persists it.
	GameManager.run_lobsters = GameManager.MOLTING_THRESHOLD * 4.0
	GameManager.building_counts[GameManager.MOLTING_BUILDING_INDEX] = 1
	_expect(GameManager.get_pending_shells() == 2, "longer runs award multiple Shells on square-root curve")
	_expect(GameManager.get_next_shell_target() == GameManager.MOLTING_THRESHOLD * 9.0, "two-Shell run points to the exact three-Shell target")
	GameManager.pending_premium_options = [{"name": "Paid Choice"}]
	_expect(not GameManager.can_molt(), "unfinished paid card choice blocks Molting")
	GameManager.pending_premium_options.clear()
	_expect(GameManager.molt() == 2, "second accelerated Molt awards two Shells")
	_expect(GameManager.shells == 3 and GameManager.molt_count == 2, "second Molt compounds permanent Shells and count")
	_expect(is_equal_approx(GameManager.get_shell_multiplier(), 1.3), "three total Shells provide the documented 30% multiplier")
	_expect(is_equal_approx(GameManager.get_click_value(), 1.3), "second-Molt Shell total applies to clicking")
	_expect(is_equal_approx(GameManager.lobsters_per_second, 130.0), "second-Molt Shell total applies to retained permanent LCPS")
	var second_molt_save := GameManager.get_save_data()
	GameManager.reset_progress()
	GameManager.load_save_data(second_molt_save)
	_expect(GameManager.shells == 3 and GameManager.molt_count == 2, "second-Molt state survives save/load")
	_expect(is_equal_approx(GameManager.get_shell_multiplier(), 1.3), "second-Molt multiplier survives save/load")

	_expect(SaveManager._decode_save('{"save_version":3,"total_lobsters":1,"shells":-1}').is_empty(), "negative Shell count is rejected")

	# Main-scene settings smoke: controls instantiate and reduced motion avoids animation.
	GameManager.reset_progress()
	GameManager.music_muted = false
	GameManager.reduced_motion = true
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_ui = main_scene.instantiate()
	add_child(main_ui)
	await get_tree().process_frame
	main_ui._layout_corner_buttons(true)
	_expect(main_ui.mute_button.anchor_right < 0.5, "desktop mute control stays inside the left panel and clear of Molt")
	main_ui._layout_corner_buttons(false)
	_expect(main_ui.mute_button.anchor_right == 1.0, "mobile mute control stays aligned to the viewport edge")
	_expect(main_ui.settings_button.custom_minimum_size.x == 72.0 and main_ui.mute_button.custom_minimum_size.x == 72.0, "mobile corner controls leave the title a readable center lane")
	main_ui._is_desktop = true
	main_ui._last_width = 0
	main_ui._apply_layout()
	_expect(main_ui.right_panel.custom_minimum_size.y >= 280.0, "mobile inventory drawer reserves a useful height without clipping the playfield")
	_expect(main_ui.content_scroll.custom_minimum_size.y >= 164.0, "mobile inventory list keeps a swipeable touch region on short browsers")
	_expect(main_ui.right_panel.get_theme_stylebox("panel").bg_color.a >= 0.99, "mobile inventory cabinet is opaque over the painted playfield")
	_expect(main_ui.content_scroll.get_v_scroll_bar().custom_minimum_size.x >= 18.0, "mobile inventory exposes a comfortable visible scroll handle")
	_expect(main_ui.building_container.find_child("ScrollEndSpacer", false, false) != null, "building list keeps bottom breathing room above mobile browser chrome")
	_expect(not main_ui.scroll_up_btn.visible and not main_ui.scroll_down_btn.visible, "mobile inventory uses native swipe scrolling without space-hungry arrow controls")
	_expect(main_ui.objective_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "long objectives wrap instead of clipping on narrow layouts")
	main_ui._switch_tab(main_ui.Tab.BUILDINGS)
	main_ui._cycle_tab(1)
	_expect(main_ui.current_tab == main_ui.Tab.UPGRADES and main_ui.upgrades_tab.has_focus(), "keyboard/controller tab cycling advances focus")
	main_ui.consumables_tab.visible = false
	main_ui._cycle_tab(1)
	_expect(main_ui.current_tab == main_ui.Tab.MOLT, "tab cycling skips locked consumables")
	_expect(main_ui.theme.get_stylebox("focus", "Button") != null, "keyboard/controller focus uses a high-visibility ring")
	_expect(main_ui.hero_claw.texture != null, "visual-polish hero claw asset is loaded")
	_expect(main_ui.score_panel.get_theme_stylebox("panel") != null, "neo-arcade score cabinet is styled")
	_expect(main_ui.capsule_machine.texture != null, "Boosts tab loads its illustrated Capsule Catcher")
	_expect(main_ui.capsule_machine_frame.get_theme_stylebox("panel") != null, "Capsule Catcher uses a cabinet-style frame")
	_expect(main_ui.result_panel.get_theme_stylebox("panel") != null, "boost results use a rarity-ready reward panel")
	var owned_upgrade_scene: PackedScene = load("res://scenes/building_upgrade_item.tscn")
	var owned_upgrade_item = owned_upgrade_scene.instantiate()
	main_ui.add_child(owned_upgrade_item)
	owned_upgrade_item.setup(0, 0, true)
	_expect(owned_upgrade_item.buy_button.text == "OWNED", "owned upgrade buttons use font-safe status text")
	owned_upgrade_item.queue_free()
	var arcade_first_building = main_ui.building_container.get_child(0)
	_expect(arcade_first_building.icon_texture.texture != null and arcade_first_building.icon_badge.visible == false, "first building uses illustrated arcade cabinet art")
	var final_illustrated_building = main_ui.building_container.get_child(8)
	_expect(final_illustrated_building.icon_texture.texture != null and final_illustrated_building.icon_badge.visible == false, "all nine buildings use illustrated arcade cabinet art")
	var harbor_backdrop = main_ui.get_node_or_null("HarborBackdrop")
	_expect(harbor_backdrop != null, "Midnight Harbor backdrop is present")
	_expect(ResourceLoader.exists("res://assets/art/environment/harbor_diorama.png"), "painted harbor diorama is packaged")
	_expect(harbor_backdrop != null and harbor_backdrop.is_processing(), "living harbor animation is active")
	_expect(harbor_backdrop.get_active_landmark_count() == 0, "fresh harbor starts without earned empire landmarks")
	GameManager.building_counts[0] = 1
	GameManager.building_counts[3] = 1
	GameManager.building_counts[8] = 1
	_expect(harbor_backdrop.get_active_landmark_count() == 3, "harbor landmarks reflect owned building families")
	GameManager.building_counts.fill(0)
	_expect(ResourceLoader.exists("res://assets/art/ui/medallions/claw_power.png"), "claw upgrade medallion is packaged")
	_expect(ResourceLoader.exists("res://assets/art/ui/medallions/building_power.png"), "building upgrade medallion is packaged")
	_expect(ResourceLoader.exists("res://assets/art/ui/medallions/offline_power.png"), "offline upgrade medallion is packaged")
	_expect(ResourceLoader.exists("res://assets/art/ui/medallions/boost_power.png"), "Boost card medallion is packaged")
	_expect(ResourceLoader.exists("res://assets/art/ui/medallions/achievement_medal.png"), "achievement medallion is packaged")
	var soundtrack = load("res://assets/music/midnight_harbor_arcade_loop.ogg")
	_expect(soundtrack is AudioStreamOggVorbis and soundtrack.loop, "original Midnight Harbor arcade soundtrack is packaged as a seamless loop")
	main_ui._show_offline_report(12345.0, 3660.0)
	_expect(main_ui.offline_popup.visible and "NIGHT SHIFT REPORT" in main_ui.offline_title.text, "offline earnings use the arcade harbor report")
	_expect("12,345" in main_ui.offline_label.text and "1h 1m" in main_ui.offline_label.text, "offline report explains earnings and elapsed shift")
	main_ui._on_offline_ok()
	_expect(main_ui.title_label.get_theme_font("font") != null, "local display typography is applied")
	main_ui._refresh_molt()
	_expect(main_ui.molt_progress_bar.value == 0.0, "Molting presentation starts with an empty progress meter")
	GameManager.reduced_motion = false
	main_ui._show_molt_celebration(2, 3)
	_expect(main_ui._celebration_layer != null and main_ui._celebration_layer.name == "MoltCelebration", "Molting triggers the full-screen arcade celebration")
	_expect(main_ui._celebration_layer.find_child("MoltMarquee", true, false) != null, "Molting celebration includes its permanent-power marquee")
	main_ui._clear_celebration_layer()
	await get_tree().process_frame
	GameManager.reduced_motion = true
	main_ui._show_molt_celebration(1, 1)
	_expect(main_ui._celebration_layer == null, "reduced motion skips animated Molting effects")
	main_ui.mute_button.pressed.emit()
	_expect(GameManager.music_muted and main_ui.mute_button.text == "UNMUTE", "mute shortcut mutes and updates its label")
	main_ui.mute_button.pressed.emit()
	_expect(not GameManager.music_muted and main_ui.mute_button.text == "MUTE", "mute shortcut can unmute through the same control")
	GameManager.reset_progress()
	main_ui.claw_button.grab_focus()
	await get_tree().process_frame
	var joy_click := InputEventJoypadButton.new()
	joy_click.button_index = JOY_BUTTON_A
	joy_click.pressed = true
	main_ui._unhandled_input(joy_click)
	_expect(GameManager.total_lobsters == 1.0, "controller A activates the focused claw")
	main_ui._show_settings_dialog()
	await get_tree().process_frame
	var found_settings_dialog := false
	var settings_dialog: AcceptDialog
	for child in main_ui.get_children():
		if child is AcceptDialog and child.title == "Settings":
			found_settings_dialog = true
			settings_dialog = child
	_expect(found_settings_dialog, "settings dialog opens from the main scene")
	if settings_dialog:
		settings_dialog.queue_free()
		await get_tree().process_frame
	main_ui._show_credits_dialog()
	await get_tree().process_frame
	var found_credits_dialog := false
	var credits_dialog: AcceptDialog
	for child in main_ui.get_children():
		if child is AcceptDialog and child.title == "Credits & Licenses":
			found_credits_dialog = true
			credits_dialog = child
	_expect(found_credits_dialog, "credits and licenses are available in game")
	if credits_dialog:
		credits_dialog.queue_free()
		await get_tree().process_frame
	GameManager.total_lobsters = 123.0
	main_ui._show_reset_confirmation()
	await get_tree().process_frame
	var reset_dialog: ConfirmationDialog
	for child in main_ui.get_children():
		if child is ConfirmationDialog and child.title == "Reset all progress?":
			reset_dialog = child
	_expect(reset_dialog != null, "reset is protected by an explicit confirmation dialog")
	if reset_dialog:
		reset_dialog.canceled.emit()
		await get_tree().process_frame
	_expect(GameManager.total_lobsters == 123.0, "canceling reset preserves progress")
	main_ui._do_click()
	_expect(main_ui.claw_state == main_ui.ClawState.IDLE, "reduced motion skips claw animation")
	GameManager.reduced_motion = false
	var idle_claw_texture: Texture2D = main_ui.hero_claw.texture
	main_ui._start_claw_animation()
	_expect(main_ui.claw_state == main_ui.ClawState.SNAPPING, "drawn claw animation enters its snapping phase")
	_expect(main_ui.hero_claw.texture != idle_claw_texture, "drawn claw animation replaces the idle artwork with an anticipation frame")
	main_ui._update_claw_animation(0.07)
	_expect(main_ui.hero_claw.texture == main_ui.ClawPinchFrames[2], "drawn claw animation reaches its closing frame")
	for frame_index in range(main_ui.ClawPinchFrames.size()):
		var frame_image: Image = main_ui.ClawPinchFrames[frame_index].get_image()
		var edges_are_clear := true
		var edge_padding := 1
		for x in range(frame_image.get_width()):
			for y in range(frame_image.get_height()):
				var is_edge_pixel := x < edge_padding or x >= frame_image.get_width() - edge_padding or y < edge_padding or y >= frame_image.get_height() - edge_padding
				if is_edge_pixel and frame_image.get_pixel(x, y).a > 0.01:
					edges_are_clear = false
					break
			if not edges_are_clear:
				break
		_expect(edges_are_clear, "claw animation frame %d keeps the complete claw inside a transparent safety border" % frame_index)
	main_ui._update_claw_animation(0.25)
	_expect(main_ui.claw_state == main_ui.ClawState.IDLE, "drawn claw animation returns to idle after recovery")
	_expect(main_ui.hero_claw.texture == idle_claw_texture, "drawn claw animation restores the idle artwork")
	main_ui._spawn_claw_snap_effect()
	var snap_burst = main_ui.click_effects.find_child("ClawSnapBurst", false, false)
	_expect(snap_burst != null, "claw pinch triggers a dedicated arcade impact burst")
	if snap_burst:
		var expected_impact := Vector2(main_ui.claw_button.size.x * 0.5, main_ui.claw_button.size.y * 0.27)
		_expect(snap_burst.position.is_equal_approx(expected_impact), "claw impact burst stays centered on the pincer contact point")
		_expect(snap_burst.find_child("ImpactRing", false, false) is Line2D, "claw impact uses a drawn ring instead of blue square particles")
		_expect(snap_burst.find_child("SnapRay0", false, false) is Polygon2D, "claw impact rays use engine-drawn arcade geometry")
	_expect(main_ui.boost_aura is Node2D and not main_ui.boost_aura is CPUParticles2D, "capsule boosts do not use square Web particle sprites")
	main_ui._spawn_capsule_reward_burst(Color("#a56de2"), "rare")
	var capsule_burst = main_ui.click_effects.find_child("CapsuleRewardBurst", false, false)
	_expect(capsule_burst != null, "capsule opening triggers a dedicated nautical arcade reveal")
	if capsule_burst:
		var expected_capsule_origin := Vector2(main_ui.claw_button.size.x * 0.5, main_ui.claw_button.size.y * 0.27)
		_expect(capsule_burst.position.is_equal_approx(expected_capsule_origin), "capsule reveal stays centered on the painted pinch point")
		_expect(capsule_burst.find_child("CapsuleRewardRing", false, false) is Line2D, "capsule reveal uses a rarity-colored ring")
		var first_capsule = capsule_burst.find_child("CapsuleSpark0", false, false)
		var capsule_shell = first_capsule.find_child("CapsuleShell", false, false) if first_capsule else null
		_expect(capsule_shell != null and capsule_shell.find_child("TopHalf", false, false) is Polygon2D and capsule_shell.find_child("BottomHalf", false, false) is Polygon2D, "capsule reveal uses two-tone drawn capsules instead of blue blocks")
	GameManager.reset_progress()
	GameManager.total_lobsters = GameManager.get_building_cost(0)
	GameManager.lobsters_changed.emit(GameManager.total_lobsters)
	var first_building_item = main_ui.building_container.get_child(0)
	_expect(first_building_item.icon_frame.custom_minimum_size == Vector2(68, 68), "Building artwork keeps its enlarged showcase size")
	first_building_item.buy_button.pressed.emit()
	_expect(GameManager.building_counts[0] == 1, "main-scene smoke buys the first building through its real button")
	var purchase_burst = first_building_item.icon_frame.find_child("PurchaseBurst", false, false)
	_expect(purchase_burst != null, "building purchase triggers its arcade particle burst")
	var milestone_popup = main_ui.find_child("MilestonePopup", false, false)
	_expect(milestone_popup != null, "earned milestones remain visible as a readable popup")
	if milestone_popup:
		var close_milestone_button = milestone_popup.find_child("CloseMilestoneButton", true, false)
		_expect(close_milestone_button is Button, "milestone popup provides a large explicit close button")
		if close_milestone_button:
			close_milestone_button.pressed.emit()
			await get_tree().process_frame
			_expect(not is_instance_valid(milestone_popup), "milestone popup closes only after player dismissal")
	_expect(main_ui.milestones_button != null and main_ui.milestones_button.text == "MILESTONES", "milestone collection is discoverable from the main HUD")
	main_ui._show_milestones_dialog()
	var milestones_dialog = main_ui.find_child("MilestonesDialog", false, false)
	_expect(milestones_dialog != null and milestones_dialog.visible, "milestone cabinet opens from the player interface")
	if milestones_dialog:
		var milestone_list = milestones_dialog.find_child("MilestoneList", true, false)
		_expect(milestone_list != null and milestone_list.get_child_count() == GameManager.ACHIEVEMENT_DEFS.size(), "milestone cabinet shows every tracked achievement")
		var tiny_fleet_card = milestones_dialog.find_child("Milestone_tiny_fleet", true, false)
		_expect(tiny_fleet_card != null, "earned milestone appears in the cabinet")
		milestones_dialog.queue_free()
		await get_tree().process_frame
	var burst_uses_geometry := purchase_burst != null
	if purchase_burst:
		for burst_particle in purchase_burst.get_children():
			if not burst_particle is Polygon2D:
				burst_uses_geometry = false
				break
	_expect(burst_uses_geometry, "purchase burst uses drawn geometry instead of font-dependent symbols")
	var scene_save := GameManager.get_save_data()
	GameManager.reset_progress()
	GameManager.load_save_data(scene_save)
	_expect(GameManager.building_counts[0] == 1, "main-scene smoke restores purchased progress")
	main_ui.queue_free()
	await get_tree().process_frame
	main_ui = null
	main_scene = null
	await get_tree().process_frame

	if failures.is_empty():
		print("PASS: Lobster Clicker regression suite")
		get_tree().quit(0)
	else:
		print("FAILURES: %d" % failures.size())
		get_tree().quit(1)
