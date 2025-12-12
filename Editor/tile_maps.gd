class_name TileMapManager extends Node2D

@onready var debug_info_label: Label = %DebugInfoLabel
@onready var grid: ColorRect = %HighlightGrid
@onready var control: Control = $"../BeforeMap/InputControl"
@onready var decor_erase_prev_tilemap: TileMapLayer = %DecorErasePrevTilemap

@onready var preview_sprite: Sprite2D = %PreviewSprite

signal tilemap_changed

var active_selection : SelectionRes
var active_tilemap_layer: TileMapLayer

var last_coords: Vector2i
var current_tool: int = 0
var tool_start: bool
var tool_first_coord: Vector2
var erase_tool_start: bool
var erase_tool_first_coord: Vector2

var preview := true
var decor_erase_prev := false


func _process(_delta: float) -> void:
	## update the label at the top right
	var coords = %Mainground.local_to_map(get_local_mouse_position())
	if coords != last_coords:
		last_coords = coords
		debug_info_label.update_info(coords)
	
	## for the grid highlight
	grid.material.set_shader_parameter("mouse_position", grid.get_global_mouse_position())
	
	## Move the preview sprite when its active, it snappes to the grid
	preview_sprite.hide()
	if preview:
		if active_selection and active_selection.list:
			if control.get_rect().has_point(control.get_local_mouse_position()):
				var at = get_global_mouse_position()
				var local_at = active_tilemap_layer.local_to_map(to_local(at))
				var standerdized_local_at  = local_at*active_tilemap_layer.tile_set.tile_size/16
				if is_placeable_location(standerdized_local_at):
					preview_sprite.show()
					preview_sprite.texture = active_selection.texture
					preview_sprite.position = local_at * active_tilemap_layer.tile_set.tile_size + active_tilemap_layer.tile_set.tile_size/2 - active_selection.preview_offset
	

func _on_input_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		## the decor_erase_prev get hidden but mostly gets shown again a little down the execution
		_hide_decor_erase_prev()
		if control.get_rect().has_point(control.get_local_mouse_position()):
			if not active_selection:
				return
			## similar to decor_erase_prev, but the other way round
			_show_preview()
			## for now that when the only types that use buttons at all, but maybe I will add buttons for other types 
			if active_selection.type in [SelectionRes.SelectionType.terrain,SelectionRes.SelectionType.noterrain,SelectionRes.SelectionType.wall]:
				match current_tool:
					0: ## pencil tool 
						## when you move the mouse quick there will be holes in the "line", this prevents this to some extent
						if event is InputEventMouseMotion:
							if abs(event.screen_relative.x) > 16 or abs(event.screen_relative.x) > 16:
								if event.button_mask == 1:
									place(get_global_mouse_position() - (event.screen_relative/2))
								elif event.button_mask == 2:
									place(get_global_mouse_position() - (event.screen_relative/2),true)
						if event.button_mask == 1:
							place(get_global_mouse_position())
						elif event.button_mask == 2:
							_hide_preview()
							place(get_global_mouse_position(),true)
					1: ## line tool
						## when you first press the start of the line is gettign marked
						if event is InputEventMouseButton:
							if not event.is_echo():
								if event.button_mask == 1:
									tool_start = true
									tool_first_coord = get_global_mouse_position()
								if event.button_mask == 2:
									erase_tool_start = true
									erase_tool_first_coord = get_global_mouse_position()
						## only if the line has started already
						if tool_start:
							## preview line gets updated as long as pressed
							if event.button_mask == 1:
								line(tool_first_coord,get_global_mouse_position(),false,true)
								
							## when released the actual line is placed
							elif event.is_released():
								tool_start = false
								clear_temp()
								line(tool_first_coord,get_global_mouse_position())
						
						## same for erase line
						if erase_tool_start:
							if event.button_mask == 2:
								_hide_preview()
								line(erase_tool_first_coord,get_global_mouse_position(),true,true)
								
							elif event.is_released():
								erase_tool_start = false
								clear_temp()
								_hide_preview()
								line(erase_tool_first_coord,get_global_mouse_position(),true)
					2: ## rect tool
						
						## similar to line tool but the changed tiles are different
						if event is InputEventMouseButton:
							if not event.is_echo():
								if event.button_mask == 1:
									tool_start = true
									tool_first_coord = get_global_mouse_position()
								if event.button_mask == 2:
									erase_tool_start = true
									erase_tool_first_coord = get_global_mouse_position()
									
						if tool_start:
							if event.button_mask == 1:
								rect(tool_first_coord,get_global_mouse_position(),false,true)
								
							elif event.is_released():
								tool_start = false
								clear_temp()
								rect(tool_first_coord,get_global_mouse_position())
							
						if erase_tool_start:
							if event.button_mask == 2:
								_hide_preview()
								rect(erase_tool_first_coord,get_global_mouse_position(),true,true)
								
							elif event.is_released():
								erase_tool_start = false
								clear_temp()
								_hide_preview()
								rect(erase_tool_first_coord,get_global_mouse_position(),true)
					3: ## fill tool
						_hide_preview()
						
						if event is InputEventMouseButton:
							if not event.is_echo():
								if event.button_mask == 1:
									if tool_start:
										tool_start = false
										## if you click again on the preview, then actually set the tiles
										## if you would click outside the tool just resets
										if is_hovering_temp(get_global_mouse_position()):
											fill(get_global_mouse_position())
										clear_temp()
									else:
										## set the preview fill
										var success = fill(get_global_mouse_position(),false,true)
										if success:
											tool_start = true
										else: tool_start = false
								
								## same for erase
								elif event.button_mask == 2:
									if erase_tool_start:
										erase_tool_start = false
										if is_hovering_temp(get_global_mouse_position()):
											fill(get_global_mouse_position(),true)
										clear_temp()
									else:
										var success = fill(get_global_mouse_position(),true,true)
										if success:
											erase_tool_start = true
										else: erase_tool_start = false
			
			## for now this is everything that just gets placed, nothing fancy
			elif active_selection.type in [SelectionRes.SelectionType.decor1,SelectionRes.SelectionType.decor2,SelectionRes.SelectionType.decor3]:
				if event.button_mask == 1:
					place(get_global_mouse_position())
				elif event.button_mask == 2:
					## shows little hitboxed to make it easier to hit them
					_show_decor_erase_prev()
					_hide_preview()
					place(get_global_mouse_position(),true)


func _place_tile(at:Vector2i, source:int, tilecoords:Vector2i,tilealtid:int):
	if active_tilemap_layer:
		active_tilemap_layer.set_cell(at,source,tilecoords,tilealtid)


func _place_terrain(ats:Array[Vector2i], terrainset:int, terrainid:int):
	if active_tilemap_layer:
		active_tilemap_layer.set_cells_terrain_connect(ats,terrainset,terrainid)


func clear_temp():
	%PrevTilemap.clear()


func is_hovering_temp(at: Vector2) -> bool:
	return %PrevTilemap.get_cell_source_id(%PrevTilemap.local_to_map(to_local(at))) != -1


func place(at: Vector2, erase := false, temp := false):
	if active_selection and active_selection.list:
		var local_at = active_tilemap_layer.local_to_map(to_local(at))
		var standerdized_local_at  = local_at*active_tilemap_layer.tile_set.tile_size/16
		if is_placeable_location(standerdized_local_at):
			if temp:
				%PrevTilemap.set_cell(standerdized_local_at,0,Vector2i(0,0),0)
				return
			tilemap_changed.emit()
			#match selection_type:
				#SelectionType.tile:
					#_place_tile(at, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				#SelectionType.terrain:
			if erase:
				active_tilemap_layer.erase_cell(local_at)
				##Only Decor
				if active_selection.type in [SelectionRes.SelectionType.decor1,SelectionRes.SelectionType.decor2,SelectionRes.SelectionType.decor3]:
					_update_decor_erase_tilemap(local_at,true)
					
			else:
				if active_selection.type in [SelectionRes.SelectionType.terrain,SelectionRes.SelectionType.wall]:
					_place_terrain([local_at], active_selection.terrainset, active_selection.terrainid)
				
				elif active_selection.type == SelectionRes.SelectionType.noterrain:
					_place_tile(local_at,active_selection.tilesrc,active_selection.tilecoords,active_selection.tilealtid)
				##Only Decor
				elif active_selection.type in [SelectionRes.SelectionType.decor1,SelectionRes.SelectionType.decor2,SelectionRes.SelectionType.decor3]:
					_update_decor_erase_tilemap(local_at)
					_place_tile(local_at,active_selection.tilesrc,active_selection.tilecoords,active_selection.tilealtid)

func fill(at: Vector2,erase := false, temp := false) -> bool:
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_terrain(%PrevTilemap.local_to_map(local_at))
			if cell_coords.is_empty():
				cell_coords = get_fill_cells_by_cell(%PrevTilemap.local_to_map(local_at))
				
			if temp:
				clear_temp()
				if erase:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				else:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return true
			
			tilemap_changed.emit()
			#match selection_type:
				#SelectionType.tile:
					#for coords in cell_coords:
						#_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				#SelectionType.terrain:
			if not erase:
				_place_terrain(cell_coords, active_selection.terrainset, active_selection.terrainset)
			else:
				for coords in cell_coords:
					active_tilemap_layer.erase_cell(coords)
	return true


func rect(at: Vector2, to: Vector2, erase := false, temp := false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):
			var cell_coords := get_rect_cells(%PrevTilemap.local_to_map(local_at), %PrevTilemap.local_to_map(local_to))

			if temp:
				clear_temp()
				if erase:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				else:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			if erase:
				for coords in cell_coords:
					active_tilemap_layer.erase_cell(coords)
			else:
				_place_terrain(cell_coords, active_selection.terrainset, active_selection.terrainset)
			#match selection_type:
				#SelectionType.tile:
					#for coords in cell_coords:
						#_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				#SelectionType.terrain:


func line(at: Vector2, to: Vector2, erase := false, temp := false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):

			var cell_coords := get_intersecting_cells(local_at,local_to)

			if temp:
				clear_temp()
				if erase:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				else:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			
			if erase:
				for coords in cell_coords:
					active_tilemap_layer.erase_cell(coords)
			else:
				_place_terrain(cell_coords, active_selection.terrainset, active_selection.terrainset)
			#match selection_type:
				#SelectionType.tile:
					#for coords in cell_coords:
						#_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				#SelectionType.terrain:



func get_fill_cells_by_cell(at: Vector2) -> Array[Vector2i]:
	var cells_hit: Array[Vector2i] = [at]
	var current_cells: Array[Vector2i] = [at]
	var next_cells: Array[Vector2i]
	var search_empty := false
	
	if active_tilemap_layer.get_cell_source_id(at) == -1:
		if active_tilemap_layer.get_cell_atlas_coords(at) == Vector2i(-1,-1):
			if active_tilemap_layer.get_cell_alternative_tile(at) == -1:
				search_empty = true
				
	var same_cells = active_tilemap_layer.get_used_cells_by_id(active_tilemap_layer.get_cell_source_id(at),active_tilemap_layer.get_cell_atlas_coords(at),active_tilemap_layer.get_cell_alternative_tile(at))
	
	if search_empty:
		while true:
			for cell in current_cells:
				for new_cell in active_tilemap_layer.get_surrounding_cells(cell):
					if not cells_hit.has(new_cell):
						if is_placeable_location(new_cell):
							if not same_cells.has(new_cell):
								cells_hit.append(new_cell)
								next_cells.append(new_cell)
							
			if next_cells.is_empty():
				break
			current_cells = next_cells.duplicate_deep()
			next_cells.clear()
		
		return cells_hit
	else:
		
		while true:
			for cell in current_cells:
				for new_cell in active_tilemap_layer.get_surrounding_cells(cell):
					if not cells_hit.has(new_cell):
						if is_placeable_location(new_cell):
							if same_cells.has(new_cell):
								cells_hit.append(new_cell)
								next_cells.append(new_cell)
							
			if next_cells.is_empty():
				break
			current_cells = next_cells.duplicate_deep()
			next_cells.clear()
		
		return cells_hit


func get_fill_cells_by_terrain(at: Vector2) -> Array[Vector2i]:
	var cells_hit: Array[Vector2i] = [at]
	var current_cells: Array[Vector2i] = [at]
	var next_cells: Array[Vector2i]
	var cell_tile_data := active_tilemap_layer.get_cell_tile_data(at)
	var search_terrain_set: int
	var search_terrain: int
	if cell_tile_data:
		search_terrain_set = cell_tile_data.terrain_set
		search_terrain = cell_tile_data.terrain
	else:
		return []
	
	while true:
		for cell in current_cells:
			for new_cell in active_tilemap_layer.get_surrounding_cells(cell):
				if not cells_hit.has(new_cell):
					if is_placeable_location(new_cell):
						cell_tile_data = active_tilemap_layer.get_cell_tile_data(new_cell)
						if cell_tile_data:
							if cell_tile_data.terrain_set == search_terrain_set and cell_tile_data.terrain == search_terrain:
								cells_hit.append(new_cell)
								next_cells.append(new_cell)
		
		if next_cells.is_empty():
			break
		current_cells = next_cells.duplicate_deep()
		next_cells.clear()
	
	return cells_hit

func _hide_preview():
	preview = false


func _show_preview():
	preview = true
	
	
func _show_decor_erase_prev():
	decor_erase_prev_tilemap.show()
	decor_erase_prev = true


func _update_decor_erase_tilemap(coords:Vector2i, erase := false):
	if erase:
		var has_another_tile = false
		for layer: TileMapLayer in get_children().filter(func(x): return x.is_in_group("decorlayer")):
			if layer.get_cell_tile_data(coords):
				has_another_tile = true
				break
		if not has_another_tile:
			decor_erase_prev_tilemap.erase_cell(coords)
	else: 
		decor_erase_prev_tilemap.set_cell(coords,0,Vector2i(0,0),0)


func _create_decor_erase_tilemap():
	decor_erase_prev_tilemap.clear()
	for layer: TileMapLayer in get_children().filter(func(x): return x.is_in_group("decorlayer")):
		for cell in layer.get_used_cells():
			_update_decor_erase_tilemap(cell)


func _hide_decor_erase_prev():
	decor_erase_prev_tilemap.hide()
	decor_erase_prev = false



func get_rect_cells(start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
	var cells_hit: Array[Vector2i] = []
	
	var first_pos = Vector2i(min(start_pos.x, end_pos.x), min(start_pos.y, end_pos.y))
	var second_pos = Vector2i(max(start_pos.x, end_pos.x), max(start_pos.y, end_pos.y))
	
	for cell_x in range(first_pos.x,second_pos.x+1):
		for cell_y in range(first_pos.y,second_pos.y+1):
			cells_hit.append(Vector2i(cell_x,cell_y))
	return cells_hit


func get_intersecting_cells(start_pos: Vector2, end_pos: Vector2) -> Array[Vector2i]:
	var cells_hit: Array[Vector2i] = []
	var direction: Vector2 = end_pos - start_pos
	var distance: float = direction.length()
	var tilemap_node = %PrevTilemap
	
	if distance == 0:
		cells_hit.append(tilemap_node.local_to_map(start_pos))
		return cells_hit
	
	var normalized_dir: Vector2 = direction / distance
	var tile_size: Vector2 = tilemap_node.tile_set.tile_size
	var current_cell: Vector2i = tilemap_node.local_to_map(start_pos)
	var step_x: int = 1 if normalized_dir.x > 0 else -1
	var step_y: int = 1 if normalized_dir.y > 0 else -1
	var inv_dir_x: float = 1.0 / normalized_dir.x if normalized_dir.x != 0 else INF
	var inv_dir_y: float = 1.0 / normalized_dir.y if normalized_dir.y != 0 else INF
	var delta_t_x: float = abs(tile_size.x * inv_dir_x)
	var delta_t_y: float = abs(tile_size.y * inv_dir_y)
	var t_max_x: float
	var t_max_y: float
	
	if normalized_dir.x > 0:
		t_max_x = abs((float(current_cell.x + 1) * tile_size.x - start_pos.x) * inv_dir_x)
	else:
		t_max_x = abs((float(current_cell.x) * tile_size.x - start_pos.x) * inv_dir_x)
		
	if normalized_dir.y > 0:
		t_max_y = abs((float(current_cell.y + 1) * tile_size.y - start_pos.y) * inv_dir_y)
	else:
		t_max_y = abs((float(current_cell.y) * tile_size.y - start_pos.y) * inv_dir_y)
		
	var t_total: float = 0.0

	while t_total <= distance:
		if not cells_hit.has(current_cell):
			cells_hit.append(current_cell)
		
		if t_max_x < t_max_y:
			t_total = t_max_x
			t_max_x += delta_t_x
			current_cell.x += step_x
		else:
			t_total = t_max_y
			t_max_y += delta_t_y
			current_cell.y += step_y
			
	var final_cell = tilemap_node.local_to_map(end_pos)
	if not cells_hit.has(final_cell):
		cells_hit.append(final_cell)

	return cells_hit


func is_placeable_location(at:Vector2):
	var placeable_rect = Rect2(-abs(owner.chunks_left * (owner.chunk_width-1)),0,
		abs(((owner.chunks_right + owner.chunks_left) * (owner.chunk_width-1)) + owner.chunk_width),owner.height)

	return placeable_rect.has_point(at)


func _on_ui_selection_changed(selection: SelectionRes) -> void:
	active_selection = selection
	if active_selection:
		
		for tilemap in get_children():
			if tilemap is TileMapLayer:
				if tilemap.tile_set == active_selection.tileset:
					active_tilemap_layer = tilemap
					break


func _on_editor_tool_changed(new_current_tool: int) -> void:
	current_tool = new_current_tool
	tool_start = false
	erase_tool_start = false


func _on_save_menu_new_chunk_loaded(_data: LevelChunkRes) -> void:
	_hide_preview()
	_hide_decor_erase_prev()
	await get_tree().process_frame
	_create_decor_erase_tilemap()
