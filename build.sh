#!/bin/bash

set -e

haxe -v --connect 6001 build.hxml

#tortilla build nw
#./build/nw/linux64/game

tortilla build browser
