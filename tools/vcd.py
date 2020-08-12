#!/usr/bin/python3

import sys


#
# A datapoint is a variable's value at a certain point in time
#
class VCD_Datapoint:
    def __init__(self, time, value):
        self.time = time
        self.value = value


#
# A timeseries is a set of datapoints
#
class VCD_Timeseries:
    def __init__(self, line=None, lineNumber=None):
        self.type = ""
        self.bitwidth = 0
        self.symbol = ""
        self.label = ""
        self.range = ""
        self.datapoints = []

        if not (line is None):
            self.parseDeclaration(line, lineNumber)

    def parseDeclaration(self, line, lineNumber):
        keys = line.split(" ")
        if (keys[0] != "$var") or (len(keys) < 5):
            print("Error: Attempt to parse variable declaration from incompatible line {:d}. Skipping.".format(lineNumber))
            return

        self.type = keys[1]
        try:
            self.bitwidth = int(keys[2])
        except:
            print("Error: Failed to parse variable bitwidth on line {:d}.".format(lineNumber))
            return

        expectedKeyCount = 6
        if self.bitwidth > 1:
            expectedKeyCount = 7

        self.symbol = keys[3]
        self.label = keys[4]

        self.range = "[0:0]"
        endKeyIndex = 5
        if self.bitwidth > 1:
            self.range = keys[5]
            endKeyIndex = 6

        if keys[endKeyIndex] != "$end":
            print("Warning: Missing $end token while parsing variable on line {:d}.".format(lineNumber))

        if len(keys) > expectedKeyCount:
            print("Warning: Unexpected extra tokens while parsing variable on line {:d}.".format(lineNumber))

    def addDatapoint(self, time, value):
        datapoint = VCD_Datapoint(time, value)
        self.datapoints += [datapoint]

    def getLabel(self):
        return self.label


#
# This class stores a Value Change Dump (model)
#
# A VCD is basically an array of value changesets.
#
class VCD:
    def __init__(self, filename=None, debug=False):
        self.debug = debug
        self.clear()
        if not (filename is None):
            self.importFromFile(filename)

    def log(self, message):
        if self.debug:
            print(message)

    def clear(self):
        self.timeserieses = []

    def importFromFile(self, filename):
        if filename is None:
            self.log("Error: Called import method without specifying a filename. Aborting.")
            return

        self.clear()

        # Import file contents
        self.log("Importing VCD from file \"{:s}\"...".format(filename))
        try:
            f = open(filename, "r")
            lines = f.read().split("\n")
            f.close()
        except:
            self.log("Error: Unable to read file. Aborting.")
            return

        # Parse line by line
        lineNumber = 0
        for line in lines:
            lineNumber += 1

            # Skip empty lines
            if len(line.strip(" \t")) == 0:
                continue

            # Detect variable/signal declarations
            if line[:5] == "$var ":
                timeseries = VCD_Timeseries(line, lineNumber)
                self.timeserieses += [timeseries]
                self.log("Found signal declaration on line {:d}: {:s}".format(lineNumber, timeseries.getLabel()))
                continue

        self.log("Finished importing {:d} lines.".format(lineNumber))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: vcd.py <*.vcd>")
        sys.exit()

    filename = sys.argv[1]
    v = VCD(filename, debug=True)
