#!/bin/csh -fe

## Compute sensitivity - CARMA
#rm -rf carma.sen
#mossen in=carma.map sen=carma.sen
#
## Compute sensitivity - NRO
#rm -rf nro.sen
#mossen in=nro.map sen=nro.sen
#
## calculate rms from sensitivity map
#set rmsCARMA = `imstat in=carma.sen | tail -n 1 | awk '{print $3}'`
#echo "rms from CARMA sensitivity map is $rmsCARMA"
#set rmsNRO   = `imstat in=carma.sen | tail -n 1 | awk '{print $3}'`
#echo "rms from NRO   sensitivity map is $rmsNRO"
#exit
set cutoff = 50
set carmap = "carma.map"
set nromap = "nro.map"
set cutoffmap = "nro"

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

#Remove existing files to overwrite them.
echo 'removing files'
rm -rf carma.mask nro.mask
rm -rf carma2.map nro2.map
rm -rf $out

if $cutoffmap == "carma" then
  echo 'applying carma cutoff'
  # make mask file
  maths exp="<$carmap>.gt.$cutoff" out=carma.mask 
  # Multiply by mask
  maths exp="<$carmap>*<carma.mask>" out=carma2.map
  maths exp="<$nromap>*<carma.mask>" out=nro2.map
endif

if $cutoffmap == "nro" then
  echo 'applying nro cutoff'
  # make mask file
  maths exp="<$nromap>.gt.$cutoff" out=nro.mask 
  # Multiply by mask
  maths exp="<$carmap>*<nro.mask>" out=carma2.map
  maths exp="<$nromap>*<nro.mask>" out=nro2.map
endif

# Compute ratio
maths exp="<carma2.map>/<nro2.map>" out=${out}

