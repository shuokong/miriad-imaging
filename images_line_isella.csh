#!/bin/csh -fe
# Select algorithm
  set algorithm = "mossdi"
# set algorithm = "mosmem"
# If run_invert = 1, then make the combined dirty map from the CARMA and NRO UV files.
  echo "Setting run_invert and vis"
  set run_invert = 0
  echo "Setting vis"
  #set carvis = "nro/13co/carma_uv.mir"
  #set nrovis = "nro/13co/13co.uv.all"
  set vis = "nro/13co/carma_uv.mir,nro/13co/13co.uv.all"
#The root file name for the dirty map, beam, psf,sen etc.
  echo "Setting dirty_name and source..."
  set dirty_name = 'combined_scalefactor' 
#  set source = 'omc42,omc43'
  # set vis = "/hifi/carmaorion/orion/images/jrf/nro/13co/carma_uv.mir, /hifi/carmaorion/orion/images/jrf/nro/13co/13co.uv.all"
# If run_mkmask = 1, then we use mask in clean ; c.hara
  echo "Setting run_mkmask, mask, run_clean, run_restor..." 
  set run_mkmask = 0
  set mkmask_dummy = 1
  set polygon_region = 'region.txt'
  set region_limit = 0.
  set mask = ""

# If run_clean = 1, then we clean!
  set run_clean = 1

# If make_plots = 1, then plot the flux recovered vs. clean component every
# time a channel finishes.
  set make_plots = 0

# If run_restor =1, then runrestor
  set run_restor = 1

# If run_restart, then clean up to niters on the specified channel.
  set run_restart = 0
  set restart_channel = 1
  

# Read molecule
  set mol = "13co"
  # set molecules = ''

# Invert parameters
  set robust = 2
  set cell   = 1.0
  set imsize = 257
  set options = "mosaic, double" 
  set select = "dec(-10,-3)"

  set different_beam = 0
  set use_psf_as_beam = 0
  set use_which_antennas = 0
# mossdi parameters
  set cutoff = 0.01 
  set region = ""
  set niter      = 1000
  set gain = 0.1
# mosmem parameters
  set rmsfac     = 1.0
  set flux       = 1e-10

# Flux recovered vs. Clean component plot parameters
  set plot_ccflux = 1 
  set cclogfile = 'ccflux.log'
  set plotfile = 'ccflux.pdf'
  

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
  echo $niter
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

       if ($different_beam == 1) then
            set dirtyBeam = 13co/carmaonly_42_mosaic_171.172_13co.beam
            set dirtyPSF = 13co/carmaonly_42_mosaic_171.172_13co.psf
       endif

#       if ($use_which_antennas == "10m") then
#            set ant = "-ant(7,8,9,10,11,12,13,14,15)"
#            set select = $select,$ant
#       endif

#       if ($use_which_antennas == "6m") then
#            set ant = "-ant(1,2,3,4,5,6)"
#            set select = $select,$ant
#       endif

#      if ($use_which_antennas == "6m10m") then
#            set ant = "ant(1,2,3,4,5,6)(7,8,9,10,11,12,13,14,15)"
#            set select = $select,$ant
#       endif

#       if ($use_which_antennas == "not10m10m") then
#            set ant = "-ant(1,2,3,4,5,6)(1,2,3,4,5,6)"
#            set select = $select,$ant
#            echo $select
#       endif
      echo $run_invert

      # Make dirty map
       if ($run_invert == 1) then
         # Clean existing files
           rm -rf $dirtyImage $dirtyBeam $dirtyPSF $dirtySen $dirtyGain $dirtySNR

           echo ""
           echo ""
           echo ""
           echo "*** Making $dirtyImage and $dirtyBeam ***"
           invert vis=$vis map=$dirtyImage beam=$dirtyBeam \
                    select=$select \
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
     #  set outfile = $dir/combined_$mol

     # Get beam size
       # set log = $outfile.psf.log
       set log = $dirtyPSF.log
       rm -rf $log
#       imfit in=$outfile.psf object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
       imfit in=$dirtyPSF object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
       set bmaj=`grep "Major axis" $log | awk '{print $4}'`
       set bmin=`grep "Minor axis" $log | awk '{print $4}'`
       set bpa=`grep "  Position angle" $log | awk '{print $4}'`
       echo "Beam size = $bmaj x $bmin arcsec at PA = $bpa deg"


       if $run_clean == 1 then
         echo "Running clean..."
         #Use define_region.py to create a polygon region file using the gain image and a floor of 1.0
         if $run_mkmask == 1 then 
           if $mkmask_dummy == 1 then
            #Make a polygon region file with the 4 corners of the map as the vertices, this dummy region
            #tricks mossdi into only CLEANing the channel of the map that we want. Otherwise mossdi will output
            #multiple planes of clean components even if only one channel is requested.
            set naxis1 = `imhead in=$dirtyImage key=naxis1`
            set naxis2 = `imhead in=$dirtyImage key=naxis2`
            echo "polygon(1,1,1,$naxis2,$naxis1,$naxis2,$naxis1,1,1,1)" > $polygon_region
            endif

         # Can put calls to imsub here to pick out the narrower region and use the outputs of IMSUB as the inputs to mossdi2.        
           if (!(-e $polygon_region)) then  
           echo "Defining polygon region..."
           fits in=$dirtyGain out=gain.fits op=xyout
           python define_region.py -image 'gain.fits' -image_type 'gain' -outfile "$polygon_region" -limit $region_limit
           endif
         endif
         if $run_restart == 1 then
           echo "Running restart..."
           set n = $restart_channel
           set chan = `printf "%03d" $n`
           set outcc = $dir/$mol.$chan
           #mkdir -p $outcc
           set outfile = $dir/$mol.$chan/$mol.$chan

           set crval3 = `imlist in=$dirtyImage | grep cdelt3 | awk '{print $9}'`
           set crpix3 = `imlist in=$dirtyImage | grep crpix3 | awk '{print $9}'`
           set cdelt3 = `imlist in=$dirtyImage | grep cdelt3 | awk '{print $9}'`
           set velocity = `echo "scale=5;$crval3 + $cdelt3 * ($n - $crpix3)" | bc`

         # # Create mask
         #   if ($run_mkmask == 1) then
         #       # Remove existing files
         #         rm -rf $outfile.mask

         #       # make signal to noise ratio map
         #         maths exp="<$outfile.map>/<$outfile.sen>" out=$outfile.snr 

         #       # make mask file
         #         maths exp="<$outfile.snr>.gt.2.5" out=$outfile.mask
         #   endif

         # Clean map
           rm -rf $outfile.$cclogfile
           if ($algorithm == "mossdi") then
              if ($run_mkmask == 1) then
                   mossdi map=$outfile.map beam=$dirtyBeam out=$outfile.cc.new \
                     cutoff=$cutoff niters=$niter region=@$polygon_region\
                     model=$outfile.cc gain=$gain  > $outfile.$cclogfile
              else 
                   mossdi map=$dirtyImage beam=$dirtyBeam out=$outfile.cc.new \
                     cutoff=$cutoff niters=$niter\
                     model=$outfile.cc gain=$gain > $outfile.$cclogfile
              endif

           else if ($algorithm == "mossdi2") then
              if ($run_mkmask == 1) then
                   mossdi2 map=$outfile.map beam=$dirtyBeam out=$outfile.cc.new \
                     cutoff=$cutoff niters=$niter region=@$polygon_region\
                     model=$outfile.cc gain=$gain  > $outfile.$cclogfile
              else 
                   mossdi2 map=$dirtyImage beam=$dirtyBeam out=$outfile.cc.new \
                     cutoff=$cutoff niters=$niter\
                     model=$outfile.cc gain=$gain > $outfile.$cclogfile
              endif

           else if ($algorithm == "mosmem") then
              if ($run_mkmask == 1) then 
                   mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc.new \
                       niters=$niter rmsfac=$rmsfac \
                       flux=$flux measure=gull region=@$polygon_region model=$outfile.cc > $outfile.$cclogfile
              else
                   mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc.new \
                       niters=$niter rmsfac=$rmsfac \
                       flux=$flux measure=gull model=$outfile.cc > $outfile.$cclogfile
              endif
           else
              echo 'set algorithm = "mossdi2" or "mosmem"'
              exit
           endif

         # Move the new clean component file to overwrite the old one.
         rm -rf $outfile.cc
         mv $outfile.cc.new $outfile.cc 

         endif

         if $run_restart == 0 then 
            echo "Not running restart..."
         # Determine which channel to clean next
            set nchan = `imlist in=$dirtyImage | grep naxis3 | awk '{print $6}'`

          # Determine the next channel that needs to be reduced
            set n = 0
            set found = 0
            set outcc = 0
            while ($found == 0 && $n < $nchan) 
                echo "Determining which channel to clean next..."
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
                echo "Found an uncleaned channel, cleaning it..."
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
                 # if ($run_mkmask == 1) then
                 #     # Remove existing files
                 #       rm -rf $outfile.mask

                 #     # make signal to noise ratio map
                 #       maths exp="<$outfile.map>/<$outfile.sen>" out=$outfile.snr 

                 #     # make mask file
                 #       maths exp="<$outfile.snr>.gt.2.5" out=$outfile.mask
                 # endif

               # Clean map
                 if ($use_psf_as_beam != 0) then 
                    set dirtyBeam = $dirtyPSF
                 endif

                 echo "Cleaning..."
                 if ($algorithm == "mossdi") then
                    if ($run_mkmask == 1) then
                         mossdi map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                           cutoff=$cutoff niters=$niter region=@$polygon_region\
                            gain=$gain  > $outfile.$cclogfile
                    else 
                         mossdi map=$dirtyImage beam=$dirtyBeam out=$outfile.cc \
                           cutoff=$cutoff niters=$niter\
                            gain=$gain > $outfile.$cclogfile
                    endif

                 else if ($algorithm == "mossdi2") then
                    if ($run_mkmask == 1) then
                         mossdi2 map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                           cutoff=$cutoff niters=$niter region=@$polygon_region gain=$gain > $outfile.$cclogfile
                    else 
                         mossdi2 map=$dirtyImage beam=$dirtyBeam out=$outfile.cc \
                           cutoff=$cutoff niters=$niter gain=$gain > $outfile.$cclogfile
                    endif

                 else if ($algorithm == "mosmem") then
                    if ($run_mkmask == 1) then 
                         mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                             niters=$niter rmsfac=$rmsfac \
                             flux=$flux measure=gull region=@$polygon_region > $outfile.$cclogfile
                    else
                         mosmem map=$outfile.map beam=$dirtyBeam out=$outfile.cc \
                             niters=$niter rmsfac=$rmsfac \
                             flux=$flux measure=gull > $outfile.$cclogfile
                    endif
                 else
                    echo 'set algorithm = "mossdi2" or "mosmem"'
                    exit
                 endif
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

       # Plot the flux recovered by CLEAN vs the number of clean iterations used.a
       if ($plot_ccflux == 1) then
         echo "Plotting cc vs. flux..."
         set infile = $outfile.$cclogfile
         set plotfile = $outfile.$plotfile
         python ccflux.py -infile $infile -plotfile $plotfile 
         pdfopen --file $plotfile        
       endif     


  end # molecule
