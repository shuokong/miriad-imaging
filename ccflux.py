import matplotlib.pyplot as plt
import numpy as np

#Default parameters
flux_str = 'Total CLEANed flux'
cc_str = 'Steer'
    
def plot(infile='clean.log', plotfile='ccflux.pdf',
      flux_str='Total CLEANed flux', cc_str='Steer'):

   f = open(infile)
   lines = f.read().split('\n')
   f.close()

   cc_lines = [i for i in lines if cc_str in i]
   flux_lines = [i for i in lines if flux_str in i]

   cc = np.array([int(i.split()[2]) for i in cc_lines])
   flux = np.array([float(i.split()[3]) for i in flux_lines])

   fig, ax = plt.subplots(1)
   plt.plot(cc, flux)
   plt.xlabel('Clean Component')
   plt.ylabel('Flux Recovered')
   plt.savefig(plotfile)
