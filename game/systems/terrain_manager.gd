class_name TerrainManager
extends Node2D
## Used to control and manage a collection of tile map layers
##
##


#region Tile Layers
@onready var ground: TileMapLayer = %Ground
@onready var background: TileMapLayer = %Background
@onready var distant_background: TileMapLayer = %DistantBackground

#endregion
