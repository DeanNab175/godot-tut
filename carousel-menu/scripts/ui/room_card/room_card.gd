extends Control

@onready var room_title: Label = %RoomTitle
@onready var bet_range_container = %BetRangeContainer
@onready var range_label: Label  = %BetRangeContainer/RangeContainer/RangeLabel
@onready var card_footer_container = %CardFooterContainer
@onready var play_button: Button = %CardFooterContainer/PlayButton
@onready var total_player_label: Label = %CardFooterContainer/TotalPlayerLabel

@onready var private_container = %PrivateContainer
#@onready var lock_icon: TextureRect = %LockIcon
@onready var private_label: Label = %PrivateLabel

#@export var card_data: RoomCardData
var _card_data: RoomCardData
@export var card_data: RoomCardData :
	set(value):
		_card_data = value
		if is_node_ready(): # ✅ only call setup if nodes exist
			setup(_card_data)

signal play_pressed(card_data: RoomCardData)

func _ready() -> void:
	if _card_data:
		setup(_card_data)

func setup(data: RoomCardData) -> void:
	_card_data = data
	room_title.text = data.title

	match data.card_type:
		RoomCardData.CardType.NORMAL:
			_setup_normal_card(data)
		RoomCardData.CardType.PRIVATE:
			_setup_private_card(data)

func _setup_normal_card(data: RoomCardData) -> void:
	# Show bet range + play button, hide lock UI
	bet_range_container.visible = true
	card_footer_container.visible = true
	private_container.visible = false
	#lock_icon.visible = false
	#private_label.visible = false
	modulate.a = 1.0  # fully visible

	#range_label.text = "%s - %s" % [
		#_format_number(data.bet_min),
		#_format_number(data.bet_max)
	#]
	
	# ✅ Guard against both being 0
	if data.bet_min == 0 and data.bet_max == 0:
		range_label.text = "TBD"
	else:
		range_label.text = "%s - %s" % [
			_format_number(data.bet_min),
			_format_number(data.bet_max)
		]
		
	total_player_label.text = "%d players" % data.total_players

func _setup_private_card(data: RoomCardData) -> void:
	# Hide bet range + play button, show lock UI
	bet_range_container.visible = false
	card_footer_container.visible = false
	private_container.visible = true
	#lock_icon.visible = true
	#private_label.visible = true
	modulate.a = 0.6  # dimmed like in your screenshot

	private_label.text = data.lock_label

func _on_play_button_pressed() -> void:
	emit_signal("play_pressed", card_data)

# Formats 75000 → "75,000" and 500000000 → "500M"
#func _format_number(n: int) -> String:
	#if n >= 1_000_000:
		#return "%dM" % (n / 1_000_000)
	#var s = str(n)
	#var result = ""
	#var count = 0
	#for i in range(s.length() - 1, -1, -1):
		#if count > 0 and count % 3 == 0:
			#result = "," + result
			#result = s[i] + result
			#count += 1
	#return result

func _format_number(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.1fB" % (float(n) / 1_000_000_000.0)
	if n >= 1_000_000:
		return "%.0fM" % (float(n) / 1_000_000.0)  # ✅ cast to float, fixes warning

	# Add thousands separators
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
