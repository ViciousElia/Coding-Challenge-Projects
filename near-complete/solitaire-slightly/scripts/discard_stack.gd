class_name DiscardStack
extends CardStack
## An extension of [CardStack] specific to the discard stack
##
## A specific class (as opposed to a generalised class) providing features of the
## discard stack, including handling of several cards fanned out, and flipping cards
## when adding or removing signal cards.[br][br]
## Explicitly handles how card stacking differs for face-up vs face-down cards.

## On the @ready signal, this sets the overlap lengths and the placeholder texture.[br][br]
## These actions are in addition to the actions in [method CardStack._ready].
func _ready() -> void:
	super()
	overlap_face_down = Globals.CARD_OVERLAP_INVISIBLE
	overlap_face_up = Globals.CARD_OVERLAP_VISIBLE
	var tile_source = Globals.tile_set.get_source(1)
	texture = AtlasTexture.new()
	texture.atlas = tile_source.texture
	texture.region = tile_source.get_tile_texture_region(Vector2i(1,1))

## Flips all cards face down, then adds new cards to the top of the stack. Should
## only be called from [GameBoard], generally.
func add_cards(new_cards:Array[StackableCard]):
	if not (top_card == self):
		var flip_card = get_child(0)
		while flip_card is StackableCard:
			if flip_card.face_up:
				flip_card.face_up = false
			if flip_card.get_child_count() > 0:
				flip_card = flip_card.get_child(0)
			else:
				break
	for i in range(len(new_cards)):
		new_cards[i].face_up = true
		new_cards[i].reparent(top_card,false)
		new_cards[i].connect("child_exiting_tree",_on_card_leaving)

## Listener for cards being pulled from the stack. May not be a viable method for
## flipping the top card face up. Will have to test.
func _on_card_leaving(node: Node) -> void:
	if Globals.resetting_deck:
		return
	top_card = node.get_parent()
	if top_card is StackableCard:
		if not top_card.face_up:
			top_card.face_up = true
	node.disconnect("child_exiting_tree",_on_card_leaving)

## Runs cleaning operation to ensure a fresh deck of cards. Similar functions should
## exist across all non-card stacks.
func end_game():
	if get_child_count()>0:
		get_child(0).queue_free()

## Puts all cards from the stack into an array and returns the array for use by
## [GameBoard] to move cards back to [DeckStack].
func remove_cards() -> Array[StackableCard]:
	var all_cards : Array[StackableCard] = []
	var current = top_card
	while current is StackableCard:
		all_cards.push_back(current)
		current = current.get_parent()
	return all_cards
