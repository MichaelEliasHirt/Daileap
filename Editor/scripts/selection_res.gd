class_name SelectionRes extends Resource

enum SelectionType {
	NA, terrain, trap, wall, decor1, decor2, decor3
}

var type: SelectionType
var list: ItemList
var list_index: int

var tileset: TileSet
var texture: Texture2D
var name: String

var preview_offset: Vector2i
var tilesrc: int
var tilecoords: Vector2i
var tilealtid: int

var terrainset: int
var terrainid: int

var direction: int

func custom_duplicate() -> SelectionRes:
	var new =  SelectionRes.new()
	new.type = type
	new.list = list
	new.list_index = list_index
	new.tileset = tileset
	new.texture = texture
	new.name = name
	new.preview_offset = preview_offset
	new.tilesrc = tilesrc
	new.tilecoords  = tilecoords
	new.tilealtid = tilealtid
	new.terrainset = terrainset
	new.terrainid = terrainid
	new.direction = direction
	return new
