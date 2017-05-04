#!/bin/sh

python2 embed.py shlib.sh        dist

cat shlib.sh | grep source | while read src fn; do
python2 embed.py $fn        dist
done

chmod +x dist/*
