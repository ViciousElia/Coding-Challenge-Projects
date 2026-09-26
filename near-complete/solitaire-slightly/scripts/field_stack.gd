class_name FieldStack
extends CardStack

signal drop_zone_active(which : FieldStack)
signal drop_zone_inactive(which : FieldStack)

func _ready() -> void:
	super()
	overlap_face_down = Globals.CARD_OVERLAP_SIDE
	overlap_face_up = Globals.CARD_OVERLAP_VISIBLE
	var tile_source = Globals.tile_set.get_source(1)
	texture = AtlasTexture.new()
	texture.atlas = tile_source.texture
	texture.region = tile_source.get_tile_texture_region(Vector2i(1,1))

func add_cards(new_cards:Array[StackableCard]):
	for i in range(len(new_cards)):
		if new_cards[i].face_up:
			new_cards[i].face_up = false
		new_cards[i].reparent(top_card,false)
	new_cards.back().face_up = true

func _on_action_button_pressed() -> void:
	if top_card == self:
		return
	if not (top_card.face_up):
		top_card.face_up = true

func _on_mouse_entered() -> void:
	drop_zone_active.emit(self)

func _on_mouse_exited() -> void:
	drop_zone_inactive.emit(self)
