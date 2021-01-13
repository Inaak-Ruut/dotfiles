#!/usr/bin/env sh

# More info : https://github.com/jaagr/polybar/wiki

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar > /dev/null; do sleep 1; done

desktop=$(echo $DESKTOP_SESSION)
count=$(xrandr --query | grep " connected" | cut -d" " -f1 | wc -l)

case $desktop in

    bspwm)
    if type "xrandr" > /dev/null; then
      for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload leftbar-bspwm -c ~/.config/polybar/config &
      done
    else
    polybar --reload leftbar-bspwm -c ~/.config/polybar/config &
    fi
    
    # second polybar at right    
        if type "xrandr" > /dev/null; then
      for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload mainbar-bspwm -c ~/.config/polybar/config &
      done
    else
    polybar --reload mainbar-bspwm -c ~/.config/polybar/config &
    fi
    
    # third polybar at right
     if type "xrandr" > /dev/null; then
       for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
         MONITOR=$m polybar --reload rightbar-bspwm -c ~/.config/polybar/config &
       done
     else
     polybar --reload rightbar-bspwm  -c ~/.config/polybar/config &
     fi
    
   # fourth polybar at bottom
   #  if type "xrandr" > /dev/null; then
   #    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
   #      MONITOR=$m polybar --reload mainbar-bspwm-extra -c ~/.config/polybar/config &
   #    done
   #  else
   #  polybar --reload mainbar-bspwm-extra -c ~/.config/polybar/config &
   #  fi
    ;;

    herbstluftwm)
    if type "xrandr" > /dev/null; then
      for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload mainbar-herbstluftwm -c ~/.config/polybar/config &
      done
    else
    polybar --reload mainbar-herbstluftwm -c ~/.config/polybar/config &
    fi
    # second polybar at bottom
    # if type "xrandr" > /dev/null; then
    #   for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    #     MONITOR=$m polybar --reload mainbar-herbstluftwm-extra -c ~/.config/polybar/config &
    #   done
    # else
    # polybar --reload mainbar-herbstluftwm-extra -c ~/.config/polybar/config &
    # fi
    ;;

esac
