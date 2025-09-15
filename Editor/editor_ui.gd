extends Control

@export_subgroup("UI-Prefences")
@export_range(0.1,20) var inv_open_strech_ratio: float = 1.5

@onready var mainground_tiles: TabContainer = %MaingroundTiles
@onready var mainground_tiles_list_container: MarginContainer = %MaingroundTilesListContainer
@onready var mainground_tiles_list: ItemList = %MaingroundTilesList
@onready var mainground_terrain_list: ItemList = %MaingroundTerrainList

@onready var inv_container: TabContainer = %InvContainer
@onready var auto_tile_btn: CheckButton = %AutoTileBtn

@onready var MaingroundTileset: TileSet = $"..".MaingroundTileset
@onready var BackgroundTileset: TileSet =  $"..".BackgroundTileset


enum selection_type {
	tile, terrain
}

var inv_open: bool = false
var auto_tile_on: bool = false

var active_tab_tree: Array[Node]
var active_selection = {
	"list": -1,
	"list_idx": -1,
	"id": null,
	"type": null,
}
var all_lists: Array[ItemList]


func _ready() -> void:
	active_tab_tree.clear()
	_create_tab_tree(inv_container)
	
	_auto_tile_btn_toggled(auto_tile_on)
	
	mainground_tiles_list.clear()
	mainground_terrain_list.clear()
	inv_container.current_tab = -1
	_close_inv()
	
	_populate_item_lists()
	
	_connect_methods()
	
	


func _create_tab_tree(start:Node):
	active_tab_tree.clear()
	while true:
		active_tab_tree.append(start)
		if start.is_in_group("InvTabContainer"):
			if start.current_tab != -1:
				start = start.get_child(start.current_tab)
				continue
		break


func _populate_item_lists():
	var tileset = MaingroundTileset
	var i = 0
	for tileset_source_count in range(tileset.get_source_count()):
		var src_id = tileset.get_source_id(tileset_source_count)
		var src : TileSetAtlasSource = tileset.get_source(src_id) as TileSetAtlasSource
		
		i += 1
		
		var container:MarginContainer
		if i != 1:
			container = mainground_tiles_list_container.duplicate(DUPLICATE_GROUPS)
			mainground_tiles.add_child(container)
		else:
			container = mainground_tiles_list_container
		
		var tiles_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TilesList"))[0]
		var terrain_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TerrainList"))[0]
		container.name = str(i)
		
		tiles_list.clear()
		terrain_list.clear()
		
		var tiles = list_all_tiles(tileset,src_id,src)
		print(tiles.size())
		for tile in tiles:
			var idx = tiles_list.add_icon_item(tile.get("texture"))
			tiles_list.set_item_metadata(idx,tile)
		
		var terrains = list_all_terrains(tileset,src_id,src)
		for terrain in terrains:
			
			var icon_texture = terrain.get("icon_tile_texture",null)
			if icon_texture == null:
				icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			
			terrain.erase("icon_tile_texture")
			terrain.erase("icon_tile_info")
				
			var idx = terrain_list.add_icon_item(icon_texture,true)
			terrain_list.set_item_tooltip_enabled(idx,true)
			terrain_list.set_item_tooltip(idx,terrain.get("name","no_name"))
			terrain_list.set_item_metadata(idx,terrain)
	


func _connect_methods():
	inv_container.tab_changed.connect(_on_inv_container_tab_changed)
	
	for btn:CheckButton in get_tree().get_nodes_in_group("AutoTileBtns"):
		btn.toggled.connect(_auto_tile_btn_toggled)
		
	for tab_container:TabContainer in get_tree().get_nodes_in_group("InvTabContainer"):
		tab_container.tab_changed.connect(_on_tab_container_tab_changed)
	
	for list: ItemList in get_tree().get_nodes_in_group("List"):
		all_lists.append(list)
		var callable = Callable(self, "_on_item_list_item_selected").bind(list)
		list.item_selected.connect(callable)


func list_all_terrains(tileset:TileSet,src_id:int,src : TileSetAtlasSource) -> Array[Dictionary]:
	var terrains: Array[Dictionary] = []
	
	for terrain_sets_idx in range(tileset.get_terrain_sets_count()):
		for terrain_idx in range(tileset.get_terrains_count(terrain_sets_idx)):
			var terrain_name = tileset.get_terrain_name(terrain_sets_idx, terrain_idx)

		# --- find first tile belonging to this terrain ---
			var icon_tile_info = null
			var icon_tile_texture: AtlasTexture = null

			for tiles_idx in range(src.get_tiles_count()):
				var tile_id := src.get_tile_id(tiles_idx)
				var tiledata := src.get_tile_data(tile_id, 0)
				if tiledata.terrain_set == terrain_sets_idx and tiledata.terrain == terrain_idx:
					icon_tile_info = {
						"source_id": src_id,
						"tile_id": tile_id,
						"atlas_coords": tile_id}

					icon_tile_texture = AtlasTexture.new()
					icon_tile_texture.atlas = src.texture
					icon_tile_texture.region = src.get_tile_texture_region(tile_id,0)
					
					break
			
			if not icon_tile_info:
				terrains.append({
					"source":tileset,
					"set": terrain_sets_idx,
					"index": terrain_idx,
					"name": terrain_name,
					"icon_tile_info": icon_tile_info,
					"icon_tile_texture": icon_tile_texture,
					"type": selection_type.terrain,
				})
			
	return terrains


func list_all_tiles(tileset:TileSet,src_id:int,src: TileSetAtlasSource) -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []

	for tiles_idx in range(src.get_tiles_count()):
		var tile_id := src.get_tile_id(tiles_idx)
		
		var tile_texture = AtlasTexture.new()
		tile_texture.atlas = src.texture
		tile_texture.region = src.get_tile_texture_region(tile_id,0)
		
		tiles.append({
			"source":tileset,
			"set": src_id,
			"index": tile_id,
			"texture": tile_texture,
			"type": selection_type.tile
		})
	
	return tiles


func _on_inv_container_tab_changed(_tab: int) -> void:
	if inv_open and inv_container.current_tab == -1:
		_close_inv()
	elif not inv_open:
		_open_inv()


func _on_tab_container_tab_changed(_tab: int) -> void:

	_create_tab_tree(inv_container)
	if active_tab_tree.back().is_in_group("TileTerrainContainer"):
		_tiles_terrain_container_update(active_tab_tree.back())


func _open_inv():
	if not inv_open:
		inv_open = true
		var tween = get_tree().create_tween()
		tween.tween_property(inv_container,"size_flags_stretch_ratio",inv_open_strech_ratio,0.2)
		await_kill_tween(tween)


func _close_inv():
	if inv_open:
		inv_open = false
		var tween = get_tree().create_tween()
		tween.tween_property(inv_container,"size_flags_stretch_ratio",0,0.1)
		await_kill_tween(tween)



func _auto_tile_btn_toggled(toggled_on: bool):
	auto_tile_on = toggled_on
	if active_tab_tree.back().is_in_group("TileTerrainContainer"):
		_tiles_terrain_container_update(active_tab_tree.back())


func _on_item_list_item_selected(index:int,list:ItemList):
	var data = list.get_item_metadata(index)
	active_selection = {
	"list": list,
	"list_idx": index,
	"type": data.get("type"),
	"id": data.get("index"),
	"set": data.get("set"),
	"source": data.get("source")
	}
	print(active_selection)
	
	for _list in all_lists:
		if _list != list:
			_list.deselect_all()

func _tiles_terrain_container_update(container:MarginContainer):
	if container.is_in_group("TileTerrainContainer"):
		for list in container.get_children():
			if list.is_in_group("TilesList"):
				list.visible = not auto_tile_on
			elif list.is_in_group("TerrainList"):
				list.visible = auto_tile_on
			elif list.name == "Control":
				list.get_child(0).button_pressed = auto_tile_on



func await_kill_tween(tween:Tween):
	await tween.finished
	tween.kill()
