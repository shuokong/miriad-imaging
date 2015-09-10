#! /usr/bin/env python
"""Summary"""
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt


def plot_radec(ratio_image, out='ratio_radec.png', cutoff=None, plotxy=False):
    """
    Parameters
    ----------
    ratio_image : str
        Location of FITS image with NRO/CARMA ratio.
    out : str, optional
        Location of plot file.
    cutoff : float, optional
        Description, the default is None.
    plotxy : bool, optional
        If True, then plot the xy coordinates, not RaDec

    Deleted Parameters
    ------------------
    plot_image : str
        Location of output plot file.
    plot : str, optional
        Description
    """
    hdulist = fits.open(ratio_image)
    hdr = hdulist[0].header
    data = hdulist[0].data
    hdulist.close()

    data = data[0]  # Drop polarization axis.

    for nchan in range(data.shape[0]):

        ratio = data[nchan]

        if plotxy:
            if cutoff is not None:
                crd = np.where((ratio > -1. * cutoff) & (ratio < cutoff))
                xcrd = crd[1]
                ycrd = crd[0]
            else:
                crd = np.where(np.isfinite(ratio))
                xcrd = crd[1]
                ycrd = crd[0]
        else:
            pass
            # Transform pixel coordinates to sky coordinates using WCS.

        f, axarr = plt.subplots(2, sharey=True)
        axarr[0].plot(xcrd, ratio[crd], '+', [xcrd[0], xcrd[-1]], [1, 1])
        axarr[1].plot(ycrd, ratio[crd], '+', [ycrd[0], ycrd[-1]], [1, 1])
        plt.show()
        plt.savefig(plot + str(nchan))
