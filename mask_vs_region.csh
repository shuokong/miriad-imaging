#!/bin/csh -fe
 
images_cont_jrf.csh run_mkmask=1 run_replace=1 snr_mask=3 niter=1000000 source='OMC42,OMC43' cutoff=0.01 dir=/hifi/carmaorion/orion/images/jrf/cont_mask > /hifi/carmaorion/orion/images/jrf/cont_mask/clean.log

images_cont_jrf.csh run_mkmask=0 run_replace=0 region='arcsec,box(180,-240,-180,200)' niter=1000000 source='OMC42,OMC43' cutoff=0.01 dir=/hifi/carmaorion/orion/images/jrf/cont_region > /hifi/carmaorion/orion/images/jrf/cont_region/clean.log

