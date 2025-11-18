This git repository is meant to showcase the development and thought process behind the capstone game.

Preliminarily, the capstone game is going to be a continuation of the walking sim. The general thought process for the capstone game
is to create something that is continuously immersive. I want the player to feel confusion at first, in a minimally rendered world.
As they continue through the path and journey, they should subconsciously notice that the world around them is becoming more complete.
Part of this immersion is the passage of time, which I want to be directly proportional to the movement of the player. 

I want the game to essentially be constructed in a straight line, where the sun will change its position over time. This will be done by
having the sun move through different phases with relation to the game itself. While technically the sun is always moving, it will be progressing
to two different points with every step the player takes.

	1. When the game starts, the sun will be in front of the player. This will create a blinding effect, as if awakening from a hibernation.
	   At this point of the game, the world will be minimally rendered, perhaps there won't even be color to the floor and surroundings,
	   which will ideally go on forever.
		
	   With every step the player takes, the world around them will continue to develop, and the sun will move out of direct sight, subsequently
	   being less blinding.

	2. As the player continues to walk through the world/along the path, the sun will reach a point of being directly overhead at the midway point
	   of the game/journey. At this point, the game should be mildly immersive. Certainly more immersive than the first leg of the game, but not
	   as immersive as the ending. The world will be well illuminated, and not blinding. This is where the player should feel most certain in 
	   the game and their journey.

	3. As the player continues to the end, the sun will be directly behind the player, illuminating the end of their journey, as if it is giving 
	   a spotlight to what they have reached. This is where the player should be most immersed, with spatial audio emerging from an endpoint/
	   finish line.
	
	   The finishing point itself is still being decided on. I like the idea of it being extremely mysterious, like perhaps a cabin with a 
	   single light left on inside. I want the player to feel as if they have reached the beginning of the end, and perhaps leave them
	   feeling a bit confused.

*** SPOILER ALERT *** SKIP AHEAD IF YOU HAVE NOT SEEN BREAKING BAD ***

The best way for me to describe the type of feeling that I want the player to have, is by relating it to a specific feeling that I felt after
having seen the conculding episode of Breaking Bad. At the end of this episode, Jesse has made his escape from the neo-nazi biker gang that
is holding him hostage after Walt saves him. Walt proceeds to die in the lab, while Jesse makes his escape driving a car away.

When Breaking Bad was originally filmed, there was no further development of Jesse's story. No closure was given as to what his fate was meant
to be. Of course, there is now a mini empire built of the Breaking Bad universe as El Camino tells the story of Jesse after escaping, and Better Call
Saul for a look at Saul's entire character arc. Because of this lack of information, the viewer was left stumped and curious, desperate for more.
Call me psycho, but I liked this feeling. This unknown perspective that forces us to be curious.

*** END OF SPOILER CONTENT ***

IDEAS ON HOW TO CREATE IMMERSION:

Since immersion is essentailly a function of time and player movement, there are a few different ways that I want to create a more immersive environment.

	1. Scenery and World Design:
		- As previously mentioned, the world should be bare when the player first loads in. It should feel empty and barren, even colorless.
		  I like the idea of using megascans as assets to build the world, but I partially worry about how intense that would be. It would be 
		  interesting to perhaps include less realistic assets at first, maybe even ones that are of very different (unrealistic) animation syles
		  In any case, the environment should be heavily based on nature and as the player continues to walk forward, nature will become surround 
		  the view. 
		- As the world becomes naturally more immersive, the lighting will also reflect this. As previously mentioned, light will change with
		  relation to the player's movement. In a way, this is like creating twice the amount of immersion. As scenery and assets grow around
		  the player, illumination will only make it more intruiging.
		- From when we discussed particles, I think it would be great to use some particles to create an idea of leaves flowing from a tree,
		  or perhaps wind blowing.
		- At the "finish line" there will be a cabin/tower/tent (really just something) that can be offered as the singular point of curiosity.
		  Ideally, the player will become familiar enough with the changes around them, with the finish line being a bit of a curveball.
	
	2. Sounds:
		- For things like footseps, I want them to play as the player walks (of course), but to have them get progressively louder until reaching
		  a maximum volume (ideally when the player reaches the final third of the game).
		- Environmental sounds like birds chirping, russling of the leaves, and other nature-like sounds, they will be audiostream players coming from
		  a specific place in the world. As the player gets closer/further from these places, the audio will naturally be impacted.

	3. Player Movement:
		- Movement in the game is going to be very straight-forward (literally, lol). While the world will develop in essentially a straight line, things
		  such as sun movement, sound expansion, etc. will be updated as the player moves along the x-direction (for example).
		- The player will not have much space to move around on their path. I want the immersion to be essentially focused on the path itself, wandering
		  off of it should not be allowed, and if possible, should be gracefully punished.

INSPIRATION:

I have long wanted to play an environmentally immersive game that tells a short story, while giving the feeling of being trapped in nature and time. The closest
game that I can think of to relate to this is Firewatch, which is really fantastic. While I know my game will be quite basic and will not permit extensive amounts
of exploration and whatnot, I still want it to tell a story and leave the player curious for more.
Another game for inspiration is Life is Strange. I find this game to be beautiful in its art and use of music and lighting. I never played the 
entire game but when I was playing it, there were so many beautiful aspects to appreciate.

DEVELOPMENT PROCESS:

Start:
	- I think to begin, the biggest thing to take care of is going to be setting the environment where the world changes with every step. This will
	
