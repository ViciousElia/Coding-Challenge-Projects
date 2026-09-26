class_name StackableCard
extends CardStack
## An extension of [CardStack] specific to single card behaviour
##
## A specific class (as opposed to a generalised class) providing features of single
## cards, including suit, colour, value, and design, as well as certain behavioural cues.[br][br]
## Provides for explicit "flip" action, which is not animated at present, and extends
## card entry behaviour as defined by [CardStack] to handle local behaviours as well.[br][br]
## Explicitly handles how card stacking differs for face-up vs face-down cards.

## Card suit as defined in [Globals]. When it is set, the [member card_colour] is also set.
@export var card_suit : Globals.CardSuits :
	set(value):
		_card_colour = (value % len(Globals.CardColours)) as Globals.CardColours
		card_suit = value
## Card colour as defined in [Globals]. Private to the class, since it should only be 
## set in conjunction with the suit. This setup trusts that suits are arranged 
## appropriately compared to colours.
var _card_colour : Globals.CardColours
## Card value, limited by [Globals]. Strictly numeric so that it's easier to work
## against, since stack order requires counting up or down.
@export_range(1,Globals.CARD_VALUES_COUNT) var card_value : int

## Texture displayed when [member face_up] is true.
var _card_face : AtlasTexture
## Texture displayed when [member face_up] is false.
var card_back : AtlasTexture

var _held_card : bool = false
var _held_position : Vector2
var _held_offset : Vector2

signal lifted_card(which : StackableCard)
signal auto_send(which : StackableCard)

## Indicator for whether the card's value or back should be displayed.
var face_up : bool = false :
	set(value):
		if value:
			set_deferred("texture",_card_face)
			mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			set_deferred("texture",card_back)
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		face_up = value
		handle_overlap()

## On the @ready signal, this sets the card back texture.[br][br]
## These actions are in addition to the actions in [method CardStack._ready].
func _ready() -> void:
	super()
	var tile_source = Globals.tile_set.get_source(0)
	card_back = AtlasTexture.new()
	card_back.atlas = tile_source.texture
	card_back.region = tile_source.get_tile_texture_region(Vector2i(0,Globals.deck_style))
	texture = card_back
	add_to_group("all_cards")

## Assigns the value and suit of a card. At once, it assigns the appropriate face
## texture of the card.
func set_card(new_suit : Globals.CardSuits, new_value):
	card_suit = new_suit
	card_value = new_value
	var tile_source = Globals.tile_set.get_source(0)
	_card_face = AtlasTexture.new()
	_card_face.atlas = tile_source.texture
	_card_face.region = tile_source.get_tile_texture_region(Vector2i(card_value,card_suit))

## Listener for when a card is added to the stack. This extends the behaviour of
## the listener from [CardStack]. Updates the overlap value of the card. May require
## further actions later.
func _on_card_entered(node : StackableCard):
	node.handle_overlap()

## Overlap management. If the card lands on a non-card, its overlap is zeroed out.
## Otherwise, the new parent's [member face_up], [member overlap_face_up], [member overlap_face_down],
## and [member stack_direction] are used to apply the appropriate position for overlap.
func handle_overlap():
	var parent = get_parent()
	if not (parent is StackableCard):
		set_position(Vector2.ZERO)
		return
	var overlap_value = parent.overlap_face_up if parent.face_up else parent.overlap_face_down
	var basis = \
		Vector2(1,0) if parent.stack_direction == Globals.StackDirections.HORIZONTAL else \
		Vector2(0,1) if parent.stack_direction == Globals.StackDirections.VERTICAL else \
		Vector2.ZERO
	set_position(overlap_value * basis)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (drag_and_drop & Globals.DragAndDrop.DRAGGABLE) == 0:
			return
		if get_child_count()>0:
			if (drag_and_drop & Globals.DragAndDrop.DRAG_MANY) == 0:
				return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				if get_child_count() > 0:
					return
				auto_send.emit(self)
			elif event.pressed:
				grab_card(event.global_position)
				get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not _held_card:
		return
	elif event is InputEventMouseMotion:
		set_position(event.global_position - _held_offset)
		get_viewport().set_input_as_handled()

func drop_card(is_reparenting : bool = false):
	_held_card = false
	z_index = 0
	if not is_reparenting:
		position = _held_position
	else:
		handle_overlap()
	mouse_filter = MOUSE_FILTER_PASS
func grab_card(grab_position : Vector2):
	_held_card = true
	_held_position = position
	_held_offset = grab_position - position
	z_index = 4096
	lifted_card.emit(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pass
