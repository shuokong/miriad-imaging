set niter=2000000
set run_invert = 1
#set vis = "nro/13co/carma_uv_full_171.172_scalefactor.mir,nro/13co/13co.uv_full_171.172_scalefactor.all"
#set vis = "nro/13co/carma_uv_42_171.172_scalefactor.mir,nro/13co/13co.uv_42_171.172_scalefactor.mir"

set vis = "nro/13co/13co.carmacell1_uvall.all,nro/13co/carma_carmacell1_uvall.mir2"
#set vis = "nro/13co/carma_uv6to1000_42_171.172_scalefactor.mir,nro/13co/13co.uv6to1000_42_171.172_scalefactor.all"
#set vis = "nro/13co/13co.uvall_42_171.172_scalefactor.all"
#set dirty_name = 'carmaonly_noscalefactor'
#set dirty_name = 'omc_full_mosaic.double.systemp_171.172'
set dirty_name = 'combined_carmacell1_rob2_uvall'
set source = 'omc42'
set robust = 2
set cell = 1
set run_mkmask = 1
set run_restart = 0
set restart_channel = 2
set run_clean = 1
set run_restor = 1
set cutoff = 0.01
#set polygon_region = 'region_none.txt'
set polygon_region = '42_region.txt'
set region_limit = 0
set options="double,systemp,mosaic"
set different_beam = 0
set use_psf_as_beam = 0
set use_which_antennas = 0 
#set use_which_antennas = "6m10m" 
#set select = "dec(-8,-05:25)"
#set options="mosaic"

time images_line_isella.csh niter=$niter run_mkmask=$run_mkmask run_restart=$run_restart cutoff=$cutoff polygon_region=$polygon_region restart_channel=$restart_channel run_invert=$run_invert run_clean=$run_clean run_restor=$run_restor robust=$robust vis=$vis dirty_name=$dirty_name options=$options region_limit=$region_limit different_beam=$different_beam use_psf_as_beam=$use_psf_as_beam use_which_antennas=$use_which_antennas cell=$cell#select=$select #source=$source

