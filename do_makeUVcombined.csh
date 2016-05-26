#set uvselect = "uvrange(6,1000.0)"
set uvflag = 1
#select = "source(omc42),dec(-10,-3)"
source makeUVcombined_jrf.csh carmap='carma_41_171.172_cell1rob2imsize200.map' carbeam='carma_41_171.172_cell1rob2imsize200.beam' makeImage=1 cell=1 imsize=200 robust=2 uvflag=$uvflag #select=$select #uvselect=$uvselect 

mv nro/13co/13co.uv.all nro/13co/13co.carmacell1_uv6to1000_nrobm16_imsize200.all
mv nro/13co/carma_uv.mir nro/13co/carma_carmacell1_uv6to1000_nrobm16_imsize200.mir
