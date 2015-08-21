#! /usr/bin/env python
#This comment was added while working on hifi.
import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt 

#This comment was added while working on sagan.

def region(gain_image='gain.fits', outfile='region.txt', gainfloor=1.0,
      format='pixels', outformat='oneline'):
   """
      Write out a text file that can be be read by the MIRIAD command mossdi
      to specify a region for cleaning. Finds the vertices of a polygon that
      covers the entire region where gain >= gainfloor. The vertices are
      written in pi<p></p>xels relative to the center or in RA/DEC. Write ou t in
      RA/DEC when writing one region file that will be used repeatedly with
      mossdi. Write out in relative pixels if the pixel scale, image size do
      not change. See the next function below to convert ra/dec coordinates to
      pixel coordinates.
   """
   gain_hdu = fits.open(gain_image) 
   gain = gain_hdu[0].data[0][0] # Assumes continuum, no vel/pol info.
   hdr = gain_hdu[0].header
   
   one_coords = np.where(gain == 1)

   n_row_left, ind = np.unique(one_coords[0], return_index=True)
   n_col_left = one_coords[1][ind]
   print(n_col_left, n_row_left) #Coordinates of leftmost gain=1 pixels.
   
   one_coords_bwd = (one_coords[0][::-1], one_coords[1][::-1])
   n_row_right, ind = np.unique(one_coords_bwd[0], return_index=True)
   n_col_right = one_coords_bwd[1][ind]
   print(n_col_right, n_row_right) #Coordinates of rightmost gain=1 pixels.

   
  
   # Pick the rows that have at least one pixel with gain = 1.
   #gain_hasones = gain[np.any(gain == 1, axis=1)]


   #for n_row, row in enumerate(gain):
   #   if 
       

   plt.imshow(gain, cmap="Greys", interpolation='none')    

   if format == 'pixels':


     #Miriad wants 1-indexd coordinates.  
     n_col_left += 1
     n_col_right += 1
     n_row_left += 1
     n_row_right += 1
     #Reverse the rightmost pixel coordinates so that the polygon wraps
     #around the top of the image.
     n_row_right, n_col_right = n_row_right[::-1], n_col_right[::-1]

     #Plot the polygon on top of the gain image.
     plt.plot(n_col_left, n_row_left)
     plt.plot(n_col_right, n_row_right)
     plt.show()

     #Combine left and right columns and rows into single array.
     n_col = [n_col_left, n_col_right]
     n_row = [n_row_left, n_row_right]

     out_list = ['polygon(']

     if outformat == 'multiline':

        for x,y in zip(n_col, n_row):
           out_list.append(str(x))
           out_list.append('\n')
           out_list.append(str(y))
           out_list.append('\n')

        #    out_list.append(str(x))
        #    out_list.append('\n')
        #    out_list.append(str(y))
        #    out_list.append('\n')

        # for x,y in zip(n_col_right, n_row_right):
        #    out_list.append(str(x))
        #    out_list.append('\n')
        #    out_list.append(str(y))
        #    out_list.append('\n')

        out_list[-1] = ')'
        out_string = ''.join(out_list)
        
        f = open(outfile, 'w')
        f.write(out_string)
        f.close()


     if outformat == 'oneline':

        for x,y in zip(n_col, n_row):
           out_list.append(str(x))
           out_list.append(',')
           out_list.append(str(y))
           out_list.append(',')

        #    out_list.append(str(x))
        #    out_list.append(',')
        #    out_list.append(str(y))
        #    out_list.append(',')

        # for x,y in zip(n_col_right, n_row_right):
        #    out_list.append(str(x))
        #    out_list.append(',')
        #    out_list.append(str(y))
        #    out_list.append(',')

        #Replace trailing comma with parenthesis to close off polygon.
        out_list[-1] = ')'
        out_string = ''.join(out_list)
        
        f = open(outfile, 'w')
        f.write(out_string)
        f.close()


   if format == 'radec':
       pass

def main():
   """
   Calls region() function to generate region.txt file for use in image
   cleaning.
   """
   print("running main()")
   region(outformat='multiline')

if __name__ == "__main__":
   print("This program is running by itself")
   main()    
