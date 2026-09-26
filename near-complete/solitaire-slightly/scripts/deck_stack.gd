class_name DeckStack
extends CardStack
## An extension of [CardStack] specific to the primary deck
##
## A specific class (as opposed to a generalised class) providing features of the
## draw deck, including shuffling the cards and dealing them out.[br][br]
## Includes signals for sending and receiving cards.[br][br]
## Explicitly handles how card stacking differs for face-up vs face-down cards.

## Signal emitted to pass cards to any other destination. Default behaviour assumes[br]
## - 0 - pass to discard[br]
## - 1 - pass to field[br]
## - default - pass to discard[br]
## This can be extended as needed.
signal pass_cards(new_cards:Array[StackableCard],destination:int)
## Signal emitted to indicate the stack is empty and must retrieve cards from somewhere.
## By default, [GameBoard] must make this decision.
signal pull_cards()

signal ready_to_deal()

## On the @ready signal, this sets the overlap lengths and the placeholder texture.
## In development and debug, this also calls [method new_game] to create the deck,
## shuffle the cards, and set a signal to deal. Before shipping, this function call
## should be offloaded to [GameBoard].[br][br]
## These actions are in addition to the actions in [method CardStack._ready].
func _ready() -> void:
	super()
	overlap_face_down = Globals.CARD_OVERLAP_EDGE
	overlap_face_up = Globals.CARD_OVERLAP_INVISIBLE
	var tile_source = Globals.tile_set.get_source(1)
	texture = AtlasTexture.new()
	texture.atlas = tile_source.texture
	texture.region = tile_source.get_tile_texture_region(Vector2i(1,0))

## Runs cleaning operation to ensure a fresh deck of cards. Similar functions should
## exist across all non-card stacks.
func end_game():
	if get_child_count()>0:
		get_child(0).queue_free()

## Builds the deck, shuffles it, then stacks the cards in the deck. In the future,
## this will need to also emit [signal pass_cards] to the top 28 cards for dealing
## to the field stacks.
func new_game():
	var deck : Array[StackableCard]
	for value in range(1,Globals.CARD_VALUES_COUNT+1):
		for suit in range(len(Globals.CardSuits)):
			var new_card = Globals.StackableCards.instantiate()
			new_card.set_card(suit,value)
			deck.push_back(new_card)
	deck.shuffle()
	for card_idx in range(len(deck)):
		var this_card = deck[card_idx]
		top_card.add_child(this_card)
	$ActionButton.custom_minimum_size.x = custom_minimum_size.x+51
	$ActionButton.move_to_front()
	ready_to_deal.emit()

## Handles the action of clicking the deck. Since the deck is not draggable or
## droppable, the button behaviour is the only gui_input event we need to handle.
func _on_action_button_pressed() -> void:
	if top_card == self:
		pull_cards.emit()
	else:
		var new_cards : Array[StackableCard]
		for i in range(Globals.discard_count):
			new_cards.push_back(top_card)
			if top_card.get_parent() is CardStack:
				top_card = top_card.get_parent()
			if top_card == self:
				break
		pass_cards.emit(new_cards,0)

## Moves cards into the stack from bottom (idx=0) to top (idx=count-1). Should only
## be called from [GameBoard], but technically, could be called from [method new_game].
func add_cards(new_cards:Array[StackableCard]):
	for i in range(len(new_cards)):
		if new_cards[i].face_up:
			new_cards[i].face_up = false
		new_cards[i].reparent(top_card,false)
	$ActionButton.move_to_front()
