extends Node2D


@export var portals: Array[Portal] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for p in portals:
		PortalRegistry.register(p)
	
	pass # Replace with function body.
