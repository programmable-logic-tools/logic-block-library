#!/usr/bin/python3
#
# This script scans the synthesized design
# and complains about occurences of DFFSR primitives.
# Those are illegal when working with iCE40HX8k FPGAs.
#
# Example for a forbidden register:
#
#        "$auto$simplemap.cc:467:simplemap_dffsr$2768": {
#          "hide_name": 1,
#          "type": "$_DFFSR_PPP_",
#          "parameters": {
#          },
#          "attributes": {
#            "src": "src/interlacing.v:108|src/pwm.v:62"
#          },
#          "port_directions": {
#            "C": "input",
#            "D": "input",
#            "Q": "output",
#            "R": "input",
#            "S": "input"
#          },
#

import sys

# Check command line arguments
if len(sys.argv) < 2:
    print("Not enough arguments. Aborting.")
    sys.exit(1)

# Import file
f = open(sys.argv[1], "r")
content = f.read()
f.close()

# Check if the keyword occurs anywhere in the file
keyword = "$_DFFSR_PPP_"
if content.upper().find(keyword) < 0:
    print("Test passed: No instance of {:s} found, netlist seems to be clean.".format(keyword))
    sys.exit(0)

print("Test failed: An instance of {:s} was found!".format(keyword))

# Find out which file(s) caused the violation(s)
print("Analyzing design...")

import json

netlist = json.loads(content)
cells = netlist["modules"]["top"]["cells"]
print("Violations in module 'top':")

violation_count = 0
for key in cells.keys():
    cell = cells[key]
    if cell["type"] == keyword:
        src = cell["attributes"]["src"]
        src = "\n\t" + src.replace("|", "\n\t")
        print("Offending cell '{:s}' inferred from {:s}'".format(key, src))
        violation_count += 1
print("Total offending cells: {:d}".format(violation_count))

sys.exit(2)
