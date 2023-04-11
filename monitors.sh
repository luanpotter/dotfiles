#!/bin/bash

# variables
EXT_MONITOR=HDMI1
INTERNAL_MONITOR=eDP1
MONITOR_RES=2560x1440
# MONITOR_RES=1920x1080
#

fix_res() {
  xrandr --newmode "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
  xrandr --addmode VGA1 "1600x900_60.00"
  xrandr --output VGA1 --mode "1600x900_60.00"
}

monitor() {
  house_monitor_right
}

monitor_up() {
  xrandr --output $EXT_MONITOR --mode $MONITOR_RES --above $INTERNAL_MONITOR
}

monitor_left() {
  xrandr --output $EXT_MONITOR --mode $MONITOR_RES --left-of $INTERNAL_MONITOR
}

monitor_right() {
  xrandr --output $EXT_MONITOR --mode $MONITOR_RES --right-of $INTERNAL_MONITOR
}

monitor_present() {
  xrandr --output $EXT_MONITOR --mode 800x600 --right-of $INTERNAL_MONITOR
}

monitor_mirror() {
  xrandr --output $INTERNAL_MONITOR --mode 800x600
  xrandr --output $EXT_MONITOR --mode 800x600 --same-as $INTERNAL_MONITOR
}

monitor_clear() {
  xrandr --output $INTERNAL_MONITOR --mode 1920x1080
}
