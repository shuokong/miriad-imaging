#!/usr/bin/env python
import vismerge
import sys

argvs = sys.argv
# Usage : python vismerge_single.py inpdir out outdir
if (len(argvs) != 4):
   print "Usage: $python %s inpdir out outdir" % (argvs[0])
   sys.exit()

inpdir = argvs[1]
out    = argvs[2]
outdir = argvs[3]

vismerge.vismerge_singledish(inpdir, outdir, out)
