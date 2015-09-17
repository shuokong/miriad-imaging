#! /usr/bin/env python
"""Contains functions for working with the NRO/CARMA ratio image produced by fluxscale + ratio scripts."""
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt
import sys


# def nro_mask():
# 	"""

# 	"""


def plot_radec(ratio_image, out='ratio_radec.png', cutoff=None, plotxy=False, mask=None):
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
    mask : str, optional
        Location of FITS image to be used to mask `ratio_image`.
        If None, no mask is applied.

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
            # Only plot pixels where the ratio is within the bounds set by
            # `cutoff`
            if cutoff is not None:
                boolean_crd = (ratio > -1. * cutoff) & (ratio < cutoff)
            else:
                boolean_crd = np.isfinite(ratio)

            try:
                maskhdulist = fits.open(mask)
            except ValueError:
                print('No mask specified. Plotting all defined pixels.')
                pass
            except:
                raise
            else:
                # If `mask` is a valid file name, apply it.
                maskdata = maskhdulist[0].data[0]  # Pick out first channel.
                boolean_mask = np.isfinite(maskdata)
                boolean_crd = boolean_crd & boolean_mask

        else:
            pass
            # Transform pixel coordinates to sky coordinates using WCS.

        # boolean_crd is a boolean array that picks only the pixels covered by NRO and
        # within the cutoff.
        crd = np.where(boolean_crd)
        # Mask the area not covered by NRO with Nan

        # plt.imshow(ratio)
        print('Median ratio: ' + str(np.median(ratio[crd])))
        f, axarr = plt.subplots(2, sharey=True)
        axarr[0].plot(crd[1], ratio[crd], '+', [crd[1][0], crd[1][-1]], [1, 1])
        axarr[1].plot(crd[0], ratio[crd], '+', [crd[0][0], crd[0][-1]], [1, 1])
        plt.show()
        plt.savefig(str(nchan) + out)
