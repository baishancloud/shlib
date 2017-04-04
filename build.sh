#!/bin/sh

python2 embed.py shlib.sh        dist
python2 embed.py shlib_color.sh  dist
python2 embed.py shlib_format.sh dist
python2 embed.py shlib_git.sh    dist
python2 embed.py shlib_log.sh    dist

chmod +x dist/*
