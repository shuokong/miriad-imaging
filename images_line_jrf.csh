#!/bin/csh -fe

# Make images for web site
  set make_images = 1
  set webdir_plots = jansky:/scr2/carmaorion/web/orion/images

# Select algorithm
  set algorithm = "mossdi"
#  set algorithm = "mosmem"

# If run_invert = 1, then make dirty map
  set run_invert = 1

# If run_mkmask = 1, then we use mask in clean ; c.hara
  set run_mkmask = 0
  set mask = ""

# If run_clean = 1, then clean map
  set run_clean = 0

# If run_combine = 1, then combine CARMA + single dish
  set run_combine = 0

# If plotx = 1, plot maps onto xwindow
  set plotx = 0

# Set source
  set source = ""

# Number of channels to image
  set nchan = ""
  set vchan = ""
  set dvchan = ""

# Read molecule
  set mol = ""
  set molecules = (12co 13co c18o cn so cs)

# Invert parameters
  set robust = 2
  set cell   = 2.0
  set imsize = 129

# mossdi parameters
  set cutoff = 1.0 
  set region = ""

# mosmem parameters
  set niter      = 40
  set rmsfac     = 1.0
  set flux       = 1e-10

# Set RA/DEC
  set coords = "ra(4,7),dec(-10,-2)"

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

# Set source to all sources
  set source_orig = $source
  if ("$source_orig" == "") set source = "omc*"

# Loop over molcules
  foreach mol ($molecules) 
     # channel to clean run # for debug
       set nc  = $nchan
       set vch = $vchan
       set dv  = $dvchan
       if ($mol == "13co") then
          if ($vch == "") set vch = "0"
          if ($dv  == "") set dv = 0.132
          if ($nc  == "") set nc = 128
       else if ($mol == "so" | $mol == "cs" | $mol == "c18o") then
          if ($vch == "") set vch = "0"
          if ($dv  == "") set dv = 0.5
          if ($nc  == "") set nc =  32
       else if ($mol == "cn") then
          if ($vch == "") set vch = "-40"
          if ($dv  == "") set dv = 1.0
          if ($nc  == "") set nc = 60
       else if ($mol == "12co") then
          if ($vch == "") set vch = "0"
          if ($dv  == "") set dv = 0.5
          if ($nc  == "") set nc = 80
       endif
       set line = "velocity,$nc,$vch,$dv,$dv"

     # Set visibility and output file
       set vis  = ""
       set singledish = ""
       if ($mol == "12co") then
          set mol = 12co
       else if ($mol == "cn") then
          set mol = cn
          set run_combine = 0
       else if ($mol == "13co") then
          set mol = 13co
       else if ($mol == "c18o") then
          set mol = c18o
       else if ($mol == "so") then
          set mol = so
          set run_combine = 0
       else if ($mol == "cs") then
          set mol = cs
          set run_combine = 0
       else
          echo "Unknown molecule"
          exit
       endif
       if ($vis == "") then
          set cdir = "../calibrate"
          set ldir = merged/$mol
          set vis = "$cdir/$ldir/orion.D.narrow.mir,$cdir/$ldir/orion.E.narrow.mir"
       endif
       echo "vis = $vis"

     # Set output directories
       set dir      = jmc/${mol}
       set dir_plot = $dir/plots
       set sindir   = $dir/45m

     # Set output files
       set outfile    = "$dir/carma_${mol}"
       if ($source_orig != "") set outfile = "$dir/${source_orig}_${mol}"
       set singledish = "$sindir/$singledish"

     # Make directories
       if (!(-e "$dir")) mkdir $dir
       if (!(-e "$dir_plot")) mkdir $dir_plot

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
                options=systemp,mosaic,double \
                line=$line

         # Make combined beam
           mospsf beam=$outfile.beam out=$outfile.psf

        # Create theoretical noise image   
          rm -rf $outfile.sen $outfile.gain
          mossen in=$outfile.map sen=$outfile.sen gain=$outfile.gain

        # Compute SNR map
          rm -rf $outfile.snr
          maths exp="<$outfile.map>/<$outfile.sen>" out=$outfile.snr
       endif

     # Get beam size
       set log = $outfile.psf.log
       rm -rf $log
       imfit in=$outfile.psf object=beam 'region=arcsec,box(-5,-5,5,5)' > $log
       set bmaj=`grep "Major axis" $log | awk '{print $4}'`
       set bmin=`grep "Minor axis" $log | awk '{print $4}'`
       set bpa=`grep "  Position angle" $log | awk '{print $4}'`
       echo "Beam size = $bmaj x $bmin arcsec at PA = $bpa deg"

     # Clean image
       if ($run_clean == 1) then
          # Remove existing files
            rm -rf $outfile.{cc,cm,rs}

            if ($run_mkmask == 1) then
                # Remove existing files
                rm -rf $outfile.{mask}
                # calculate rms from sensitivity map
                set rms = `imstat in=$outfile.sen | tail -n 1 | awk '{print $3}'`
                echo "rms from sensitivity map is $rms"
                set clip = `calc "$rms*2.5"`
                echo "Clipping mask is constructed from emission is larger than $clip"
                # make mask file
                maths exp="<$outfile.map>.gt.$clip" out=$outfile.mask
            endif

          # Clean map
            if ($algorithm == "mossdi") then
               if ($run_mkmask == 1) then
                    mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                      cutoff=$cutoff region=$region niters=$niter region="mask("$outfile.mask")"
               else 
                  #  mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                  #    cutoff=$cutoff region=$region niters=$niter
                    mossdi map=$outfile.map beam=$outfile.beam out=$outfile.cc \
                      cutoff=$cutoff region=$region niters=$niter region="mask("$mask")"
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
            restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                   out=$outfile.cm fwhm=$bmaj,$bmin pa=$bpa
            restor map=$outfile.map beam=$outfile.beam model=$outfile.cc \
                   out=$outfile.rs fwhm=$bmaj,$bmin pa=$bpa mode=residual

          # Create signal to noise image
            rm -rf $outfile.snr
            maths exp="<$outfile.cm>/<$outfile.sen>" out=$outfile.snr
       endif

     # Combine with single dish
       if ($run_combine == 1) then
#          python combine_classy.py "$outfile.map" "$singledish" "$outfile.cc" "$outfile.beam" $bmaj $bmin $bpa 45
          python immerge_main.py "$singledish" "$outfile.cm" "$outfile.combine"
       endif

     # Display Dirty images
     # set directory
       set outplot = $dir_plot/carma_$mol
       if ($run_invert) then
          if ($plotx == 1) then
             cgdisp device=1/xs in=$outfile.map options=full labtyp=arcmin \
                    beamtyp=b,l options=full,wedge
          endif
       endif

     # Display Cleaned Images
       if ($run_clean) then
          if ($plotx == 1) then
             cgdisp device=2/xs in=$outfile.cm options=full,wedge \
                    beamtyp=b,l labtyp=arcmin
          endif
       endif

     # Make PDF images
       if ($make_images != 0) then
          # Remove files
            rm -rf orion_${mol}_{signal,rms,snr}.{ps,pdf}

          # Make images
            set psfiles = ()
            if (-e $outfile.map) then
               set fn = $dir/orion_${mol}_signal
               cgdisp device=$fn.ps/ps  in=$outfile.map \
                      options=blacklab,wedge,3value 3format=F6.2 \
                       labtyp=hms beamtyp=b,l nxy=1 range=-1,10
               set psfiles = ($psfiles $fn)
            endif
            if (-e $outfile.sen) then
               set fn = $dir/orion_${mol}_rms
               cgdisp device=$fn.ps/ps  in=$outfile.sen \
                    options=wedge region="images(1,1)" \
                    labtyp=hms beamtyp=b,l nxy=1 range=0,2
               set psfiles = ($psfiles $fn)
            endif
            if (-e $outfile.snr) then
               set fn = $dir/orion_${mol}_snr
               cgdisp device=$fn.ps/ps  in=$outfile.snr \
                    options=blacklab,wedge,3value 3format=F6.2 \
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

     # Done with molecule
       echo ""
       echo ""
       echo "*** Finished making maps of $outfile"
       echo ""
       echo ""
  end # molecule
