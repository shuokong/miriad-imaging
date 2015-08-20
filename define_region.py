import numpy as np
from astropy.io import fits
import matplotlib.pyplot as plt 

#This comment was added while working on sagan.

def region(gain_image='gain.fits', outfile='region.txt', gainfloor=1.0,
      format='pixels'):
   """
      Write out a text file that can be be read by the MIRIAD command mossdi
      to specify a region for cleaning. Finds the vertices of a polygon that
      covers the entire region where gain >= gainfloor. The vertices are
      written in pixels relative to the center or in RA/DEC. Write ou t in
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
       

   plt.imshow(gain)    

   if format == 'pixels':
     #Miriad wants 1-indexd coordinates.  
     n_col_left += 1
     n_col_right += 1
     n_row_left += 1
     n_row_right += 1
     #Reverse the rightmost pixel coordinates so that the polygon wraps
     #around the top of the image.
     n_row_right, n_col_right = n_row_right[::-1], n_col_right[::-1]

     out_list = ['polygon(']

     for x,y in zip(n_col_left, n_row_left):
        out_list.append(str(x))
        out_list.append(',')
        out_list.append(str(y))
        out_list.append(',')

     for x,y in zip(n_col_right, n_row_right):
        out_list.append(str(x))
        out_list.append(',')
        out_list.append(str(y))
        out_list.append(',')

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
   region()

if __name__ == "__main()__":
   main()    
