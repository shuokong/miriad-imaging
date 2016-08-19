#set uvselect = "uvrange(6,1000.0)"
set uvflag = 1
#select = "source(omc42),dec(-10,-3)"
source makeUVcombined_jrf.csh carmap='carma_42_171.172_cell1rob2imsize257.map' carbeam='carma_42_171.172_cell1rob2imsize257.beam' makeImage=1 cell=1 imsize=257 robust=2 uvflag=$uvflag #select=$select #uvselect=$uvselect 

rm -rf nro/13co/13co.carmacell1_uv6to1000_nrobm16.all
rm -rf nro/13co/carma_carmacell1_uv6to1000_nrobm16.mir
mv nro/13co/13co.uv.all nro/13co/13co.carmacell1_uv6to1000_nrobm16.all
mv nro/13co/carma_uv.mir nro/13co/carma_carmacell1_uv6to1000_nrobm16.mir
