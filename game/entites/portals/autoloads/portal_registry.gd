extends Node
## Portal Registry
##
## Used to register portals. Allows portals to hold a valid ID to another portal
## The register checks the ID and then gives the coordinates of the portal back.
## The coordinates can be used to Teleport the player or pan a camera etc.

@onready var portals := PortalSet.new()


func register(portal: Portal) -> void:
	portals.push(portal)


func unregister(portal: Portal) -> void:
	portals.pop(portal.portal_id)


func has(portal: StringName) -> bool:
	return portals.has(portal)


## Gets the coordinates for the portal with the given id
func get_coords(portal: StringName) -> PortalResult:
	if not has(portal): return PortalResult.new(false, Vector2.ZERO)
	return PortalResult.new(true, portals.peek(portal).global_position)


class PortalResult:
	var ok: bool
	var coords: Vector2
	
	func _init(flag: bool, pos: Vector2):
		ok = flag
		coords = pos
