# Plot pointing centers of CARMA and NRO pointings from UVINDEX (MIRIAD)
# ouput files.


def plot(carma_pntgs='cell1_pointings_carma.txt', nro_pntgs='cell1_pointings_nro.txt',
         col_starts=(0, 23, 37, 56, 68), format='fixed_width_no_header',
         data_start_carma=73, data_start_nro=143,
         data_end_carma=199, data_end_nro=269,
         names=('Source', 'RA', 'DEC', 'dra', 'ddec'),
         plotfile='pointing_centers.png'):
    """
    """
    from astropy.io import ascii
    from astropy.coordinates import SkyCoord
    import astropy.units as u
    import matplotlib.pyplot as plt
    import numpy as np

    carma_table = ascii.read(carma_pntgs, format=format, names=names,
                             col_starts=col_starts, data_start=data_start_carma,
                             data_end=data_end_carma)
    nro_table = ascii.read(nro_pntgs, format=format, names=names,
                           col_starts=col_starts, data_start=data_start_nro,
                           data_end=data_end_nro)

    carma_ref_coord = SkyCoord(ra=carma_table['RA'][0],
                               dec=carma_table['DEC'][0],
                               unit=(u.hourangle, u.degree))
    carma_pntg_offsets = SkyCoord(ra=carma_table['dra'] * u.arcsec,
                                  dec=carma_table['ddec'] * u.arcsec)
    carma_pntg_coords = SkyCoord(ra=carma_ref_coord.ra + carma_pntg_offsets.ra,
                                 dec=carma_ref_coord.dec + carma_pntg_offsets.dec)

    nro_ref_coord = SkyCoord(ra=nro_table['RA'][0],
                             dec=nro_table['DEC'][0],
                             unit=(u.hourangle, u.degree))
    nro_pntg_offsets = SkyCoord(ra=nro_table['dra'] * u.arcsec,
                                dec=nro_table['ddec'] * u.arcsec)
    nro_pntg_coords = SkyCoord(ra=nro_ref_coord.ra + nro_pntg_offsets.ra,
                               dec=nro_ref_coord.dec + nro_pntg_offsets.dec)

    # Sort the arrays by RA then DEC to match up corresponding NRO/CARMA
    # pointings.
    nro_ra = nro_pntg_coords.ra.value
    nro_dec = nro_pntg_coords.dec.value
    nro_ind = np.lexsort((nro_dec, nro_ra))
    nro_ra = nro_ra[nro_ind]
    nro_dec = nro_dec[nro_ind]
    # Do the same for CARMA
    carma_ra = carma_pntg_coords.ra.value
    carma_dec = carma_pntg_coords.dec.value
    carma_ind = np.lexsort((carma_dec, carma_ra))
    carma_ra = carma_ra[carma_ind]
    carma_dec = carma_dec[carma_ind]

    print((nro_ra - carma_ra) * 3600.)
    print((nro_dec - carma_dec) * 3600.)

    fig, ax = plt.subplots()

    carma_plt = ax.plot(carma_ra,
                        carma_dec, 'rs', markersize=3,
                        label='CARMA Pointings')
    nro_plt = ax.plot(nro_ra,
                      nro_dec, 'b+', markersize=10,
                      label='NRO Pointings')

    ax.set_xlabel('Right Ascension (deg)', size=16)
    ax.set_ylabel('Declination (deg)', size=16)
    plt.legend(prop={'size': 8})
    plt.savefig(plotfile)

   #  fig, ax = plt.subplots()

    # ax.plot((nro_ra - carma_ra)*3600., (nro_dec - carma_dec)*3600., 'b+'
   #  ax.set_xlabel('Right Ascension (deg)', size=16)
   #  ax.set_ylabel('Declination (deg)', size=16)
   #  plt.savefig(plotfile)
