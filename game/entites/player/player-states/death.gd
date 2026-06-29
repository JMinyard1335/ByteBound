extends PlayerState
## Death state for the player.
##
## No transitions in or out. The player decides when to enter by calling 
## change state

@export var death_scene: PackedScene
var has_died: bool = false

func enter() -> void:
	super()
	if has_died: return
	
	_hide_player()
	
	if death_scene:
		var ds = death_scene.instantiate() as AnimatedSprite2D
		player.add_child(ds)
		await ds.animation_finished
		ds.call_deferred("queue_free")
	
	has_died = true


func _hide_player() -> void:
	player.sprite.visible = false
	player.motion.frozen = true
	player.input.enabled = false
