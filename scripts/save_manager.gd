extends Node

const SAVE_KEY := "lobster_clicker_save"
const BACKUP_KEY := "lobster_clicker_save_backup"
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.backup.json"
const TEMP_PATH := "user://save.tmp.json"
const SAVE_INTERVAL := 10.0  # Save every 10 seconds (browsers throttle background tabs)

var save_timer: float = 0.0
var offline_earnings: float = 0.0
var _test_mode: bool = false

# Must keep references to prevent GC of JS callbacks
var _beforeunload_cb: JavaScriptObject
var _pagehide_cb: JavaScriptObject
var _visibility_cb: JavaScriptObject
var _freeze_cb: JavaScriptObject

func calculate_offline_earnings(lps: float, elapsed_seconds: float, max_seconds: float, rate: float) -> float:
	if not is_finite(lps) or not is_finite(elapsed_seconds) or not is_finite(max_seconds) or not is_finite(rate):
		return 0.0
	if lps <= 0.0 or elapsed_seconds <= 0.0 or max_seconds <= 0.0 or rate <= 0.0:
		return 0.0
	return lps * minf(elapsed_seconds, max_seconds) * clampf(rate, 0.0, 1.0)

func _ready() -> void:
	_test_mode = OS.get_cmdline_user_args().has("--test")
	if _test_mode:
		return
	load_game()
	GameManager.transaction_completed.connect(save_game)
	if OS.has_feature("web"):
		# beforeunload — desktop tab close
		_beforeunload_cb = JavaScriptBridge.create_callback(_on_browser_save)
		var window := JavaScriptBridge.get_interface("window")
		window.addEventListener("beforeunload", _beforeunload_cb)

		# pagehide — more reliable on mobile than beforeunload
		_pagehide_cb = JavaScriptBridge.create_callback(_on_browser_save)
		window.addEventListener("pagehide", _pagehide_cb)

		# freeze — fired when browser discards a background tab (Page Lifecycle API)
		_freeze_cb = JavaScriptBridge.create_callback(_on_browser_save)
		JavaScriptBridge.eval("if('onfreeze' in document){}", true)  # feature check
		var document := JavaScriptBridge.get_interface("document")
		document.addEventListener("freeze", _freeze_cb)

		# visibilitychange — save when leaving, recalculate when returning
		_visibility_cb = JavaScriptBridge.create_callback(_on_visibility_change)
		document.addEventListener("visibilitychange", _visibility_cb)

func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		save_game()

func _on_browser_save(_args: Array) -> void:
	save_game()

func _on_visibility_change(_args: Array) -> void:
	var hidden = JavaScriptBridge.eval("document.visibilityState === 'hidden';")
	if hidden:
		# Leaving — save immediately
		save_game()
	else:
		# Returning — recalculate offline earnings since last save
		_calculate_offline_bonus()

func _calculate_offline_bonus() -> void:
	# Read the saved timestamp from localStorage and award offline production
	if not OS.has_feature("web"):
		return
	var storage := JavaScriptBridge.get_interface("localStorage")
	var result = storage.getItem(SAVE_KEY)
	if result == null:
		return
	var json_str := str(result)
	if json_str == "" or json_str == "null":
		return
	var data := _decode_save(json_str)
	if data.is_empty():
		return
	var saved_time: int = data.get("last_save_time", 0)
	if saved_time > 0 and GameManager.lobsters_per_second > 0:
		var now := int(Time.get_unix_time_from_system())
		var elapsed := now - saved_time
		if elapsed > 5:
			var earned := calculate_offline_earnings(GameManager.lobsters_per_second, elapsed, GameManager.get_offline_max_seconds(), GameManager.get_offline_rate())
			GameManager.total_lobsters += earned
			GameManager.lifetime_lobsters += earned
			GameManager.run_lobsters += earned
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)
			GameManager.unlock_offline_achievement()
			# Save the updated total immediately
			save_game()

func save_game() -> void:
	if _test_mode:
		return
	var data := GameManager.get_save_data()
	var json := JSON.stringify(data)
	if OS.has_feature("web"):
		var storage := JavaScriptBridge.get_interface("localStorage")
		var current = storage.getItem(SAVE_KEY)
		if current != null and not _decode_save(str(current)).is_empty():
			storage.setItem(BACKUP_KEY, str(current))
		storage.setItem(SAVE_KEY, json)
	else:
		var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
		if file:
			file.store_string(json)
			file.flush()
			file.close()
			var save_path := ProjectSettings.globalize_path(SAVE_PATH)
			var backup_path := ProjectSettings.globalize_path(BACKUP_PATH)
			var temp_path := ProjectSettings.globalize_path(TEMP_PATH)
			if FileAccess.file_exists(SAVE_PATH):
				var current_text := FileAccess.get_file_as_string(SAVE_PATH)
				if not _decode_save(current_text).is_empty():
					DirAccess.copy_absolute(save_path, backup_path)
				DirAccess.remove_absolute(save_path)
			DirAccess.rename_absolute(temp_path, save_path)

func load_game() -> void:
	var data: Dictionary = {}
	if OS.has_feature("web"):
		var storage := JavaScriptBridge.get_interface("localStorage")
		var result = storage.getItem(SAVE_KEY)
		if result != null:
			data = _decode_save(str(result))
		if data.is_empty():
			var backup = storage.getItem(BACKUP_KEY)
			if backup != null:
				data = _decode_save(str(backup))
	else:
		if FileAccess.file_exists(SAVE_PATH):
			data = _decode_save(FileAccess.get_file_as_string(SAVE_PATH))
		if data.is_empty() and FileAccess.file_exists(BACKUP_PATH):
			data = _decode_save(FileAccess.get_file_as_string(BACKUP_PATH))

	if data.is_empty():
		return
	GameManager.load_save_data(data)

	# Calculate offline earnings from last save
	var saved_time: int = data.get("last_save_time", 0)
	if saved_time > 0:
		var now := int(Time.get_unix_time_from_system())
		var elapsed := now - saved_time
		if elapsed > 5 and GameManager.lobsters_per_second > 0:
			offline_earnings = calculate_offline_earnings(GameManager.lobsters_per_second, elapsed, GameManager.get_offline_max_seconds(), GameManager.get_offline_rate())
			GameManager.total_lobsters += offline_earnings
			GameManager.lifetime_lobsters += offline_earnings
			GameManager.run_lobsters += offline_earnings
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)
			GameManager.unlock_offline_achievement()

func _decode_save(json_str: String) -> Dictionary:
	if json_str == "" or json_str == "null":
		return {}
	var json := JSON.new()
	if json.parse(json_str) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = json.data
	if not _is_valid_save(data):
		return {}
	return data

func _is_valid_save(data: Dictionary) -> bool:
	if not data.has("total_lobsters"):
		return false
	if typeof(data["total_lobsters"]) != TYPE_FLOAT and typeof(data["total_lobsters"]) != TYPE_INT:
		return false
	var total := float(data["total_lobsters"])
	if not is_finite(total) or total < 0.0:
		return false
	var save_version := int(data.get("save_version", 1))
	if save_version < 1 or save_version > GameManager.SAVE_VERSION:
		return false
	for key in ["building_counts", "building_upgrades"]:
		if data.has(key) and typeof(data[key]) != TYPE_ARRAY:
			return false
	if data.has("building_counts"):
		for count in data["building_counts"]:
			if (typeof(count) != TYPE_INT and typeof(count) != TYPE_FLOAT) or int(count) < 0 or float(count) != floor(float(count)):
				return false
	if data.has("building_upgrades"):
		for tiers in data["building_upgrades"]:
			if typeof(tiers) != TYPE_ARRAY:
				return false
			for purchased in tiers:
				if typeof(purchased) != TYPE_BOOL:
					return false
	for key in ["click_upgrades", "cps_click_upgrades", "hold_click_upgrades", "gacha_cooldown_upgrades", "offline_rate_upgrades", "offline_duration_upgrades"]:
		if data.has(key):
			if typeof(data[key]) != TYPE_ARRAY:
				return false
			for purchased in data[key]:
				if typeof(purchased) != TYPE_BOOL:
					return false
	if data.has("farm_name") and typeof(data["farm_name"]) != TYPE_STRING:
		return false
	for key in ["music_volume", "sfx_volume"]:
		if data.has(key):
			if typeof(data[key]) != TYPE_FLOAT and typeof(data[key]) != TYPE_INT:
				return false
			if not is_finite(float(data[key])) or float(data[key]) < 0.0 or float(data[key]) > 1.0:
				return false
	if data.has("reduced_motion") and typeof(data["reduced_motion"]) != TYPE_BOOL:
		return false
	for key in ["music_muted", "first_rare_event_seen"]:
		if data.has(key) and typeof(data[key]) != TYPE_BOOL:
			return false
	for key in ["lifetime_lobsters", "run_lobsters"]:
		if data.has(key):
			if typeof(data[key]) != TYPE_FLOAT and typeof(data[key]) != TYPE_INT:
				return false
			if not is_finite(float(data[key])) or float(data[key]) < 0.0:
				return false
	for key in ["shells", "molt_count"]:
		if data.has(key):
			if typeof(data[key]) != TYPE_INT and typeof(data[key]) != TYPE_FLOAT:
				return false
			if int(data[key]) < 0 or float(data[key]) != floor(float(data[key])):
				return false
	for key in ["flat_lcps_bonus", "pending_premium_cost", "boost_end_time", "cooldown_end_time", "single_building_boost_mult", "single_boost_end_time", "last_save_time"]:
		if data.has(key):
			if typeof(data[key]) != TYPE_FLOAT and typeof(data[key]) != TYPE_INT:
				return false
			if not is_finite(float(data[key])) or float(data[key]) < 0.0:
				return false
	if data.has("single_building_boost_index"):
		if typeof(data["single_building_boost_index"]) != TYPE_INT and typeof(data["single_building_boost_index"]) != TYPE_FLOAT:
			return false
		if int(data["single_building_boost_index"]) < -1 or int(data["single_building_boost_index"]) >= GameManager.building_defs.size():
			return false
	if data.has("achievements"):
		if typeof(data["achievements"]) != TYPE_DICTIONARY:
			return false
		for value in data["achievements"].values():
			if typeof(value) != TYPE_BOOL:
				return false
	if data.has("pending_premium_options"):
		if typeof(data["pending_premium_options"]) != TYPE_ARRAY:
			return false
		for option in data["pending_premium_options"]:
			if not _is_valid_saved_boost(option):
				return false
	if data.has("active_boost") and not (typeof(data["active_boost"]) == TYPE_DICTIONARY and (data["active_boost"].is_empty() or _is_valid_saved_boost(data["active_boost"]))):
		return false
	return true

func _is_valid_saved_boost(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var boost: Dictionary = value
	if typeof(boost.get("name")) != TYPE_STRING or typeof(boost.get("type")) != TYPE_STRING:
		return false
	for key in ["mult", "duration", "amount"]:
		if boost.has(key):
			if typeof(boost[key]) != TYPE_FLOAT and typeof(boost[key]) != TYPE_INT:
				return false
			if not is_finite(float(boost[key])) or float(boost[key]) < 0.0:
				return false
	if boost.has("building_index"):
		if typeof(boost["building_index"]) != TYPE_INT and typeof(boost["building_index"]) != TYPE_FLOAT:
			return false
		if int(boost["building_index"]) < 0 or int(boost["building_index"]) >= GameManager.building_defs.size():
			return false
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
