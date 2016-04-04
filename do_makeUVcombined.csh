uvselect = "uvrange(6,1000.0)"
#select = "source(omc42),dec(-10,-3)"
source makeUVcombined_jrf.csh carmap='carma_42_171.172_cell5rob0imsize257_.map' carbeam='carma_42_171.172_cell5rob0imsize257_.beam' makeImage=1 cell=2. #select=$select #uvselect=$uvselect 

mv nro/13co/13co.uv.all nro/13co/13co.uv6to1000_42_171.172_cell2rob0imsize257_scalefactor.all
mv nro/13co/carma_uv.mir nro/13co/carma_uv6to1000_42_171.172_cell2rob0imsize257_scalefactor.mir
