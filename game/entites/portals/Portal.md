# Portals

Portals are ways the player can move around the map after unlocking or 
enabling them. These provide a fasttravel system to allow the player
to go back and complete puzzles and challenges they might have missed


## Portal Nodes

The portal is made up of two ProximityArea's, which are Area2D's that only fire
when the player is in the area. It holds a reference to the player while the player
is in the area.

### Portal Sprite

Plays the animation and is the actual portal visuals. The sprites color can be 
dynamically changed by setting the `portal_color` variable in the editor or in
code with `portal.portal_color`
