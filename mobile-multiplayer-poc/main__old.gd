extends Node

const PORT = 7777
@export var server_ip := "127.0.0.1"

@onready var status_label: TextEdit = $CanvasLayer/VBoxContainer/StatusLabel
@onready var start_server_button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/StartServer
@onready var start_client_button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/StartClient
@onready var quit_button: Button = $CanvasLayer/QuitButton
@onready var find_match: Button = $CanvasLayer/VBoxContainer/FindMatch
@onready var cancel_match: Button = $CanvasLayer/VBoxContainer/CancelMatch


var waiting_player = null
var rooms = {}
var room_id_counter = 1
var player_rooms = {}
var searching_players = {}


func _ready():
	start_server_button.pressed.connect(_on_start_server_pressed)
	start_client_button.pressed.connect(_on_start_client_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	find_match.pressed.connect(_on_find_match_pressed)
	cancel_match.pressed.connect(_on_cancel_match_pressed)
	
	cancel_match.visible = false
	log_message("Choose mode: Server or Client")
	
func _process(_delta):
	if multiplayer.multiplayer_peer:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			# Optional: show connected
			pass

# -------------------
# BUTTON HANDLERS
# -------------------
func _on_start_server_pressed():
	status_label.text = ""
	
	start_server_button.disabled = true
	start_client_button.disabled = true
	start_server()

func _on_start_client_pressed():
	status_label.text = ""
	
	start_server_button.disabled = true
	start_client_button.disabled = true
	start_client()
	
func _on_quit_button_pressed():
	log_message("👋 Shutting down...")

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null

	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_find_match_pressed():
	log_message("🔎 Finding match...")
	rpc_id(1, "request_matchmaking")
	
	find_match.disabled = true
	cancel_match.visible = true
	
func _on_cancel_match_pressed():
	log_message("❌ Cancelling matchmaking...")
	rpc_id(1, "cancel_matchmaking")
	
	find_match.disabled = false
	cancel_match.visible = false
# -------------------
# SERVER
# -------------------
func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	#log_message("✅ Server started on port " + str(PORT))
	log_message("✅ Server started")

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _on_player_connected(id):
	log_message("🟢 Player connected: " + str(id))
	rpc_id(id, "welcome_message", id)

#func _on_player_disconnected(id):
	#log_message("🔴 Player disconnected: " + str(id))
	#if player_rooms.has(id):
		#var room_id = player_rooms[id]
		#rooms.erase(room_id)
		#player_rooms.erase(id)
		
func _on_player_disconnected(id):
	log_message("🔴 Player disconnected: " + str(id))

	# Remove from queue
	if waiting_player == id:
		waiting_player = null

	searching_players.erase(id)

	# Remove from room
	if player_rooms.has(id):
		var room_id = player_rooms[id]
		var players = rooms[room_id]

		# Notify opponent
		for p in players:
			if p != id:
				rpc_id(p, "opponent_left")

		rooms.erase(room_id)
		player_rooms.erase(id)
	
#func create_room(p1, p2):
	#var room_id = room_id_counter
	#room_id_counter += 1
#
	#rooms[room_id] = [p1, p2]
	#player_rooms[p1] = room_id
	#player_rooms[p2] = room_id
#
	#log_message("🏠 Room " + str(room_id) + " created")
#
	## Notify both players
	#rpc_id(p1, "match_found", room_id)
	#rpc_id(p2, "match_found", room_id)
	
func create_room(p1, p2):
	var room_id = room_id_counter
	room_id_counter += 1

	rooms[room_id] = [p1, p2]

	player_rooms[p1] = room_id
	player_rooms[p2] = room_id

	# ✅ Remove from searching
	searching_players.erase(p1)
	searching_players.erase(p2)

	log_message("🏠 Room " + str(room_id) + " created")

	rpc_id(p1, "match_found", room_id)
	rpc_id(p2, "match_found", room_id)

# -------------------
# CLIENT
# -------------------
func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(server_ip, PORT)
	multiplayer.multiplayer_peer = peer

	log_message("🔄 Connecting to server...")

# -------------------
# RPCs
# -------------------
@rpc("any_peer")
func welcome_message(_id):
	log_message("🎉 Connected! ID: " + str(multiplayer.get_unique_id()))

@rpc("any_peer")
func send_ping(msg):
	log_message("📨 Server received: " + msg)
	rpc_id(multiplayer.get_remote_sender_id(), "receive_pong", "Pong from server")

@rpc("any_peer")
func receive_pong(msg):
	log_message("📩 Client received: " + msg)
	
#@rpc("any_peer")
#func request_matchmaking():
	#var player_id = multiplayer.get_remote_sender_id()
	#log_message("📥 Player " + str(player_id) + " wants to match")
#
	#if waiting_player == null:
		#waiting_player = player_id
		#log_message("⏳ Waiting for another player...")
	#else:
		#create_room(waiting_player, player_id)
		#waiting_player = null
		
@rpc("any_peer")
func request_matchmaking():
	var player_id = multiplayer.get_remote_sender_id()

	# ❌ Prevent duplicate requests
	if searching_players.has(player_id):
		log_message("⚠️ Player already searching: " + str(player_id))
		return

	searching_players[player_id] = true
	log_message("🔎 Player " + str(player_id) + " is searching...")

	if waiting_player == null:
		waiting_player = player_id
		rpc_id(player_id, "matchmaking_status", "waiting")
	else:
		create_room(waiting_player, player_id)
		waiting_player = null

@rpc("any_peer")
func match_found(room_id):
	log_message("🎉 Match found! Room ID: " + str(room_id))
	find_match.disabled = false
	cancel_match.visible = false
	
@rpc("any_peer")
func cancel_matchmaking():
	var player_id = multiplayer.get_remote_sender_id()

	if waiting_player == player_id:
		waiting_player = null

	searching_players.erase(player_id)

	log_message("❌ Player " + str(player_id) + " cancelled matchmaking")

	rpc_id(player_id, "matchmaking_status", "cancelled")
	
@rpc("any_peer")
func matchmaking_status(status):
	match status:
		"waiting":
			log_message("⏳ Waiting for opponent...")
		"cancelled":
			log_message("❌ Matchmaking cancelled")
			
@rpc("any_peer")
func opponent_left():
	log_message("⚠️ Opponent disconnected")
# -------------------
# INPUT TEST
# -------------------
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if multiplayer.is_server():
			log_message("Server doesn't send ping")
		else:
			log_message("➡️ Sending ping...")
			rpc_id(1, "send_ping", "Hello Server!")

func log_message(msg: String):
	var time = Time.get_time_string_from_system()
	status_label.text += "[" + time + "] " + msg + "\n"
	status_label.scroll_vertical = status_label.get_line_count()
