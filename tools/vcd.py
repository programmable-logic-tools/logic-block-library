#!/usr/bin/python3

import sys
import svgwrite


#
# A datapoint is a variable's value at a certain point in time
#
class VCD_Datapoint:
    def __init__(self, time, value):
        self.time = time
        self.value = value

    def getTime(self):
        return self.time

    def getValue(self):
        return self.value


#
# A timeseries is a set of datapoints
#
class VCD_Timeseries:
    def __init__(self, line=None, lineNumber=None):
        self.type = ""
        self.bitwidth = 0
        self.id = ""
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

        self.id = keys[3]
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

    def getID(self):
        return self.id

    def getMaxTime(self):
        time = 0
        for p in self.datapoints:
            t = p.getTime()
            if t > time:
                time = t
        return time

    def drawToSVG(self, drawing, offsetY=0, maxTime=100):
        if len(self.datapoints) == 0:
            return

        scaleY = 10
        d = ""

        previousTime = None
        previousValue = None
        for p in self.datapoints:
            time = p.getTime()
            value = p.getValue()

            if previousTime is None:
                # Append absolute moveto to path
                if value == "1":
                    value = 1
                else:
                    value = 0
                value *= scaleY
                value += offsetY
                moveto = "M{:d} {:d} ".format(time, value)
                d += moveto
            else:
                # Append relative lineto to path
                x1 = previousTime
                y1 = 0
                if (previousValue == 1) or (previousValue == "1"):
                    y1 = 1
                y1 *= scaleY
                y1 += offsetY
                x2 = time
                y2 = 0
                if (value == 1) or (value == "1"):
                    y2 = 1
                y2 *= scaleY
                y2 += offsetY
                line1 = "L{:d} {:d} ".format(x2, y1)
                line2 = "L{:d} {:d} ".format(x2, y2)
                d += line1 + line2

            previousTime = time
            previousValue = value

        # Close path and append path to SVG
        value = 0
        if previousValue == 1:
            value = 1
        value *= scaleY
        value += offsetY
        d += "L{:d} {:d}".format(maxTime, value)
        # print(d)
        path = drawing.path(d=d, **{"class":"waveform"})
        drawing.add(path)


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
        timestamp = 0
        for line in lines:
            lineNumber += 1

            # Skip empty lines
            if len(line.strip(" \t")) == 0:
                continue

            # Detect variable/signal declarations
            if line[:5] == "$var ":
                # Create new timeseries
                timeseries = VCD_Timeseries(line, lineNumber)
                self.timeserieses += [timeseries]
                self.log("Found signal declaration on line {:d}: {:s}".format(lineNumber, timeseries.getLabel()))
                continue

            # VCD keywords start with $
            if line[0] == "$":
                # No need to evaluate them
                continue

            # VCD values start with a tab
            if line[0] == "\t":
                # No need to evaluate them
                continue

            # Timestamps start with #
            if line[0] == "#":
                timestamp = int(line[1:])
                self.log("Time = {:d}...".format(timestamp))
                continue

            # bitwidth > 1: Stored as binary Verilog vector
            failMsg = "Warning: Failed parse line {:d}. Skipping.".format(lineNumber)
            if line[0] == "b":
                s = line.split(" ")
                if len(s) < 2:
                    self.log(failMsg)
                    continue
                value = s[0]
                id = s[1]
            elif line[0] in ["0", "1", "z"]:
                if len(line) < 2:
                    self.log(failMsg)
                    continue
                value = line[0]
                id = line[1:]
            else:
                self.log(failMsg)
                continue

            timeseries = self.getTimeseriesByID(id)
            if timeseries is None:
                self.log("Error: Timeseries with ID \"{:s}\" not found. Skipping.".format(id))
                continue
            timeseries.addDatapoint(timestamp, value)
            label = timeseries.getLabel()
            self.log("Added datapoint ({:d}, {:s}) to timeseries for \"{:s}\".".format(timestamp, value, label))

        self.log("Finished importing {:d} lines.".format(lineNumber))

    def getTimeseriesCount(self):
        return len(self.timeserieses)

    def getTimeseriesByLabel(self, label):
        for t in self.timeserieses:
            if t.getLabel() == label:
                return t
        return None

    def getTimeseriesByID(self, id):
        for t in self.timeserieses:
            if t.getID() == id:
                return t
        return None

    def getMaxTime(self):
        time = 0
        for ts in self.timeserieses:
            t = ts.getMaxTime()
            if t > time:
                time = t
        return time

    def generateSVG(self):
        drawing = svgwrite.Drawing()

        # Embed stylesheet
        f = open("style.css" ,"r")
        stylesheet = f.read()
        f.close()
        style = drawing.style(stylesheet)
        drawing.defs.add(style)

        # Timeserieses
        offsetY = 10
        maxTime = self.getMaxTime()
        for t in self.timeserieses:
            t.drawToSVG(drawing, offsetY=offsetY, maxTime=maxTime)
            offsetY += 20

        maxX = self.getMaxTime()
        maxY = offsetY

        # X axis
        drawing.add(drawing.line((0, 0), (0, maxY), stroke=svgwrite.rgb(10, 10, 16, '%')))
        # Y axis
        drawing.add(drawing.line((0, 0), (maxX, 0), stroke=svgwrite.rgb(10, 10, 16, '%')))

        return drawing

    def exportSVG(self, filename):
        drawing = self.generateSVG()
        drawing.saveas(filename, pretty=True, indent=4)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: vcd.py <*.vcd>")
        sys.exit()

    filename = sys.argv[1]
    v = VCD(filename, debug=True)
