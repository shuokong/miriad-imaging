#!/bin/csh -fe
# Select algorithm
  set algorithm = "mossdi"
# set algorithm = "mosmem"
# If run_invert = 1, then make the combined dirty map from the CARMA and NRO UV files.
  echo "Setting run_invert and vis"
  set run_invert = 1
  echo "Setting vis"
  set vis = "nro/13co/carma_uv.mir,nro/13co/13co.uv.all"
#The root file name for the dirty map, beam, psf,sen etc.
  echo "Setting dirty_name and source..."
  set dirty_name = 'combined_scalefactor' 
  set source = 'omc42,omc43'
  # set vis = "/hifi/carmaorion/orion/images/jrf/nro/13co/carma_uv.mir, /hifi/carmaorion/orion/images/jrf/nro/13co/13co.uv.all"
# If run_mkmask = 1, then we use mask in clean ; c.hara
  echo "Setting run_mkmask, mask, run_clean, run_restor..." 
  set run_mkmask = 0
  set mask = ""

# If run_clean = 1, then we clean!
  set run_clean = 0

# If run_restor =1, then runrestor
  set run_restor = 0

# If run_restart
#

# Read molecule
  set mol = "13co"
  # set molecules = ''

# Invert parameters
  set robust = 2
  set cell   = 1.0
  set imsize = 257
  set options = "mosaic" 

# mossdi parameters
  set cutoff = 1.0 
  set region = ""

# mosmem parameters
  set niter      = 1000
  set rmsfac     = 1.0
  set flux       = 1e-10

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

# Set which molecule(s) to process
  if ($mol != "") set molecules = ($mol)

# Loop over molcules
  foreach mol ($molecules) 
     
	echo $mol

	# Set output directories
       set dir = ${mol}
####CHANGE THIS !!!!!!!!!!##########
######################
########################@@@@@@@@@@@@@@@@@@@@@@@@!!!!!!!!!!!!!DSF:LKJSDF:LKJSD:FLKJ:SDLFJK:SLDK
#       set vis = 'nro/13co/carma_uv.mir,nro/13co/13co.uv.all'
#      set dir = ${mol}_center

     # Set dirty image and beam
       set dirtyImage = $dir/$dirty_name\_$mol.map
       set dirtyBeam  = $dir/$dirty_name\_$mol.beam
       set dirtyPSF   = $dir/$dirty_name\_$mol.psf
       set dirtySen   = $dir/$dirty_name\_$mol.sen
       set dirtyGain = $dir/$dirty_name\_$mol.gain
       set dirtySNR = $dir/$dirty_name\_$mol.SNR

      # Make dirty map
       if ($run_invert == 1) then
         # Clean existing files
           rm -rf $dirtyImage $dirtyBeam $dirtyPSF $dirtySen $dirtyGain $dirtySNR

           echo ""
           echo ""
           echo ""
           echo "*** Making $dirtyImage and $dirtyBeam ***"
           invert vis=$vis map=$dirtyImage beam=$dirtyBeam \
#                    select="source($source)" \
                    cell=$cell \
                    imsize=$imsize \
                    robust=$robust \
                    options=$options
               cgdisp device =/xs in=$dirtyImage options=wedge labtyp=hms
#           invert vis=$vis map=$dirtyImage beam=$dirtyBeam \
#                    select="source($source)" \
#                    cell=$cell \
#                    imsize=$imsize \
#                    robust=$robust \
#                    options=$options
#               cgdisp device =/xs in=$dirtyImage options=wedge labtyp=hms
     
         # Make combined beam
           mospsf beam=$dirtyBeam out=$dirtyPSF
     
         # Create theoretical noise image   
        
           mossen in=$dirtyImage sen=$dirtySen gain=$dirtyGain

         # Create signal to noise image
           
           maths exp="<$dirtyImage>/<$dirtySen>" out=$dirtySNR
       endif 

     # Set outfile
       set outfile = $dir/combined_$mol

     # Get beam size
       set log = $outfile.psf.log
       rm -rf $log
       imfit in=$outfile.psf object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
       set bmaj=`grep "Major axis" $log | awk '{print $4}'`
       set bmin=`grep "Minor axis" $log | awk '{print $4}'`
       set bpa=`grep "  Position angle" $log | awk '{print $4}'`
       echo "Beam size = $bmaj x $bmin arcsec at PA = $bpa deg"

       if run_clean == 1 then
     # Determine which channel to clean next
         set nchan = `imlist in=$dirtyImage | grep naxis3 | awk '{print $6}'`

       # Determine the next channel that needs to be reduced
         set n = 0
         set found = 0
         set outcc = 0
         while ($found == 0 && $n < $nchan) 
             # Increment
               @ n += 1
               set chan = `printf "%03d" $n`

             # Set output directory
               set outcc = $dir/$mol.$chan

             # If it doesn't exist, then we found the channel
               if (!(-e $outcc)) then
                  set found = 1
                  mkdir -p $outcc
                  set outfile = $dir/$mol.$chan/$mol.$chan
               endif
         end

       # If found a channel, then clean it
         if ($found == 1) then
            # Compute velocity of this channel
              set crval3 = `imlist in=$dirtyImage | grep cdelt3 | awk '{print $9}'`
              set crpix3 = `imlist in=$dirtyImage | grep crpix3 | awk '{print $9}'`
              set cdelt3 = `imlist in=$dirtyImage | grep cdelt3 | awk '{print $9}'`
              set velocity = `echo "scale=5;$crval3 + $cdelt3 * ($n - $crpix3)" | bc`

            # Message
              echo "Processing channel $chan, velocity = $velocity"

            # Separate each channel
              imsub in=$dirtyImage out=$outfile.map region=abspix,images"($chan,$chan)"
              imsub in=$dirtySen out=$outfile.sen region=abspix,images"($chan,$chan)"

            # Create mask
              if ($run_mkmask == 1) then
                  # Remove existing files
                    rm -rf $outfile.mask

                  # make signal to noise ratio map
                    maths exp="<$outfile.map>/<$outfile.sen>" out=$outfile.snr 

                  # make mask file
                    maths exp="<$outfile.snr>.gt.2.5" out=$outfile.mask
              endif

            # Clean map
              if ($algorithm == "mossdi") then
                 if ($run_mkmask == 1) then
                      mossdi map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                        cutoff=$cutoff niters=$niter region="mask($outfile.mask)"
                 else 
                      mossdi map=$dirtyImage beam=$dirtyBeam out=$outfile.cc \
                        cutoff=$cutoff region=$region niters=$niter
                 endif

              else if ($algorithm == "mosmem") then
                 if ($run_mkmask == 1) then 
                      mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                          niters=$niter region=$region rmsfac=$rmsfac \
                          flux=$flux measure=gull region="mask($outfile.mask)"
                 else
                      mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                          niters=$niter region=$region rmsfac=$rmsfac \
                          flux=$flux measure=gull
                 endif
              else
                 echo 'set algorithm = "mossdi" or "mosmem"'
                 exit
              endif

            # Create cleaned image and residuals
              if ($run_restor == 1) then
                 # Clean image
                 restor map=$outfile.map beam=$dirtyBeam model=$outfile.cc \
                        out=$outfile.cm fwhm=$bmaj,$bmin pa=$bpa

                 # Clean residuals
                 restor map=$outfile.map beam=$dirtyBeam model=$outfile.cc \
                        out=$outfile.rs fwhm=$bmaj,$bmin pa=$bpa mode=residual
              endif 
         endif
       endif
       endif

     # Done with channel
       echo ""
       echo ""
       echo "*** Finished to make maps of $outfile"
       echo ""
       echo ""
  end # molecule
