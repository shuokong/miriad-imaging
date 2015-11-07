#! /usr/bin/env python
"""Contains functions for working with the NRO/CARMA ratio image produced by fluxscale + ratio scripts.

Attributes
----------
cmap : TYPE
    Description
dec_region : list
    Description
ra_region : TYPE
    Description
"""
import numpy as np
from astropy.io import fits
from astropy.wcs import WCS
import matplotlib as mpl
import matplotlib.pyplot as plt
import sys
from scipy import stats

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
# Define the color map to use
cmap = mpl.cm.jet

# colors = ['black', 'red', 'blue', 'green']


def plot_radec(ratio_image_list, out='ratio.png', cutoff=None,
               plotxy=True, mask=None, ra_region=ra_region, dec_region=dec_region,
               only_positive=True, plot_points=False, plot_bins=True, plot_medians=True):
    """
    Parameters
    ----------
    ratio_image_list : str, list
        Description
    out : str, optional
        Location of plot file.
    cutoff : float, optional
        Description, the default is None.
    plotxy : bool, optional
        If True, then plot the xy coordinates, not RaDec
    mask : str, optional
        Location of FITS image to be used to mask `ratio_image`.
        If None, no mask is applied.
    ra_region : str, optional
        Description
    dec_region : str, optional
        Description
    only_positive : bool, optional
        If True, then plot only positive ratios.
    plot_points : bool, optional
        If True, plot individual pixel values.
    plot_bins : bool, optional
        If True, plot binned medians with std deviation errorbars.
    plot_medians : bool, optional
        If True, plot median ratios in each channel as horizontal lines.

    Deleted Parameters
    ------------------
    plot_image : str
        Location of output plot file.
    plot : str, optional
        Description
    ratio_image : str, list
        List of FITS image with NRO/CARMA ratio.
    """
    # Ensure that we can loop over a one item list.
    if type(ratio_image_list) == str:
        ratio_image_list = [ratio_image_list]
    # Plot all channels on a single ratio plot
    f, axarr = plt.subplots(2, sharey=True)
    # Define the total number of channels to be plotted
    # as the number of equally space colors to use from cmap.
    n_images = np.size(ratio_image_list)
    n_colors = 0
    for ratio_image in ratio_image_list:
        n_colors += fits.open(ratio_image)[0].data[0].shape[0]

    i_color = -1
    for ratio_image in ratio_image_list:
        hdulist = fits.open(ratio_image)
        hdr = hdulist[0].header
        data = hdulist[0].data
        hdulist.close()

        data = data[0]  # Drop polarization axis.

        for nchan in range(data.shape[0]):
            i_color += 1

            ratio = data[nchan]

            if plotxy:
                # Only plot pixels where the ratio is within the bounds set by
                # `cutoff`
                if cutoff is not None:
                    boolean_crd = (ratio > -1. * cutoff) & (ratio < cutoff)
                else:
                    boolean_crd = np.isfinite(ratio)

                # Only plot positive ratios.
                if only_positive == True:
                    boolean_crd = (ratio >= 0) & (boolean_crd)

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
            # plt.imshow(ratio)
            # plt.plot(crd[1], crd[0], 'o')
            # plt.show()
            print('Median ratio: ' + str(np.median(ratio[crd])))
            # f, axarr = plt.subplots(2, sharey=True)
            axarr[0].set_ylabel('CARMA/NRO')
            axarr[0].set_xlabel('X pixel')
            axarr[1].set_ylabel('CARMA/NRO')
            axarr[1].set_xlabel('Y pixel')
            if plot_points == True:
                axarr[0].plot(
                    crd[1], ratio[crd], '.', markersize=2, alpha=0.1, color=cmap(i_color / float(n_colors)))
                axarr[1].plot(
                    crd[0], ratio[crd], '.', markersize=2, alpha=0.1, color=cmap(i_color / float(n_colors)))

            # Plot binned medians.
            # bin_medians_x, bin_edges_x, bin_number_x = stats.binned_statistic(crd[1], ratio[crd], statistic='median', bins=50)
            # bin_medians_y, bin_edges_y, bin_number_y = stats.binned_statistic(crd[0], ratio[crd], statistic='median', bins=50)
            # axarr[0].hlines(bin_medians_x, bin_edges_x[:-1], bin_edges_x[1:], lw=5,
            #      label='binned medians')
            # axarr[1].hlines(bin_medians_y, bin_edges_y[:-1], bin_edges_y[1:], lw=5,
            #      label='binned medians')
            # Plot binned medians
            if plot_bins == True:
	            nbins = 20
	            xbins = np.linspace(crd[1].min(), crd[1].max(), nbins)
	            ybins = np.linspace(crd[0].min(), crd[0].max(), nbins)
	            xdelta = xbins[1] - xbins[0]
	            ydelta = ybins[1] - ybins[0]
	            xidx = np.digitize(crd[1], xbins)
	            yidx = np.digitize(crd[0], ybins)
	            xrunning_median = [np.median(ratio[crd][xidx == k])
	                                         for k in range(nbins)]
	            xrunning_std = [ratio[crd][xidx == k].std() for k in range(nbins)]
	            yrunning_median = [np.median(ratio[crd][yidx == k])
	                                         for k in range(nbins)]
	            yrunning_std = [ratio[crd][yidx == k].std() for k in range(nbins)]
                axarr[0].errorbar(xbins - xdelta / 2, xrunning_median, xrunning_std, xdelta / 2, ecolor=cmap(i_color / float(n_colors)), markersize=10, fmt=None, elinewidth=3)
                axarr[1].errorbar(ybins - ydelta / 2, yrunning_median, yrunning_std, ydelta / 2, ecolor=cmap(i_color / float(n_colors)), markersize=10, fmt=None, elinewidth=3)
            # Plot total medians
            if plot_medians == True:
                axarr[0].plot([crd[1].min(), crd[1].max()], [np.median(ratio[crd]), np.median(
                    ratio[crd])], lw=2, color=cmap(i_color / float(n_colors)), label='channel ' + ratio_image[6 + (nchan * 4): 9 + (nchan * 4)])
                axarr[1].plot([crd[0].min(), crd[0].max()], [np.median(ratio[crd]), np.median(
                    ratio[crd])], lw=2, color=cmap(i_color / float(n_colors)), label='channel ' + ratio_image[6 + (nchan * 4): 9 + (nchan * 4)])

            # Plot a histogram of the ratio image.
            # f, ax = plt.subplots(1)
            # ax.hist(ratio[crd], bins=100)
            # plt.show()
    axarr[0].legend(prop={'size': 6})
    plt.show()
    plt.savefig(out)
