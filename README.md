# sleepnoise
### Purpose
Play white noise (although can be any clip) in a loop for a specific amount of time depending on the day to aid in sleeping. Good for newborns, elderly pets, or anyone.

### Notes
Runs very robustly on a [Raspberry Pi 2 ](https://www.raspberrypi.org/products/raspberry-pi-2-model-b), but any Linux machine can run it if so long as the dependencies are met. Of particular interest for the RPi2, is that a totally independent audio/video stream can run simultaneously out the HDMI while this script runs outputting to the 3.5mm jack. See the inline comments in the script itself if you want to tweak to your needs.

### Dependencies
* alsa-utils
* sox
* High quality noise clips (white and pink) are available free of charge from [audiocheck.net](http://www.audiocheck.net/testtones_highdefinitionaudio.php). This script expects both the [white noise clip](http://www.audiocheck.net/download.php?filename=Audio/audiocheck.net_white_192k_-3dBFS.wav) and the [pink noise clip](http://www.audiocheck.net/download.php?filename=Audio/audiocheck.net_pink_192k_-3dBFS.wav) to be on your filesystem (see below).

### Installation
* Copy `sleepnoise` to a directory of your choosing and make it executable (`~/bin` or `/usr/local/bin` for example).
* Create `/usr/share/sleepnoise` and copy the two wav files mentioned above into it.

### Usage
#### General usage
The syntax to run the script is given by invoking it.
```
% sleepnoise 
Usage: /usr/local/bin/sleepnoise [-r <# of 15 sec repeats>] [-n <white|pink>]
```
The -r switch is required and is an interger value that corresponds to the number of repeats you want. Since both test clips are 15 seconds long, a value of 1 will play for 15 sec (1 repeat). To run for 1 min, use a value of 4. To run for 1 hour, use a value of 240.

The -n switch is optional. If nothing is specified, the white noise clip is played. To hear the pink noise clip, use a value of pink.

#### Have cron run the script for you
Assuming you have cron installed, simple edit your crontab to call the script as you wish.
```
% crontab -l
#*     *     *   *    *        command to be executed
#-     -     -   -    -
#|     |     |   |    |
#|     |     |   |    +----- day of week (0 - 6) (Sunday=0)
#|     |     |   +------- month (1 - 12)
#|     |     +--------- day of month (1 - 31)
#|     +----------- hour (0 - 23)
#+------------- min (0 - 59)

# start at 8:30 PM on sun-thurs and run for 10 h
30 20 * * 0-4 /usr/local/bin/sleepnoise -r 2400 -n pink

# start at 8:30 PM on fri-sat and run for 11-1/2 h
30 20 * * 5-6 /usr/local/bin/sleepnoise -r 2760 -n pink
```
