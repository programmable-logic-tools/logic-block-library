#!/usr/bin/python3

import sys
sys.path.append("..")
from vcd import *

if len(sys.argv) < 3:
    print("Usage: plot.py <*.vcd> <*.svg>")
    sys.exit()

infile = sys.argv[1]
outfile = sys.argv[2]

vcd = VCD(infile)
vcd.exportSVG(outfile)
print("SVG written to \"{:s}\".".format(outfile))
