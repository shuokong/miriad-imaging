foreach n (5 6 7 8 9)
    ratio_jrf.csh cutoff=$n carmap=carma_full_186.187.map nromap=nro_full_186.187.map out=ratio_full_186.187_{$n}_nrocutoff.map
    rm -rf ratio_full_186.187_{$n}_nrocutoff.map.fits
    fits in=ratio_full_186.187_{$n}_nrocutoff.map out=ratio_full_186.187_{$n}_nrocutoff.map.fits op=xyout
end
foreach n (5 6 7 8 9)
    ratio_jrf.csh cutoff=$n carmap=carma_full_171.172.map nromap=nro_full_171.172.map out=ratio_full_171.172_{$n}_nrocutoff.map
    rm -rf ratio_full_171.172_{$n}_nrocutoff.map.fits
    fits in=ratio_full_171.172_{$n}_nrocutoff.map out=ratio_full_171.172_{$n}_nrocutoff.map.fits op=xyout
end
foreach n (5 6 7 8 9)
    ratio_jrf.csh cutoff=$n carmap=carma_full_155.156.map nromap=nro_full_155.156.map out=ratio_full_155.156_{$n}_nrocutoff.map
    rm -rf ratio_full_155.156_{$n}_nrocutoff.map.fits
    fits in=ratio_full_155.156_{$n}_nrocutoff.map out=ratio_full_155.156_{$n}_nrocutoff.map.fits op=xyout
end
foreach n (5 6 7 8 9)
    ratio_jrf.csh cutoff=$n carmap=carma_full_163.164.map nromap=nro_full_163.164.map out=ratio_full_163.164_{$n}_nrocutoff.map
    rm -rf ratio_full_163.164_{$n}_nrocutoff.map.fits
    fits in=ratio_full_163.164_{$n}_nrocutoff.map out=ratio_full_163.164_{$n}_nrocutoff.map.fits op=xyout
end
