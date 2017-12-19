import numpy as np
import os
import sys
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
upperbound = 3.
lowerbound = 0
for k in range(len(data[:,0,0])):
    for j in range(len(data[0,:,0])):
        for i in range(len(data[0,0,:])):  
            if data[k,j,i] < upperbound and data[k,j,i] > lowerbound:
                ratio.append(data[k,j,i])

x = ratio
print np.nanmean(ratio)
p=plt.figure(figsize=(7,6))
# the histogram of the data
n, bins, patches = plt.hist(x, 50, normed=1, facecolor='green', alpha=0.75)

plt.xlabel('CARMA/NRO')
plt.ylabel('Probability Density')
plt.grid(True)
os.system('rm ratio.png')
plt.savefig('ratio.png')
plt.show()
sys.exit()

boxes = [(3033,6723,708,638), (1943,6287,708,638), (2551,5314,708,638), (2411,2877,708,638)]

for nn,bb in enumerate(boxes):
    xcenter = bb[0]
    ycenter = bb[1]
    xwidth = bb[2]
    ywidth = bb[3]
    xlow  = int(xcenter - xwidth/2.) 
    xhigh = int(xcenter + xwidth/2.)
    ylow  = int(ycenter - ywidth/2.)
    yhigh = int(ycenter + ywidth/2.)
    ratio = []
    upperbound = 10.
    lowerbound = 0
    for k in range(len(data[:,0,0])):
        for j in range(ylow,yhigh):
            for i in range(xlow,xhigh):  
                if data[k,j,i] < upperbound and data[k,j,i] > lowerbound:
                    ratio.append(data[k,j,i])
    x = ratio
    p=plt.figure(figsize=(7,6))
    n, bins, patches = plt.hist(x, 50, normed=1, facecolor='green', alpha=0.75)
    plt.title(str(nn+1))
    plt.xlabel('CARMA/NRO')
    plt.ylabel('Probability Density')
    plt.grid(True)
    plt.show()

