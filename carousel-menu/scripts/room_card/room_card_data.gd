class_name RoomCardData
extends Resource

enum CardType { NORMAL, PRIVATE }

@export var card_type: CardType = CardType.NORMAL
@export var title: String = "SHARK"
@export var bet_min: int = 3500
@export var bet_max: int = 75000
@export var total_players: int = 1809
@export var is_locked: bool = false
@export var lock_label: String = "Private Table"  # shown under title when locked
