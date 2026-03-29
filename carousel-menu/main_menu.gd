extends Node2D

const RoomCard = preload("res://scenes/interface/room_card/room_card.tscn")

# Point directly to the Control inside CarouselContainer
@onready var cards_control: Control = %CarouselContainer/Control
@onready var previous_button: Button = $CanvasLayer/MainControl/PreviousButton
@onready var next_button: Button = $CanvasLayer/MainControl/NextButton
@onready var exit_button: Button = $CanvasLayer/MainControl/MarginContainer/FooterContainer/ExitButton
@onready var settings_button: Button = $CanvasLayer/MainControl/MarginContainer/FooterContainer/SettingsButton
@onready var settings_back_button: Button = $CanvasLayer/SettingsContainer/VBoxContainer/SettingsHeaderContainer/MarginContainer/SettingsBackButton


@onready var main_control: Control = $CanvasLayer/MainControl
@onready var settings_container: PanelContainer = $CanvasLayer/SettingsContainer



func _ready() -> void:
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	settings_back_button.pressed.connect(_on_settings_back_button_pressed)
	main_control.visible = true
	settings_container.visible = false
	_populate_cards()
	_update_buttons()

func _update_buttons() -> void:
	previous_button.disabled = !%CarouselContainer.can_go_left
	next_button.disabled = !%CarouselContainer.can_go_right

func _populate_cards() -> void:
	# 1. Remove all existing Panel nodes
	for child in cards_control.get_children():
		child.queue_free()

	# 2. Define your room data
	var rooms: Array[RoomCardData] = [
		_make_private_card(),
		_make_shark_card(),
		_make_joker_card(),
	]

	# 3. Instantiate and add each RoomCard
	for data in rooms:
		var card = RoomCard.instantiate()
		cards_control.add_child(card)
		card.setup(data)
		card.play_pressed.connect(_on_play_pressed)

func _make_private_card() -> RoomCardData:
	var d = RoomCardData.new()
	d.card_type = RoomCardData.CardType.PRIVATE
	d.title = "Play with Friends"
	d.lock_label = "Private Table"
	d.is_locked = true
	return d

func _make_shark_card() -> RoomCardData:
	var d = RoomCardData.new()
	d.card_type = RoomCardData.CardType.NORMAL
	d.title = "SHARK"
	d.bet_min = 3500
	d.bet_max = 75000
	d.total_players = 1809
	return d

func _make_joker_card() -> RoomCardData:
	var d = RoomCardData.new()
	d.card_type = RoomCardData.CardType.NORMAL
	d.title = "Joker"
	d.bet_min = 15000
	d.bet_max = 500_000_000
	d.total_players = 1809
	return d

func _on_play_pressed(data: RoomCardData) -> void:
	print("Joining room: ", data.title)
	# Load your game scene here

func _on_previous_button_pressed() -> void:
	%CarouselContainer._left()
	_update_buttons()

func _on_next_button_pressed() -> void:
	%CarouselContainer._right()
	_update_buttons()

func _on_settings_button_pressed() -> void:
	main_control.visible = false
	settings_container.visible = true
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()
	
func _on_settings_back_button_pressed() -> void:
	main_control.visible = true
	settings_container.visible = false
