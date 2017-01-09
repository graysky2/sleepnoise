# sleepnoise
### Purpose
Play white noise (although can be any clip) in a loop for a specific amount of time depending on the day to aid in sleeping.  Good for newborns, elderly pets, or anyone.

### Notes
This particular code runs very robustly on a [Raspberry Pi 2 ](https://www.raspberrypi.org/products/raspberry-pi-2-model-b), but any Linux machine can run it if so long as the dependencies are met. Of particular interest for the RPi2, is that a totally independent audio/video stream can run simultaneously out the HDMI while this script runs outputting to the 3.5mm jack. See the inline comments in the script itself if you want to tweak to your needs.

Various high quality noise clips (white, pink, brown, blue, violet, and grey) are available free of charge from [audiocheck.net](http://www.audiocheck.net/testtones_highdefinitionaudio.php).

### Dependencies
* alsa-utils
* sox
