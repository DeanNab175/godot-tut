#extends Node
#
## ---------------------------------------------------------------
## Constants
## ---------------------------------------------------------------
#const PORT := 7777
#
## ---------------------------------------------------------------
## Signals — other nodes listen to these instead of coupling to RPCs
## ---------------------------------------------------------------
#signal connected_to_server(my_id: int)
#signal connection_failed()
#signal player_connected(id: int)
#signal player_disconnected(id: int)
#signal match_found(room_id: int)
#signal matchmaking_status_changed(status: String)
#signal opponent_left()
#
## ---------------------------------------------------------------
## State
## ---------------------------------------------------------------
#var server_ip := "127.0.0.1"
#var is_server_mode := false
#
#func _ready() -> void:
	## Auto-start as server if launched with --server argument
	## e.g: ./SlotGather.x86_64 --server
	##if "--server" in OS.get_cmdline_args():
	#if OS.has_feature("dedicated_server"):
		#print("Server started!")
		#start_server()
#
## ---------------------------------------------------------------
## Public API
## ---------------------------------------------------------------
#func start_server() -> void:
	#is_server_mode = true
	#var peer := ENetMultiplayerPeer.new()
	#var err := peer.create_server(PORT, 32)
	#if err != OK:
		#push_error("NetworkManager: Failed to start server — error %d" % err)
		## Print more detail to help diagnose
		#push_error("Check: is port %d already in use? Try: lsof -i :%d" % [PORT, PORT])
		#return
#
	#multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#print("Server listening on port %d" % PORT)
#
#
#func start_client(ip: String = server_ip) -> void:
	#is_server_mode = false
	#server_ip = ip
	#var peer := ENetMultiplayerPeer.new()
	#var err := peer.create_client(server_ip, PORT)
	#if err != OK:
		#push_error("NetworkManager: Failed to connect — error %d" % err)
		#return
#
	#multiplayer.multiplayer_peer = peer
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
#
#
#func disconnect_peer() -> void:
	#if multiplayer.multiplayer_peer:
		#multiplayer.multiplayer_peer.close()
		#multiplayer.multiplayer_peer = null
#
#func request_matchmaking() -> void:
	#rpc_id(1, "_server_request_matchmaking")
#
#func cancel_matchmaking() -> void:
	#rpc_id(1, "_server_cancel_matchmaking")
#
#func quit_match() -> void:
	#rpc_id(1, "_server_quit_match")
	#
## Called by MatchmakingManager to ping clients
#func notify_client(player_id: int, rpc_method: String, args: Array = []) -> void:
	#match rpc_method:
		#"_client_match_found":
			#rpc_id(player_id, "_client_match_found", args[0])
		#"_client_matchmaking_status":
			#rpc_id(player_id, "_client_matchmaking_status", args[0])
		#"_client_opponent_left":
			#rpc_id(player_id, "_client_opponent_left")
#
## ---------------------------------------------------------------
## Multiplayer callbacks
## ---------------------------------------------------------------
#func _on_peer_connected(id: int) -> void:
	#print("🟢 Player connected: %d" % id)
	#emit_signal("player_connected", id)
	## Send the client their assigned ID
	#rpc_id(id, "_client_welcome", id)
#
#func _on_peer_disconnected(id: int) -> void:
	#print("🔴 Player disconnected: %d" % id)
	#emit_signal("player_disconnected", id)
#
#func _on_connected_to_server() -> void:
	#emit_signal("connected_to_server", multiplayer.get_unique_id())
#
#func _on_connection_failed() -> void:
	#emit_signal("connection_failed")
#
## ---------------------------------------------------------------
## RPCs (client-facing — called BY server ON clients)
## ---------------------------------------------------------------
#@rpc("authority")
#func _client_welcome(id: int) -> void:
	#emit_signal("connected_to_server", id)
#
#@rpc("authority")
#func _client_match_found(room_id: int) -> void:
	#emit_signal("match_found", room_id)
#
#@rpc("authority")
#func _client_matchmaking_status(status: String) -> void:
	#emit_signal("matchmaking_status_changed", status)
#
#@rpc("authority")
#func _client_opponent_left() -> void:
	#emit_signal("opponent_left")
#
## ---------------------------------------------------------------
## RPCs (server-facing — called BY clients ON server)
## ---------------------------------------------------------------
#@rpc("any_peer")
#func _server_request_matchmaking(_args: Array = []) -> void:
	#print("📥 Matchmaking requested by: %d" % multiplayer.get_remote_sender_id())
	## Delegate to MatchmakingManager (also an autoload)
	#MatchmakingManager.handle_request(multiplayer.get_remote_sender_id())
#
#@rpc("any_peer")
#func _server_cancel_matchmaking(_args: Array = []) -> void:
	#print("❌ Matchmaking cancelled by: %d" % multiplayer.get_remote_sender_id())
	#MatchmakingManager.handle_cancel(multiplayer.get_remote_sender_id())
#
#@rpc("any_peer")
#func _server_quit_match() -> void:
	#print("🚪 Player %d is leaving their match" % multiplayer.get_remote_sender_id())
	#MatchmakingManager.handle_quit(multiplayer.get_remote_sender_id())


extends Node

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------
const PORT := 7777

# ---------------------------------------------------------------
# Signals — other nodes listen to these instead of coupling to RPCs
# ---------------------------------------------------------------
signal connected_to_server(my_id: int)
signal connection_failed()
signal player_connected(id: int)
signal player_disconnected(id: int)
signal match_found(room_id: int)
signal matchmaking_status_changed(status: String)
signal opponent_left()

# ---------------------------------------------------------------
# State
# ---------------------------------------------------------------
var server_ip := "127.0.0.1"
var is_server_mode := false

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		print("Server started!")
		start_server()

# ---------------------------------------------------------------
# Public API
# ---------------------------------------------------------------
func start_server() -> void:
	is_server_mode = true
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 32)
	if err != OK:
		push_error("NetworkManager: Failed to start server — error %d" % err)
		push_error("Check: is port %d already in use? Try: lsof -i :%d" % [PORT, PORT])
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server listening on port %d" % PORT)


func start_client(ip: String = server_ip) -> void:
	is_server_mode = false
	server_ip = ip
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(server_ip, PORT)
	if err != OK:
		push_error("NetworkManager: Failed to connect — error %d" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func disconnect_peer() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func request_matchmaking() -> void:
	rpc_id(1, "_server_request_matchmaking")

func cancel_matchmaking() -> void:
	rpc_id(1, "_server_cancel_matchmaking")

func quit_match() -> void:
	rpc_id(1, "_server_quit_match")

# Called by MatchmakingManager to notify specific clients
# ✅ Each method is explicit and typed — no more generic notify_client()
func notify_client_match_found(player_id: int, room_id: int) -> void:
	rpc_id(player_id, "_client_match_found", room_id)

func notify_client_status(player_id: int, status: String) -> void:
	rpc_id(player_id, "_client_matchmaking_status", status)

func notify_client_opponent_left(player_id: int) -> void:
	rpc_id(player_id, "_client_opponent_left")

# ---------------------------------------------------------------
# Multiplayer callbacks
# ---------------------------------------------------------------
func _on_peer_connected(id: int) -> void:
	print("🟢 Player connected: %d" % id)
	emit_signal("player_connected", id)
	rpc_id(id, "_client_welcome", id)

func _on_peer_disconnected(id: int) -> void:
	print("🔴 Player disconnected: %d" % id)
	emit_signal("player_disconnected", id)

func _on_connected_to_server() -> void:
	emit_signal("connected_to_server", multiplayer.get_unique_id())

func _on_connection_failed() -> void:
	emit_signal("connection_failed")

# ---------------------------------------------------------------
# RPCs — Server → Client  (authority calls these on clients)
# ---------------------------------------------------------------
@rpc("authority")
func _client_welcome(id: int) -> void:
	emit_signal("connected_to_server", id)

@rpc("authority")
func _client_match_found(room_id: int) -> void:
	emit_signal("match_found", room_id)

@rpc("authority")
func _client_matchmaking_status(status: String) -> void:
	emit_signal("matchmaking_status_changed", status)

@rpc("authority")
func _client_opponent_left() -> void:
	emit_signal("opponent_left")

# ---------------------------------------------------------------
# RPCs — Client → Server  (any_peer calls these on server)
# ---------------------------------------------------------------

# ✅ Removed _args: Array = [] — that was causing the checksum mismatch
@rpc("any_peer")
func _server_request_matchmaking() -> void:
	print("📥 Matchmaking requested by: %d" % multiplayer.get_remote_sender_id())
	MatchmakingManager.handle_request(multiplayer.get_remote_sender_id())

# ✅ Removed _args: Array = [] — that was causing the checksum mismatch
@rpc("any_peer")
func _server_cancel_matchmaking() -> void:
	print("❌ Matchmaking cancelled by: %d" % multiplayer.get_remote_sender_id())
	MatchmakingManager.handle_cancel(multiplayer.get_remote_sender_id())

@rpc("any_peer")
func _server_quit_match() -> void:
	print("🚪 Player %d is leaving their match" % multiplayer.get_remote_sender_id())
	MatchmakingManager.handle_quit(multiplayer.get_remote_sender_id())
