class_name PortalSet
extends RefCounted
## This is a set class for the portal addon
##
## Holds a set of portal references. Does not allow dupes

var portal_set: Dictionary[StringName, Portal] = {}


## Add a new portal to the set if it is not on it already
func push(portal: Portal) -> void:
	if portal_set.has(portal.portal_id): return
	portal_set.set(portal.portal_id, portal)


## remove a portal from the set if it exists and return the protal
func pop(portal: StringName) -> Portal:
	if not portal_set.has(portal): return null
	var rv: Portal = portal_set.get(portal)
	portal_set.erase(portal)
	return rv


## Looks at a portal with the given id in the set if it exists. 
func peek(portal: StringName) -> Portal:
	if not portal_set.has(portal): return null
	return portal_set.get(portal) as Portal


## Checks to see if a portal by the given portal id exists
func has(portal: StringName) -> bool:
	return portal_set.has(portal)


## return the size of the portal set
func size() -> int:
	return portal_set.size()
