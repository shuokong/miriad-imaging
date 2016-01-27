foreach f ($nrouv*)
    uvputhd hdvar=systemp type=r length=1 varval=$tsysnro vis=$f out=tmptmp1.mir
    uvputhd hdvar=jyperk  type=r length=1 varval=$jyperk  vis=tmptmp1.mir out=tmptmp2.mir
    uvputhd hdvar=pol type=i length=1 varval=1 vis=tmptmp2.mir out=tmptmp3.mir
    uvputhd hdvar=lst type=d length=1 varval=12 vis=tmptmp3.mir out=tmptmp4.mir
    uvputhd hdvar=telescop type=a varval='GAUS(120)' vis=tmptmp4.mir out=tmptmp5.mir
    rm -rf $f
    mv tmptmp5.mir $f
    rm -rf tmptmp*.mir
end
