# sleepnoise
### Purpose
Play noise in a loop for a specific amount of time depending on the day to aid in sleeping. Good for newborns, elderly pets, or anyone.

### Notes
Runs robustly on a Raspberry Pi (tested on RPi2 and RPi4), but any Linux machine with alsa-utils should be able to run it if so long as the dependencies are met. Of particular interest for RPi boards, is that a totally independent audio/video stream can run simultaneously out the HDMI while this script runs outputting to another audio out (USB or 3.5mm jack).

### Dependencies
* alsa-utils
* ffmpeg
* sox

### Installation
* Copy `sleepnoise` to a directory of your choosing and make it executable (`~/bin` or `/usr/local/bin` for example).

High quality (192 kbit/32-bit) noise samples will be created by the script.

### Usage
#### General usage
The syntax to run the script is given by invoking it.
```
/path/to/sleepnoise.sh
Usage: sleepnoise.sh -r <time: Nh, Nm, or raw count> -n <white|pink|brown> -v <1-100> -e <element_id> [-l]

ERROR: Missing required parameter(s):
  -r <time: Nh, Nm, or raw count>
  -n <white|pink|brown> (noise color)
  -v <1-100> (volume % of sound card)
  -e <element_id> (from 'amixer controls')

Optional:
  -l (enable logging to /home/graysky/sleepnoise.log)
```

Required args are documented. You can get the element_id from `amixer controls`. For example, on RPi4:
```
% amixer controls
numid=2,iface=MIXER,name='PCM Playback Switch'
numid=3,iface=MIXER,name='PCM Playback Volume'
numid=1,iface=PCM,name='Playback Channel Map'
```

`numid=3` is used for USB speakers.

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
30 20 * * 0-4 /path/to/sleepnoise.sh -n brown -r 10h -v 20 -e 3 -l

# start at 8:30 PM on fri-sat and run for 12 h
30 20 * * 5-6 /path/to/sleepnoise.sh -n brown -r 12h -v 20 -e 3 -l
```
