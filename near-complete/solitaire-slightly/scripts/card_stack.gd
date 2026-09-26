class_name CardStack
extends TextureRect
## A generalised, extensible class for stacking cards.
##
## Provides members and methods for card stacks, generally, using globally defined
## datatypes, constants, and enumerations. Implements a default listener for adding
## new cards to a stack, which propagates relevant data to cards closer to the top.[br][br]
##
## Implemented features include stack type, direction, and order, as outlined in
## [Globals], drag-and-drop behaviour flags, overlap length for stacked cards, and
## an identifier for the card at the top of a stack.

# Begin stack property declarations

## Stack type as laid out in [Globals]. All stacks have this export, but it should
## be used sparingly on base stacks (deck, goal, field, discard).
@export var stack_type : Globals.StackTypes
## Stack direction as laid out in [Globals]. All stacks have this export, but it should
## be used sparingly on base stacks (deck, goal, field, discard).
@export var stack_direction : Globals.StackDirections
## Stack order as laid out in [Globals]. All stacks have this export, but it should
## be used sparingly on base stacks (deck, goal, field, discard).
@export var stack_order : Globals.StackOrders
## Flag set for indicating drag-and-drop behaviour. Based on [enum Globals.DragAndDrop]
## enumeration, and aligns directly with it.
@export_flags(
	"DRAGGABLE",
	"DROPPABLE",
	"DRAG_MANY",
	"DROP_MANY"
) var drag_and_drop = 0
## Size of overlap when cards are face up. Applies to the child of the stack,
## not the stack itself.
@export var overlap_face_up : float
## Size of overlap when cards are face down. Applies to the child of the stack,
## not the stack itself.
@export var overlap_face_down : float
var top_card : CardStack

# Begin method definitions.

func _ready() -> void:
	child_entered_tree.connect(_on_card_stack_entered)
	child_exiting_tree.connect(_on_card_stack_exiting)
	top_card = self

## Listener for gaining new cards in a stack. This is automatically connected in
## the [method _ready] function, which is called as super() from all derived classes.
## Any behaviour that applies to all card types should exist here.
func _on_card_stack_entered(node : CardStack):
	propagate_data(node)

## Listener for losing cards in a stack. This is automatically connected in the
## [method _ready] function, which is called as super() from all derived classes.
## The primary function is to reassign [member top_card] when the card leaves. By
## fixing this behaviour, some odd edge cases were fixed.
func _on_card_stack_exiting(node : CardStack):
	node.set_position(Vector2.ZERO)
	var parent = node.get_parent()
	var new_top_card = parent
	while parent is CardStack:
		parent.top_card = new_top_card
		parent = parent.get_parent()

## Passes the exportable properties of the stack to the provided node and recursively
## to its children. Due to the underlying structure, this is safe recursion, as
## a stack's maximum size is generally 20, except for the deck, which admits up to 52.
func propagate_data(node : CardStack):
	node.stack_type = stack_type
	node.stack_direction = stack_direction
	node.stack_order = stack_order
	node.overlap_face_up = overlap_face_up
	node.overlap_face_down = overlap_face_down
	node.drag_and_drop = drag_and_drop
	if (node.get_child_count() > 0):
		propagate_data(node.get_child(0))
	else:
		top_card = node
		var parent = node.get_parent()
		while parent is CardStack:
			parent.top_card = node
			parent = parent.get_parent()
