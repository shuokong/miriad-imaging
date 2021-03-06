#!/bin/csh -fe
#Modified from images_cont_jmc.csh from John Carpenter 2015
# If verb = 1, echo status/debug statements to terminal.
  set miriad_64 = 1
  if $miriad_64 then
     echo ""
     echo "*** Loading miriad version miriad_64 ***"
     echo ""
     source ~/.cshrc startMiriad=0
     source /scr/carmaorion/sw/miriad_64/miriad_start.csh
  endif

  set verb = 0
  if $verb echo "Setting up parameters..."
# Make images for web site
  set make_images = 0
  set webdir_plots = jansky:/scr2/carmaorion/web/orion/images

# Select algorithm
# set algorithm = "mosmem"
  set algorithm = "mossdi"

# Visibilities
  set cdir = /hifi/carmaorion/orion/calibrate/merged/cont
  set vis = "$cdir/orion.D.wide.mir,$cdir/orion.E.wide.mir"

# If run_invert = 1, then make dirty map
  set run_invert = 1

# If run_mkregion = 1, then define a region where gain=1, and only clean within
# this.
  set run_mkregion = 0

# If run_mkmask = 1, then we use mask in clean ; c.hara
  set run_mkmask = 0
  set snr_mask = 2.5 # The minimum SNR to be cleaned.
  set mask = ""

# If run_replace = 1, replace values below mask in dirty map with 0s; jrf 
  set run_replace = 0


# If run_imfit = 1, then fit the psf image and derive the beam
  set run_imfit = 0

# If run_clean = 1, then clean map
  set run_clean = 0


# If plotx = 1, plot maps onto xwindow
  set plotx = 1

# If hardcopy = 1, plot maps onto eps 
  set hardcopy = 0

# Set source
  set source = ""

# invert parameters
  set cell = 2
  set imsize = 127
  set robust = 0

# mossdi parameters
  set cutoff = 0.1
  set niter  = 40
# set region = "arcsec,'box(-540,-540,540,540)'"
  set region = ""

# mosmem parameters
  set rmsfac     = 1.0
  set flux       = 1e-10

# Set RA/DEC
  set coords = "ra(3,7),dec(-10,0)"

# Set output directories
  set dir      = /hifi/carmaorion/orion/images/jrf/cont
  set dir_plot = $dir/plots

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

# Set source to all sources
  if $verb echo "Setting sources..."
  set source_orig = $source
  if ($source_orig == "") then
     set source = "omc*"
  endif


# Set output files
  set outfile = "$dir/carma_cont"
  if ($source_orig != "") then
     set s = `echo $source_orig | awk '{split($1,a,","); print a[1]}'`
     set outfile = "$dir/${s}_cont"
  endif

# Make directories
  if $verb echo "Making directories..."

  if (!(-e "$dir")) then
     mkdir $dir
  endif

  if (!(-e "$dir_plot")) then
     mkdir $dir_plot
  endif
  
# Make dirty map
  if ($run_invert == 1) then
     # Clean existing files
       rm -rf $outfile.{map,beam,snr,sen,gain,psf,psf.log}
 
       echo ""
       echo ""
       echo ""
       echo "*** Making $outfile.map and $outfile.beam ***"
       invert vis=$vis map=$outfile.map beam=$outfile.beam \
                select="$coords,source($source)" \
                cell=$cell \
                imsize=$imsize \
                robust=$robust \
                options=systemp,mosaic,double,mfs
           cgdisp device =/xs in=$outfile.map options=wedge labtyp=hms
 
     # Make combined beam
       mospsf beam=$outfile.beam out=$outfile.psf
 
     # Create theoretical noise image   
       rm -rf $outfile.sen $outfile.gain
       mossen in=$outfile.map sen=$outfile.sen gain=$outfile.gain

     # Create signal to noise image
       rm -rf $outfile.snr
       maths exp="<$outfile.map>/<$outfile.sen>" out=$outfile.snr
  endif

# Get beam size
  if ($run_imfit == 1) then
     set log = $outfile.psf.log
     rm -rf $log
     imfit in=$outfile.psf object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
     set bmaj=`grep "Major axis" $log | awk '{print $4}'`
     set bmin=`grep "Minor axis" $log | awk '{print $4}'`
     set bpa=`grep "  Position angle" $log | awk '{print $4}'`
     echo "Beam size = $bmaj x $bmin arcsec at PA = $bpa deg"
  endif

# Clean image
  if ($run_clean == 1) then
     # Remove existing files
       rm -rf $outfile.{cc,cm,rs}

       if ($run_mkmask == 1) then
           # Remove existing files
           rm -rf $outfile.{mask}
           rm -rf $outfile.{snr_dirty}
           
           # JRF, August 2015
           # ==================
           # Problem: The mean of the sensitivity map, found below, is the mean
           # rms of the image, but the RMS is much higher on the edges, so we
           # should really define the mask pixel by pixel based on a snr IMAGE, not just the
           # overall mean!!
            
           # Define mask using SNR image and the snr floor specified.
           maths exp="<$outfile.snr>.gt.$snr_mask" out=$outfile.mask           

     

           # Old mask routine
           # =================

           # calculate rms from sensitivity map
           #set rms = `imstat in=$outfile.sen | tail -n 1 | awk '{print $3}'`
           #echo "rms from sensitivity map is $rms"
           #set clip = `calc "$rms*$snr_mask"`
           #echo "Clipping mask is constructed from emission is larger than $clip"
           # make mask file
           #maths exp="<$outfile.map>.gt.$clip" out=$outfile.mask
            
           if ($run_replace == 1) then
              # JRF, August 2015
              # Replace all unwanted areas of image with 0s by
              # multiplying the dirty image by the mask.
              rm -rf $outfile.{map_replace}
              maths exp="<$outfile.map>*<$outfile.mask>" out=$outfile.map_replace
           endif 

       endif

     # Working on this... 8/18/15
     #  if ($run_mkregion == 1) then
     #     fits in=$outfile.gain out=$outfile.gain.fits op=xyout
     #     python 

     #     endif

     # Clean map
       if ($algorithm == "mossdi") then
          
          if ($run_mkmask == 1) then

             if ($run_replace == 1) then
                mossdi map=$outfile.map_replace beam=$outfile.beam out=$outfile.cc \
                 cutoff=$cutoff region=$region niters=$niter 

             else
                mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                 cutoff=$cutoff region=$region niters=$niter region="mask("$outfile.mask")"
                
             endif

          else 
             #  mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
             #    cutoff=$cutoff region=$region niters=$niter
               mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                 cutoff=$cutoff region=$region niters=$niter # region="mask("$mask")"
          endif
       else if ($algorithm == "mosmem") then
          if ($run_mkmask == 1) then 
               mosmem map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                   niters=$niter region=$region rmsfac=$rmsfac \
                   flux=$flux measure=gull region="mask("$outfile.mask")"
          else
               mosmem map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                   niters=$niter region=$region rmsfac=$rmsfac \
                   flux=$flux measure=gull
          endif
       else
          echo 'set $algorithm = "mossdi" or "mosmem"'
          exit
       endif

     # Restore image
       if ($run_replace == 1) then
          #Use the original (unmasked) dirty map as the input file for restor.
          restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                 out=$outfile.cm fwhm=$bmaj,$bmin pa=$bpa
          restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                 out=$outfile.rs fwhm=$bmaj,$bmin pa=$bpa mode=residual

          #restor map=$outfile.map_replace beam=$outfile.beam model=$outfile.cc \
          #       out=$outfile.cm fwhm=$bmaj,$bmin pa=$bpa
          #restor map=$outfile.map_replace beam=$outfile.beam model=$outfile.cc \
          #       out=$outfile.rs fwhm=$bmaj,$bmin pa=$bpa mode=residual
       
       else
          restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                 out=$outfile.cm fwhm=$bmaj,$bmin pa=$bpa
          restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                 out=$outfile.rs fwhm=$bmaj,$bmin pa=$bpa mode=residual
       endif

     # Create signal to noise image
       rm -rf $outfile.snr
       maths exp="<$outfile.cm>/<$outfile.sen>" out=$outfile.snr
  endif

  
# Display Dirty images
# set directory
  if $verb echo "Displaying images, if requested..."
  set outplot = $dir_plot/carma_cont
  if ($run_invert) then
     if ($plotx == 1) then
        cgdisp device=1/xs in=$outfile.map options=full labtyp=arcmin \
               beamtyp=b,l options=full,wedge
     endif
     if ($hardcopy == 1) then
        cgdisp device=$outplot.map.eps/cps in=$outfile.map \
               options=full,blacklab,wedge labtyp=arcmin beamtyp=b,l
     endif
  endif

# Display Cleaned Images
  if ($run_clean) then
     if ($plotx == 1) then
        cgdisp device=2/xs in=$outfile.cm options=full,wedge \
               beamtyp=b,l labtyp=arcmin
     endif
     if ($hardcopy == 1) then
        cgdisp device=$outplot.cm.eps/cps in=$outfile.cm \
               options=full,blacklab,wedge labtyp=arcmin beamtyp=b,l
     endif
  endif

# Make PDF images
  if $verb echo "Making pdfs, if requested..."
  if ($make_images != 0) then
     # Remove files
       rm -rf orion_continuum_{signal,rms,snr}.{ps,pdf}

     # Make images
       set psfiles = ()
       set ext = ""
       if (-e $outfile.cm) then
          set ext = "cm"
       else if (-e $outfile.map) then
          set ext = "map"
       endif
       if (-e $outfile.$ext) then
          set fn = $dir/orion_continuum_signal
          cgdisp device=$fn.ps/ps  in=$outfile.$ext \
                 options=blacklab,wedge \
                  labtyp=hms beamtyp=b,l nxy=1 range=-5e-3,30e-3
          set psfiles = ($psfiles $fn)
       endif
       if (-e $outfile.sen) then
          set fn = $dir/orion_continuum_rms
          cgdisp device=$fn.ps/ps  in=$outfile.sen \
               options=blacklab,wedge \
                labtyp=hms beamtyp=b,l nxy=1 range=0,10e-3
          set psfiles = ($psfiles $fn)
       endif

       if (-e $outfile.snr) then
          set fn = $dir/orion_continuum_snr
          cgdisp device=$fn.ps/ps  in=$outfile.snr \
               options=blacklab,wedge \
                labtyp=hms beamtyp=b,l nxy=1 range=-3,10
          set psfiles = ($psfiles $fn)
       endif

     # Make pdf and copy to web directory
       foreach fn ($psfiles)
          ps2pdf $fn.ps $fn.pdf
          rm $fn.ps
          rsync $fn.pdf $webdir_plots
       end
  endif

# Done with channel
  echo ""
  echo ""
  echo "*** Finished to make maps of $outfile"
  echo ""
  echo ""
