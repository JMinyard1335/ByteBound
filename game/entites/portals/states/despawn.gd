extends PortalState


@export var volitile_state: PortalState
var _safe_exit: bool = false

func enter() -> void:
	if animation_name and has_anim(animation_name):
		portal.portal_sprite.play(animation_name)
		await portal.portal_sprite.animation_finished
		_safe_exit = true


func process_frame(_delta: float) -> FSMState:
	if not _safe_exit: return
	return volitile_state


func exit() -> void:
	super()
	_safe_exit = false
