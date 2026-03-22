extends Node

const SAVE_KEY := "lobster_clicker_save"
const SAVE_INTERVAL := 30.0

var save_timer: float = 0.0
var offline_earnings: float = 0.0

# Must keep references to prevent GC of JS callbacks
var _beforeunload_cb: JavaScriptObject
var _visibility_cb: JavaScriptObject

func _ready() -> void:
	load_game()
	if OS.has_feature("web"):
		_beforeunload_cb = JavaScriptBridge.create_callback(_on_browser_beforeunload)
		_visibility_cb = JavaScriptBridge.create_callback(_on_browser_visibility_change)
		var window := JavaScriptBridge.get_interface("window")
		window.addEventListener("beforeunload", _beforeunload_cb)
		var document := JavaScriptBridge.get_interface("document")
		document.addEventListener("visibilitychange", _visibility_cb)

func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		save_game()

func _on_browser_beforeunload(_args: Array) -> void:
	save_game()

func _on_browser_visibility_change(_args: Array) -> void:
	var hidden = JavaScriptBridge.eval("document.visibilityState === 'hidden';")
	if hidden:
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

	# Calculate offline earnings
	var saved_time: int = data.get("last_save_time", 0)
	if saved_time > 0:
		var now := int(Time.get_unix_time_from_system())
		var elapsed := now - saved_time
		if elapsed > 5 and GameManager.lobsters_per_second > 0:
			offline_earnings = GameManager.lobsters_per_second * elapsed
			GameManager.total_lobsters += offline_earnings
			GameManager.lobsters_changed.emit(GameManager.total_lobsters)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
