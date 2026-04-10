# This node only does meaningful work when running as server.
extends Node

# ---------------------------------------------------------------
# Signals
# ---------------------------------------------------------------
signal room_created(room_id: int, players: Array)
signal player_queued(player_id: int)
signal player_dequeued(player_id: int)

# ---------------------------------------------------------------
# State
# ---------------------------------------------------------------
var _waiting_player: int = -1          # -1 = nobody waiting
var _searching: Dictionary = {}        # player_id → true
var _rooms: Dictionary = {}            # room_id → { players, state }
var _player_rooms: Dictionary = {}     # player_id → room_id
var _room_counter: int = 1

# ---------------------------------------------------------------
# Public API (called by NetworkManager RPCs)
# ---------------------------------------------------------------
func handle_request(player_id: int) -> void:
	if not multiplayer.is_server():
		return

	if _searching.has(player_id):
		print("⚠️ Player %d already searching" % player_id)
		push_warning("MatchmakingManager: Player %d already searching" % player_id)
		return

	_searching[player_id] = true
	print("🔎 Player %d added to queue" % player_id)
	emit_signal("player_queued", player_id)

	if _waiting_player == -1:
		_waiting_player = player_id
		print("⏳ Player %d is waiting for opponent..." % player_id)
		_notify_client(player_id, "_client_matchmaking_status", ["waiting"])
	else:
		print("✅ Pairing player %d with player %d" % [_waiting_player, player_id])
		_create_room(_waiting_player, player_id)
		_waiting_player = -1


func handle_cancel(player_id: int) -> void:
	if not multiplayer.is_server():
		return

	if _waiting_player == player_id:
		_waiting_player = -1

	_searching.erase(player_id)
	print("❌ Player %d cancelled matchmaking" % player_id)
	emit_signal("player_dequeued", player_id)
	_notify_client(player_id, "_client_matchmaking_status", ["cancelled"])


func handle_disconnect(player_id: int) -> void:
	print("🔌 Handling disconnect for player %d" % player_id)
	
	if _waiting_player == player_id:
		_waiting_player = -1
		print("⏳ Removed player %d from waiting queue" % player_id)

	_searching.erase(player_id)

	if _player_rooms.has(player_id):
		var room_id: int = _player_rooms[player_id]
		print("🏚️ Dissolving room %d due to player %d leaving" % [room_id, player_id])
		_dissolve_room(room_id, player_id)


func get_room(room_id: int) -> Dictionary:
	return _rooms.get(room_id, {})


func get_player_room_id(player_id: int) -> int:
	return _player_rooms.get(player_id, -1)

# ---------------------------------------------------------------
# Internal
# ---------------------------------------------------------------
func _create_room(p1: int, p2: int) -> void:
	var room_id := _room_counter
	_room_counter += 1

	_rooms[room_id] = {
		"players": [p1, p2],
		"state": "lobby",       # lobby → in_game → finished
		"scores": { p1: 0, p2: 0 }
	}
	_player_rooms[p1] = room_id
	_player_rooms[p2] = room_id

	_searching.erase(p1)
	_searching.erase(p2)

	print("🏠 Room %d created — Players: [%d, %d]" % [room_id, p1, p2])
	emit_signal("room_created", room_id, [p1, p2])

	_notify_client(p1, "_client_match_found", [room_id])
	_notify_client(p2, "_client_match_found", [room_id])


func _dissolve_room(room_id: int, leaving_player: int) -> void:
	if not _rooms.has(room_id):
		return

	var room: Dictionary = _rooms[room_id]
	for p in room["players"]:
		_player_rooms.erase(p)
		if p != leaving_player:
			print("📢 Notifying player %d that opponent left" % p)
			_notify_client(p, "_client_opponent_left", [])

	_rooms.erase(room_id)


func _notify_client(player_id: int, rpc_method: String, args: Array) -> void:
	# Calls an RPC method on NetworkManager located on a specific client
	NetworkManager.notify_client(player_id, rpc_method, args)
