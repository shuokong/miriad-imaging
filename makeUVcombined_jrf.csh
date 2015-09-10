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


# Molecule name - required
  set mol = "13co"

# NRO image in miriad format
  set nroorg = /hifi/carmaorion/orion/images/nro45m/$mol/13co_dv0.264kms_tmb.mir # Ta*

# CARMA dirty image 
# set carmap = "../$mol/dv0.264kms/carma_$mol.map"
  set carmap = "/hifi/carmaorion/orion/images/test/13co/omc43_13co.map"

# CARMA uv data
  set caruv  = /hifi/carmaorion/orion/calibrate/merged/$mol/orion.E.narrow.mir
  set caruv  = omc43.mir

# Set velocity to image
  set source = "omc*"
  set vel    = "9.5"


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
  if (! -e $caruv) then
     echo "CARMA uv file does not exist: $carmuv"
     exit
  endif
  if (! -e $carmap) then
     echo "CARMA image does not exist: $carmap"
     exit
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
  set nrofch  = "$nrodtmp/$mol.$vel"kms

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
  source nroParams.csh

# Make directories
  if (!(-e $nrod))     mkdir -p $nrod
  if (!(-e $nrodtmp))  mkdir -p $nrodtmp

# Clean up files
  if (-e $nroscl)   rm -rf $nroscl
  if (-e $nroreg)   rm -rf $nroreg
  if (-e $nrodcv)   rm -rf $nrodcv
  if (-e $nrojypix) rm -rf $nrojypix

#foreach f (`cat list.dat`)

# =============================
# NRO45 Convert unit and regrid
# =============================

# Convert Ta* -> Jy
  maths exp="<$nroorg>*$cjyknro" out=$nroscl

  puthd in=$nroscl/bunit value=Jy/BEAM type=ascii 
  puthd in=$nroscl/bmaj value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bmin value=$fwhmnro,arcs type=real
  puthd in=$nroscl/bpa value=0.0,arcs type=real
  puthd in=$nroscl/restfreq value=$freq type=double

# Regrid wrt CARMA map
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
  if sigk == "" then
     set sig1  = `imstat in=$nroreg "region=images($z0,$z1)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
     set sig2  = `imstat in=$nroreg "region=images($z2,$z3)" | tail -1 | sed s/"-"/" "/g | sed s/"+"/" "/g | awk '{printf("%f",$5)}'` # XXX
     set sig1  = `sigest in=$nroreg region=abspix,"images($z0,$z1)" \
         | grep Estimated\ rms | awk '{print $NF}'`  
     set sig2  = `sigest in=$nroreg region=abspix,"images($z2,$z3)" \
         | grep Estimated\ rms | awk '{print $NF}'`  
     set sigjy = `echo $sig1 $sig2 | awk '{printf("%f",($1+$2)/2.0)}'`
     set sigk  = `calc "$sigjy/$cjyknro"`    # jy -> K in Ta*
  endif
    
  set inttot = `calc "$tsysnro**2/$sigk**2/$effq**2/$bwcar"`
  set npoint = `calc "$inttot/$tintnro" | awk '{printf("%d",$1)}'`

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
  sleep 2

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
  cp -r $caruv $tmpuv
  puthd in=$tmpuv/telescop value="GAUS(120)"
# puthd in=$tmpuv/telescop value="NBYM"

# Make images of pointings
# If you do not use hkdemos, miriad will not understand each FoV positions appropriately
# demos map=$nrodcv vis=tmp/tmptmp.uv out=$nrodem"." select="source($source)"
  hkdemos map=$nrodcv vis=$tmpuv out=$nrodem"." select="source($source)"
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

  if (-r uvgauss.mir) rm -rf uvgauss.mir
  hkuvrandom npts=$npoint nchan=$nzcar inttime=$tintnro sdev=$sdev gauss=true freq=$freq out=uvgauss.mir
  # uvrandom npts=$npoint nchan=$nzcar inttime=$tintnro uvmax=$klammax gauss=true freq=$freq out=uvgauss.mir # from jens script

  uvflag vis=uvgauss.mir flagval=flag "select=uvrange(10.0,1000.0)"
  uvcat vis=uvgauss.mir out=tmptmp.mir options=unflagged
  \rm -r uvgauss.mir
  mv tmptmp.mir uvgauss.mir
# smauvplt device=/xs vis=uvgauss.mir axis=uc,vc options=equal

# Swap amp/phase with NRO45 ones
  foreach f ($nrodem*)
     set n = `echo $f | sed s/".dem."/" "/ | awk '{printf("%d",$2)}'`
     set g = $nrouv"."$n
#    hkuvmodel vis=uvgauss.mir model=$f out=$g options=replace,imhead # XXX
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
  python vismerge_single.py $nrodtmp $mol $nrod

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
  invert vis=$nrod/$mol".uv.all" map=test.dm beam=test.bm imsize=129 cell=1.0 robust=2 options=mosaic,systemp,double line=chan,$nzcar,1,1,1
  cgdisp device=/xs in=test.dm
  mospsf beam=test.bm out=test.psf

  imfit in=test.psf object=beam "region=relcen,box(-10,-10,10,10)" 