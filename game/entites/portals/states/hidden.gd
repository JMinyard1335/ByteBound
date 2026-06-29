extends PortalState

@export var volitile_state: PortalState

func process_frame(_delta: float) -> FSMState:
	if portal.locked: return self # if locked do nothing
	if portal.trigger_area.player: 
		return volitile_state
	return self
