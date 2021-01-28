#!/bin/sh
emerge --ask --verbose --newuse --changed-use --update --deep --changed-slot=y --with-bdeps=y \
x11-libs/libX11 \
x11-base/xorg-server \
x11-apps/xinit \
x11-libs/libXrandr \
x11-libs/libXinerama \
x11-libs/libXft \
x11-apps/xrdb \
x11-apps/xrandr \
x11-drivers/nvidia-drivers \
app-shells/dash \
app-shells/zsh \
x11-terms/kitty \
x11-misc/unclutter \
x11-misc/clipmenu \
x11-misc/picom \
x11-misc/lightdm \
x11-misc/sxhkd \
x11-misc/lightdm-gtk-greeter \
# x11-misc/lightdm-webkit2-greeter \
x11-wm/bspwm \
x11-wm/i3-gaps \
x11-misc/i3lock-color \
x11-misc/polybar \
x11-wm/awesome \
media-sound/alsa-utils \
media-sound/mpd \
media-fonts/fontawesome \
media-fonts/roboto \
media-fonts/fira-code \
media-fonts/noto \
media-fonts/droid
