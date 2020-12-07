#!/bin/sh

# This file runs when a DM logs you into a graphical session.
# If you use startx/xinit like a Chad, this file will also be sourced.

# Fix Gnome Apps Slow  Start due to failing services
# Add this when you include flatpak in your system
dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY

# picom &		# xcompmgr for transparency
# dunst &			# dunst for notifications
# unclutter &		# Remove mouse when idle

export EDITOR=/usr/bin/nvim
# export QT_QPA_PLATFORMTHEME="qt5ct"