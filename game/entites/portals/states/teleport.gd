extends PortalState
## This is the teleport state. it is an end state.
##
## Upon leaving this state the portal should return to its default start state

@export var active_state: PortalState

func process_frame(_delta: float) -> FSMState:
	# make sure the to portal is valid
	if not PortalRegistry.has(portal.to_portal):
		push_warning("Portal Registry does not know about portal: ", portal.to_portal)
		return active_state
	
	# get the portal represented by to to_portal id
	var por: Portal = PortalRegistry.portals.peek(portal.to_portal)
	# attempt to get the portals coordinates
	var res := PortalRegistry.get_coords(portal.to_portal)
	# grab the player from the portals trigger area
	var p: Player = portal.trigger_area.player
	
	if por.locked: 
		# check if the to_portal is locked
		return active_state
	
	if not res: 
		# did we get the correct coords?
		push_error("Failed to get coordinates")
	
	# set the to portals trigger areas player.
	por.trigger_area.player = p
	p.visible = false
	# set the to portals state to active
	por.portal_state.change_state(por.portal_state.state_list.get("Active"))
	p.global_position = res.coords
	p.visible = true

	# The player just left this (source) portal; mute its collapse whoosh so the
	# teleport itself is silent. The destination was snapped to Active above.
	portal.suppress_next_transition_sfx()

	return _get_default_state()


func _get_default_state() -> PortalState:
	match portal.starting_state:
		"ACTIVE":
			return machine.state_list.get("Active")
		"VOLITILE":
			return machine.state_list.get("Volitile")
		"HIDDEN":
			return machine.state_list.get("Hidden")
		_:
			return machine.state_list.get("Volitile")
