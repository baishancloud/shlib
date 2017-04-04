#!/usr/bin/env python
# coding: utf-8

import re
import sys

skip_in_subfile = (
    '^#!/bin/sh',
)


def embed_source(fn, processed=None, skip=()):

    if processed is None:
        processed = {}

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

            if subfn in processed:
                continue

            processed[subfn] = True
            sublines = embed_source(subfn,
                                    processed=processed,
                                    skip=skip_in_subfile)
            lines.extend(sublines)

    return lines


if __name__ == "__main__":

    fn = sys.argv[1]
    dist = sys.argv[2]

    lines = embed_source(fn)
    with open(dist + '/' + fn, 'w') as f:
        f.write(''.join(lines))
