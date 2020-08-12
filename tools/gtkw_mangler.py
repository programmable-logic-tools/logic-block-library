#!/usr/bin/python3
#
# This script searches for GTKWave project files
# and removes explicit folder names from them.
#

import sys, os
import re


def process_string(content):

    oldcontent = content

    # Split the content into lines for line-by-line processing
    lines = content.split("\n")

    # Remove path from dumpfile and savefile
    exp1 = re.compile("\[dumpfile\] \"([\/a-zA-Z0-9\.\-\_ ]*)\"")
    exp2 = re.compile("\[savefile\] \"([\/a-zA-Z0-9\.\-\_ ]*)\"")

    for line in lines:
        # Match first regular expression
        r1 = exp1.match(line)
        if r1 != None:
            # print(line)
            filename = r1.groups()[0]
            filename = os.path.basename(filename)
            # print(filename)
            new_line = "[dumpfile] \"{:s}\"".format(filename)
            content = content.replace(line, new_line)

        # Match second regular expression
        r2 = exp2.match(line)
        if r2 != None:
            # print(line)
            filename = r2.groups()[0]
            filename = os.path.basename(filename)
            # print(filename)
            new_line = "[savefile] \"{:s}\"".format(filename)
            content = content.replace(line, new_line)

    if content == oldcontent:
        print("No change.")
    else:
        print("Changed.")

    return content


def process_file(filename):
    # Import file content
    f = open(filename, "r")
    content = f.read()
    f.close()

    # Process content
    content = process_string(content)

    # Save processed content
    f = open(filename, "w")
    f.write(content)
    f.close()


def recursive_mangling(path):
    if os.path.isdir(path):
        print("{:s} is a folder. Recursing...".format(path))
        results = os.listdir(path)
        for f in results:
            recursive_mangling(os.path.join(path, f))
        return

    if os.path.isfile(path):
        if path[-5:].lower() != ".gtkw":
            #print("Info: Skipping unsupported file {:s}".format(path))
            return
        print("Processing {:s} ...".format(path))
        process_file(path)
        return

    print("Error: Is neither file nor folder: {:s}".format(path))


    if filename.lower()[-5:] != ".gtkw":
        print("Wrong file extension. Should be .gtkw. Skipping.")
        return



if __name__ == "__main__":
    path = os.getcwd()
    if len(sys.argv) > 1:
        path = sys.argv[1]

    recursive_mangling(path)
    print("Done.")
