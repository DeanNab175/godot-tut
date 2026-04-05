extends Control

@onready var animation_tree: AnimationTree = $ToggleButton/AnimationTree
@onready var label: Label = $Label

@export var active_label: String = "On"
@export var inactive_label: String = "Off"

func _ready() -> void:
	label.text = inactive_label
	animation_tree.toggle_on.connect(_on_toggled_on)
	animation_tree.toggle_off.connect(_on_toggled_off)
	
func _on_toggled_on() -> void:
	label.text = active_label
	
func _on_toggled_off() -> void:
	label.text = inactive_label
