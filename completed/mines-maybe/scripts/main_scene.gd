extends Control

const FieldSquareScene = preload("res://field_square.tscn")

@onready var grid_container = $PrimaryLayouter/GameArea/BackPanel/FieldGrid

signal won_game(play_time: float)

## Defines the number of mines for standard modes and a negative flag for custom mode.
enum GameModes {CUSTOM=-1, BEGIN=10, ADVANCE=40, EXPERT=99}

## Defines where the game's config should live. 
const CONFIG_PATH = "user://config.cfg"
## Defines all normal modes as constants. All later usage refers back to this const.
const GAME_MODES = {
	GameModes.BEGIN   : { "x": 9,  "y": 9,  "mines": 10 },
	GameModes.ADVANCE : { "x": 16, "y": 16, "mines": 40 },
	GameModes.EXPERT  : { "x": 30, "y": 16, "mines": 99 }
}
## Defines the currently active game mode taking values from the [enum GameModes] enumeration.
## This is reset in [method _init] to use the last known configuration.
var game_mode : GameModes = GameModes.BEGIN
## Defines the default mode. This is reset in [method _init] to use the last known configuration.
var grid_size = Vector2i(9,9)
## Defines the default mode. This is reset in [method _init] to use the last known configuration.
var mine_count : int = 10
## Defines the last five high scores for each mode. 
var high_scores = {
	begin   = LimitedPriorityQueue.new(),
	advance = LimitedPriorityQueue.new(),
	expert  = LimitedPriorityQueue.new()
}
## Defines a custom board setup with x and y matching the width and height, and z matching the number of mines.
var custom_mode = Vector3i(20,20,50)

var game_grid : Array[Array] = []
var bombing : bool = false
var cascading : bool = false
var cascade_queue : Array[Vector2i] = []
var visited_queue : Array[Vector2i] = []
var cascade_timer : Timer
var bombed_timer : Timer
var first_click = true
var uncovered_squares : int = 0

var elapsed_time : float = 0.0
var running : bool = false
var win : bool = true
var start_time : int
var mines_unflagged : int = 10
var displayed_time : int = 0

func _init() -> void:
	if !load_config():
		return

func _ready() -> void:
	cascade_timer = Timer.new()
	cascade_timer.wait_time = 0.001
	cascade_timer.one_shot = false
	cascade_timer.timeout.connect(_process_next_cascade)
	bombed_timer = Timer.new()
	bombed_timer.wait_time = 0.02
	bombed_timer.one_shot = false
	bombed_timer.timeout.connect(_process_next_bomb)
	add_child(cascade_timer)
	add_child(bombed_timer)
	match game_mode:
		GameModes.CUSTOM:
			$PrimaryLayouter/ControlBar/SettingGroup/ButtonCustom.button_pressed = true
		GameModes.BEGIN:
			$PrimaryLayouter/ControlBar/SettingGroup/ButtonBegin.button_pressed = true
		GameModes.ADVANCE:
			$PrimaryLayouter/ControlBar/SettingGroup/ButtonAdvance.button_pressed = true
		GameModes.EXPERT:
			$PrimaryLayouter/ControlBar/SettingGroup/ButtonExpert.button_pressed = true
	$CustomMode/Container/Width/Value.value = custom_mode.x
	$CustomMode/Container/Height/Value.value = custom_mode.y
	$CustomMode/Container/Mines/Count.value = custom_mode.z
	var source = load("res://mode_tiles.tres").get_source(0)
	for i in range($PrimaryLayouter/ControlBar/SettingGroup.get_child_count()):
		var child = $PrimaryLayouter/ControlBar/SettingGroup.get_child(i)
		var texture_norm = AtlasTexture.new()
		texture_norm.atlas = source.texture
		texture_norm.region = source.get_tile_texture_region(Vector2i(i,0))
		child.texture_normal = texture_norm
		var texture_press = AtlasTexture.new()
		texture_press.atlas = source.texture
		texture_press.region = source.get_tile_texture_region(Vector2i(i,1))
		child.texture_pressed = texture_press
		var texture_hov = AtlasTexture.new()
		texture_hov.atlas = source.texture
		texture_hov.region = source.get_tile_texture_region(Vector2i(i,2))
		child.texture_hover = texture_hov
		pass
	build_grid()

func _process(_delta : float) -> void:
	if !running:
		return
	var elapsed_rounded = int((Time.get_ticks_msec() - start_time) / 1000.0)
	if elapsed_rounded > displayed_time:
		_format_segment_number($PrimaryLayouter/ControlBar/StatusGroup/Timer,elapsed_rounded)
		displayed_time = elapsed_rounded
	if uncovered_squares == (grid_size.x * grid_size.y - mine_count):
		if win:
			running = false
			$PrimaryLayouter/GameArea/BackPanel/CutoffPanel.mouse_filter = MOUSE_FILTER_STOP
			# TODO : Figure out why this sometimes doesn't enter endgame state
			elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
			won_game.emit(elapsed_time)
			match game_mode:
				GameModes.BEGIN:
					high_scores.begin.add(elapsed_time)
				GameModes.ADVANCE:
					high_scores.advance.add(elapsed_time)
				GameModes.EXPERT:
					high_scores.expert.add(elapsed_time)
			_on_button_scores_pressed()
			save_config()

func build_grid() -> void:
	elapsed_time = 0
	uncovered_squares = 0
	_format_segment_number($PrimaryLayouter/ControlBar/StatusGroup/Timer)
	$PrimaryLayouter/GameArea/BackPanel/CutoffPanel.mouse_filter = MOUSE_FILTER_IGNORE
	running = false
	win = true
	first_click = true
	bombing = false
	cascading = false
	if game_mode == -1:
		# We set these here because there's a chance the custom changed between games.
		grid_size = Vector2i(custom_mode.x,custom_mode.y)
		mine_count  = custom_mode.z
	else:
		# We set these here just in case the game mode has changed between games.
		grid_size = Vector2i(GAME_MODES[game_mode].x,GAME_MODES[game_mode].y)
		mine_count  = GAME_MODES[game_mode].mines
	$PrimaryLayouter/GameArea.ratio = float(grid_size.x)/float(grid_size.y)
	game_grid = []
	for child in grid_container.get_children():
		child.queue_free()
	grid_container.columns = grid_size.x
	for i in range(grid_size.y):
		var temp_array : Array[FieldSquare] = []
		for j in range(grid_size.x):
			temp_array.append(FieldSquareScene.instantiate())
			temp_array[j].local_position = Vector2i(j,i)
			temp_array[j].cascade.connect(_on_cascade)
			temp_array[j].bombed.connect(_on_bombed)
			temp_array[j].toggled.connect(_on_field_square_toggled)
			temp_array[j].flag_changed.connect(_on_flag_changed)
			grid_container.add_child(temp_array[j])
		game_grid.append(temp_array)
	mines_unflagged = mine_count
	_format_segment_number($PrimaryLayouter/ControlBar/GameGroup/MineCount,mines_unflagged,5,true)
#	$PrimaryLayouter/ControlBar/GameGroup/MineCount.text = " %04d" % mine_count

func generate_mines(clicked: Vector2i):
	running = true
	start_time = Time.get_ticks_msec()
	var idx = 0
	while idx < mine_count:
		idx = idx + 1
		var check_position = Vector2i(randi()%grid_size.x,randi()%grid_size.y)
		if check_position == clicked:
			idx = idx - 1
			continue
		if game_grid[check_position.y][check_position.x].button_value == -1:
			idx = idx - 1
			continue
		game_grid[check_position.y][check_position.x].button_value = -1
		game_grid[check_position.y][check_position.x]._set_style()
		#game_grid[check_position.y][check_position.x].text = "X"
	for child in grid_container.get_children():
		if child.button_value != 0:
			continue
		var local_count = 0
		for i in range(-1,2):
			for j in range(-1,2):
				if i == 0 and j == 0:
					continue
				var check_position = child.local_position + Vector2i(i,j)
				if 0 <= check_position.x and check_position.x < grid_size.x:
					if 0 <= check_position.y and check_position.y < grid_size.y:
						if game_grid[check_position.y][check_position.x].button_value < 0:
							local_count = local_count + 1
		child.button_value = local_count
		child._set_style()
	#if game_grid[clicked.y][clicked.x].button_value != 0:
		#game_grid[clicked.y][clicked.x].text = str(game_grid[clicked.y][clicked.x].button_value)

func save_config() -> bool:
	var config = ConfigFile.new()
	
	config.set_value("game","mode",game_mode)
	config.set_value("game","custom",custom_mode)
	config.set_value("scores","begin",high_scores.begin.get_array())
	config.set_value("scores","advance",high_scores.advance.get_array())
	config.set_value("scores","expert",high_scores.expert.get_array())
	
	var error_catch = config.save(CONFIG_PATH)
	if error_catch != OK:
		push_error("Failed to save config: ", error_catch)
		return false
	return true
func load_config() -> bool:
	var config = ConfigFile.new()
	var error_catch = config.load(CONFIG_PATH)
	if error_catch != OK:
		push_error("Failed to load config: ", error_catch)
		return false
	game_mode   = config.get_value("game","mode",GameModes.BEGIN)
	custom_mode = config.get_value("game","custom",Vector3i(20,20,50))
	var scores : Array[float] = config.get_value("scores","begin",[])
	for score in scores:
		high_scores.begin.add(score)
	scores = config.get_value("scores","advance",[])
	for score in scores:
		high_scores.advance.add(score)
	scores = config.get_value("scores","expert",[])
	for score in scores:
		high_scores.expert.add(score)
	return true

func _on_field_square_toggled(toggled_on : bool):
	if toggled_on:
		uncovered_squares = uncovered_squares+1
func _on_button_begin_pressed() -> void:
	game_mode = GameModes.BEGIN
	build_grid()
	save_config()
func _on_button_advance_pressed() -> void:
	game_mode = GameModes.ADVANCE
	build_grid()
	save_config()
func _on_button_expert_pressed() -> void:
	game_mode = GameModes.EXPERT
	build_grid()
	save_config()
func _on_button_restart_pressed() -> void:
	build_grid()
	save_config()

func _on_cascade(local_position: Vector2i):
	if first_click:
		generate_mines(local_position)
		first_click = false
	if cascading:
		return
	cascading = true
	visited_queue = []
	cascade_queue = [local_position]
	cascade_timer.start()
	$PrimaryLayouter/GameArea/BackPanel/CutoffPanel.mouse_filter = MOUSE_FILTER_STOP
func _process_next_cascade():
	if cascade_queue.is_empty():
		cascade_timer.stop()
		$PrimaryLayouter/GameArea/BackPanel/CutoffPanel.mouse_filter = MOUSE_FILTER_IGNORE
		cascading = false
		return
	var local_position = cascade_queue.pop_front()
	cascade(local_position)
func cascade(local_position: Vector2i):
	visited_queue.append(local_position)
	if !game_grid[local_position.y][local_position.x].button_pressed:
		if game_grid[local_position.y][local_position.x].mode != FieldSquare.ButtonModes.ACTIVE:
			return
		game_grid[local_position.y][local_position.x].button_pressed = true
	if game_grid[local_position.y][local_position.x].button_value == 0:
		for i in range(-1,2):
			for j in range(-1,2):
				var check_position = local_position+Vector2i(i,j)
				if visited_queue.has(check_position):
					continue
				if cascade_queue.has(check_position):
					continue
				if 0 <= check_position.x and check_position.x < grid_size.x:
					if 0 <= check_position.y and check_position.y < grid_size.y:
						cascade_queue.append(check_position)

func _on_bombed(local_position: Vector2i):
	if bombing:
		return
	running = false
	elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
	win = false
	print("You lost in ",elapsed_time," seconds")
	bombing = true
	cascade_queue = [local_position]
	visited_queue = []
	bombed_timer.start()
	$PrimaryLayouter/GameArea/BackPanel/CutoffPanel.mouse_filter = MOUSE_FILTER_STOP
	for child in grid_container.get_children():
		if child.button_value == -1:
			cascade_queue.append(child.local_position)
	var first : Vector2i = cascade_queue[0]
	cascade_queue.pop_front()
	var rest : Array[Vector2i] = cascade_queue
	rest.shuffle()
	cascade_queue = rest
	rest.push_front(first)
func _process_next_bomb():
	if cascade_queue.is_empty():
		bombed_timer.stop()
		bombing = false
		return
	var local_position = cascade_queue.pop_front()
	if !game_grid[local_position.y][local_position.x].disabled:
		game_grid[local_position.y][local_position.x].disabled = true

func _on_button_scores_pressed() -> void:
	for idx in range(high_scores.begin.get_array().size()):
		$Scores/Container/Content/BeginnerBox.get_child(idx).text = "%d - %.3f" % [idx+1,high_scores.begin.get_array()[idx]]
	for idx in range(high_scores.advance.get_array().size()):
		$Scores/Container/Content/AdvancedBox.get_child(idx).text = "%d - %.3f" % [idx+1,high_scores.advance.get_array()[idx]]
	for idx in range(high_scores.expert.get_array().size()):
		$Scores/Container/Content/ExpertBox.get_child(idx).text = "%d - %.3f" % [idx+1,high_scores.expert.get_array()[idx]]
	$Scores.popup()


func _on_button_custom_pressed() -> void:
	$CustomMode.show()
	pass # Replace with function body.

func _calculate_score():
	var board_area = $CustomMode/Container/Height/Value.value * $CustomMode/Container/Width/Value.value
	var score_value = $CustomMode/Container/Mines/Count.value / board_area
	if score_value > 0.3:
		var new_mines = int(3 * board_area / 10)
		$CustomMode/Container/Mines/Count.value = new_mines
		score_value = new_mines / board_area
	return score_value

func _on_custom_mode_value_changed(_value: float) -> void:
	var new_score = _calculate_score()
	$CustomMode/Container/Difficulty/Value.text = "%.03f" % new_score


func _on_custom_mode_confirmed() -> void:
	game_mode = GameModes.CUSTOM
	custom_mode = Vector3i($CustomMode/Container/Width/Value.value,$CustomMode/Container/Height/Value.value,$CustomMode/Container/Mines/Count.value)
	save_config()
	build_grid()

func _on_flag_changed(is_on: bool):
	if is_on:
		mines_unflagged = mines_unflagged - 1
	else:
		mines_unflagged = mines_unflagged + 1
	_format_segment_number($PrimaryLayouter/ControlBar/GameGroup/MineCount,mines_unflagged,5,true)

func _format_segment_number(target:Node,number=0,length:int=3,signed:bool=false):
	var tile_set = load("res://seven_segment_tiles.tres")
	var source = tile_set.get_source(0)
	if signed:
		var texture_signed = AtlasTexture.new()
		var negative = 10
		if number < 0:
			negative = 11
		texture_signed.atlas = source.texture
		texture_signed.region = source.get_tile_texture_region(Vector2i(negative,0))
		target.get_children()[0].texture = texture_signed
	for i in range(length):
		if signed and i == length-1:
			continue
		var texture_digit = AtlasTexture.new()
		texture_digit.atlas = source.texture
		texture_digit.region = source.get_tile_texture_region(Vector2i(int(abs(number)/(pow(10,i))) % 10,0))
		target.get_children()[length-1-i].texture = texture_digit
	pass
