class_name SelectionRes extends Resource

enum SelectionType {
	terrain, wall, decor1, decor2, decor3
}

var type: SelectionType
var list: ItemList
var list_index: int

var tileset: TileSet
var texture: Texture2D
var name: String

var tilesrc: int
var tilecoords: Vector2i
var tilealtid: int

var terrainset: int
var terrainid: int
