class_name EditorUIManager extends Control

@export_subgroup("UI-Prefences")
@export_range(0.1,20) var inv_open_strech_ratio: float = 1.5

@onready var tiles_control: TabContainer = %Tiles
@onready var tiles_list_container: MarginContainer = %Tiles/ListContainer
@onready var tiles_list: ItemList = %TilesList

@onready var walls_control: TabContainer = %Walls
@onready var walls_list_container: MarginContainer = %Walls/ListContainer
@onready var walls_list: ItemList = %WallsList


@onready var vertical_slider: VSlider = %VerticalSlider

@onready var inv_container: TabContainer = %InvContainer
@onready var settings_container: Control = %SettingsContainer
@onready var save_menu_container: Control = %SaveMenuContainer

@onready var tiles_tileset: TileSet = owner.tiles_tileset
@onready var walls_tileset: TileSet =  owner.walls_tileset
@onready var tiles_tileset_info: TileSetInfo = owner.tiles_tileset_info
@onready var walls_tileset_info: TileSetInfo = owner.walls_tileset_info

enum SelectionType {
	terrain, wall,decor1, decor2, decor3
}


signal selection_changed(selection:Dictionary)
signal settings_closed

var inv_open: bool = false
var settings_open: bool = false
var save_menu_open: bool = false

var active_tab_tree: Array[Node]
var active_selection = {
	"list": -1,
	"list_idx": -1,
	"type":null,
	"tileset": null,
	"tilesrc": null,
	"tilecoords": null,
	"tilealtid":null,
	"terrainset":null,
	"terrainid":null,
}
var all_lists: Array[ItemList]


func _ready() -> void:
	active_tab_tree.clear()
	_create_tab_tree(inv_container)
	

	inv_container.current_tab = -1
	_close_inv()
	
	_populate_item_lists()
	
	_connect_methods()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				vertical_slider.value += 3. / owner.height
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				vertical_slider.value -= 3. / owner.height


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
	tiles_list.clear()
	
	var tileset = tiles_tileset
	var all_autotiles: Array[Dictionary]
	for tileset_source_count in range(tileset.get_source_count()):
		var src_id = tileset.get_source_id(tileset_source_count)
		
		var autotiles = list_all_terrains(tileset,src_id,SelectionType.terrain)
		all_autotiles.append_array(autotiles)
	
	var tiles_containers: Dictionary[String,MarginContainer]
	var first := true
	for autotile in all_autotiles:
		var auto_tile_group_name := ""
		var container: MarginContainer
		if not tiles_containers.is_empty():
			for group_name in tiles_containers.keys():
				if autotile.get("name","no_name").begins_with(group_name):
					auto_tile_group_name = group_name
					container = tiles_containers.get(group_name)
					break
		if auto_tile_group_name.is_empty():
			for group_name in tiles_tileset_info.group_names:
				if autotile.get("name","no_name").begins_with(group_name):
					auto_tile_group_name = group_name
					break
		
		if auto_tile_group_name.is_empty():
			auto_tile_group_name = "other"
			if tiles_containers.has(auto_tile_group_name):
				container = tiles_containers.get(auto_tile_group_name)
		var tiles_list_: ItemList
		if not container:
			if first:
				first = false
				container = tiles_list_container
				tiles_list_ = container.get_child(0)
			else:
				container = tiles_list_container.duplicate(DUPLICATE_GROUPS)
				tiles_control.add_child(container)
				tiles_list_ = container.get_child(0)
				tiles_list_.clear()
			
			tiles_containers.set(auto_tile_group_name,container)
			container.name = auto_tile_group_name
		else:
			tiles_list_ = container.get_child(0)
		 
			
		
		var icon_texture = autotile.get("icon_tile_texture",null)
		if icon_texture == null:
			icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			
		var idx = tiles_list_.add_icon_item(icon_texture,true)
		tiles_list_.set_item_tooltip_enabled(idx,true)
		tiles_list_.set_item_tooltip(idx,autotile.get("name","no_name"))
		tiles_list_.set_item_metadata(idx,autotile)
		
		autotile.erase("icon_tile_texture")
		autotile.erase("texture")
		autotile.erase("name")

	#background_tiles_list.clear()
	#background_terrain_list.clear()
	#tileset = BackgroundTileset
	#i = 0
	#for tileset_source_count in range(tileset.get_source_count()):
		#var src_id = tileset.get_source_id(tileset_source_count)
		#var src : TileSetAtlasSource = tileset.get_source(src_id) as TileSetAtlasSource
		#
		#i += 1
		#
		#var container:MarginContainer
		#if i != 1:
			#container = background_tiles_list_container.duplicate(DUPLICATE_GROUPS)
			#background_tiles.add_child(container)
		#else:
			#container = background_tiles_list_container
		#
		#var tiles_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TilesList"))[0]
		#var terrain_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TerrainList"))[0]
		#container.name = str(i)
		#
		#tiles_list.clear()
		#terrain_list.clear()
		#
		#var tiles = list_all_tiles(tileset,src_id,src)
		#
		#for tile in tiles:
			#var idx = tiles_list.add_icon_item(tile.get("texture"))
			#
			#tile.erase("texture")
			#
			#tiles_list.set_item_metadata(idx,tile)
		#
		#var terrains = list_all_terrains(tileset,src_id,src,)
		#for terrain in terrains:
			#
			#var icon_texture = terrain.get("icon_tile_texture",null)
			#if icon_texture == null:
				#icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			#
			#terrain.erase("icon_tile_texture")
			#terrain.erase("texture")
			#terrain.erase("name")
				#
			#var idx = terrain_list.add_icon_item(icon_texture,true)
			#terrain_list.set_item_tooltip_enabled(idx,true)
			#terrain_list.set_item_tooltip(idx,terrain.get("name","no_name"))
			#terrain_list.set_item_metadata(idx,terrain)

	walls_list.clear()
	
	tileset = walls_tileset
	var all_walls: Array[Dictionary]
	for tileset_source_count in range(tileset.get_source_count()):
		var src_id = tileset.get_source_id(tileset_source_count)
		
		var wall = list_all_terrains(tileset,src_id,SelectionType.wall)
		all_walls.append_array(wall)
	
	var walls_containers: Dictionary[String,MarginContainer]
	first = true
	for wall in all_walls:
		var walls_group_name := ""
		var container: MarginContainer
		if not tiles_containers.is_empty():
			for group_name in walls_containers.keys():
				if wall.get("name","no_name").begins_with(group_name):
					walls_group_name = group_name
					container = tiles_containers.get(group_name)
					break
		if walls_group_name.is_empty():
			for group_name in walls_tileset_info.group_names:
				if wall.get("name","no_name").begins_with(group_name):
					walls_group_name = group_name
					break
		
		if walls_group_name.is_empty():
			walls_group_name = "other"
			if walls_containers.has(walls_group_name):
				container = walls_containers.get(walls_group_name)
				
		var walls_list_: ItemList
		if not container:
			if first:
				first = false
				container = walls_list_container
				walls_list_ = container.get_child(0)
			else:
				container = walls_list_container.duplicate(DUPLICATE_GROUPS)
				tiles_control.add_child(container)
				walls_list_ = container.get_child(0)
				walls_list_.clear()
			
			walls_containers.set(walls_group_name,container)
			container.name = walls_group_name
		else:
			walls_list_ = container.get_child(0)
		 
		var icon_texture = wall.get("icon_tile_texture",null)
		if icon_texture == null:
			icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			
		var idx = walls_list_.add_icon_item(icon_texture,true)
		walls_list_.set_item_tooltip_enabled(idx,true)
		walls_list_.set_item_tooltip(idx,wall.get("name","no_name"))
		walls_list_.set_item_metadata(idx,wall)
		
		wall.erase("icon_tile_texture")
		wall.erase("texture")
		wall.erase("name")


func _connect_methods():
	inv_container.tab_changed.connect(_on_inv_container_tab_changed)
		
	for tab_container:TabContainer in get_tree().get_nodes_in_group("InvTabContainer"):
		tab_container.tab_changed.connect(_on_tab_container_tab_changed)
	
	for list: ItemList in get_tree().get_nodes_in_group("List"):
		all_lists.append(list)
		var callable = Callable(self, "_on_item_list_item_selected").bind(list)
		list.item_selected.connect(callable)


func list_all_terrains(tileset:TileSet,_src_id:int,type = SelectionType) -> Array[Dictionary]:
	var src : TileSetAtlasSource = tileset.get_source(_src_id) as TileSetAtlasSource
	var terrains: Array[Dictionary] = []
	
	for terrain_sets_idx in range(tileset.get_terrain_sets_count()):
		for terrain_idx in range(tileset.get_terrains_count(terrain_sets_idx)):
			var terrain_name = tileset.get_terrain_name(terrain_sets_idx, terrain_idx)

		# --- find first tile belonging to this terrain ---
			var icon_tile_texture: AtlasTexture = null

			for tiles_idx in range(src.get_tiles_count()):
				var tile_id := src.get_tile_id(tiles_idx)
				var tiledata := src.get_tile_data(tile_id, 0)
				if tiledata.terrain_set == terrain_sets_idx and tiledata.terrain == terrain_idx:
					icon_tile_texture = AtlasTexture.new()
					icon_tile_texture.atlas = src.texture
					icon_tile_texture.region = src.get_tile_texture_region(tile_id,0)
					
					break
			
			if icon_tile_texture:
				terrains.append({
					"tileset":tileset,
					"terrainset": terrain_sets_idx,
					"terrainid": terrain_idx,
					"name": terrain_name,
					"icon_tile_texture": icon_tile_texture,
					"type": type
				})
			
	return terrains


#func list_all_tiles(tileset:TileSet,src_id:int,src: TileSetAtlasSource) -> Array[Dictionary]:
	#var tiles: Array[Dictionary] = []
#
	#for tiles_idx in range(src.get_tiles_count()):
		#var tile_id := src.get_tile_id(tiles_idx)
		#var tile_altid:int
		#if not (src.get_alternative_tiles_count(tile_id)-1):
			#tile_altid = 0
		#else:
			#tile_altid = src.get_alternative_tile_id(tile_id,0)
		#
		#var tile_texture = AtlasTexture.new()
		#tile_texture.atlas = src.texture
		#tile_texture.region = src.get_tile_texture_region(tile_id,0)
		#
		#tiles.append({
			#"tileset":tileset,
			#"tilesrc": src_id,
			#"tilecoords": tile_id,
			#"tilealtid": tile_altid,
			#"texture": tile_texture,
			#"type": SelectionType.tile
		#})
	#
	#return tiles


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
		%MoveButtonContainer.hide()
		inv_open = true
		var tween = get_tree().create_tween()
		tween.tween_property(inv_container,"size_flags_stretch_ratio",inv_open_strech_ratio,0.2)
		await_kill_tween(tween)


func _close_inv():
	if inv_open:
		inv_open = false
		var tween = get_tree().create_tween()
		tween.tween_property(inv_container,"size_flags_stretch_ratio",0,0.1)
		await await_kill_tween(tween)
		%MoveButtonContainer.show()


func _on_item_list_item_selected(index:int,list:ItemList):
	active_selection = list.get_item_metadata(index).duplicate(true)
	
	selection_changed.emit(active_selection)
	
	active_selection.merge({"list":list,"list_idx": index})
	
	
	for _list in all_lists:
		if _list != list:
			_list.deselect_all()


func deselect_selection():
	active_selection = {}
	selection_changed.emit(active_selection)
	for _list in all_lists:
		_list.deselect_all()


func _tiles_terrain_container_update(container:MarginContainer):
	pass
	#if container.is_in_group("TileTerrainContainer"):
		#for list in container.get_children():
			#if list.is_in_group("TilesList"):
				#list.visible = not auto_tile_on
			#elif list.is_in_group("TerrainList"):
				#list.visible = auto_tile_on
			#elif list.name == "Control":
				#list.get_child(0).button_pressed = auto_tile_on



func await_kill_tween(tween:Tween):
	await tween.finished
	tween.kill()


func _on_settings_btn_pressed() -> void:
	if not settings_open:
		%GreyOut.show()
		await _close_save_menu()
		_open_settings()
	else:
		_close_settings()
		%GreyOut.hide()
		


func _open_settings():
	if not settings_open:
		settings_open = true
		settings_container.show()
		var tween = get_tree().create_tween()
		tween.tween_property(settings_container,"size_flags_stretch_ratio",0.5,0.1)
		await_kill_tween(tween)


func _close_settings():
	if settings_open:
		settings_closed.emit()
		settings_open = false
		var tween = get_tree().create_tween()
		tween.tween_property(settings_container,"size_flags_stretch_ratio",0,0.1)
		await await_kill_tween(tween)
		settings_container.hide()


func _on_save_btn_pressed() -> void:
	if not save_menu_open:
		%GreyOut.show()
		await _close_settings()
		_open_save_menu()
		
	else:
		_close_save_menu()
		%GreyOut.hide()


func _open_save_menu():
	if not save_menu_open:
		save_menu_open = true
		save_menu_container.show()
		var tween = get_tree().create_tween()
		tween.tween_property(save_menu_container,"size_flags_stretch_ratio",0.5,0.1)
		await_kill_tween(tween)


func _close_save_menu():
	if save_menu_open:
		save_menu_open = false
		var tween = get_tree().create_tween()
		tween.tween_property(save_menu_container,"size_flags_stretch_ratio",0,0.1)
		await await_kill_tween(tween)
		save_menu_container.hide()
