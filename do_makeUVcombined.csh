uvselect = "uvrange(6,1000.0)"
#select = "source(omc42),dec(-10,-3)"
source makeUVcombined_jrf.csh carmap='carma_42_171.172.map' carbeam='carma_42_171.172.beam' makeImage=0 #select=$select #uvselect=$uvselect 

mv nro/13co/13co.uv.all nro/13co/13co.uvall_42_171.172_scalefactor.all
mv nro/13co/carma_uv.mir nro/13co/carma_uvall_42_171.172_scalefactor.mir
