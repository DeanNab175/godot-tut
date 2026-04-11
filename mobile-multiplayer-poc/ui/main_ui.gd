extends Node

# ---------------------------------------------------------------
# Node refs
# ---------------------------------------------------------------
@onready var status_label: TextEdit = $VBoxContainer/StatusLabel
@onready var start_server_btn: Button = $VBoxContainer/HBoxContainer/StartServer
@onready var start_client_btn: Button = $VBoxContainer/HBoxContainer/StartClient
@onready var find_match_btn: Button = $VBoxContainer/FindMatch
@onready var cancel_match_btn: Button = $VBoxContainer/CancelMatch
@onready var quit_btn: Button = $QuitButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var ip_input: LineEdit = $VBoxContainer/IPInput
@onready var quit_match_btn: Button = $VBoxContainer/QuitMatch


# ---------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------
func _ready() -> void:
	_wire_buttons()
	_wire_network_signals()
	_set_matchmaking_ui_visible(false)
	quit_match_btn.visible = false
	#_log("Choose mode: Server or Client")
	if NetworkManager.is_server_mode:
		# Server auto-started — show server-only UI
		_show_server_ui()
	else:
		# Client mode — show join screen
		_show_client_ui()
		
func _show_server_ui() -> void:
	start_server_btn.visible = false
	start_client_btn.visible = false
	join_button.visible = false
	ip_input.visible = false
	_log("✅ Server running — waiting for players...")


func _show_client_ui() -> void:
	start_server_btn.visible = false   # hide in production builds
	start_client_btn.visible = false   # hide in production builds
	join_button.visible = true
	_log("Welcome to Slot Gather! Press Join to find a match.")


func _wire_buttons() -> void:
	start_server_btn.pressed.connect(_on_start_server)
	start_client_btn.pressed.connect(_on_start_client)
	find_match_btn.pressed.connect(_on_find_match)
	cancel_match_btn.pressed.connect(_on_cancel_match)
	quit_btn.pressed.connect(_on_quit)
	join_button.pressed.connect(_on_join_pressed)
	quit_match_btn.pressed.connect(_on_quit_match)


func _wire_network_signals() -> void:
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.match_found.connect(_on_match_found)
	NetworkManager.matchmaking_status_changed.connect(_on_matchmaking_status)
	NetworkManager.opponent_left.connect(_on_opponent_left)

	# Also listen to MatchmakingManager signals for server-side log
	MatchmakingManager.room_created.connect(_on_room_created)
	MatchmakingManager.player_queued.connect(func(id): _log("🔎 Player %d queued" % id))
	MatchmakingManager.player_dequeued.connect(func(id): _log("❌ Player %d left queue" % id))

# ---------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------
func _on_start_server() -> void:
	status_label.text = ""
	_lock_mode_buttons()
	NetworkManager.start_server()
	_log("✅ Server started on port %d" % NetworkManager.PORT)


func _on_start_client() -> void:
	status_label.text = ""
	_lock_mode_buttons()
	NetworkManager.start_client()
	_log("🔄 Connecting to %s..." % NetworkManager.server_ip)
	_set_matchmaking_ui_visible(false)   # show after connected


func _on_find_match() -> void:
	_log("🔎 Finding match...")
	NetworkManager.request_matchmaking()
	find_match_btn.disabled = true
	cancel_match_btn.visible = true


func _on_cancel_match() -> void:
	_log("❌ Cancelling matchmaking...")
	NetworkManager.cancel_matchmaking()
	find_match_btn.disabled = false
	cancel_match_btn.visible = false


func _on_quit() -> void:
	_log("👋 Shutting down...")
	NetworkManager.disconnect_peer()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_quit_match() -> void:
	_log("🚪 Leaving match...")
	NetworkManager.quit_match()
	_set_in_game_ui(false)   # back to lobby UI

func _on_join_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"  # fallback for local testing
		
	NetworkManager.start_client()
	join_button.disabled = true
	_log("🔄 Connecting to server...")
# ---------------------------------------------------------------
# Network signal handlers
# ---------------------------------------------------------------
func _on_connected(my_id: int) -> void:
	_log("🎉 Connected! My ID: %d" % my_id)
	_set_matchmaking_ui_visible(true)


func _on_connection_failed() -> void:
	_log("💥 Connection failed. Try again.")
	_unlock_mode_buttons()


func _on_player_connected(id: int) -> void:
	_log("🟢 Player connected: %d" % id)


func _on_player_disconnected(id: int) -> void:
	_log("🔴 Player disconnected: %d" % id)


func _on_match_found(room_id: int) -> void:
	_log("🎉 Match found! Room: %d — Starting game..." % room_id)
	#find_match_btn.disabled = false
	#cancel_match_btn.visible = false
	_set_in_game_ui(true)
	# TODO: transition to game scene
	# get_tree().change_scene_to_file("res://game/GameBoard.tscn")


func _on_matchmaking_status(status: String) -> void:
	match status:
		"waiting":  _log("⏳ Waiting for opponent...")
		"cancelled": _log("❌ Matchmaking cancelled")
		_: _log("ℹ️ Status: %s" % status)


func _on_opponent_left() -> void:
	_log("⚠️ Opponent disconnected. Returning to lobby...")
	_set_matchmaking_ui_visible(true)
	_set_in_game_ui(false)


func _on_room_created(room_id: int, players: Array) -> void:
	_log("🏠 Room %d created for players %s" % [room_id, str(players)])

# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------
func _log(msg: String) -> void:
	var time := Time.get_time_string_from_system()
	status_label.text += "[%s] %s\n" % [time, msg]
	status_label.scroll_vertical = status_label.get_line_count()


func _lock_mode_buttons() -> void:
	start_server_btn.disabled = true
	start_client_btn.disabled = true


func _unlock_mode_buttons() -> void:
	start_server_btn.disabled = false
	start_client_btn.disabled = false

func _set_in_game_ui(in_game: bool) -> void:
	# In-game: show Quit Match only
	quit_match_btn.visible = in_game

	# Lobby: show Find Match, hide Cancel
	find_match_btn.visible = not in_game
	find_match_btn.disabled = false
	cancel_match_btn.visible = false

func _set_matchmaking_ui_visible(visible: bool) -> void:
	find_match_btn.visible = visible
	cancel_match_btn.visible = false   # always start hidden
	quit_match_btn.visible = false
