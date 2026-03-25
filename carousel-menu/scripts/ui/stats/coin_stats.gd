extends Control

@onready var label: Label = $PanelContainer/MarginContainer/HBoxContainer/TextFrame/Label

func set_value(value: String) -> void:
	label.text = value
