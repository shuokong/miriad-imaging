import numpy as np
import os
from astropy.io import fits
from astropy.wcs import WCS
import matplotlib as mpl
import matplotlib.pyplot as plt

hdulist = fits.open('ratio.fits')
prihdu = hdulist[0]
data = prihdu.data[0,:,:,:]
print data.shape
hdulist.close()

ratio = []
upperbound = 10.
lowerbound = 0
for k in range(len(data[:,0,0])):
    for j in range(len(data[0,:,0])):
        for i in range(len(data[0,0,:])):  
            if data[k,j,i] < upperbound and data[k,j,i] > lowerbound:
                ratio.append(data[k,j,i])

x = ratio
p=plt.figure(figsize=(7,6))
# the histogram of the data
n, bins, patches = plt.hist(x, 50, normed=1, facecolor='green', alpha=0.75)

plt.xlabel('CARMA/NRO')
plt.ylabel('Probability Density')
plt.grid(True)
os.system('rm ratio.png')
plt.savefig('ratio.png')
#plt.show()

