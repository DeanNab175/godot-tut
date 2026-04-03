extends Control

signal back_pressed

@onready var back_button: Button = %SettingsBackButton  # use unique name %

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	emit_signal("back_pressed")
