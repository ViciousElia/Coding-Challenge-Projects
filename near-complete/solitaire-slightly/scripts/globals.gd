class_name Globals
extends Node

# Begin type declarations

## Stacking directions for various card stack behaviours.
enum StackDirections {
	FLUSH, ## Cards stack directly on top of each other, showing no overlap
	HORIZONTAL, ## Cards stack with an overlap to the right (negative) or left (positive)
	VERTICAL ## Cards stack with an overlap below (negative) or above (positive)
}
## Stacking types for various card stack behaviours.[br][br]
## This may need extension for other games such as Free Cell or Spider or for the
## case of new card colours and stacking conditions (see Set and other games).
enum StackTypes {
	NOTHING, ## Manual stacking by the player is not allowed
	ALTERNATE, ## Player must stack cards with alternating colours
	SUIT ## Player must stack cards with matching suits
}
## Card suits used in modern playing cards. They are essentially just integers.
## The names are strictly stand-ins, and the design of the card determines the
## user experience of these suits.[br][br]
## More colours may be added as desired, but logic in [StackableCard] must be updated.
enum CardSuits {
	SPADES, ## First black suit. Suit-index: 0, Colour-index: 0
	HEARTS, ## First red suit. Suit-index: 1, Colour-index: 1
	CLUBS, ## Second black suit. Suit-index: 2, Colour-index: 0
	DIAMONDS ## Second black suit. Suit-index: 3, Colour-index: 1
}
## Card colours. By default, this is set with just black and red, but these are
## entirely arbitrary. More colours may be added as desired, but logic in [StackableCard]
## must be updated. Current assumptions set colour based on the value of suit using
## modulo 2 division.
enum CardColours {
	BLACK, ## First card colour. Colour-index: 0, Suit-indices: 0,2
	RED ## Second card colour. Colour-index: 1, Suit-indices: 1,3
}
## How cards are arranged within their stack types.
enum StackOrders {
	NONE, ## Stack may be in any order, as decided by the player
	FORWARD, ## Player must stack so values track from low to high (Ace, 2, 3, ..., King)
	REVERSE ## Player must stack so values track from high to low (King, Queen, ..., 2, Ace)
}
## Bit flags for DragAndDrop behaviour in [CardStack] logic. Used with
## [member CardStack.drag_and_drop] in gui_input events to determine whether a given input
## is valid.
enum DragAndDrop {
	DRAGGABLE=1, ## Indicates whether the stack allows dragging [i]from[/i]
	DROPPABLE=2, ## Indicates whether the stack allows dropping [i]into[/i]
	DRAG_MANY=4, ## Indicates whether the stack allows dragging multiple cards. Ignored if DRAGGABLE is unset.
	DROP_MANY=8 ## Indicates whether the stack allows dropping multiple cards. Ignored if DROPPABLE is unset.
}

# Begin constant definitions

## Number of cards per suit in the deck as a whole
const CARD_VALUES_COUNT = 13 as int
## Global overlap value for edges only
const CARD_OVERLAP_EDGE = 0.5 as float
## Global overlap value for edges with decoration
const CARD_OVERLAP_SIDE = 15.0 as float
## Global overlap value to show the card identity
const CARD_OVERLAP_VISIBLE = 40.0 as float
## Global overlap value to fully hide the card below
const CARD_OVERLAP_INVISIBLE = 0.0 as float

# Begin variable declaration and initialisation

## Global setting for selecting which card back design should be used
static var deck_style : int = 0
## A global flag used to indicate the deck is in the process of being moved so that
## actions taken on remove_card are held
static var resetting_deck : bool = false
## Global setting for how many cards are pulled on dealing from deck into the discard
## pile. Vaguely represents difficulty setting in Klondike-style solitaire
static var discard_count : int = 3

# Begin preloads

## The static [TileSet] containing the deck backs and card faces assuming a standard
## 52 card deck spanning 13 values for each of 4 suits. This can be updated to
## use a different format, and it must be updated if the deck geometry is changed.
static var tile_set := preload("res://resources/card_decks.tres") as TileSet
## A reusable preload for [StackableCard] that allows us to generate cards within
## any card stack as necessary.
static var StackableCards = preload("res://scenes/stackable_card.tscn")
