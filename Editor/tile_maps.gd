extends Node2D

@onready var debug_info_label: Label = %DebugInfoLabel
@onready var grid: ColorRect = %HighlightGrid

signal tilemap_changed

enum SelectionType {
	tile, terrain
}

var active_selection : Dictionary
var selection_type : SelectionType
var selection_tileset : TileSet
var selection_tilesrc : int
var selection_tilecoords : Vector2i
var selection_tilealtid: int
var selection_terrainset: int
var selection_terrainid: int

var active_tilemap_layer: TileMapLayer

var last_coords: Vector2i


func _process(_delta: float) -> void:
	var coords = %Mainground.local_to_map(get_local_mouse_position())
	if coords != last_coords:
		last_coords = coords
		debug_info_label.update_info(coords)
	
	grid.material.set_shader_parameter("mouse_position", grid.get_global_mouse_position())


func _place_tile(at:Vector2i, source:int, tilecoords:Vector2i,tilealtid:int):
	if active_tilemap_layer:
		active_tilemap_layer.set_cell(at,source,tilecoords,tilealtid)


func _place_terrain(ats:Array[Vector2i], terrainset:int, terrainid:int):
	if active_tilemap_layer:
		active_tilemap_layer.set_cells_terrain_connect(ats,terrainset,terrainid)


func place(at: Vector2i, temp = false):
	if active_selection:
		if is_placeable_location(at):
			if temp:
				%PrevTilemap.set_cell(at,0,Vector2i(0,0),0)
				return
			tilemap_changed.emit()
			match selection_type:
				SelectionType.tile:
					_place_tile(at, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				SelectionType.terrain:
					_place_terrain([at], selection_terrainset, selection_terrainid)


func erase(at: Vector2i, temp = false):
	if active_selection:
		if is_placeable_location(at):
			if active_tilemap_layer:
				if temp:
					%PrevTilemap.set_cell(at,0,Vector2i(1,0),0)
					return
				tilemap_changed.emit()
				active_tilemap_layer.erase_cell(at)


func erase_mouse_coords(at: Vector2, temp = false):
	erase(%Mainground.local_to_map(to_local(at)),temp)


func place_mouse_coords(at: Vector2, temp = false):
	place(%Mainground.local_to_map(to_local(at)),temp)


func clear_temp():
	%PrevTilemap.clear()


func is_hovering_temp(at:Vector2) -> bool:
	return %PrevTilemap.get_cell_source_id(%PrevTilemap.local_to_map(to_local(at))) != -1


func fill_by_tile_mouse_coords(at: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_cell(%PrevTilemap.local_to_map(local_at))

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			match selection_type:
				SelectionType.tile:
					for coords in cell_coords:
						_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				SelectionType.terrain:
					_place_terrain(cell_coords, selection_terrainset, selection_terrainid)


func erase_fill_by_tile_mouse_coords(at: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_cell(%PrevTilemap.local_to_map(local_at))

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			for coords in cell_coords:
				active_tilemap_layer.erase_cell(coords)


func fill_by_terrain_mouse_coords(at: Vector2, temp = false) -> bool:
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_terrain(%PrevTilemap.local_to_map(local_at))
			if cell_coords.is_empty():
				return false
			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return true
			
			tilemap_changed.emit()
			match selection_type:
				SelectionType.tile:
					for coords in cell_coords:
						_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				SelectionType.terrain:
					_place_terrain(cell_coords, selection_terrainset, selection_terrainid)
	return true

func erase_fill_by_terrain_mouse_coords(at: Vector2, temp = false) -> bool:
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)):
			var cell_coords := get_fill_cells_by_terrain(%PrevTilemap.local_to_map(local_at))
			if cell_coords.is_empty():
				return false
			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				return true
			
			tilemap_changed.emit()
			for coords in cell_coords:
				active_tilemap_layer.erase_cell(coords)
	return true


func rect_mouse_coords(at: Vector2, to: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):
			var cell_coords := get_rect_cells(%PrevTilemap.local_to_map(local_at), %PrevTilemap.local_to_map(local_to))

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			match selection_type:
				SelectionType.tile:
					for coords in cell_coords:
						_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				SelectionType.terrain:
					_place_terrain(cell_coords, selection_terrainset, selection_terrainid)


func erase_rect_mouse_coords(at: Vector2, to: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):
			var cell_coords := get_rect_cells(%PrevTilemap.local_to_map(local_at), %PrevTilemap.local_to_map(local_to))

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				return
			
			tilemap_changed.emit()
			for coords in cell_coords:
				active_tilemap_layer.erase_cell(coords)


func line_mouse_coords(at: Vector2, to: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):

			var cell_coords := get_intersecting_cells(local_at,local_to)

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(0,0),0)
				return
			
			tilemap_changed.emit()
			match selection_type:
				SelectionType.tile:
					for coords in cell_coords:
						_place_tile(coords, selection_tilesrc, selection_tilecoords,selection_tilealtid)
				SelectionType.terrain:
					_place_terrain(cell_coords, selection_terrainset, selection_terrainid)


func erase_line_mouse_coords(at: Vector2, to: Vector2, temp = false):
	if active_selection:
		var local_at = %PrevTilemap.to_local(at)
		var local_to = %PrevTilemap.to_local(to)
		if is_placeable_location(%PrevTilemap.local_to_map(local_at)) and is_placeable_location(%PrevTilemap.local_to_map(local_to)):

			var cell_coords := get_intersecting_cells(local_at,local_to)

			if temp:
				clear_temp()
				for coords in cell_coords:
					%PrevTilemap.set_cell(coords,0,Vector2i(1,0),0)
				return
			
			tilemap_changed.emit()
			for coords in cell_coords:
				active_tilemap_layer.erase_cell(coords)


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


func is_placeable_location(at:Vector2i):
	var placeable_rect = Rect2i(-abs(owner.chunks_left * (owner.chunk_width-1)),0,
		abs(((owner.chunks_right + owner.chunks_left) * (owner.chunk_width-1)) + owner.chunk_width),owner.height)

	return placeable_rect.has_point(at)


func _on_ui_selection_changed(selection: Dictionary) -> void:
	active_selection = selection
	if active_selection:
		selection_type = active_selection.get("type")
		match selection_type:
			SelectionType.tile:
				selection_tileset = active_selection.get("tileset")
				selection_tilesrc = active_selection.get("tilesrc")
				selection_tilecoords = active_selection.get("tilecoords")
				selection_tilealtid = active_selection.get("tilealtid")
				
			SelectionType.terrain:
				selection_tileset = active_selection.get("tileset")
				selection_terrainset = active_selection.get("terrainset")
				selection_terrainid = active_selection.get("terrainid")
			_:
				print("tf")

	
		for tilemap in get_children():
			if tilemap is TileMapLayer:
				if tilemap.tile_set == selection.get("tileset"):
					active_tilemap_layer = tilemap
					print(active_tilemap_layer)
					break
