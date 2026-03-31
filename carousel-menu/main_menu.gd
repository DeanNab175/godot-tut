extends Node2D

const RoomCard = preload("res://scenes/interface/room_card/room_card.tscn")

# Point directly to the Control inside CarouselContainer
@onready var carousel_container: CarouselContainer = %CarouselContainer
@onready var cards_control: Control = %CarouselContainer/Control
@onready var previous_button: Button = $CanvasLayer/MainControl/PreviousButton
@onready var next_button: Button = $CanvasLayer/MainControl/NextButton
@onready var exit_button: Button = $CanvasLayer/MainControl/MarginContainer/FooterContainer/ExitButton
@onready var settings_button: Button = $CanvasLayer/MainControl/MarginContainer/FooterContainer/SettingsButton
@onready var settings_back_button: Button = $CanvasLayer/SettingsContainer/VBoxContainer/SettingsHeaderContainer/MarginContainer/SettingsBackButton

@onready var main_control: Control = $CanvasLayer/MainControl
@onready var settings_container: PanelContainer = $CanvasLayer/SettingsContainer

func _ready() -> void:
	_populate_cards()
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	settings_back_button.pressed.connect(_on_settings_back_button_pressed)
	main_control.visible = true
	settings_container.visible = false
	carousel_container.index_changed.connect(_update_buttons)
	_update_buttons()

func _update_buttons() -> void:
	previous_button.disabled = !carousel_container.can_go_left
	next_button.disabled = !carousel_container.can_go_right

func _populate_cards() -> void:
	# 1. Remove all existing Panel nodes
	for child in cards_control.get_children():
		child.queue_free()

	# 2. Define your room data
	var rooms_data: Array = [
		{
			"card_type": RoomCardData.CardType.PRIVATE,
			"title": "Play with Friends",
			"lock_label": "Private Table",
			"is_locked": true
		},
		{
			"card_type": RoomCardData.CardType.NORMAL,
			"title": "SHARK",
			"bet_min": 3500,
			"bet_max": 75000,
			"total_players": 1809
		},
		{
			"card_type": RoomCardData.CardType.NORMAL,
			"title": "Joker",
			"bet_min": 15000,
			"bet_max": 500_000_000,
			"total_players": 509
		}
	]

	# 3. Instantiate and add each RoomCard
	for data in rooms_data:
		var card = RoomCard.instantiate()
		cards_control.add_child(card)
		card.setup(_make_card(data))
		card.play_pressed.connect(_on_play_pressed)
		
func _make_card(data: Dictionary) -> RoomCardData:
	var d = RoomCardData.new()
	d.card_type = data.get("card_type", RoomCardData.CardType.NORMAL)
	d.title      = data.get("title", "")
	d.is_locked  = data.get("is_locked", false)
	d.lock_label = data.get("lock_label", "")
	d.bet_min    = data.get("bet_min", 0)
	d.bet_max    = data.get("bet_max", 0)
	d.total_players = data.get("total_players", 0)
	return d

func _on_play_pressed(data: RoomCardData) -> void:
	print("Joining room: ", data.title)
	# Load your game scene here

func _on_previous_button_pressed() -> void:
	carousel_container._left()
	_update_buttons()

func _on_next_button_pressed() -> void:
	carousel_container._right()
	_update_buttons()

func _on_settings_button_pressed() -> void:
	main_control.visible = false
	settings_container.visible = true
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()
	
func _on_settings_back_button_pressed() -> void:
	main_control.visible = true
	settings_container.visible = false
