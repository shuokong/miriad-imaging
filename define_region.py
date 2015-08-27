#! /usr/bin/env python
# This comment was added while working on hifi.
from __future__ import print_function
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt

# This comment was added while working on sagan.


def region(image='gain.fits', outfile='region.txt', limit=1.0,
           format='pixels', outformat='oneline', image_type='gain'):
    """
      Write out a text file that can be be read by the MIRIAD command mossdi
      to specify a region for cleaning. Finds the vertices of a polygon that
      covers the entire region where gain >= limit. The vertices are
      written in pixels relative to the center or in RA/DEC. Write ou t in
      RA/DEC when writing one region file that will be used repeatedly with
      mossdi. Write out in relative pixels if the pixel scale, image size do
      not change. See the next function below to convert ra/dec coordinates to
      pixel coordinates.

      Parameters
      ----------
      image : str, optional

      limit : flt, optional
        When `image_type` is 'gain', limit is the gain floor to be selected
        When `image_type` is 'sen', `limit` is the fraction of the median
        sensitivity accross the entire image to be set as the sensitivity
        ceiling. i.e; selects data <= `limit` * median_sensitivity.

      image_type : str, {'gain', 'sen'}, optional
        Use an upper limit to select pixels from sensitivity image, and
        lower limit to select pixels from the gain image.
    """

    hdu = fits.open(image)
    data = hdu[0].data[0][0]  # Assumes continuum, no vel/pol info.
    hdr = hdu[0].header

    # Select all pixels that satisfy the floor

    if image_type == 'gain':
        good_coords = np.where(data >= limit)

    elif image_type == 'sen':
        ceiling = np.nanmedian(data) * limit
        good_coords = np.where(data <= ceiling)
    else:
        raise ValueError("image_type must be 'gain' or 'sen'")

    n_row_left, ind = np.unique(good_coords[0], return_index=True)
    n_col_left = good_coords[1][ind]
    # print(n_col_left, n_row_left)  # Coordinates of leftmost gain=1 pixels.

    good_coords_bwd = (good_coords[0][::-1], good_coords[1][::-1])
    n_row_right, ind = np.unique(good_coords_bwd[0], return_index=True)
    n_col_right = good_coords_bwd[1][ind]
    # print(n_col_right, n_row_right)  # Coordinates of rightmost gain=1
    # pixels.

    # Pick the rows that have at least one pixel with gain = 1.
    # gain_hasones = gain[np.any(gain == 1, axis=1)]

    # for n_row, row in enumerate(gain):
    #   if

    plt.imshow(data, cmap="Greys", interpolation='none')

    if format == 'pixels':

        # Miriad wants 1-indexd coordinates.
        n_col_left += 1
        n_col_right += 1
        n_row_left += 1
        n_row_right += 1
        # Reverse the rightmost pixel coordinates so that the polygon wraps
        # around the top of the image.
        n_row_right, n_col_right = n_row_right[::-1], n_col_right[::-1]

        # Plot the polygon on top of the gain image.
        plt.plot(n_col_left, n_row_left)
        plt.plot(n_col_right, n_row_right)
        plt.show()

        # Combine left and right columns and rows into single array.
        # n_col = [n_col_left, n_col_right]
        # n_row = [n_row_left, n_row_right]
        n_col = np.concatenate((n_col_left, n_col_right))
        n_row = np.concatenate((n_row_left, n_row_right))

        out_list = ['polygon(']

        if outformat == 'multiline':

            for x, y in zip(n_col, n_row):
                out_list.append(str(x))
                out_list.append('\n')
                out_list.append(str(y))
                out_list.append('\n')

            # Close the polygon by repeating the first vertex.
            out_list.append(str(n_col[0]))
            out_list.append('\n')
            out_list.append(str(n_row[0]))
            out_list.append(')')

            out_string = ''.join(out_list)

            f = open(outfile, 'w')
            f.write(out_string)
            f.close()

        if outformat == 'oneline':

            for x, y in zip(n_col, n_row):
                print(x, y)
                out_list.append(str(x))
                out_list.append(',')
                out_list.append(str(y))
                out_list.append(',')

            # Close the polygon by repeating the first vertex.
            # print(str(n_col[0]))
            out_list.append(str(n_col[0]))
            out_list.append(',')
            out_list.append(str(n_row[0]))
            out_list.append(')')

            out_string = ''.join(out_list)

            f = open(outfile, 'w')
            f.write(out_string)
            f.close()

        # Return the column and row numbers IN 1-INDEXED FORMAT.
        # return n_col, n_row
        pass

    if format == 'radec':
        pass


def main():
    """
     Calls region() function to generate region.txt file for use in image
     cleaning.
    """
    import argparse
    print("running main()")
    region(outformat='multiline')

if __name__ == "__main__":
    print("This program is running by itself")
    main()
