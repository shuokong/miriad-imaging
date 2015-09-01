#!/bin/csh -fe

# Compute sensitivity - CARMA
# rm -rf carma.sen
# mossen in=carma.map sen=carma.sen

# Compute sensitivity - NRO
# rm -rf nro.sen
# mossen in=nro.map sen=nro.sen

# calculate rms from sensitivity map
# set rmsCARMA = `imstat in=carma.sen | tail -n 1 | awk '{print $3}'`
# echo "rms from CARMA sensitivity map is $rmsCARMA"
# set rmsNRO   = `imstat in=carma.sen | tail -n 1 | awk '{print $3}'`
# echo "rms from NRO   sensitivity map is $rmsNRO"

# make mask file
rm -rf carma.mask
maths exp="<carma.map>.gt.50" out=carma.mask

# Multiply by mask
rm -rf carma2.map nro2.map
maths exp="<carma.map>*<carma.mask>" out=carma2.map
maths exp="<nro.map>*<carma.mask>"   out=nro2.map

# Compute ratio
rm -rf ratio.map
maths exp="<carma2.map>/<nro2.map>" out=ratio.map

