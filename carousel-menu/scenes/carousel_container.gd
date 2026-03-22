@tool
extends Node2D
class_name CarouselContainer

@export var spacing: float = 20.0

@export var wraparound_enabled: bool = false
@export var wraparound_radius: float = 300.0
@export var wraparound_height: float = 50.0

@export_range(0.0, 1.0) var opacity_strength: float = 0.35
@export_range(0.0, 1.0) var scale_strength: float = 0.25
@export_range(0.01, 0.99, 0.01) var scale_min: float = 0.1

@export var smoothing_speed: float = 6.5
@export var selected_index: int = 0
@export var follow_button_focus: bool = false

@export var position_offset_node: Control = null

var can_go_left: bool:
	get:
		return selected_index > 0

var can_go_right: bool:
	get:
		return position_offset_node != null and selected_index < position_offset_node.get_child_count() - 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !position_offset_node or position_offset_node.get_child_count() == 0:
		return
	selected_index = clamp(selected_index, 0, position_offset_node.get_child_count() - 1)
	
	for i in position_offset_node.get_children():
		if wraparound_enabled:
			_process_wraparound(i, delta)
		else:
			_process_linear(i, delta)
	
	if wraparound_enabled:
		position_offset_node.position.x = lerp(position_offset_node.position.x, 0.0, smoothing_speed * delta)
	else:
		var selected = position_offset_node.get_child(selected_index)
		position_offset_node.position.x = lerp(position_offset_node.position.x, -(selected.position.x + selected.size.x / 2.0), smoothing_speed * delta)

func _process_wraparound(i: Control, delta: float) -> void:
	var child_count = position_offset_node.get_child_count()
	var angle = (i.get_index() - selected_index) * (2.0 * PI / child_count)
	var target_pos = Vector2(sin(angle) * wraparound_radius, -cos(angle) * wraparound_height) - i.size / 2.0
	i.pivot_offset = i.size / 2.0
	i.position = lerp(i.position, target_pos, smoothing_speed * delta)

	var dist = min(abs(i.get_index() - selected_index), child_count - abs(i.get_index() - selected_index))
	_apply_visuals(i, dist, delta)


func _process_linear(i: Control, delta: float) -> void:
	var position_x = 0.0
	if i.get_index() > 0:
		var prev = position_offset_node.get_child(i.get_index() - 1)
		position_x = prev.position.x + prev.size.x + spacing
	i.position = Vector2(position_x, -i.size.y / 2.0)
	i.pivot_offset = i.size / 2.0

	var dist = abs(i.get_index() - selected_index)
	_apply_visuals(i, dist, delta)

	if follow_button_focus and i.has_focus():
		selected_index = i.get_index()


func _apply_visuals(i: Control, dist: int, delta: float) -> void:
	var target_scale = clamp(1.0 - (scale_strength * dist), scale_min, 1.0)
	i.scale = lerp(i.scale, Vector2.ONE * target_scale, smoothing_speed * delta)

	var target_opacity = clamp(1.0 - (opacity_strength * dist), 0.0, 1.0)
	i.modulate.a = lerp(i.modulate.a, target_opacity, smoothing_speed * delta)

	var child_count = position_offset_node.get_child_count()
	i.z_index = child_count - dist


func _left():
	if can_go_left:
		selected_index -= 1

func _right():
	if can_go_right:
		selected_index += 1

# Usage example
#$ArrowLeft.disabled = !$CarouselContainer.can_go_left
#$ArrowRight.disabled = !$CarouselContainer.can_go_right
#func _left():
	#selected_index -= 1
	#if selected_index < 0:
		#selected_index += 1
#
#func _right():
	#selected_index += 1
	#if selected_index > position_offset_node.get_child_count() - 1:
		#selected_index -= 1
