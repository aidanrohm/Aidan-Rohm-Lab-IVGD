This lab demonstrates basic movement of a player, and basic swarming behavior of some enemies. 

I spent a lot of time creating the main scene and adding animations. The scene itself has three layers of a forest background.
The player and the mushrooms both have animations for moving and idling, in addition, the player has animations for jumping.

The swarm mechanic is quite simple. When the player is not in the detectable radius of the mushroom, the mushroom wanders
in a random x direction for a relatively short amount of time. Then the mushroom idles for a brief moment before continuing
to wander. If the mushroom collides with the wall boundary or another mushroom, turns around. When the player enters the detection
radius of the mushroom, it swarms/chases the player. When the player exits the radius, the mushroom goes back to wandering. Each 
mushroom is technically treated as its own scene so that they can be dragged around and placed randomly. There are 20 total 
mushrooms.

Future development will allow me to move the mushrooms to different platforms, and have them bound to this platform. The player
will have to kill all of the mushrooms in order to complete the level. This will ultimately be completed for Lab 3.

To test the swarming mechanic, I recommend jumping to the level of platforms and jumping between them. When doing this, it is
easy to see the mushrooms below swarm/chase the player.

I am looking forward to some feedback and a chance to improve!

--> The ABOVE is documentation from Lab 2 <--
--> Lab 3 was started as a duplicate of Lab 2 and will be expanding on the concepts and structures from the previous lab <--

