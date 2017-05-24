#!/bin/csh -fe
#
# Establish the fluxscale factor for the NRO image
# 
# Based originally on Jin Koda's script, modified by Chihomi,
# and then John Carpenter.
#
# Usage:
#   fluxscale.csh
#
# Requirements:
#   hkdemos:  cd $MIR/src/spec/hkmiriad; debug hkdemos
  alias MATH 'set \!:1 = `echo "\!:3-$" | bc -l`'

  set verb = 1
# Molecule
  set mol = "12co"

# NRO image in miriad format
  set nroorg = "../nro45m/$mol/regrid_12CO_specsmooth.mir" # Tmb

# CARMA uv data
 set caruv = "../../calibrate/merged/12co/orion.E.narrow.mir,../../calibrate/merged/12co/orion.D.narrow.mir"
# set caruv = omc43.mir
# set caruv = omc.mir

# Which baselines to include
  set use10m10m = 0
  set use6m10m  = 0
  set use6m6m   = 1

# Set which source to image
  set coords = "dec(-6.3,-6)"
  set coords = "dec(-10,-3)"
  set source = "omc43" # strongest, Orion KL
  set source = "omc32,omc33,omc42,omc43,omc53,omc54,omc65,omc66,omc22,omc23"
  set source = "omc*" # try bigger. shuokong 2016-10-10 
  set source = "omc31,omc32,omc33,omc41,omc42,omc43,omc52,omc53,omc54"
  #set source = @nro_subregions.txt

# CARMA dirty image
# If makeImage = 1, then the maps will be generated.
# Otherwise, they need to pre-made.
# uvrange is the range in kilolambda to make the maps
  set carmap  = "carma.map"
  set carbeam = "carma.beam"
  set uvrange = "0,6"
  set makeImage = 1 #
  set caronly = 0 #

# Set the file names for the NRO output images.
  set nromap = "nro.map"
  set nrobeam = "nro.beam"


  # source nroParams_jrf.csh

# Imaging options (both CARMA and NRO)
# "systemp" is deliberately omitted in "options" so map is weighted by 
# telescope parameters only. This is because the single dish uv data will 
# be generated with the same system temperature; to have the same data
# weighting between single dish and interferometer data, we cannot weight
# by system temperature.
  set imsize  = 257
  set cell    = 1.0
  set robust  = 2
  set options = "mosaic"  
 

# Possible bug if only channel in line commmand!
# The resampled NRO data do not look correct if nchannel=1
# jjjjjChannels set first and last channel to use.
  set chan = (115 116) # seems to be the strongest NRO 12co channel. shuokong 2016-09-28
  set chan = (45 46) 
  ## set line = "velocity,2,8.0,0.264,0.264"

# Set NRO file names
  set nrod     = "nro/$mol/fluxscale"      # Directory

# End of user-supplied arguments
##########################################################################
  if $verb echo "Reading command line arguments.."
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
# Moved these definitions below the user defined parameters to ensure that
# $nrod is captured from command line.
  set nrof     = $nrod/$mol # Root file name
  set nroscl   = $nrof".scl"
  set nroreg   = $nrof".reg"
  set nroavg   = $nrof".avg"
  set nrojypix = $nrof".jypix"
  set nrodcv   = $nrof".dcv"
  set nrodem   = $nrof".dem"
  set nrouv    = $nrof".uv"

# Set NRO45 observing parameters
  set nxnro    = `imhead in="$nroorg" key="naxis1" | awk '{printf("%i",$1)}'`
  set nynro    = `imhead in="$nroorg" key="naxis2" | awk '{printf("%i",$1)}'`
  set nznro    = `imhead in="$nroorg" key="naxis3" | awk '{printf("%i",$1)}'`
  set v1nro    = `imhead in="$nroorg" key="crval3" | awk '{printf("%f",$1)}'`
  set cellnro  = `imhead in="$nroorg" key="cdelt2" | awk '{printf("%f",$1*206264.8)}'`
  set dvnro    = `imhead in="$nroorg" key="cdelt3" | awk '{printf("%f",$1)}'`
  if $verb echo "v1nro = $v1nro"
  if $verb echo "dvnro = $dvnro"
  if $verb echo "nznro = $nznro"

#Set line definition, assuming that we want all channels between chan[1] and
#chan[2]
  if $verb echo "Setting line definition..."
  MATH nchan = $chan[2] - $chan[1] + 1
  MATH chan1 = $v1nro + ($chan[1] * $dvnro) - $dvnro
  set line = "velocity,$nchan,$chan1,$dvnro,$dvnro"
  if $verb echo "line = $line"
  ## set line = "velocity,2,8.0,0.264,0.264"
  #set junk = $<

# Set source to all sources
  if $verb echo "Setting sources..."
  set source_orig = $source
  if ($source_orig == "") then
     set source = "omc*"
  endif
  if $verb echo "Passed source_orig..."
# Make directories
  if (!(-e $nrod)) mkdir -p $nrod

# Remove preexisting files
  if (-e $nroscl) rm -rf $nroscl
  if (-e $nroreg) rm -rf $nroreg
  if (-e $nrodcv) rm -rf $nrodcv
  if (-e $nroavg) rm -rf $nroavg

# Average CARMA over velocity range.
# We need to set which antennas to select
  if ($use10m10m != 0 & $use6m10m != 0 & $use6m6m != 0) then
     set ant = "ant(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)"
  else if ($use10m10m == 1 & $use6m10m == 0 & $use6m6m == 0) then
     set ant = "-ant(7,8,9,10,11,12,13,14,15)"
  else if ($use10m10m == 0 & $use6m10m == 1 & $use6m6m == 0) then
     set ant = "ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)"
  else if ($use10m10m == 0 & $use6m10m == 0 & $use6m6m == 1) then
     set ant = "-ant(1,2,3,4,5,6)"
  else if ($use10m10m == 0 & $use6m10m == 1 & $use6m6m == 1) then
     set ant = "-ant(1,2,3,4,5,6)(1,2,3,4,5,6)"
  else
     echo "Antenna combination is not set"
     exit
  endif
  set caruvavg = $nrod/carma_uv.mir
  rm -rf $caruvavg
  set select = "$ant,uvrange($uvrange),source($source)"
  if ($coords != "") set select = "$select,$coords"
  if $verb echo "Averaging CARMA over veloicity range..."
  uvaver vis=$caruv out=$caruvavg line=$line select="$select"

# The CARMA data has variable system temperature, but the NRO data 
# does not. In order to get identical weighting of the pointings,
# we need to set the CARMA data to a constant system temperature
  if $verb echo "Setting CARMA data to a constant system temp..."
  set tmp = $nrod/tmptmp.mir
  rm -rf $tmp
  uvputhd hdvar=systemp type=r length=1 varval=650 vis=$caruvavg out=$tmp
  rm -rf $caruvavg
  mv $tmp $caruvavg
  #set junk = $<

# First, load miriad version miriad_64
  echo ""
  echo "*** Loading miriad version miriad_64 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad_64/miriad_start.csh

# Make CARMA image, if needed
  if ($makeImage != 0) then
     # Make image
       rm -rf $carmap $carbeam
       invert vis=$caruvavg map=$carmap beam=$carbeam \
              select="source($source)" \
              imsize=$imsize  cell=$cell robust=$robust options=$options
  endif

  cgdisp device=3/xs in=$carmap region="image(1)" labtyp=hms options=3value,3pixel,full nxy=1

  if ($caronly == 1) exit 
    
# Remake NRO beam
  makeBeam_jrf.csh mol=$mol carmap=$carmap
  set bmnro = "beamsNRO/$mol/beamnro.bm"

# Make sure correct version of miriad is loaded
  echo ""
  echo "*** Loading miriad version miriad_64 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad_64/miriad_start.csh

# Set NRO45 observing parameters
  source nroParams_jrf.csh

# NRO45: Convert unit to Janskys
# Convert Ta* -> Jy
  maths exp="<$nroorg>*$cjyknro" out=$nroscl
  #set junk = $<

# Add keywords to NRO image
  puthd in=$nroscl/bunit    value=Jy/BEAM       type=ascii 
  puthd in=$nroscl/bmaj     value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bmin     value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bpa      value=0.0,arcs      type=real
  puthd in=$nroscl/restfreq value=$freq         type=double

# Regrid NRO map wrt CARMA map
  regrid in=$nroscl tin=$carmap out=$nroreg
  #set junk = $<

# Display images
  echo "Displaying images"
  cgdisp device=4/xs in=$nroreg region="image(1)" labtyp=hms options=3value,3pixel,full nxy=1
# cgdisp device=3/xs in=$nroscl labtyp=hms options=3value,3pixel nxy=2,2

# Derive NRO45 RMS
  set z0    = 1
  set z1    = 2
  set z2    = `echo $nzcar | awk '{printf("%d",$1-1)}'`
  set z3    = $nzcar
  echo "*** WARNING: Using a subregion of image" # XXX
# set sig1  = `imstat in=$nroreg "region=images($z0,$z1)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
# set sig2  = `imstat in=$nroreg "region=images($z2,$z3)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
#set sig1  = `imstat in=$nroreg "region=arcsec,box(200,-200,0,0)($z0,$z1)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'`
#set sig2  = `imstat in=$nroreg "region=arcsec,box(200,-200,0,0)($z2,$z3)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'`
  if sigk == "" then
    set sig1  = `sigest in=$nroreg region=abspix,"images($z0,$z1)" \
        | grep Estimated\ rms | awk '{print $NF}'`  
    set sig2  = `sigest in=$nroreg region=abspix,"images($z2,$z3)" \
        | grep Estimated\ rms | awk '{print $NF}'`  
    set sigjy = `echo $sig1 $sig2 | awk '{printf("%f",($1+$2)/2.0)}'`
    set sigk  = `calc "$sigjy/$cjyknro"`    # jy -> K in Ta*
  endif

  set inttot = `calc "$tsysnro**2/$sigk**2/$effq**2/$bwcar/$effmb**2"`
  set npoint = `calc "$inttot/$tintnro" | awk '{printf("%d",$1)}'`

  echo "## REGRIDDED NRO45 MAP: "
  echo "##    RMS [Jy,K(mb)]   = " $sigjy ", " $sigk
  echo "##    Inttime[sec] = " $inttot
  echo "##    Npoint       = " $npoint
  sleep 2

# NRO Beam map should be twice larger than CARMA map
  set nx = `echo $nxcar | awk '{printf("%d",$1*2)}'`
  set ny = `echo $nycar | awk '{printf("%d",$1*2)}'`

# Deconvolve NRO45 map with the NRO45 beam
  set sigma = `echo $sigjy | awk '{printf("%f",$1/2.0)}'`  # down to sigma/2
  set factor = `calc "$cellcar*$cellcar/($fwhmnro*$fwhmnro*3.141592654/4./0.693147)"`
  convol map=$nroreg beam=$bmnro out=$nrodcv options=divide sigma=$sigma

# Now must switch to miriad version 4.3.8
  echo ""
  echo "*** Loading miriad version 4.3.8 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad-4.3.8/miriad_start.csh

# Next, we generate the NRO uv data. We do this one primary beam type
# at a time, since miriad will not get the jyperk factors correct 
# otherwise.
  set types = (1 2 3)
  foreach itype ($types)
     # Set root to file names
       set dem = "$nrodem.$itype"
       set uv  = "$nrouv.$itype"

     # Clear any pre-existing files
     # This could fail if the first file in each does not exist, but
     # other files in the sequence are present.
       if ( (-e $dem.1) | (-e $dem.10)) then
          foreach f ($dem.*)
            rm -rf $f
          end
       endif
       if ( (-e $uv.000001) | (-e $uv.000010)) then
          foreach f ($uv.*)
            rm -rf $f
          end
       endif

     # Process this type?
       if ($itype == 1) then
          set use = $use10m10m
          set ant = "-ant(7,8,9,10,11,12,13,14,15)"
       else if ($itype == 2) then
          set use = $use6m10m
          set ant = "ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)"
       else if ($itype == 3) then
          set use = $use6m6m
          set ant = "-ant(1,2,3,4,5,6)"
       else
          echo "Unknown antenna type: $itype"
          exit
       endif

     # Process type
       if ($use != 0) then
          # Copy miriad file to select antennas
            set tmpmir = $nrod/tmp.mir
            rm -rf $tmpmir
            uvcat vis=$caruvavg out=$tmpmir select="$ant"

          # Get JyperK factor
            set jyperkCarma = `uvio $tmpmir | grep jyperk | tail -1 | awk '{printf("%f",$4)}'`
            echo "Using Jy/K = $jyperkCarma"
            if ($jyperkCarma == "") then
               echo "Error setting JyPerK in $tmpmir"
               exit
            endif

          # Make single dish images for the CARMA pointings
          # $nrodcv is the deconvolved NRO image, $tmpmir is the sub-set uv
          # specified by antenna pair selection. shuokong 2016-10-10
          # demos command de-mosaic NRO deconvolved image with pointing
          # information from $tmpmir which is from CARMA. output images for
          # every pointing, see demos documentation. shuokong 2016-10-11
            hkdemos map=$nrodcv vis=$tmpmir out=$dem"."
          # set junk = $<

          # Swap amp/phase with NRO45 ones
          # for each demos result image $dem".", use uvmodel to get visibility
          # data set (Fourier transform) based on the uv pairs from vis
          # shuokong 2016-10-11
            foreach f ($dem*)
               set n = `echo $f | sed s/".dem.$itype."/" "/ | awk '{printf("%d",$2)}'`
               # If you change the "%.6d" format statement below, then you need
               # to change the -e $dem.000001 and -e $uv.000001 statements
               # above.
               set sn = `echo $n | awk '{printf("%.6d",$1)}'`
               set g = $uv"."$sn
#              hkuvmodel vis=$tmpmir model=$f out=$g options=replace,imhead
#              If a single point, then this should be options=replace,selradec,mfs --- I think (JMC)
               echo "uvmodel vis=$tmpmir model=$f out=$g options=replace,selradec"
               uvmodel vis=$tmpmir model=$f out=$g options=replace,selradec
            end

          # Add params in header
            foreach f ($uv*)
               uvputhd hdvar=systemp type=r length=1 varval=$tsysnro vis=$f out=tmptmp1.mir
               uvputhd hdvar=jyperk  type=r length=1 varval=$jyperkCarma  vis=tmptmp1.mir out=tmptmp2.mir
               uvputhd hdvar=pol     type=i length=1 varval=1        vis=tmptmp2.mir out=tmptmp3.mir
               uvputhd hdvar=lst     type=d length=1 varval=12       vis=tmptmp3.mir out=tmptmp4.mir
               rm -rf $f
               mv tmptmp4.mir $f
               rm -rf tmptmp*.mir
            end
       endif
  end

# Combine all UV data
  if (-e "$nrouv.all") rm -rf "$nrouv.all"
  ipython vismerge_single_jrf.py $nrod $mol $nrod
  if (! -e "$nrouv.all") then
     echo "Error generating combined uv file"
     exit
  endif

# Clean up
  foreach f ($nrodem*)
    rm -rf $f
  end
# foreach f (`cat list.dat`)
#   rm -rf $f
# end

# Now must switch to miriad version miriad_64
  echo ""
  echo "*** Loading miriad version miriad_64 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad_64/miriad_start.csh

# Dirty image for check
  if (-e $nromap)  rm -rf $nromap
  if (-e $nrobeam) rm -rf $nrobeam
  echo "Making Nobeyama map from $nrouv.all"
  invert vis=$nrouv".all" map=$nromap beam=$nrobeam \
         imsize=$imsize cell=$cell robust=$robust \
         options=$options select="uvrange($uvrange)"
  set n = 0
  foreach image ($nromap $carmap) 
    @ n += 1
    cgdisp device=$n/xs in=$image options=full,wedge labtyp=hms range=-10,100
  end
# imfit in=test.bm object=gauss "region=relcen,box(-10,-10,10,10)" 

# Check flux scaling
 #smauvplt vis=$caruv4model.avg,$nrouv.avg axis=uvdistance,amplitude device=uvamp.eps/cps
 smauvplt vis=$caruvavg,$nrouv.all axis=uvdistance,amplitude device=uvamp.eps/cps
