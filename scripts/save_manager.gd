extends Node

const SAVE_KEY := "lobster_clicker_save"
const SAVE_INTERVAL := 10.0  # Save every 10 seconds (browsers throttle background tabs)

var save_timer: float = 0.0
var offline_earnings: float = 0.0

# Must keep references to prevent GC of JS callbacks
var _beforeunload_cb: JavaScriptObject
var _pagehide_cb: JavaScriptObject
var _visibility_cb: JavaScriptObject
var _freeze_cb: JavaScriptObject

func _ready() -> void:
	load_game()
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
	var result = JavaScriptBridge.eval("localStorage.getItem('%s');" % SAVE_KEY)
	if result == null:
		return
	var json_str := str(result)
	if json_str == "" or json_str == "null":
		return
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return
	var data: Dictionary = json.data
	var saved_time: int = data.get("last_save_time", 0)
	if saved_time > 0 and GameManager.lobsters_per_second > 0:
		var now := int(Time.get_unix_time_from_system())
		var elapsed := now - saved_time
		if elapsed > 5:
			var capped_elapsed := minf(elapsed, GameManager.get_offline_max_seconds())
			var earned := GameManager.lobsters_per_second * capped_elapsed * GameManager.get_offline_rate()
			GameManager.total_lobsters += earned
			GameManager.lifetime_lobsters += earned
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)
			# Save the updated total immediately
			save_game()

func save_game() -> void:
	var data := GameManager.get_save_data()
	var json := JSON.stringify(data)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.setItem('%s', '%s');" % [SAVE_KEY, json.c_escape()])
	else:
		var file := FileAccess.open("user://save.json", FileAccess.WRITE)
		if file:
			file.store_string(json)

func load_game() -> void:
	var json_str := ""
	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("localStorage.getItem('%s');" % SAVE_KEY)
		if result != null:
			json_str = str(result)
	else:
		var file := FileAccess.open("user://save.json", FileAccess.READ)
		if file:
			json_str = file.get_as_text()

	if json_str == "" or json_str == "null":
		return

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		return

	var data: Dictionary = json.data
	GameManager.load_save_data(data)

	# Calculate offline earnings from last save
	var saved_time: int = data.get("last_save_time", 0)
	if saved_time > 0:
		var now := int(Time.get_unix_time_from_system())
		var elapsed := now - saved_time
		if elapsed > 5 and GameManager.lobsters_per_second > 0:
			var capped_elapsed := minf(elapsed, GameManager.get_offline_max_seconds())
			offline_earnings = GameManager.lobsters_per_second * capped_elapsed * GameManager.get_offline_rate()
			GameManager.total_lobsters += offline_earnings
			GameManager.lifetime_lobsters += offline_earnings
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
