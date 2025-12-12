class_name LevelChunkRes extends Resource


@export var UID: String
@export var valid: bool
@export var name: String
@export var difficulty: int

@export var mainground_tile_map_data : PackedByteArray = PackedByteArray()
@export var background_tile_map_data : PackedByteArray = PackedByteArray()
@export var decor1_tile_map_data : PackedByteArray = PackedByteArray()
@export var decor2_tile_map_data : PackedByteArray = PackedByteArray()
@export var decor3_tile_map_data : PackedByteArray = PackedByteArray()

@export var height: int
@export var chunks_left: int
@export var chunks_right: int
@export var exit_chunk: int
