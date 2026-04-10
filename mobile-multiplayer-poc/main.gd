extends Node

# Future hooks you might add here:
#   - Scene transition coordinator
#   - Game state machine (lobby → in_game → results)

func _ready() -> void:
	# Wire MatchmakingManager into NetworkManager's disconnect events
	# so the server cleans up rooms when players drop.
	NetworkManager.player_disconnected.connect(
		MatchmakingManager.handle_disconnect
	)
