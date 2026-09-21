extends TabContainer
class_name Inventory

@export var inventory_groups: Array[InventoryGroupRes]

@export_subgroup("tilesets")
@export var tiles_tileset: TileSet
@export var walls_tileset: TileSet
@export var decor1_tileset: TileSet
@export var decor2_tileset: TileSet
@export var decor3_tileset: TileSet
@onready var all_tileset: Array[TileSet] = [tiles_tileset,walls_tileset,decor1_tileset,decor2_tileset,decor3_tileset]

@onready var original_group_container: InventoryGroupContainer = %GroupContainer
#@onready var group_selector: OptionButton = $GroupSelector

var all_items_from_tilesets: Array[Dictionary]

signal selection_changed(item: InventoryItem)


func _ready() -> void:
	_populate_inventory()


func _populate_inventory():
	_update_all_items_from_tilesets()
	for group in inventory_groups:
		var group_container = original_group_container.duplicate(DUPLICATE_GROUPS|DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
		add_child(group_container)
		
		group_container.name = group.name
		group_container.title = group.name
		group_container.groups = group.groups
		group_container.themes = group.themes
		group_container.color = group.color
		
		
		group_container.populate_group()
	original_group_container.queue_free()
	
	for node: ItemList in get_tree().get_nodes_in_group("InventoryItemLists"):
		node.connect("item_selected",selected_new_item.bind(node))


func selected_new_item(idx: int,item_list: ItemList):
	var item = item_list.get_item_metadata(idx) as InventoryItem
	selection_changed.emit(item)
	
	for node in get_tree().get_nodes_in_group("InventoryItemLists"):
		if node != item_list:
			node.deselect_all()


func _update_all_items_from_tilesets():
	all_items_from_tilesets.clear()
	for tileset in all_tileset:
		var all_items := {}
		
		for terrain_set_idx in range(tileset.get_terrain_sets_count()):
			for terrain_idx in range(tileset.get_terrains_count(terrain_set_idx)):
				var terrain_name = tileset.get_terrain_name(terrain_set_idx,terrain_idx)
				if terrain_name.begins_with("#"):
					
					var item = InventoryItem.new(terrain_name,RootResTerrain.new(tileset,terrain_set_idx,terrain_idx))
					
					all_items.set(item.name,item)
					
					
		for source_idx in range(tileset.get_source_count()):
			var source_id = tileset.get_source_id(source_idx)
			var source = tileset.get_source(source_id)
			var source_name = source.resource_name
			if source_name.begins_with("#"):
				for tile_idx in source.get_tiles_count():
					var tile_coords = source.get_tile_id(tile_idx)
					for tile_alt_idx in source.get_alternative_tiles_count(tile_coords):
						var tile_alt_id = source.get_alternative_tile_id(tile_coords,tile_alt_idx)
						
						var item = InventoryItem.new(source_name,RootResTile.new(tileset,source_id,tile_coords,tile_alt_id))
						
						all_items.set(item.name,item)
		
		all_items_from_tilesets.append(all_items)


#func _populate_item_lists():
	### Populate the "Tiles" Tab
	#tiles_list.clear()
	#
	###get all the items for the item lists
	#var all_autotiles = _list_all_terrains_from_tileset(tiles_tileset,SelectionRes.SelectionType.terrain)
	#
	#var tiles_containers: Dictionary[String,MarginContainer]
	#var first := true
	#for autotile in all_autotiles:
		#var auto_tile_group_name := ""
		#var container: MarginContainer
		### check if the item name beginns with a old group name if so add it to a group
		#if not tiles_containers.is_empty():
			#for group_name in tiles_containers.keys():
				#if autotile.name.begins_with(group_name):
					#auto_tile_group_name = group_name
					#container = tiles_containers.get(group_name)
					#break
		### check if the item name beginns with a new group name if make a new group with the item
		#if auto_tile_group_name.is_empty():
			#for group_name in tiles_tileset_info.group_names:
				#if autotile.name.begins_with(group_name):
					#auto_tile_group_name = group_name
					#break
		### when the item didnt match a group yet its asorted to "other" if there is already a "other" group it gets added,
		### otherwise it creates a new one
		#if auto_tile_group_name.is_empty():
			#auto_tile_group_name = "other"
			#if tiles_containers.has(auto_tile_group_name):
				#container = tiles_containers.get(auto_tile_group_name)
		### makes a new container for new group except its the first group then it uses the original container
		#var tiles_list_: ItemList
		#if not container:
			### first container gets used
			#if first:
				#first = false
				#container = tiles_list_container
				#tiles_list_ = container.get_child(0)
			#else:
				### new container gets duplicated from the first one (make sure to clear its itemlists)
				#container = tiles_list_container.duplicate(DUPLICATE_GROUPS)
				#tiles_control.add_child(container)
				#tiles_list_ = container.get_child(0)
				#tiles_list_.clear()
			#
			#tiles_containers.set(auto_tile_group_name,container)
			#container.name = auto_tile_group_name
		#else:
			### if no new container is created just use previously asigned one
			#tiles_list_ = container.get_child(0)
		#
		### set the icon for the item
		#var icon_texture = autotile.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			#
		#var idx = tiles_list_.add_icon_item(icon_texture,true)
		#tiles_list_.set_item_tooltip_enabled(idx,true)
		#tiles_list_.set_item_tooltip(idx,autotile.name)
		#tiles_list_.set_item_metadata(idx,autotile)
	#_sort_children_by_list(tiles_control,tiles_tileset_info.group_names)
#
	##background_tiles_list.clear()
	##background_terrain_list.clear()
	##tileset = BackgroundTileset
	##i = 0
	##for tileset_source_count in range(tileset.get_source_count()):
		##var src_id = tileset.get_source_id(tileset_source_count)
		##var src : TileSetAtlasSource = tileset.get_source(src_id) as TileSetAtlasSource
		##
		##i += 1
		##
		##var container:MarginContainer
		##if i != 1:
			##container = background_tiles_list_container.duplicate(DUPLICATE_GROUPS)
			##background_tiles.add_child(container)
		##else:
			##container = background_tiles_list_container
		##
		##var tiles_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TilesList"))[0]
		##var terrain_list: ItemList = container.get_children().filter(func(x): return x.is_in_group("TerrainList"))[0]
		##container.name = str(i)
		##
		##tiles_list.clear()
		##terrain_list.clear()
		##
		##var tiles = list_all_tiles(tileset,src_id,src)
		##
		##for tile in tiles:
			##var idx = tiles_list.add_icon_item(tile.get("texture"))
			##
			##tile.erase("texture")
			##
			##tiles_list.set_item_metadata(idx,tile)
		##
		##var terrains = list_all_terrains(tileset,src_id,src,)
		##for terrain in terrains:
			##
			##var icon_texture = terrain.get("icon_tile_texture",null)
			##if icon_texture == null:
				##icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			##
			##terrain.erase("icon_tile_texture")
			##terrain.erase("texture")
			##terrain.erase("name")
				##
			##var idx = terrain_list.add_icon_item(icon_texture,true)
			##terrain_list.set_item_tooltip_enabled(idx,true)
			##terrain_list.set_item_tooltip(idx,terrain.get("name","no_name"))
			##terrain_list.set_item_metadata(idx,terrain)
#
#
	### Populate the "Walls" tab
	#walls_list.clear()
	#
	###this just is duplicate code, I know bad, but I really rather just copied the code instead of making huge confusing functions
	#var all_walls = _list_all_terrains_from_tileset(walls_tileset,SelectionRes.SelectionType.wall)
	#
	#var walls_containers: Dictionary[String,MarginContainer]
	#first = true
	#for wall in all_walls:
		#var walls_group_name := ""
		#var container: MarginContainer
		#if not walls_containers.is_empty():
			#for group_name in walls_containers.keys():
				#if wall.name.begins_with(group_name):
					#walls_group_name = group_name
					#container = walls_containers.get(group_name)
					#break
		#if walls_group_name.is_empty():
			#for group_name in walls_tileset_info.group_names:
				#if wall.name.begins_with(group_name):
					#walls_group_name = group_name
					#break
		#
		#if walls_group_name.is_empty():
			#walls_group_name = "other"
			#if walls_containers.has(walls_group_name):
				#container = walls_containers.get(walls_group_name)
				#
		#var walls_list_: ItemList
		#if not container:
			#if first:
				#first = false
				#container = walls_list_container
				#walls_list_ = container.get_child(0)
			#else:
				#container = walls_list_container.duplicate(DUPLICATE_GROUPS)
				#tiles_control.add_child(container)
				#walls_list_ = container.get_child(0)
				#walls_list_.clear()
			#
			#walls_containers.set(walls_group_name,container)
			#container.name = walls_group_name
		#else:
			#walls_list_ = container.get_child(0)
		 #
		#var icon_texture = wall.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			#
		#var idx = walls_list_.add_icon_item(icon_texture,true)
		#walls_list_.set_item_tooltip_enabled(idx,true)
		#walls_list_.set_item_tooltip(idx,wall.name)
		#walls_list_.set_item_metadata(idx,wall)
	#_sort_children_by_list(walls_control,walls_tileset_info.group_names)
	#
	#
	###Populate the "Decor" Tab
	#
	### basicly the same again, but this time the container is a little more complex, because of "layers"
	#
	#decor_1_list.clear()
	#decor_2_list.clear()
	#decor_3_list.clear()
	#
	#var all_decor1tiles = _list_all_tiles_from_tileset(decor1_tileset,SelectionRes.SelectionType.decor1)
	#var all_decor2tiles = _list_all_tiles_from_tileset(decor2_tileset,SelectionRes.SelectionType.decor2)
	#var all_decor3tiles = _list_all_tiles_from_tileset(decor3_tileset,SelectionRes.SelectionType.decor3)
	#
	#var decortiles_containers: Dictionary[String,MarginContainer]
	#first = true
	#for decortile in all_decor1tiles:
		#var tile_group_name := ""
		#var container: MarginContainer
		#if not decortiles_containers.is_empty():
			#for group_name in decortiles_containers.keys():
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#container = decortiles_containers.get(group_name)
					#break
		#if tile_group_name.is_empty():
			#for group_name in decor1_tileset_info.group_names:
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#break
		#
		#if tile_group_name.is_empty():
			#tile_group_name = "other"
			#if decortiles_containers.has(tile_group_name):
				#container = decortiles_containers.get(tile_group_name)
		#var tiles_list_: ItemList
		#if not container:
			#if first:
				#first = false
				#container = decor_list_container
				#tiles_list_ = container.decor_1_list
			#else:
				### make sure too clear out ALL the item lists
				#container = decor_list_container.duplicate()
				#decor_control.add_child(container)
				#tiles_list_ = container.decor_1_list
				#container.decor_2_list.clear()
				#container.decor_3_list.clear()
				#tiles_list_.clear()
			#
			#decortiles_containers.set(tile_group_name,container)
			#container.name = tile_group_name
		#else:
			#tiles_list_ = container.decor_1_list
		#
		#var icon_texture = decortile.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("uid://clmxr0gm1perm"))
			#
		#var idx = tiles_list_.add_icon_item(icon_texture,true)
		#tiles_list_.set_item_tooltip_enabled(idx,true)
		#tiles_list_.set_item_tooltip(idx,decortile.name)
		#tiles_list_.set_item_metadata(idx,decortile)
	#
	#for decortile in all_decor2tiles:
		#var tile_group_name := ""
		#var container: MarginContainer
		#if not decortiles_containers.is_empty():
			#for group_name in decortiles_containers.keys():
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#container = decortiles_containers.get(group_name)
					#break
		#if tile_group_name.is_empty():
			#for group_name in decor2_tileset_info.group_names:
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#break
		#
		#if tile_group_name.is_empty():
			#tile_group_name = "other"
			#if decortiles_containers.has(tile_group_name):
				#container = decortiles_containers.get(tile_group_name)
		#var tiles_list_: ItemList
		#if not container:
			#if first:
				#first = false
				#container = decor_list_container
				#tiles_list_ = container.decor_2_list
			#else:
				### make sure too clear out ALL the item lists
				#container = decor_list_container.duplicate()
				#decor_control.add_child(container)
				#tiles_list_ = container.decor_2_list
				#tiles_list_.clear()
				#container.decor_1_list.clear()
				#container.decor_3_list.clear()
				#tiles_list_.clear()
			#
			#decortiles_containers.set(tile_group_name,container)
			#container.name = tile_group_name
		#else:
			#tiles_list_ = container.decor_2_list
		#
		#var icon_texture = decortile.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("uid://clmxr0gm1perm"))
			#
		#var idx = tiles_list_.add_icon_item(icon_texture,true)
		#tiles_list_.set_item_tooltip_enabled(idx,true)
		#tiles_list_.set_item_tooltip(idx,decortile.name)
		#tiles_list_.set_item_metadata(idx,decortile)
	#
	#for decortile in all_decor3tiles:
		#var tile_group_name := ""
		#var container: MarginContainer
		#if not decortiles_containers.is_empty():
			#for group_name in decortiles_containers.keys():
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#container = decortiles_containers.get(group_name)
					#break
		#if tile_group_name.is_empty():
			#for group_name in decor3_tileset_info.group_names:
				#if decortile.name.begins_with(group_name):
					#tile_group_name = group_name
					#break
		#
		#if tile_group_name.is_empty():
			#tile_group_name = "other"
			#if decortiles_containers.has(tile_group_name):
				#container = decortiles_containers.get(tile_group_name)
		#var tiles_list_: ItemList
		#if not container:
			#if first:
				#first = false
				#container = decor_list_container
				#tiles_list_ = container.decor_3_list
			#else:
				### make sure too clear out ALL the item lists
				#container = decor_list_container.duplicate()
				#decor_control.add_child(container)
				#tiles_list_ = container.decor_3_list
				#tiles_list_.clear()
				#container.decor_1_list.clear()
				#container.decor_2_list.clear()
				#tiles_list_.clear()
			#
			#decortiles_containers.set(tile_group_name,container)
			#container.name = tile_group_name
		#else:
			#tiles_list_ = container.decor_3_list
		#
		#var icon_texture = decortile.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("uid://clmxr0gm1perm"))
			#
		#var idx = tiles_list_.add_icon_item(icon_texture,true)
		#tiles_list_.set_item_tooltip_enabled(idx,true)
		#tiles_list_.set_item_tooltip(idx,decortile.name)
		#tiles_list_.set_item_metadata(idx,decortile)
	#
	#var combinded_sorting_list = _combine_arrays(decor1_tileset_info.group_names,_combine_arrays(decor2_tileset_info.group_names,decor3_tileset_info.group_names))
	#_sort_children_by_list(decor_control,combinded_sorting_list)
	#
	#
	### Populate the "Traps" tab
	#traps_list.clear()
	#
	#var all_traps = _list_all_tiles_from_tileset(tiles_tileset,SelectionRes.SelectionType.NA)
	#all_traps = all_traps.filter(func(x): return x.type == SelectionRes.SelectionType.trap)
	#
	#var trap_containers: Dictionary[String,MarginContainer]
	#first = true
	#for trap in all_traps:
		#var trap_group_name := ""
		#var container: MarginContainer
		#if not trap_containers.is_empty():
			#for group_name in trap_containers.keys():
				#if trap.name.begins_with(group_name):
					#trap_group_name = group_name
					#container = trap_containers.get(group_name)
					#break
		#if trap_group_name.is_empty():
			#for group_name in traps_tileset_info.group_names:
				#if trap.name.begins_with(group_name):
					#trap_group_name = group_name
					#break
		#
		#if trap_group_name.is_empty():
			#trap_group_name = "other"
			#if trap_containers.has(trap_group_name):
				#container = trap_containers.get(trap_group_name)
		#
		#var trap_list_: ItemList
		#if not container:
			#if first:
				#first = false
				#container = trap_list_container
				#trap_list_ = container.get_child(0)
			#else:
				#container = trap_list_container.duplicate(DUPLICATE_GROUPS)
				#traps_control.add_child(container)
				#trap_list_ = container.get_child(0)
				#trap_list_.clear()
			#
			#trap_containers.set(trap_group_name,container)
			#container.name = trap_group_name
		#else:
			#trap_list_ = container.get_child(0)
		 #
		#var icon_texture = trap.texture
		#if icon_texture == null:
			#icon_texture = ImageTexture.create_from_image(load("res://assets/icon.svg"))
			#
		#var idx = trap_list_.add_icon_item(icon_texture,true)
		#trap_list_.set_item_tooltip_enabled(idx,true)
		#trap_list_.set_item_tooltip(idx,trap.name)
		#trap_list_.set_item_metadata(idx,trap)
	#_sort_children_by_list(traps_control,traps_tileset_info.group_names)
