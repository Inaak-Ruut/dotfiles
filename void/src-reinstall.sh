#!/bin/sh
cd "$(xdistdir)"
./xbps-src binary-bootstrap

xbps-query -l | cut -d' ' -f2 | rev | cut -d- -f2- | rev | while read -r pkg; do
    ./xbps-src -N pkg "$pkg"
done

xi -f $(xpkg)