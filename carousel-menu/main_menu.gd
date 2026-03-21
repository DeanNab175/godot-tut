extends Node2D


func _on_previous_button_pressed() -> void:
	%CarouselContainer._left()


func _on_next_button_pressed() -> void:
	%CarouselContainer._right()


func _on_play_pressed() -> void:
	print("Play now")
