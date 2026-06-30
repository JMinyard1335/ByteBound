@tool
extends EditorPlugin
## Registers the [Pathfinder] addon's node types.
##
## The [RefCounted]/[Resource] helpers ([PathfinderMapper], [PathfinderSet],
## [PoissonDiskSampler], [PoissonSettings]) are global through [code]class_name[/code]
## and need no registration; only the two scene-tree nodes are added here so they show
## up in the [b]Create Node[/b] dialog.

const PatherScript = preload("res://addons/pathfinder/pathfinder-pather/pathfinder.gd")
const RegionScript = preload("res://addons/pathfinder/pathfinder-region/pathfinder_region.gd")


func _enter_tree() -> void:
	add_custom_type("Pathfinder", "NavigationAgent2D", PatherScript, null)
	add_custom_type("PathfinderRegion", "NavigationRegion2D", RegionScript, null)


func _exit_tree() -> void:
	remove_custom_type("PathfinderRegion")
	remove_custom_type("Pathfinder")
