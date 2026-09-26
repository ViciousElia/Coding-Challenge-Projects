class_name GoalStack
extends CardStack

signal drop_zone_active(which : GoalStack)
signal drop_zone_inactive(which : GoalStack)

var card_suit : Globals.CardSuits

func _ready() -> void:
	super()
	overlap_face_down = Globals.CARD_OVERLAP_INVISIBLE
	overlap_face_up = Globals.CARD_OVERLAP_INVISIBLE
	set_suit(3 as Globals.CardSuits)

func set_suit(suit : Globals.CardSuits):
	card_suit = suit
	var tile_source = Globals.tile_set.get_source(1)
	texture = AtlasTexture.new()
	texture.atlas = tile_source.texture
	texture.region = tile_source.get_tile_texture_region(Vector2i(0,suit as int))

func _on_mouse_entered() -> void:
	drop_zone_active.emit(self)

func _on_mouse_exited() -> void:
	drop_zone_inactive.emit(self)
