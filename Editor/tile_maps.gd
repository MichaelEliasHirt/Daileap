extends Node2D

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



func _place_tile(at:Vector2i, source:int, tilecoords:Vector2i,tilealtid:int):
	if active_tilemap_layer:
		active_tilemap_layer.set_cell(at,source,tilecoords,tilealtid)


func _place_terrain(at:Vector2i, terrainset:int, terrainid:int):
	if active_tilemap_layer:
		print(1)
		active_tilemap_layer.set_cells_terrain_connect([at],terrainset,terrainid)


func place(at: Vector2i):

	match selection_type:
		SelectionType.tile:
			_place_tile(at, selection_tilesrc, selection_tilecoords,selection_tilealtid)
		SelectionType.terrain:
			_place_terrain(at, selection_terrainset, selection_terrainid)


func place_mouse_coords(at: Vector2):
	place(%Mainground.local_to_map(to_local(at)))
	


func _on_ui_selection_changed(selection: Dictionary) -> void:
	active_selection = selection
	print(selection)
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
