This lab demonstrates basic movement of a player, and basic swarming behavior of some enemies. 

I spent a lot of time creating the main scene and adding animations. The scene itself has three layers of a forest background.
The player and the trolls both have animations for moving and idling, in addition, the player has animations for jumping.

The swarm mechanic is quite simple. When the player is not in the detectable radius of the troll, the troll wanders
in a random x direction for a relatively short amount of time. Then the troll idles for a brief moment before continuing
to wander. If the troll collides with the wall boundary or another troll, turns around. When the player enters the detection
radius of the troll, it swarms/chases the player. When the player exits the radius, the troll goes back to wandering. Each 
troll is technically treated as its own scene so that they can be dragged around and placed randomly. There are 20 total 
trolls.

Future development will allow me to move the trolls to different platforms, and have them bound to this platform. The player
will have to kill all of the trolls in order to complete the level. This will ultimately be completed for Lab 3.

To test the swarming mechanic, I recommend jumping to the level of platforms and jumping between them. When doing this, it is
easy to see the trolls below swarm/chase the player.

I am looking forward to some feedback and a chance to improve!

--> The ABOVE is documentation from Lab 2 <--
--> Lab 3 was started as a duplicate of Lab 2 and will be expanding on the concepts and structures from the previous lab <--

Lab 3 implements a player attack, which is a simple swing animation that kills the troll
There are 3 main ways the player can take damage:
	1. Falling into the rocks at the bottom of the screen triggers a killbox
	2. Being attacked by a troll by standing next to it for too long
	3. Being idle for too long, which forces the player to keep moving
	
There is simple audio used for background music, troll death, player attack, and checkpoints

Lives are displayed in the top left of the screen, but may be modified to display an Hboxcontainer with heart images
(I was having trouble with the hbox so it was not implemented for this lab)

MOVEMENT GUIDE:
	The player can be moved using typical WASD controls, W and SPACE can be used for jump
	The player's attack is mapped to the ENTER key
	
--> The ABOVE is documentation from Lab 3 <--
--> The 2D game was started as a duplicate of Lab 3 and will be expanding on the concepts and structures from this lab <--

Here is a brief outline of some of the systems that I implemented:
	1. Player movement (see above)
	2. Damage/death to player
		a. A player can fall to its death
		b. A player can be attacked by a troll
		c. A player can be pushed to its death by a flying eye
		d. NOTE: previous development suggested that idling for too long would cause death. While I like this idea, I did not have enough time to adequately implement it, therefore it was left out
	3. Attacking (see above w/ enter key)
		The player must kill all enemies in order to continue on to the next level. Killing enemies does not improve score
		The two enemy types are the trolls (previously mushrooms) and eyes (which do not have an attack, but can push you)
	4. Scoring
		Done through the collection of coins, a player's score can be improved from "run" to "run"
		Collecting coins is not detrimental to development of the game, but adds an extra layer of complexity
	5. Checkpoints
		While checkpoints are not abundant in my game, there is one available. The checkpoint (when triggered) gives the player an additional life to play with , which can help with level completion

General Notes:
	1. Because of the way that I structured the project, and really the lack of global controls, there are three levels and subsequently three player scenes.
		While I ultimately would have liked to have had this a bit more fluid from a management persepective, I think it gives me something to work on in the event that I elect to continue developing the game
		as my capstone project
	3. I realize that the play time was meant to take at least 3 minutes, and I really did try to make the average run take that long. Unfortunately I feel like my game is easier to beat than that. I am thinking that for
		future development, I make the loss of all lives a bit more detrimental to the progress made (i.e. restart the entire game and lose all progress). My sincere apologies for not having a more flushed out game at this
		point. As we have discussed in class, game design is iterative and to me, I worked on a lot of other structures in this game. Hopefully a short run time can be overlooked.

I HOPE YOU ENJOY THE GAME AND THANK YOU FOR PLAYING!
	
