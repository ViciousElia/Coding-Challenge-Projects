extends TextureButton

class_name FieldSquare

enum ButtonModes {ACTIVE, SUSPECTED, UNCERTAIN}
@export var mode : ButtonModes = ButtonModes.ACTIVE
@export_range(-1,8) var button_value: int = 0
@export var local_position : Vector2i = Vector2i.ZERO

@export var tile_set: TileSet
@export var tile_size: Vector2i = Vector2i(256, 256)
@export var border_size: Vector2i = Vector2i(32, 32)

var left_held  : bool = false
var right_held : bool = false

signal bombed(position : Vector2i)
signal cascade(position : Vector2i)
signal one_point_five_click_held(position: Vector2i)
signal one_point_five_click_unheld()
signal chord(position: Vector2i)

signal flag_changed(on_off: bool)

func _ready() -> void:
	_update_styles()
	pass
func _update_styles():
	var states : Dictionary = {"normal":0,"hover":0,"pressed":0,"disabled":0}
	var source = tile_set.get_source(0)
	match mode:
		ButtonModes.ACTIVE:
			states.normal = 10
			states.pressed = 13
			states.hover = 16
		ButtonModes.SUSPECTED:
			states.normal = 11
			states.pressed = 14
			states.hover = 17
		ButtonModes.UNCERTAIN:
			states.normal = 12
			states.pressed = 15
			states.hover = 18
	var texture_norm = AtlasTexture.new()
	texture_norm.atlas = source.texture
	texture_norm.region = source.get_tile_texture_region(Vector2i(states.normal,0))
	texture_normal = texture_norm
	var texture_press = AtlasTexture.new()
	texture_press.atlas = source.texture
	texture_press.region = source.get_tile_texture_region(Vector2i(states.pressed,0))
	texture_pressed = texture_press
	var texture_hov = AtlasTexture.new()
	texture_hov.atlas = source.texture
	texture_hov.region = source.get_tile_texture_region(Vector2i(states.hover,0))
	texture_hover = texture_hov
	
func _set_style():
	var state
	if button_value == -1:
		state = 9
	else:
		state = button_value
	var source = tile_set.get_source(0)
	var texture_norm = AtlasTexture.new()
	texture_norm.atlas = source.texture
	texture_norm.region = source.get_tile_texture_region(Vector2i(state,0))
	texture_disabled = texture_norm

func _on_gui_input (event: InputEvent):
	var mouse_pos = get_global_mouse_position()
	var button_rect = Rect2(global_position, size)
	if event is InputEventMouseButton:
		if !button_rect.has_point(mouse_pos):
			if !event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					left_held = false
				if event.button_index == MOUSE_BUTTON_RIGHT:
					right_held = false
					one_point_five_click_unheld.emit()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if right_held:
					one_point_five_click_held.emit(local_position)
				left_held = true
			else:
				if right_held:
					chord.emit(local_position)
				left_held = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if left_held:
					one_point_five_click_held.emit(local_position)
			else:
				if !left_held and !disabled:
					match mode:
						ButtonModes.ACTIVE:
							mode = ButtonModes.SUSPECTED
							button_mask = 0
							flag_changed.emit(true)
						ButtonModes.SUSPECTED:
							mode = ButtonModes.UNCERTAIN
							flag_changed.emit(false)
						ButtonModes.UNCERTAIN:
							button_mask = MOUSE_BUTTON_MASK_LEFT
							mode = ButtonModes.ACTIVE
					_update_styles()
				else:
					one_point_five_click_unheld.emit()
				right_held = false
			pass

func _on_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		return
	disabled = true
	if button_value == -1:
		bombed.emit(local_position)
	elif button_value == 0:
		cascade.emit(local_position)
