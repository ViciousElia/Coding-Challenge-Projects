class_name GameWindow
extends VBoxContainer

var card_back : AtlasTexture
var tile_source : TileSetSource

func _ready() -> void:
	tile_source = Globals.tile_set.get_source(0)
	card_back = AtlasTexture.new()
	card_back.atlas = tile_source.texture
	card_back.region = tile_source.get_tile_texture_region(Vector2i(0,Globals.deck_style))
	for idx in $HBoxContainer/DeckSelector.get_child_count():
		$HBoxContainer/DeckSelector.get_child(idx).texture_normal = AtlasTexture.new()
		$HBoxContainer/DeckSelector.get_child(idx).texture_normal.atlas = tile_source.texture
		$HBoxContainer/DeckSelector.get_child(idx).texture_normal.region = tile_source.get_tile_texture_region(Vector2i(0,idx))
	var new_source = Globals.tile_set.get_source(1)
	for idx in $HBoxContainer/CountSelector.get_child_count():
		$HBoxContainer/CountSelector.get_child(idx).texture_normal = AtlasTexture.new()
		$HBoxContainer/CountSelector.get_child(idx).texture_normal.atlas = new_source.texture
		$HBoxContainer/CountSelector.get_child(idx).texture_normal.region = new_source.get_tile_texture_region(Vector2i(2,1+idx))
		

func _on_deck_1_pressed():
	Globals.deck_style = 0
	reset_deck_style(0)
func _on_deck_2_pressed():
	Globals.deck_style = 1
	reset_deck_style(1)
func _on_deck_3_pressed():
	Globals.deck_style = 2
	reset_deck_style(2)
func _on_deck_4_pressed():
	Globals.deck_style = 3
	reset_deck_style(3)
func _on_deal_1_pressed():
	Globals.discard_count = 1
func _on_deal_2_pressed():
	Globals.discard_count = 2
func _on_deal_3_pressed():
	Globals.discard_count = 3

func reset_deck_style(new_style : int):
	card_back.region = tile_source.get_tile_texture_region(Vector2i(0,new_style))
	for card in get_tree().get_nodes_in_group("all_cards"):
		card.card_back = card_back
		if not card.face_up:
			card.set_deferred("texture",card_back)
