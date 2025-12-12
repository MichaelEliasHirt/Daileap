class_name SelectionRes extends Resource

enum SelectionType {
	terrain, noterrain, wall, decor1, decor2, decor3
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
