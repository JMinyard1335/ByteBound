# Hazards

Hazards are physical objects in the game world and not apart of the TileMapLayer. A Hazard is made
to provide an obsticle that can damage or kill the player if the player comes into contact with it.
There are multiple modes that a hazard can operate on `Contact, Periodic, Proximity`, each changing
how the hazard acts in the game world.

## Hazard Nodes

Below are the nodes that make up the hazard objects and a description of what they do.

### Damage Shape

a CollisionShape2D that damages the player when they come into contact with the hazard

### Ground Shape

Allows the player to stand on hazards when they are not active. This allows hazards to double as 
platforms, making the player jump from damgerous platform to the next for harder sections.

### Hazard Sprite

The AnimatedSprite2D that holds the image of the hazard. The animation names used can be set on the
hazards top level node. The allowed animations are the following 

- Idle: an animation or frame for the disabled hazard
- Telegraph: an animation that plays before the hazard becomes active (one-shot)
- Active: an animation or frame for the active hazard.
- Activate: an animation that is played when the hazard is activating (one-shot)
- Deactivate: an animation that is played when the trap is deactivating (one-shot)

### Proximity Area

An Area2D that says when the player gets close to the hazard. Used with the `proximity` mode.
change this to change when the hazard knows about the player.

### Hazard Component

A component that manages the logic for the hazard based off the Hazard Stats

### Animation Player

Animates the Hazard Sprite and Damage Shape to get a more accurate collision with the hazard while
it is activating, active, or deactivating. These animaitons are played at different times based on
the mode being used. for example `Contact` will only ever play the active animation as the hazard 
should always be active in that mode.


## Hazard Stats

These are te stats the determine how a hazard is supposed to opperate from, tick damage, mode of 
operation, as well as tuning for the `periodic` and `proximity` modes.

## Creating a Hazard

1. Create a new inherited scene from `hazard.tscn`
2. Add the desired sprite
3. Set up the animations, with proper collisions
4. Give the hazard a `HazardStats` resource
