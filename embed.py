#!/usr/bin/env python
# coding: utf-8

import re

skip_in_subfile = (
        '^#!/bin/sh',
)

def doit(fn, passed=None, skip=()):

    print 'doit:', fn
    if passed is None:
        passed = {}
    lines = []

    with open(fn, 'r') as f:

        for line in f:

            to_skip = False
            for sk in skip:
                if re.match(sk, line):
                    to_skip = True
                    break

            if to_skip:
                continue

            m = re.match('^ *source (.*)', line)
            if not m:
                lines.append(line)
                continue

            subfn = m.groups()[0]
            print 'subfn:', subfn, passed

            if subfn in passed:
                continue

            passed[subfn] = True
            sublines = doit(subfn, passed, skip=skip_in_subfile)
            lines.extend(sublines)

    return lines



if __name__ == "__main__":

    import sys

    fn = sys.argv[1]
    dist = sys.argv[2]


    lines = doit(fn)
    with open(dist + '/' + fn, 'w') as f:
        f.write(''.join(lines))
