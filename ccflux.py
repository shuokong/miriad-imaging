import matplotlib.pyplot as plt
import numpy as np

#Default parameters
flux_str = 'Total CLEANed flux'
cc_str = 'Steer'
    
def plot(infile='clean_region.log', plotfile='ccflux_region.pdf',
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

def plotmulti(infiles, plotfile='ccflux_multi.pdf',
      flux_str='Total CLEANed flux', cc_str='Steer', labels=None, 
      xlim=None, ylim=None):
   """
   Plot multiple CLEANing runs on the same figure.
   """

   if labels is None:
      labels = infiles
      
   fig, ax = plt.subplots(1)
   
   for ii_file, file in enumerate(infiles):
      f = open(file)
      lines = f.read().split('\n')
      f.close()

      cc_lines = [i for i in lines if cc_str in i]
      flux_lines = [i for i in lines if flux_str in i]

      cc = np.array([int(i.split()[2]) for i in cc_lines])
      flux = np.array([float(i.split()[3]) for i in flux_lines])
      
      plt.plot(cc, flux, label=labels[ii_file], lw=1.3) 

   if xlim is not None:
      plt.xlim(xlim)
   if ylim is not None:
      plt.ylim(ylim)   

   plt.xlabel('Clean Component', fontsize=14)
   plt.ylabel('Flux Recovered', fontsize=14)
   plt.legend(loc='best') 
   plt.savefig(plotfile) 
        
           
