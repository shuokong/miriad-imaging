import numpy as np
import pylab as py
import os

def writeuv(vis, output, chan=None):
   # Set line command
   line = ''
   if chan is not None:
      line = "line=channel,1,%d,1,1" % chan

   # Write out visibilities
   os.system("rm -rf %s" % output)
   os.system("uvlist recnum=0 vis=%s %s| sed -e '1,12d' | grep -v Data | grep -v Vis | grep . > %s" % (vis, line, output))

def readuv(vis):
   # Get number of channels
   log = 'log.txt'
   os.system('rm -rf %s' % log)
   os.system("uvlist vis=%s | grep channels | awk '{printf($3)}' | sed s/','//g > %s" % (vis, log))
   nchan = np.genfromtxt(log, unpack=True, usecols=[0], dtype=int)
   print 'Reading %d channels in %s' % (nchan, vis)

   # Initialize
   sid = np.array([], dtype=str)
   amp = np.array([], dtype=float)

   # Loop over channels
   for ch in range(1,nchan+1):
      # Generate file
      writeuv(vis, log, chan=ch)

      # Read info
      time, ant1, ant2, u, v = np.genfromtxt(log, unpack=True,
            usecols=[1,2,3,5,6], dtype=str)
      amptmp = np.genfromtxt(log, unpack=True, usecols=[7])

      # Create id
      s =  np.core.defchararray.add(time, ' ')
      s =  np.core.defchararray.add(s, ant1)
      s =  np.core.defchararray.add(s, ant2)
      s =  np.core.defchararray.add(s, ' ')
      s =  np.core.defchararray.add(s, u)
      s =  np.core.defchararray.add(s, ' ')
      s =  np.core.defchararray.add(s, v)
      s =  np.core.defchararray.add(s, ' %d' % ch)

      # Add to ID list
      sid = np.concatenate( (sid, s) )
      amp = np.concatenate( (amp, amptmp) )

   # Sort
   i = np.argsort(sid)

   # Return amplitudes and sorted string
   return {'id': sid[i], 'amp':amp[i]}

def match(vis1, vis2):
   """ Match visibilities between two datasets """

   # Sort
   index = np.argsort(vis1['id'])
   sorted_x = vis1['id'][index]
   sorted_index = np.searchsorted(sorted_x, vis2['id'])

   # Make mask
   yindex = np.take(index, sorted_index, mode="clip")
   mask = vis1['id'][yindex] != vis2['id']

   # Find matching values
   result = np.ma.array(yindex, mask=mask)

   # Replace arrays
   j = np.where(result.mask == False)[0]
   vis1['id']  = vis1['id'][result.data[j]]
   vis1['amp'] = vis1['amp'][result.data[j]]
   vis1['id']  = vis1['id'][j]
   vis2['amp'] = vis2['amp'][j]


def uv(viscarma, visnro):
   # Read and sort visibilities
   resultCarma = readuv(viscarma)
   resultNro = readuv(visnro)

   # Must have identical IDs
   if (resultCarma['id'].shape != resultNro['id'].shape) or \
      (np.any(resultCarma['id'] != resultNro['id'])):
       print 'Matching visibilities...'
       match(resultCarma, resultNro)
   if resultCarma['id'].shape != resultNro['id'].shape:
      raise Exception,'Visibilities are not identical in size'
   if np.any(resultCarma['id'] != resultNro['id']):
      raise Exception,'IDs are not identical'

   # Plot visibilities
   py.figure(1)
   py.clf()
   py.plot(resultCarma['amp'], resultNro['amp'], 'o', ms=1)
   xlim = py.xlim()
   py.plot(xlim, xlim, '--')
   py.xlabel('CARMA Amplitude')
   py.ylabel('NRO Amplitude')
