class_name Hazard
extends Area2D
## A drop-in damaging hazard (spikes, saws, lava, pulsing/proximity traps).
##
## Thin coordinator around a [HazardComponent]: it maps the component's danger
## [enum HazardComponent.Phase] onto animations and plays an optional hit sound.
## Each phase is driven on a [member sprite] and/or an [member anim_player] using
## the same animation name, so you can animate the [CollisionShape2D] (position,
## [code]disabled[/code], scale, even [code]shape:size[/code]) in the
## [AnimationPlayer] to make the hitbox follow the dangerous part of the sprite.
## [br][br]
## [b]Animations[/b] are configurable by name. Each phase has a steady (looping)
## animation, and arming/disarming can play an optional one-shot [i]transition[/i]
## first ([member activate_anim] / [member deactivate_anim]) that falls through to
## the steady animation when it finishes. When an [member anim_player] is assigned
## it is the timing authority for that fall-through; otherwise the [member sprite]
## is.[br]
## [b]Important:[/b] transition animations must be [i]non-looping[/i] (so
## [code]animation_finished[/code] fires); steady animations should loop. Any name
## blank or missing from a target is simply skipped, so partial setups are fine.

## Behaviour preset: damage, mode and timing. Lives here on the root node so it
## is editable per instance in a level; handed down to [member hazard] on ready.
@export var stats: HazardStats
## The brain. Decides when the hazard is dangerous and applies damage.
@export var hazard: HazardComponent
## Optional sprite. Its [SpriteFrames] animation is switched to match the phase.
@export var sprite: AnimatedSprite2D
## Optional [AnimationPlayer]. Its same-named animation is played per phase —
## animate the [CollisionShape2D] here so the hitbox tracks the dangerous part.
@export var anim_player: AnimationPlayer
## Optional sound played each time the hazard hits the player.
@export var hit_sound: AudioPoolStream

@export_group("Animations")
## Looping animation shown while safe.
@export var idle_anim: StringName = &"Idle"
## Looping animation shown during the telegraph/charge warning.
@export var telegraph_anim: StringName = &"Telegraph"
## Looping animation shown while dangerous.
@export var active_anim: StringName = &"Active"
## Optional one-shot played when arming, before [member active_anim]. Non-looping.
@export var activate_anim: StringName = &""
## Optional one-shot played when going safe, before [member idle_anim]. Non-looping.
@export var deactivate_anim: StringName = &""

# Steady animation to switch to once the current one-shot transition finishes.
var _pending: StringName = &""


#region Engine Methods
func _ready() -> void:
	assert(stats, "Hazard: stats (HazardStats) not set")
	assert(hazard, "Hazard: hazard (HazardComponent) not set")
	assert(sprite or anim_player, "Hazard: assign a sprite and/or an anim_player")
	hazard.init(stats)
	hazard.phase_changed.connect(_on_phase_changed)
	hazard.struck.connect(_on_struck)
	# The AnimationPlayer is the transition authority when present, else the sprite.
	if anim_player:
		anim_player.animation_finished.connect(_on_player_finished)
	elif sprite:
		sprite.animation_finished.connect(_on_sprite_finished)
	# Snap straight to the steady look on spawn (no activate flash at level load).
	_pending = &""
	_play(_steady_anim(hazard.get_phase()))
#endregion


#region Signal Handlers
func _on_phase_changed(phase: HazardComponent.Phase) -> void:
	var transition: StringName = _transition_anim(phase)
	if transition != &"" and _conductor_has(transition):
		_pending = _steady_anim(phase)
		_play(transition)
		return
	_pending = &""
	_play(_steady_anim(phase))


func _on_player_finished(_anim: StringName) -> void:
	_advance_pending()


func _on_sprite_finished() -> void:
	_advance_pending()


func _on_struck(_body: Node2D) -> void:
	if hit_sound:
		AudioPool.play(hit_sound, global_position)
#endregion


#region Private Helpers
func _steady_anim(phase: HazardComponent.Phase) -> StringName:
	match phase:
		HazardComponent.Phase.ARMED:
			return active_anim
		HazardComponent.Phase.TELEGRAPH:
			return telegraph_anim
		_:
			return idle_anim


func _transition_anim(phase: HazardComponent.Phase) -> StringName:
	match phase:
		HazardComponent.Phase.ARMED:
			return activate_anim
		HazardComponent.Phase.IDLE:
			return deactivate_anim
		_:
			return &""


## When a one-shot transition ends, fall through to its steady animation.
func _advance_pending() -> void:
	if _pending == &"":
		return
	_play(_pending)
	_pending = &""


## Whether the transition-timing authority (anim_player if set, else sprite) has
## [param anim] — decides if a one-shot transition exists to wait on.
func _conductor_has(anim: StringName) -> bool:
	if anim_player:
		return anim_player.has_animation(anim)
	return _sprite_has(anim)


func _sprite_has(anim: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim)


## Plays [param anim] on every assigned target that has it.
func _play(anim: StringName) -> void:
	if _sprite_has(anim):
		sprite.play(anim)
	if anim_player and anim_player.has_animation(anim):
		anim_player.play(anim)
#endregion
