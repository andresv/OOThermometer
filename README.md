# OOThermometer

This is little indoor/outdoor wireless thermometer that I made for my girlfried.
It consists of 3 parts, otherwise it would not be over engineered.

1. [mbed](http://mbed.org/) with LCD screen
2. base (Iris)
3. node (Iris)

Node sends temperature readings to base who forwards them to mbed who finally shows temperatures on LCD screen.
Base has also temperature sensor, so also indoor temperature can be seen.

## Software

This is written for TinyOS Iirs platform. It uses low power listening to conserve power.
Mbed part can be found [here](http://mbed.org/users/grandmastera/programs/OOThermometer/m3o1bz)

## LICENSE

You can do whatever you want with that source.
