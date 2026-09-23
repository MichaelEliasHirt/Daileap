class_name TileMapManager extends Node2D

enum Brushes {
	paint,
	line,
	rect,
	fill
}



@onready var debug_info_label: Label = %DebugInfoLabel
@onready var grid: ColorRect = %HighlightGrid
@onready var control: Control = $".."
@onready var hitbox_tilemap: TileMapLayer = %HitboxTilemap

@onready var preview_sprite: Sprite2D = %PreviewSprite

signal tilemap_changed

var active_item: InventoryItem
var active_tilemap_layer: TileMapLayer


var active_brush: Brushes = 0 as Brushes
var brush_down: bool
var brush_first_coord: Vector2
#var erase_tool_start: bool
#var erase_tool_first_coord: Vector2

var decor_erase_prev := false

func _process(_delta: float) -> void:
	## Move the preview sprite when its active, it snappes to the grid
	
	if preview_sprite.visible:
		preview_sprite.hide()
		if active_item:
			if control.get_rect().has_point(control.get_local_mouse_position()):
				var at = get_global_mouse_position()
				var local_at = active_tilemap_layer.local_to_map(to_local(at))
				var standerdized_local_at  = local_at*active_tilemap_layer.tile_set.tile_size/16
				if is_placeable_location(standerdized_local_at):
					preview_sprite.show()
					preview_sprite.texture = active_item.root.icon_texture
					preview_sprite.position = local_at * active_tilemap_layer.tile_set.tile_size + active_tilemap_layer.tile_set.tile_size/2 - active_item.root.icon_offset
					#if active_selection.direction:
						#preview_sprite.rotation_degrees = active_selection.direction
					#else: preview_sprite.rotation_degrees = 0
					

func _on_input_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		## the decor_erase_prev get hidden but mostly gets shown again a little down the execution
		hitbox_tilemap.hide()
		if control.get_rect().has_point(event.position):
			if not active_item:
				return
			preview_sprite.show()
			
			if active_item.bulk_placement:
				match active_brush:
					Brushes.paint: 
						clear_preview_tilemap()
						## when you move the mouse quick there will be holes in the "line", this prevents this to some extent
						if event is InputEventMouseMotion:
							if event.button_mask == 2:
								paint(event.global_position, true, true)
								
							if abs(event.screen_relative.x) > 16 or abs(event.screen_relative.x) > 16:
								if event.button_mask in [1,2]:
									paint(event.global_position - (event.screen_relative/2), event.button_mask == 2)
								#elif event.button_mask == 2:
									#place(get_global_mouse_position() - (event.screen_relative/2),true)
						
						if event.button_mask in [1,2]:
							paint(event.global_position, event.button_mask == 2)
							
						#elif event.button_mask == 2:
							#_hide_preview()
							#place(get_global_mouse_position(),true)
					Brushes.line:
						## when you first press the start of the line is gettign marked
						if event is InputEventMouseButton:
							if not event.is_echo() and event.button_mask in [1,2]:
								brush_down = true
								brush_first_coord = event.global_position
							#if event.button_mask == 2:
								#erase_tool_start = true
								#erase_tool_first_coord = get_global_mouse_position()
						## only if the line has started already
						if brush_down:
							## preview line gets updated as long as pressed
							if event.button_mask in [1,2]:
								line(brush_first_coord,event.global_position,event.button_mask == 2,true)
								
							## when released the actual line is placed
							elif event is InputEventMouseButton and event.is_released() and event.button_index in [1,2]:
								brush_down = false
								clear_preview_tilemap()
								line(brush_first_coord,event.global_position, event.button_index == 2)
						
						### same for erase line
						#if erase_tool_start:
							#if event.button_mask == 2:
								#_hide_preview()
								#line(erase_tool_first_coord,get_global_mouse_position(),true,true)
								#
							#elif event.is_released():
								#erase_tool_start = false
								#clear_temp()
								#_hide_preview()
								#line(erase_tool_first_coord,get_global_mouse_position(),true)
					Brushes.rect:
						## similar to line tool but the changed tiles are different
						if event is InputEventMouseButton:
							if not event.is_echo() and event.button_mask in [1,2]:
								brush_down = true
								brush_first_coord = event.global_position
							#if event.button_mask == 2:
								#erase_tool_start = true
								#erase_tool_first_coord = get_global_mouse_position()
						## only if the line has started already
						if brush_down:
							## preview line gets updated as long as pressed
							if event.button_mask in [1,2]:
								rect(brush_first_coord,event.global_position,event.button_mask == 2, true)
								
							## when released the actual line is placed
							elif event is InputEventMouseButton and event.is_released() and event.button_index in [1,2]:
								brush_down = false
								clear_preview_tilemap()
								rect(brush_first_coord,event.global_position, event.button_index == 2)
							
						#if erase_tool_start:
							#if event.button_mask == 2:
								#_hide_preview()
								#rect(erase_tool_first_coord,event.global_position,true,true)
								
							#elif event.is_released():
								#erase_tool_start = false
								#clear_temp()
								#_hide_preview()
								#rect(erase_tool_first_coord,event.global_position,true)
					Brushes.fill:
						preview_sprite.hide()
						
						if event is InputEventMouseButton:
							if not event.is_echo() and event.button_mask in [1,2]:
								if brush_down:
									brush_down = false
									## if you click again on the preview, then actually set the tiles
									## if you would click outside the tool just resets
									if is_hovering_preview_tile(event.global_position):
										fill(event.global_position, event.button_mask == 2)
									clear_preview_tilemap()
								else:
									## set the preview fill
									var success = fill(event.global_position,event.button_mask == 2,true)
									if success:
										brush_down = true
									else: brush_down = false
							
							### same for erase
							#elif event.button_mask == 2:
								#if erase_tool_start:
									#erase_tool_start = false
									#if is_hovering_temp(event.global_position):
										#fill(event.global_position,true)
									#clear_temp()
								#else:
									#var success = fill(event.global_position,true,true)
									#if success:
										#erase_tool_start = true
									#else: erase_tool_start = false
			else:
				if event.button_mask == 2:
					hitbox_tilemap.show()
					preview_sprite.hide()
					place(event.global_position,true)
					
				elif event is InputEventMouseButton:
					if event.button_mask == 1 and not event.is_echo():
						place(event.global_position)

func _place_tile(at:Vector2i, root: RootRes):
	if active_tilemap_layer:
		active_tilemap_layer.set_cell(at,root.source_id,root.tile_coords,root.alt_id)


func _place_terrain(ats:Array[Vector2i], root: RootRes):
	if active_tilemap_layer:
		active_tilemap_layer.set_cells_terrain_connect(ats,root.terrain_set_idx,root.terrain_idx)


func clear_preview_tilemap():
	%PrevTilemap.clear()


func is_hovering_preview_tile(at: Vector2) -> bool:
	return %PrevTilemap.get_cell_source_id(%PrevTilemap.local_to_map(to_local(at))) != -1


func paint(at: Vector2, erase, preview := false):
	if active_item:
		var local_at = active_tilemap_layer.local_to_map(to_local(at))
		var standerdized_local_at  = local_at * active_tilemap_layer.tile_set.tile_size / 16
		if is_placeable_location(standerdized_local_at):
			tilemap_changed.emit()
	
			if preview:
				if erase:
					%PrevTilemap.set_cell(standerdized_local_at,0,Vector2i(1,0),0)
				return
			
			if erase:
				active_tilemap_layer.erase_cell(local_at)
				owner.data_changed()
					
			else:
				if active_item.root is RootResTerrain:
					_place_terrain([local_at], active_item.root)
					owner.data_changed()

				elif active_item.root is RootResTile:
					_place_tile(local_at,active_item.root)
					owner.data_changed()


func fill(at: Vector2, erase, preview := false) -> bool:
	if active_item:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_terrain(%PrevTilemap.local_to_map(local_at))
			if cell_coords.is_empty():
				cell_coords = get_fill_cells_by_cell(%PrevTilemap.local_to_map(local_at))
				
			if preview:
				clear_preview_tilemap()
				if erase:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				else:
					for coords in cell_coords:
						%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return true
			
			tilemap_changed.emit()

			if erase:
				for coords in cell_coords:
					active_tilemap_layer.erase_cell(coords)
				owner.data_changed()
					
			else:
				if active_item.root is RootResTerrain:
					_place_terrain(cell_coords, active_item.root)
					owner.data_changed()
					
				elif active_item.root is RootResTile:
					for coord in cell_coords:
						_place_tile(coord,active_item.root)
					owner.data_changed()
	return true


func rect(at: Vector2, to: Vector2, erase, preview := false):
	if active_item:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):
			var cell_coords := get_rect_cells(%PrevTilemap.local_to_map(local_at), %PrevTilemap.local_to_map(local_to))

			if preview:
				clear_preview_tilemap()
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
				owner.data_changed()
			else:
				if active_item.root is RootResTerrain:
					_place_terrain(cell_coords, active_item.root)
					owner.data_changed()

				elif active_item.root is RootResTile:
					for coord in cell_coords:
						_place_tile(coord,active_item.root)
					owner.data_changed()


func line(at: Vector2, to: Vector2, erase, preview := false):
	if active_item:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):
			var cell_coords := get_intersecting_cells(local_at,local_to)

			if preview:
				clear_preview_tilemap()
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
				owner.data_changed()
			else:
				if active_item.root is RootResTerrain:
					_place_terrain(cell_coords, active_item.root)
					owner.data_changed()

				elif active_item.root is RootResTile:
					for coord in cell_coords:
						_place_tile(coord,active_item.root)
					owner.data_changed()


func place(at: Vector2i, erase:= false):
	if active_item:
		var local_at = active_tilemap_layer.local_to_map(to_local(at))
		var standerdized_local_at  = local_at * active_tilemap_layer.tile_set.tile_size / 16
		if is_placeable_location(standerdized_local_at):
			tilemap_changed.emit()
			
			if erase:
				active_tilemap_layer.erase_cell(local_at)
				owner.data_changed()
				if active_item.bulk_placement == false:
					if active_item.root.tileset.tile_size.x == 8:
						hitbox_tilemap.erase_cell(local_at)
						
					
			else:
				if active_item.root is RootResTile:
					_place_tile(local_at,active_item.root)
					owner.data_changed()
					if active_item.bulk_placement == false:
						if active_item.root.tileset.tile_size.x == 8:
							hitbox_tilemap.set_cell(local_at,0,Vector2i(0,0),0)


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


func _update_hitbox_tilemap():
	hitbox_tilemap.clear()
		
	for cell in %Decor3Layer.get_used_cells() + %Decor2Layer.get_used_cells() + %Decor1Layer.get_used_cells():
		hitbox_tilemap.set_cell(cell,0,Vector2i(0,0),0)




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
	var placeable_rect = Rect2(-abs(owner.chunk_data.chunks_left * (owner.chunk_width-1)),0,
		abs(((owner.chunk_data.chunks_right + owner.chunk_data.chunks_left) * (owner.chunk_width-1)) + owner.chunk_width),owner.chunk_data.height)

	return placeable_rect.has_point(at)




#func _on_rotate_left_btn_pressed() -> void:
	#if active_selection.type in [SelectionRes.SelectionType.trap]:
		#if not active_selection.direction:
			#active_selection.direction = 0
			#
		#active_selection.direction = wrapi(active_selection.direction - 90,0,360)
		#active_selection.tilealtid = _get_tile_rotation_alt(active_selection.direction)
#
#
#func _on_rotate_right_btn_pressed() -> void:
	#if active_selection.type in [SelectionRes.SelectionType.trap]:
		#if active_selection.direction == null:
			#active_selection.direction = 0
			#
		#active_selection.direction = wrapi(active_selection.direction + 90,0,360)
		#active_selection.tilealtid = _get_tile_rotation_alt(active_selection.direction)


func _get_tile_rotation_alt(direction:int):
	var tile_alt: int = 0
	match direction:
		270: tile_alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE + TileSetAtlasSource.TRANSFORM_FLIP_V
		180: tile_alt = TileSetAtlasSource.TRANSFORM_FLIP_V + TileSetAtlasSource.TRANSFORM_FLIP_H
		90: tile_alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE + TileSetAtlasSource.TRANSFORM_FLIP_H
	return tile_alt
	


func _on_inventory_selection_changed(item: InventoryItem) -> void:
	if item:
		active_item = item
		for tilemap in get_children():
			if tilemap is TileMapLayer:
				if tilemap.tile_set == active_item.root.tileset:
					active_tilemap_layer = tilemap
					break
	else:
		active_item = null


func _on_tool_container_brush_changed(brush: TileMapManager.Brushes) -> void:
	active_brush = brush
	brush_down = false
	#erase_tool_start = false


func _on_main_chunk_data_updated(chunk_data: LevelChunkRes) -> void:
	%Background.tile_map_data = chunk_data.background_tile_map_data
	%Decor3Layer.tile_map_data = chunk_data.decor3_tile_map_data
	%Mainground.tile_map_data = chunk_data.mainground_tile_map_data
	%Decor2Layer.tile_map_data = chunk_data.decor2_tile_map_data
	%Decor1Layer.tile_map_data = chunk_data.decor1_tile_map_data
	
	
	preview_sprite.hide()
	hitbox_tilemap.hide()

	await get_tree().process_frame
	_update_hitbox_tilemap()
