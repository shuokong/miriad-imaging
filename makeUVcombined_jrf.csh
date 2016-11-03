#! /bin/csh -f
#
# Version: 3     2010.03.13  J.Koda  Clean up and add comments
# Version: 4     2010.11.25  J.Koda  Change to keep input CARMA UV intact
#
# Usage:
#   > nro2uv_v4.csh (NRO45 map [Ta*]) (CARMA map) (CARMA uv)
#   > nro2uv_v4.csh nro45.mp carma.mp carma.uv
#
# Requirements:
#   hkimgen:  cd $MIR/src/spec/hkmiriad; gcc -g -I$MIRINC -I$MIRSUBS -o hkimgen hkimgen.c $MIRLIB/libmir.a -lm $MIRLIB/libZeno.a -I$MIR/borrow/zeno
#   hkconvol: cd $MIR/src/spec/hkmiriad; debug hkconvol
#   hkdemos:  cd $MIR/src/spec/hkmiriad; debug hkdemos
#   hkrandom: cd $MIR/src/spec/hkmiriad; debug hkrandom
  alias MATH 'set \!:1 = `echo "\!:3-$" | bc -l`'

  set vismerge_single_path = '/hifi/carmaorion/orion/images/script/vismerge_single.py'

# Molecule name - required
  set verb = 1
  set mol = "12co"

# NRO image in miriad format
  set nroorg = "/hifi/carmaorion/orion/images/nro45m/$mol/12CO_20161017_FOREST-BEARS_spheroidal_xyb_grid7.5_0.099kms_YS.mir" # Tmb
  set nroparams = /hifi/carmaorion/orion/images/sk/nroParams_jrf.csh

# CARMA dirty image 
# set carmap = "../$mol/dv0.264kms/carma_$mol.map"
  set carmap = "carma_full_115.116.map"
  set carbeam = "carma_full_115.116.beam"
  set makeImage = 1
  set remakeBeam = 1
# CARMA uv data
  # set caruv  = /hifi/carmaorion/orion/calibrate/merged/$mol/orion.E.narrow.mir
  set caruv  = "/hifi/carmaorion/orion/calibrate/merged/$mol/orion.D.narrow.mir,/hifi/carmaorion/orion/calibrate/merged/$mol/orion.E.narrow.mir"
  #set caruv  = omc.mir
  set run_fluxscale = 1

  set imsize  = 257
  set cell    = 1.0
  set robust  = 0
  set options = "mosaic,double,systemp"

# Set velocity to image
  set source = "omc31,omc32,omc33,omc41,omc42,omc43,omc52,omc53,omc54"
  set source = "omc42"
  set source = "omc*"
  set select = "source($source),dec(-10,-3)"
#  set source = @nro_subregions.txt
  set chan = (115 116)
  # set vel    = "9.5"
# Set 
  set uvflag = 1
  set uvselect = "uvrange(6,1000.0)"

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

# Make sure files exist
# Can be list of two files, so this check doesn't make sense.
  # if (! -e $caruv) then
  #    echo "CARMA uv file does not exist: $caruv"
  #    exit
  # IF it does not exist then makeImage must be et to 1
  endif
  if (! -e $carmap) then
     echo "CARMA image does not exist: $carmap"
     if (makeImage == 0) then
        exit
     endif
  endif
  if (! -e $nroorg) then
     echo "NRO image does not exist: $nroorg"
     exit
  endif

# First, load miriad version 4.3.9
  echo ""
  echo "*** Loading miriad version 4.3.9 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad_64/miriad_start.csh

# Set file names
  set nrod    = "nro/$mol"
  set nrodtmp = "$nrod/tmp"
  set nrofch  = "$nrodtmp/$mol$chan[1]_$chan[2]"chan

  set nrojy = $nrofch".jy"
  set nroscl = $nrofch".scl"
  set nroreg = $nrofch".reg"
  set nrojypix = $nrofch".jypix"
  set nrodcv = $nrofch".dcv"
  set nrodem = $nrofch".dem"
  set nrouv  = $nrofch".uv"

# Remove pre-existing files
  if (-e $nrodem.1) then
      foreach f ($nrodem*)
         rm -rf $f
      end
  endif
  if (-e $nrouv.1) then
      foreach f ($nrouv*)
         rm -rf $f
      end
  endif

# first, check miriad version
  echo "Miriad version is $MIR"

# Set NRO45 observing parameters
  source $nroparams

  # Set line definition, assuming that we want all channels between chan[1] and
  # chan[2]
  if $verb echo "Setting line definition using NRO parameters file to regrid CARMA."
  MATH nchan = $chan[2] - $chan[1] + 1
  MATH chan1 = $v1nro + ($chan[1] * $dvnro) - $dvnro
  set line = "velocity,$nchan,$chan1,$dvnro,$dvnro"
  if $verb echo "line = $line"
  ## set line = "velocity,2,8.0,0.264,0.264"

# Set source to all sources
  if $verb echo "Setting sources..."
  set source_orig = $source
  if ($source_orig == "") then
     set source = "omc*"
  endif
  if $verb echo "Passed source_orig..."

# Make directories
  if (!(-e $nrod))     mkdir -p $nrod
  if (!(-e $nrodtmp))  mkdir -p $nrodtmp

# Clean up files
  if (-e $nrojy)    rm -rf $nrojy
  if (-e $nroscl)   rm -rf $nroscl
  if (-e $nroreg)   rm -rf $nroreg
  if (-e $nrodcv)   rm -rf $nrodcv
  if (-e $nrojypix) rm -rf $nrojypix

#foreach f (`cat list.dat`)

# =============================
# NRO45 Convert unit and regrid
# =============================

# Convert Ta* -> Jy
  echo "Converting NRO image from Ta* to Jy using NROparams file."
  #$chyknro comes from NROparams file.
  maths exp="<$nroorg>*$cjyknro" out=$nrojy

# Use CARMA/NRO scale factor
  if ($run_fluxscale == 1) then
     echo "Scaling NRO image by CARMA/NRO scale factor from NROparams file."
     maths exp="<$nrojy>*$scalefac" out=$nroscl
  else
    cp -rf $nrojy $nroscl
  endif

  echo "Updating NRO image header with beam and rest frequency info."
  puthd in=$nroscl/bunit value=Jy/BEAM type=ascii 
  puthd in=$nroscl/bmaj value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bmin value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bpa value=0.0,arcs type=real
  puthd in=$nroscl/restfreq value=$freq type=double

  #
  set caruvavg = $nrod/carma_uv.mir
  rm -rf $caruvavg
  #set select = "source($source),dec(-10,-3)"

  # set select = "$ant,uvrange($uvrange),source($source)"
  #if ($coords != "") set select = "$select,$coords"
  echo "Averaging CARMA over veloicity range..."
  uvaver vis=$caruv out=$caruvavg line=$line select="$select"

  # Make CARMA image, if needed
  if ($makeImage != 0) then
     # Make image
       echo "Making CARMA dirty image."
       rm -rf $carmap $carbeam
       invert vis=$caruvavg map=$carmap beam=$carbeam \
              # select="source($source)" \
              select="$select" \
              imsize=$imsize  cell=$cell robust=$robust options=$options
       # Source the NRO parameters file again because we need parameters from
       # the CARMA image.
       source $nroparams
  endif

# Remake NRO beam
if ($remakeBeam != 0) then
    echo "Remaking NRO beam..."
    makeBeam_jrf.csh mol=$mol carmap=$carmap
#  set bmnro = "beamsNRO/$mol/beamnro.bm"


# Regrid wrt CARMA map
  echo "Regridding NRO image with respect to CARMA map."
  regrid in=$nroscl tin=$carmap out=$nroreg 
# cgdisp device=1/xs in=$carmap labtyp=hms options=3value,3pixel nxy=1,1
# cgdisp device=2/xs in=$nroreg labtyp=hms options=3value,3pixel nxy=1,1
# cgdisp device=3/xs in=$nroscl labtyp=hms options=3value,3pixel nxy=1,1
# exit

calculation:
# ================
# Derive NRO45 RMS
# ================
  set z0    = 1
  set z1    = 2
  set z2    = `echo $nzcar | awk '{printf("%d",$1-1)}'`
  set z3    = $nzcar
  echo "*** WARNING: Using a subregion of image" # XXX
  if $sigk == "" then
     set sig1  = `imstat in=$nroreg "region=images($z0,$z1)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
     set sig2  = `imstat in=$nroreg "region=images($z2,$z3)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
     set sig1  = `sigest in=$nroreg region=abspix,"images($z0,$z1)" \
         | grep Estimated\ rms | awk '{print $NF}'`  
     set sig2  = `sigest in=$nroreg region=abspix,"images($z2,$z3)" \
         | grep Estimated\ rms | awk '{print $NF}'`  
     set sigjy = `echo $sig1 $sig2 | awk '{printf("%f",($1+$2)/2.0)}'`
     set sigk  = `calc "$sigjy/$cjyknro"`    # jy -> K in Ta*
  endif
  echo $sigjy,$sigk
    
  set inttot = `calc "$tsysnro**2/$sigk**2/$effq**2/$bwcar"`
  set npoint = `calc "$inttot/$tintnro" | awk '{printf("%d",$1)}'`
  echo $inttot,$npoint
#  set junk = $<

  echo "## REGRIDDED NRO45 MAP: "
  echo "##    RMS [Jy,K(mb)]   = " $sigjy ", " $sigk
  echo "##    Inttime[sec] = " $inttot
  echo "##    Npoint       = " $npoint
  sleep 2

# Set and check NRO45-OTF PB map
  set bmsph = "beamsNRO/$mol/beamsph.bm"
  set bmgau = "beamsNRO/$mol/beamgau.bm"
  set bmnro = "beamsNRO/$mol/beamnro.bm"

  echo "Check beam size is near $fwhmnro"
  imfit in=$bmnro object=beam region=arcsec,box'(-20,-20,20,20)'
#  sleep 2
#  set junk = $<

# Deconvolve NRO45 map with the NRO45 beam
  set sigma = `echo $sigjy | awk '{printf("%f",$1/2.0)}'`  # down to sigma/2
  set factor = `calc "$cellnro*$cellnro/($fwhmnro*$fwhmnro*3.141592654/4./0.693147)"`
# maths exp="<$nroreg>*$factor" out=$nrojypix
# puthd in=$nrojypix/bunit value=Jy/PIXEL type=ascii 

# Deconvolve
  convol map=$nroreg beam=$bmnro out=$nrodcv options=divide sigma=$sigma 

# Now must switch to miriad version 4.3.8
  echo ""
  echo "*** Loading miriad version 4.3.8 ***"
  echo ""
  source ~/.cshrc startMiriad=0
  source /scr/carmaorion/sw/miriad-4.3.8/miriad_start.csh

# Multiply psuede 2'-FWHM primary beam with NRO45 at each CARMA
  set tmpuv = tmptmp.uv
  if (-e $tmpuv) rm -rf $tmpuv
  # cp -r $caruv $tmpuv
  cp -r $caruvavg $tmpuv
  puthd in=$tmpuv/telescop value="GAUS(120)"
# puthd in=$tmpuv/telescop value="NBYM"

# Make images of pointings
# If you do not use hkdemos, miriad will not understand each FoV positions appropriately
# demos map=$nrodcv vis=tmp/tmptmp.uv out=$nrodem"." select="source($source)"
  hkdemos map=$nrodcv vis=$tmpuv out=$nrodem"." select="$select" #select="source($source)"
  rm -rf $tmpuv

# Make NRO45 UV data
# Gaussian UV distribution
#   sdev; standard deviation for normal distribution in nsec
#       --> sigma_F = sqrt(2*ln(2))/(PI*FWHM) *lambda / c
#                   = 257.86 * lambda[mm] / FWHM[arcsec]
#
#           sqrt(2ln2)/PI * (180*60*60/PI) * 1/10 / 29.979 = 257.86
  set sdev    = `calc "257.86*$lambda/$fwhmnro"`
  set klammax = `calc "180.*3600./1.0e3/3.14/$fwhmnro"` # twice of the beam in nsec
  echo "max klambda:" $klammax
#  set junk = $<

  if (-r uvgauss.mir) rm -rf uvgauss.mir
  hkuvrandom npts=$npoint nchan=$nzcar inttime=$tintnro sdev=$sdev gauss=true freq=$freq out=uvgauss.mir
  # uvrandom npts=$npoint nchan=$nzcar inttime=$tintnro uvmax=$klammax gauss=true freq=$freq out=uvgauss.mir # from jens script

  if ($uvflag != 0) then
  #uvflag vis=uvgauss.mir flagval=flag select=$uvselect #"select=uvrange(6,1000.0)"
  #uvflag vis=uvgauss.mir flagval=flag "select=uvrange(3,1000.0)"
  uvflag vis=uvgauss.mir flagval=flag "select=uvrange(6,1000.0)"
  uvcat vis=uvgauss.mir out=tmptmp.mir options=unflagged
  rm -rf uvgauss.mir
  mv tmptmp.mir uvgauss.mir
  endif
  #smauvplt device=/xs vis=uvgauss.mir axis=uc,vc options=equal
  rm -rf uvgauss2.mir
  cp -r uvgauss.mir uvgauss2.mir

# Swap amp/phase with NRO45 ones
  foreach f ($nrodem*)
     set n = `echo $f | sed s/".dem."/" "/ | awk '{printf("%d",$2)}'`
     set g = $nrouv"."$n
#     hkuvmodel vis=uvgauss.mir model=$f out=$g options=replace,imhead # XXX
     uvmodel vis=uvgauss.mir model=$f out=$g options=replace,imhead
  end

# Add params in header
  if (-e tmptmp1.mir) rm -rf tmptmp1.mir
  if (-e tmptmp2.mir) rm -rf tmptmp2.mir
  if (-e tmptmp3.mir) rm -rf tmptmp3.mir
  if (-e tmptmp4.mir) rm -rf tmptmp4.mir
  if (-e tmptmp5.mir) rm -rf tmptmp5.mir
  foreach f ($nrouv*)
     uvputhd hdvar=systemp type=r length=1 varval=$tsysnro vis=$f out=tmptmp1.mir
     uvputhd hdvar=jyperk  type=r length=1 varval=$jyperk  vis=tmptmp1.mir out=tmptmp2.mir
     uvputhd hdvar=pol     type=i length=1 varval=1        vis=tmptmp2.mir out=tmptmp3.mir
     uvputhd hdvar=lst     type=d length=1 varval=12       vis=tmptmp3.mir out=tmptmp4.mir
     uvputhd hdvar=telescop type=a varval='GAUS(120)' vis=tmptmp4.mir out=tmptmp5.mir
     rm -rf $f
     mv tmptmp5.mir $f
     rm -rf tmptmp*.mir
  end

# Combine all UV data
  if (-e $nrod/$nrod.uv.all) rm -rf $nrod/$nrod.uv.all
  echo "Running vismerge..."
  python $vismerge_single_path $nrodtmp $mol $nrod

# Clean up
# foreach f ($nrodem*)
#   rm -rf $f
# end
# foreach f (`cat list.dat`)
#   rm -rf $f
# end


# Dirty image for check
  if (-e test.dm) rm -rf test.dm
  if (-e test.bm) rm -rf test.bm
  if (-e test.psf) rm -rf test.psf
  invert vis=$nrod/$mol".uv.all" map=test.dm beam=test.bm imsize=$imsize cell=$cell robust=$robust options=mosaic,systemp,double line=$line
  cgdisp device=/xs in=test.dm
  mospsf beam=test.bm out=test.psf

  imfit in=test.psf object=beam "region=relcen,box(-10,-10,10,10)" 
