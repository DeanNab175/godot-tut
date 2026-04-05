extends AnimationTree

signal toggle_on
signal toggle_off

@onready var animation_tree = self

func _ready():
	active = true
	
func _on_toggle_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		animation_tree["parameters/playback"].start("ToggleOn")
		await get_tree().create_timer(0.35).timeout
		emit_signal("toggle_on")
	else:
		animation_tree["parameters/playback"].travel("ToggleOff")
		await get_tree().create_timer(0.35).timeout
		emit_signal("toggle_off")
