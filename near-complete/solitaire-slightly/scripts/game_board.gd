class_name GameBoard
extends VBoxContainer

@onready var discard_stack = $TopRow/DeckAndDiscard/DiscardStack
@onready var deck_stack = $TopRow/DeckAndDiscard/DeckStack
@onready var field_container = $FieldContainer
@onready var goal_container = $TopRow/GoalContainer

var _hovered : CardStack
var _held_card : StackableCard

func _ready() -> void:
	deck_stack.new_game()
	for child in field_container.get_children():
		if not (child is CardStack):
			continue
		child.connect("drop_zone_active",_on_field_drop_zone_active)
		child.connect("drop_zone_inactive",_on_field_drop_zone_inactive)
	for idx in range(goal_container.get_child_count()):
		if not (goal_container.get_child(idx) is CardStack):
			continue
		goal_container.get_child(idx).set_suit(int(idx/2))
		goal_container.get_child(idx).connect("drop_zone_active",_on_field_drop_zone_active)
		goal_container.get_child(idx).connect("drop_zone_inactive",_on_field_drop_zone_inactive)

func _on_deck_stack_pass_cards(new_cards: Array[StackableCard],destination: int) -> void:
	if destination != 0:
		return
	discard_stack.add_cards(new_cards)

func _on_deck_stack_pull_cards() -> void:
	if discard_stack.top_card == discard_stack:
		return
	var new_cards = discard_stack.remove_cards()
	deck_stack.add_cards(new_cards)

func _on_deck_stack_ready_to_deal() -> void:
	for card in get_tree().get_nodes_in_group("all_cards"):
		card.lifted_card.connect(_on_card_lifted)
		card.auto_send.connect(_on_auto_send)
	var next_card = deck_stack.top_card
	var card_count = 1
	for child in field_container.get_children():
		if not (child is CardStack):
			continue
		var cards_to_pass : Array[StackableCard] = []
		for counter in range(card_count):
			cards_to_pass.push_back(next_card)
			next_card = next_card.get_parent()
		child.add_cards(cards_to_pass)
		card_count = card_count + 1

func _on_field_drop_zone_active(which : CardStack):
	_hovered = which
func _on_field_drop_zone_inactive(which : CardStack):
	if _hovered == which:
		_hovered = null

func _on_card_lifted(which : StackableCard):
	_held_card = which
	pass

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed:
			if _held_card == null:
				return
			elif _hovered == null:
				drop_card()
				return
			if (_hovered.drag_and_drop & Globals.DragAndDrop.DROPPABLE) == 0:
				drop_card()
			if _held_card.get_child_count()>0:
				if (_hovered.drag_and_drop & Globals.DragAndDrop.DROP_MANY) == 0:
					drop_card()
			var top = _hovered.top_card
			
			if top.stack_order == Globals.StackOrders.NONE:
				drop_card()
				return
			if top.stack_type == Globals.StackTypes.NOTHING:
				drop_card()
				return
			if top is StackableCard:
				if not top.face_up:
					drop_card()
					return
				if top.stack_type == Globals.StackTypes.ALTERNATE:
					if top._card_colour == _held_card._card_colour:
						drop_card()
						return
				if top.stack_type == Globals.StackTypes.SUIT:
					if top.card_suit != _held_card.card_suit:
						drop_card()
						return
				if top.stack_order == Globals.StackOrders.FORWARD:
					if top.card_value >= _held_card.card_value or top.card_value < _held_card.card_value-1:
						drop_card()
						return
				if top.stack_order == Globals.StackOrders.REVERSE:
					if top.card_value <= _held_card.card_value or top.card_value > _held_card.card_value+1:
						drop_card()
						return
			else:
				if top.stack_order == Globals.StackOrders.REVERSE:
					if _held_card.card_value < Globals.CARD_VALUES_COUNT:
						drop_card()
						return
				if top.stack_order == Globals.StackOrders.FORWARD:
					if _held_card.card_value > 1:
						drop_card()
						return
				if "card_suit" in top:
					if top.card_suit != _held_card.card_suit:
						if top.stack_type == Globals.StackTypes.SUIT:
							drop_card()
							return
			_held_card.reparent(top)
			drop_card(true)

func drop_card(is_reparenting : bool = false):
	_held_card.drop_card(is_reparenting)
	_held_card = null

func _on_auto_send(which : StackableCard):
	var suit = which.card_suit
	var value = which.card_value
	var goal = goal_container.get_child(suit * 2)
	if goal.top_card == goal:
		if value == 1:
			which.reparent(goal)
			which.handle_overlap()
	elif goal.top_card.card_value == value - 1:
			which.reparent(goal.top_card)
			which.handle_overlap()
