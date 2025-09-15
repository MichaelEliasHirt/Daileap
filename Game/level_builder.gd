@tool
extends Node2D


@export_tool_button("New / Load") var load_action = load_level.bind()
@export var level_chunk_res : LevelChunkRes
@export var ID : int = 0
@export var level_chunk_name : String = "TestLevel":
	set(value):
		value = value.dedent().validate_filename().to_pascal_case()
		if not value:
			value = "TestLevel"
		level_chunk_name = value
		

@export_tool_button("Save") var save_action = save_level.bind()
@export_tool_button("Delete") var delete_action = delete_level.bind()
@export_tool_button("Update_Visuals") var visupdate_action = visupdate.bind()

@export_subgroup("Settings")
@export var entrances : Array[bool]
@export var exits : Array[bool]

@export_subgroup("Properties")
@export_tool_button("Update") var update_action = update_properties.bind()
@export var _level_valid : bool :
	get:return level_valid
	set(value):pass
@export_custom(PROPERTY_HINT_NONE,"suffix:tiles") var _level_chunk_height : float :
	get:return level_chunk_height
	set(value):pass
@export_custom(PROPERTY_HINT_NONE,"suffix:level_widths") var _level_chunk_width : float :
	get:return level_chunk_width
	set(value):pass
@export_multiline var _level_errors : Array[String] :
	get:return level_errors
	set(value):pass

@onready var background: TileMapLayer = $Background
@onready var mainground: TileMapLayer = $Mainground
@onready var valid_zone: NinePatchRect = $Display/ValidZone
@onready var level_width_divider: Line2D = $Display/LevelWidthDivider
var level_dividers: Array[Line2D]
@onready var entrance_arrow: Sprite2D = $Display/EntranceArrow
var entrance_arrows: Array[Sprite2D]
@onready var exit_arrow: Sprite2D = $Display/ExitArrow
var exit_arrows: Array[Sprite2D]

var level_valid : bool
var level_chunk_height : int
var level_chunk_width : int

var level_errors : Array[String]


func save_level():
	update_properties()
	level_chunk_height += 1
	# Saving changes to the resource
	level_chunk_res.ID = ID
	level_chunk_res.resource_name = level_chunk_name
	level_chunk_res.mainground_tile_map_data = mainground.tile_map_data
	level_chunk_res.background_tile_map_data = background.tile_map_data
	
	
	# Saving the resource
	var filepath = "res://Game/LevelChunks/%s.tres" % level_chunk_name
	var file_exists = ResourceLoader.exists(filepath,"LevelChunkRes")
	var error := ResourceSaver.save(level_chunk_res,filepath)
	
	if not error:
		if file_exists:
			print('Saved "%s" successfully to %s' % [level_chunk_name,filepath])
		else:
			print('Created new file named "%s" successfully to %s' % [level_chunk_name,filepath])
	else:
		print("An error ocoured whilst trying to save to %s" % filepath)
		print("Error: %s" % error_string(error))
	
	
	
	var res: ChunkInfo = ResourceLoader.load("res://Game/LevelChunks/ChunkInfo.tres","ChunkInfo")
	
	if ID > res.count:
		res.count += 1
		res.name.append(level_chunk_name)
		res.valid.append(level_valid)
		res.width.append(level_chunk_width)
		res.entrances.append(bool_array_to_int(entrances))
		res.exits.append(bool_array_to_int(exits))
	else:
		res.name[ID] = level_chunk_name
		res.valid[ID] = level_valid
		res.width[ID] = level_chunk_width
		res.entrances[ID] = bool_array_to_int(entrances)
		res.exits[ID] = bool_array_to_int(exits)
	
	ResourceSaver.save(res,"res://Game/LevelChunks/ChunkInfo.tres")
	


func load_level():
	if level_chunk_res:
		var res: ChunkInfo = ResourceLoader.load("res://Game/LevelChunks/ChunkInfo.tres","ChunkInfo")
		ID = level_chunk_res.ID
		
		level_chunk_name = res.name[ID]
		level_valid = res.valid[ID]
		level_chunk_width = res.width[ID]
		entrances = int_to_bool_array(res.entrances[ID],level_chunk_width)
		exits = int_to_bool_array(res.entrances[ID],level_chunk_width)
		
		mainground.tile_map_data = level_chunk_res.mainground_tile_map_data
		background.tile_map_data = level_chunk_res.background_tile_map_data
		
	else:
		var res: ChunkInfo = ResourceLoader.load("res://Game/LevelChunks/ChunkInfo.tres","ChunkInfo")
		ID = res.count + 1
		level_chunk_res = LevelChunkRes.new()
		mainground.clear()
		background.clear()
		
	update_properties()


func update_properties():
	level_errors.clear()
	
	var map_size = mainground.get_used_rect()
	if map_size.position != Vector2i.ZERO:
		level_errors.append("Origin of chunk isnt at 0 (Position: %s)" %  map_size.position)
	elif not map_size.encloses(background.get_used_rect()):
		level_errors.append("Background layer is bigger then Mainground layer")

	level_chunk_height = map_size.size.y
	level_chunk_width = int(map_size.size.x / 14)
	
	if level_chunk_width <= 0:
		level_errors.append("Chunk is not wide enough needs to be 14 or a multiple")
	elif (map_size.size.x) % 14 != 0:
		level_errors.append("Chunk width isnt multiple of 14. Level is %s to wide!" % (map_size.size.x % 14))
	
	entrances.resize(int(map_size.size.x / 14))
	entrances.map(func(x): return x == true)
	exits.resize(int(map_size.size.x / 14))
	exits.map(func(x): return x == true)
	
	
	if not entrances.any(func(x): return x):
		level_errors.append("No entrances defined")
	
	if not exits.any(func(x): return x):
		level_errors.append("No exits defined")
	
	
	print("Errors: %s" % str(level_errors))
	level_valid = level_errors.is_empty()
	
	notify_property_list_changed()

func delete_level():
	
	# Saving the resource
	var filepath = "res://Game/LevelChunks/%s.tres" % level_chunk_name
	DirAccess.remove_absolute(filepath)
	
	var res: ChunkInfo = ResourceLoader.load("res://Game/LevelChunks/ChunkInfo.tres","ChunkInfo")
	
	res.count -= 1
	res.name.pop_at(ID)
	res.valid.pop_at(ID)
	res.width.pop_at(ID)
	res.entrances.pop_at(ID)
	res.exits.pop_at(ID)
	
	ResourceSaver.save(res,"res://Game/LevelChunks/ChunkInfo.tres")
	

func visupdate():
	update_properties()
	valid_zone.position = Vector2i.ZERO
	valid_zone.size = Vector2i(int(mainground.get_used_rect().size.x / 14)*14,mainground.get_used_rect().size.y) * 16
	
	if int(mainground.get_used_rect().size.x/14) > 1:
		level_width_divider.show()
		level_dividers.erase(level_width_divider)
		for x in level_dividers:
			x.queue_free()
		level_dividers = [level_width_divider]
		for x in range(int(mainground.get_used_rect().size.x/14)-2):
			var new_divider = level_width_divider.duplicate()
			$Display.add_child(new_divider)
			level_dividers.append(new_divider)
			
		for x in range(int(mainground.get_used_rect().size.x/14)-1):
			
			var y = x+1
			level_dividers[x].clear_points()
			level_dividers[x].points = [Vector2i(y*14*16,-50),Vector2i(y*14*16,mainground.get_used_rect().size.y*16+50)]
	else:
		level_width_divider.hide()

	entrance_arrow.hide()
	entrance_arrows.erase(entrance_arrow)
	for x in entrance_arrows:
		x.queue_free()
	entrance_arrows = [entrance_arrow]
	for x in range(entrances.size()-1):
		var new_entrance_arrow = entrance_arrow.duplicate()
		$Display.add_child(new_entrance_arrow)
		new_entrance_arrow.hide()
		entrance_arrows.append(new_entrance_arrow)
	
	for x in range(entrances.size()):
		if entrances[x]:
			entrance_arrows[x].position = Vector2i((x*14*16)+(7*16),mainground.get_used_rect().size.y*16)
			entrance_arrows[x].show()
			
			
	exit_arrow.hide()
	exit_arrows.erase(exit_arrow)
	for x in exit_arrows:
		x.queue_free()
	exit_arrows = [exit_arrow]
	for x in range(exits.size()-1):
		var new_exit_arrow = exit_arrow.duplicate()
		$Display.add_child(new_exit_arrow)
		new_exit_arrow.hide()
		exit_arrows.append(new_exit_arrow)
	
	for x in range(exits.size()):
		if exits[x]:
			exit_arrows[x].position = Vector2i((x*14*16)+(7*16),0)
			exit_arrows[x].show()


func bool_array_to_int(bool_array: Array) -> int:
	var result = 0
	for i in range(bool_array.size()):
		if bool_array[i]:
			result |= (1 << i)
	return result


func int_to_bool_array(value: int, array_size: int) -> Array:
	var result = []
	for i in range(array_size):
		if (value >> i) & 1:
			result.append(true)
		else:
			result.append(false)
	return result
