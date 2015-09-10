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
set cutoff = 50
set carmap = "carma.map"
set nromap = "nro.map"
set out = "ratio.map"

  foreach a ( $* )
    set nargs = `echo $a | awk -F= '{print NF}'`
    set var   = `echo $a | awk -F= '{print $1}'`
    if ("$nargs" == 1) then
       echo "Error reading command line option '$a'"
       echo "Format is $a=<value>"
       exit
    endif
    set $a
  end

# make mask file
rm -rf carma.mask
maths exp="<$carmap>.gt.$cutoff" out=carma.mask

# Multiply by mask
rm -rf carma2.map nro2.map
maths exp="<$carmap>*<carma.mask>" out=carma2.map
maths exp="<$nromap>*<carma.mask>"   out=nro2.map

# Compute ratio
rm -rf ratio.map
maths exp="<carma2.map>/<nro2.map>" out=$out

