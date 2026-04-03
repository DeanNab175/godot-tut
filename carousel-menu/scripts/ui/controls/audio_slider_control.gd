extends Control

@export var audio_bus_name: String
@onready var audio_slider: HSlider = $AudioSlider

var audio_bus_id

func _ready() -> void:
	audio_slider.value_changed.connect(_on_value_changed)
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)

func _on_value_changed(new_value: float) -> void:
	var db = linear_to_db(new_value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
