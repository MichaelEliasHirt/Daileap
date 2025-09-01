@tool
extends Node2D


@export_tool_button("New / Load") var load_action = load_level.bind()
@export var level_chunk_name : String = "TestLevel":
	set(value):
		value = value.dedent().validate_filename().to_pascal_case()
		if not value:
			value = "TestLevel"
		level_chunk_name = value
		
@export var level_chunk_res : LevelChunkRes
@export_tool_button("Save") var save_action = save_level.bind()
@export_tool_button("Try Auto Fix") var fix_action = fix_level.bind()
@export_tool_button("Update_Visuals") var visupdate_action = visupdate.bind()

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

var level_valid : bool
var level_chunk_height : int
var level_chunk_width : int

var level_errors : Array[String]


func save_level():
	update_properties()
	level_chunk_height += 1
	# Saving changes to the resource
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


func load_level():
	
	if level_chunk_res:
		level_chunk_name = level_chunk_res.resource_name
		mainground.tile_map_data = level_chunk_res.mainground_tile_map_data
		background.tile_map_data = level_chunk_res.background_tile_map_data
	
	else:
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
		print(map_size)
		level_errors.append("Chunk width isnt multiple of 14. Level is %s to wide!" % (map_size.size.x % 14))
	
	print("Errors: %s" % str(level_errors))
	
	level_valid = level_errors.is_empty()

func fix_level():
	pass

func visupdate():
	update_properties()
	valid_zone.position = Vector2i.ZERO
	valid_zone.size = Vector2i(int(mainground.get_used_rect().size.x / 14)*14,mainground.get_used_rect().size.y) * 16
	
	if int(mainground.get_used_rect().size.x/14) > 1:
		level_dividers.erase(level_width_divider)
		for x in level_dividers:
			x.queue_free()
		level_dividers = [level_width_divider]
		for x in range(int(mainground.get_used_rect().size.x/14)-2):
			var new_divider = level_width_divider.duplicate()
			$Display.add_child(new_divider)
			level_dividers.append(new_divider)
		print(level_dividers)
		for x in range(int(mainground.get_used_rect().size.x/14)-1):
			
			var y = x+1
			print(y)
			level_dividers[x].points = [Vector2i(y*14*16,-50),Vector2i(y*14*16,mainground.get_used_rect().size.y*16+50)]
	
