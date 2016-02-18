set niter=2000000
set run_invert = 1
#set vis = "nro/13co/carma_uv_omc4243_171.172_scalefactor.mir,nro/13co/13co.uv_omc4243_171.172_scalefactor.mir"
set vis = "nro/13co/carma_uv.mir,nro/13co/13co.uv.all_old"
#set dirty_name = 'carmaonly_noscalefactor'
set dirty_name = 'combined_full'
#set source = 'omc42,omc43'
set robust = 0
set run_mkmask = 0
set run_restart = 0
set restart_channel = 1
set run_clean = 0
set run_restor = 0
set cutoff = 0.01
set polygon_region = 'gain0_region.txt'

time images_line_isella.csh niter=$niter run_mkmask=$run_mkmask run_restart=$run_restart cutoff=$cutoff polygon_region=$polygon_region restart_channel=$restart_channel run_invert=$run_invert run_clean=$run_clean run_restor=$run_restor robust=$robust vis=$vis dirty_name=$dirty_name #source=$source
