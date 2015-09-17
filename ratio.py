#! /usr/bin/env python
"""Contains functions for working with the NRO/CARMA ratio image produced by fluxscale + ratio scripts."""
import numpy as np
from astropy.io import fits
from astropy.wcs import WCS
import matplotlib.pyplot as plt
import sys

#- Region: Middle: dec = -05:55 to -05:23 , ra = 5:36:30 to 5:33:37
#                Bottom: dec = -6:30 to -05:55 , ra = 5:36:30 to 5:34:47
#                Top: dec = -05:23 to -04:49, ra = 5:35:31 to 5:34:34
# def nro_mask():
# 	"""

# 	"""
ra_region = [['5:36:30', '5:33:37'], [
    '5:36:30', '5:34:47'], ['5:35:31', '5:34:34']]
dec_region = [['-05:55', '-05:23'], ['-06:30', '-05:55'], ['-05:23', '-04:49']]
import astropy.units as u
import astropy.coordinates as coord
# Convert region limits to degrees.
ra_region = coord.Angle(ra_region, unit=u.hour).deg
dec_region = coord.Angle(dec_region, unit=u.deg).deg


def plot_radec(ratio_image, out='ratio_radec.png', cutoff=None, plotxy=False, mask=None,
               ra_region=ra_region, dec_region=dec_region):
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

            #==============Region masking========================

            w = WCS(ratio_image).dropaxis(3).dropaxis(2)
            lx, ly = ratio.shape[1], ratio.shape[0]
            X, Y = np.ogrid[0:lx, 0:ly]
            boolean_region = (np.isnan(X)) & (np.isnan(Y))
            for ra, dec in zip(ra_region, dec_region):

                x, y = w.wcs_world2pix(ra, dec, 0)
                new_boolean_region = (X > x[0]) & (
                    X < x[1]) & (Y > y[0]) & (Y < y[1])
                boolean_region = boolean_region | new_boolean_region

            # boolean_crd = boolean_region & boolean_crd
            boolean_crd = np.swapaxes(boolean_region, 0, 1) & boolean_crd
            # try:
            #     maskhdulist = fits.open(mask)
            # except ValueError:
            #     print('No mask specified. Plotting all defined pixels.')
            #     pass
            # except:
            #     raise
            # else:
            # If `mask` is a valid file name, apply it.
            # maskdata = maskhdulist[0].data[0]  # Pick out first channel.
            #     boolean_mask = np.isfinite(maskdata)
            #     boolean_crd = boolean_crd & boolean_mask

        else:
            pass
            # Transform pixel coordinates to sky coordinates using WCS.

        # boolean_crd is a boolean array that picks only the pixels covered by NRO and
        # within the cutoff.
        crd = np.where(boolean_crd)
        # Mask the area not covered by NRO with Nan

        plt.imshow(ratio)
        plt.plot(crd[1], crd[0], 'o')
        plt.show()
        print('Median ratio: ' + str(np.median(ratio[crd])))
        f, axarr = plt.subplots(2, sharey=True)
        axarr[0].plot(crd[1], ratio[crd], '+', [crd[1][0], crd[1][-1]], [1, 1])
        axarr[1].plot(crd[0], ratio[crd], '+', [crd[0][0], crd[0][-1]], [1, 1])
        plt.show()
        plt.savefig(str(nchan) + out)
