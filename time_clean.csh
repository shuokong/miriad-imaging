set niter=1000000
set run_invert = 0
set vis = "nro/13co/carma_uv_42.43.53.54_171.172_scalefactor.mir,nro/13co/13co.uv_42.43.53.54_171.172_scalefactor.mir"
#set vis = "nro/13co/carma_uv.mir,nro/13co/13co.uv.all_old"
#set dirty_name = 'carmaonly_noscalefactor'
set dirty_name = 'omc42.43.53.54_mosaic.double.systemp_171.172'
#set source = 'omc42,omc43'
set robust = 0
set run_mkmask = 1
set run_restart = 0
set restart_channel = 1
set run_clean = 1
set run_restor = 1
set cutoff = 0.5
set polygon_region = 'gain0_region42.43.53.54.txt'
set region_limit = 0
set options="mosaic,double,systemp"

time images_line_isella.csh niter=$niter run_mkmask=$run_mkmask run_restart=$run_restart cutoff=$cutoff polygon_region=$polygon_region restart_channel=$restart_channel run_invert=$run_invert run_clean=$run_clean run_restor=$run_restor robust=$robust vis=$vis dirty_name=$dirty_name options=$options region_limit=$region_limit #source=$source
