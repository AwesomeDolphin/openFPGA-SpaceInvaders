# openFPGA-SpaceInvaders
This is the openFPGA core for the arcade game Space Invaders. You will need to find roms and samples on your own. I cannot tell you where to get them from.

The roms need to be joined into a single 8k file named invaders.rom and placed in Assets/spaceinvaders/common
The samples need to be raw 44.1k/16-bit samples. I used Audigy to do the conversion. If your byte sizes change, you need to change data.json and the invaders_sound.v file to match.

# Known issues

* The sound system does not read the audio sizes from the loader
* The sound glitches out now and then
* This core could probably support other rom sets with only small bits of work
* The code is a mess... things landed where I was typing at the time.
