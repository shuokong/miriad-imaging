#!/bin/csh -f

#########################################################################
# Creates NRO beam map on the same pixel scale as the CARMA image.
# Output is placed in the directory $outdirRoot/$mol
#########################################################################

# Set default parameters
  set mol = ""           # Must be entered
  set carmap   = ""      # Optional - default hard coded below
  set cellnro  = "7.5"   # Cell size for NRO map in arcseconds; should not need to change

# Set output directories
  set outdirRoot = "beamsNRO"

# End of user-supplied arguments
#############################################################################

# Override user supplied parameters with command line arguments
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

# Must start with Miriad version 4.3.8
  echo ""
  echo "*** Loading miriad version 4.3.8 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad-4.3.8/miriad_start.csh

# Set map name and beam size
# see NRO homepage, http://www.nro.nao.ac.jp/~nro45mrt/html/prop/eff/eff2014.html
  if ($mol == "13co") then
#    if ($carmap == "") set carmap  = "../13co/dv0.5kms_ch0.0kms/carma_13co.map"
     if ($carmap == "") set carmap = "/hifi/carmaorion/orion/images/test/13co/omc43_13co.map"
     set nrobm   = "16.2"
  else if ($mol == "12co") then
#    if ($carmap == "") set carmap  = "../13co/dv0.5kms_ch0.0kms/carma_13co.map"
     set nrobm = "14.9"
  else 
     echo "Image not set for molecule $mol"
     echo "makeBeam.csh mol=13co"
     exit
  endif

# Make sure CARMA map exists
  if (!(-e $carmap)) then
     echo "CARMA image does not exist: $carmap"
     exit
  endif

# Make directory for beam maps
  set outdir = "$outdirRoot/$mol"
  if (! -e $outdir) mkdir -p $outdir

# Set output files for beams
  set bmsph   = "$outdir/beamsph.bm"
  set bmgau   = "$outdir/beamgau.bm"
  set bmnro   = "$outdir/beamnro.bm"

# Make sure they do not exist already
  if (-e $bmsph) rm -rf $bmsph
  if (-e $bmgau) rm -rf $bmgau
  if (-e $bmnro) rm -rf $bmnro
  if (-e tmptmp.mir) rm -rf tmptmp.mir

# Get carma beam
  set cellcar  = `imhead in="$carmap" key="cdelt2" | awk '{printf("%f",$1*206264.8)}'`
  set nxcar    = `imhead in="$carmap" key="naxis1" | awk '{printf("%i",$1)}'`
  set nycar    = `imhead in="$carmap" key="naxis2" | awk '{printf("%i",$1)}'`

  set nx = `calc "$nxcar*4"`
  set ny = `calc "$nxcar*4"`

# Make gaussian beam for Nobeyama with the CARMA cell size
  imgen out=$bmgau imsize=$nx,$ny object=gaussian \
        spar=1,0,0,$nrobm,$nrobm,0 cell=$cellcar,$cellcar

# Generate spheroidal function 
  set nx = `calc "$nxcar*2"`
  set ny = `calc "$nxcar*2"`
  hkimgen out=$bmsph imsize=$nx,$ny sdgsize=$cellnro object=SP \
          cell=$cellcar,$cellcar

# Now we need miriad 4.3.9
  echo ""
  echo "*** Loading miriad version 4.3.9 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad_64/miriad_start.csh

# Convolve gaussian with spheroidal
  convol map=$bmsph beam=$bmgau out=tmptmp.mir

# Normalize image so peak pixel is unity
  set fmax = `imstat in=tmptmp.mir region=relpix,box'(-10,-10,10,10)' | tail -1 | awk '{printf("%f",$4)}'`
  echo "Beam is divided by $fmax"
  maths exp="<tmptmp.mir>/$fmax" out=$bmnro

# Fit beam with gaussian
  imfit in=$bmnro object=beam region=arcsec,box'(-20,-20,20,20)'
  echo "Beam must be similar to following values"
  echo "22.0 arcsec in CO, 22.9 arcsec in 13CO/C18O"

# Clean up
  if (-e tmptmp.mir) rm -rf tmptmp.mir
