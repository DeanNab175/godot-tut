@tool
extends Node2D
class_name CarouselContainer

signal index_changed

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

@export var swipe_threshold: float = 50.0
@export var blocking_nodes: Array[Control] = []

var _touch_start: Vector2 = Vector2.ZERO
var _is_touching: bool = false
var _drag_offset: float = 0.0
var _is_dragging: bool = false
var _visual_offset_x: float = 0.0

var can_go_left: bool:
	get:
		return selected_index > 0

var can_go_right: bool:
	get:
		return position_offset_node != null and selected_index < position_offset_node.get_child_count() - 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
		_visual_offset_x = lerp(_visual_offset_x, 0.0, smoothing_speed * delta)
	else:
		var selected = position_offset_node.get_child(selected_index)
		var target_x = -(selected.position.x + selected.size.x / 2.0)
		
		if _is_dragging:
			_visual_offset_x = target_x + _drag_offset
		else:
			_visual_offset_x = lerp(_visual_offset_x, target_x, smoothing_speed * delta)
			
	position_offset_node.position.x = _visual_offset_x

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
		emit_signal("index_changed")

func _right():
	if can_go_right:
		selected_index += 1
		emit_signal("index_changed")
		
func _input(event: InputEvent) -> void:
	for node in blocking_nodes:
		if node.visible:
			return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_is_touching = true
			_is_dragging = true
		else:
			_is_touching = false
			_is_dragging = false
			_snap_to_nearest()

	elif event is InputEventScreenDrag and _is_touching:
		var swipe_delta = event.position.x - _touch_start.x
		_drag_offset = swipe_delta

func _snap_to_nearest() -> void:
	if !position_offset_node:
		return
	var card_width = position_offset_node.get_child(0).size.x + spacing
	var snapped_index = selected_index - round(_drag_offset / card_width)
	snapped_index = clamp(snapped_index, 0, position_offset_node.get_child_count() - 1)
	if snapped_index != selected_index:
		selected_index = snapped_index
		emit_signal("index_changed")
	_drag_offset = 0.0


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
