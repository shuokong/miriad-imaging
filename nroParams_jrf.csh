#!/bin/csh -fe

# This sets various parameters for the NRO and CARMA data.
# The following parameters are assumed to be set:
# 
# mol    : molecule name (e.g. 13co)
# nroorg : name of the original NRO single dish image
# carmap : name of the CARMA dirty image


# Set NRO45 observing parameters
  if ($mol == "13co") then
     set lambda   = 2.72            # 13CO(J=1-0) wavelength [mm]
     set freq     = 110.2013542798  # 13CO(J=1-0) frequency [GHz]
     set effmb    = 0.36            # main beam efficiency/2013; same for C18O(J=1-0)/2013
     set fwhmnro  = 22.9            # OTF-Beam HWHM: from convbeam.c (case of 13co and c18o)    
                                    #   19.7" for Sph. func. & grid=5.96"
                                    #   22.9" for Sph. func  * grid=8.00"
     set scalefac = 3.3             # CARMA/NRO median scale factor         

  else if ($mol == "12co") then
     set lambda   = 2.6             # CO(J=1-0) wavelength [mm]
     set freq     = 115.271204      # CO(J=1-0) frequency [GHz]
     set effmb    = 0.32            # main beam efficiency in 12CO(J=1-0)/2008
     set fwhmnro  = 21.6            # OTF-Beam HWHM: from convbeam.c (case of 12co)

     set scalefac = 1.0             # to be determined. shuokong 2016-10-03
     set scalefac = 1.6             # found after using Jy/K = 5
     set scalefac = 1.2             # found after using Jy/K = 7.7 (with sqrt2)
     #echo "12CO observing parameters need to be checked"
     #exit
  else 
     echo "Parameters for molecule $mol are not set"
  endif


# Other NRO45 Obs. params - molecule independent
  set effq       = 0.88   # quantum efficiency of digital correlator
  set tsysnro    = 650.0  # Typical Tsys
  set tsyscarma  = "" 
# set tsysnro    = 1      # no physical meaning
  set sigk       = "0.6"  # noise level of 45m map. also can used for changing weighting.

# NRO45 uv params
  set tintnro      = 0.001     # Integration time for NRO45 visibility ; default in Koda et al. (2011) is 0.01
  set tintnro      = 0.01     # 

# Parameters from NRO45 map
  set nxnro    = `imhead in="$nroorg" key="naxis1" | awk '{printf("%i",$1)}'`
  set nynro    = `imhead in="$nroorg" key="naxis2" | awk '{printf("%i",$1)}'`
  set nznro    = `imhead in="$nroorg" key="naxis3" | awk '{printf("%i",$1)}'`
  set v1nro    = `imhead in="$nroorg" key="crval3" | awk '{printf("%f",$1)}'`
  set cellnro  = `imhead in="$nroorg" key="cdelt2" | awk '{printf("%f",$1*206264.8)}'`
  set dvnro    = `imhead in="$nroorg" key="cdelt3" | awk '{printf("%f",$1)}'`

# Parameters from CARMA map
  set nxcar    = `imhead in="$carmap" key="naxis1" | awk '{printf("%i",$1)}'`
  set nycar    = `imhead in="$carmap" key="naxis2" | awk '{printf("%i",$1)}'`
  set nzcar    = `imhead in="$carmap" key="naxis3" | awk '{printf("%i",$1)}'`
  set cellcar  = `imhead in="$carmap" key="cdelt2" | awk '{printf("%f",$1*206264.8)}'`
  set dvcar    = `imhead in="$carmap" key="cdelt3" | awk '{printf("%f",$1)}'`
  set bwcar = `calc "$dvcar/2.99792458e5*$freq*1.0e9"` # chan. width in Hz

# CJYKNRO: Conversion coefficient (Ta* -> Jy)
#     Eqns from Tools of Radio Astronomy ed. 5 (2013) [TRA] and Essentials of Radio Astronomy [ERA]
#     From Essentials of Radio Astronomy: Antenna Temperature: Ta = P_nu/k, P_nu = Ae*S_nu/2
#       so S_nu = 2*k*Ta/Ae; Ae = lambda**2 / Omega_A [TRA 7.11]; eta_mb = Omega_mb / Omega_A
#     Thus, S_nu = 2*k*Ta*Omega_A/lambda**2 = 2*k*Ta*Omega_mb/(eta_mb*lambda**2)
#
#     where Omega_A [sr] is the antenna's normalized power pattern integrated over the whole sphere.
#           Omega_mb [sr] is the " integrated over the main beam.
#           Ae is the effective area of the antenna.
#
#     
#     S[Jy] = Ta* [K] / eta_mb * 2*k*Omega_MB/lambda**2
#           = (1/13.6) * Ta* [K] * b_maj["] * b_min["] / (eta_mb * lambda[mm]^2)
#
#   The 1/13.6 comes from the combination of factosrs of 2, k (in units of mm^2 * Jy / K),
#          1.133 (which comes from the solid angle of a gaussian beam: Omega_mb = 1.133*b_maj*b_min)
#          and the conversion of b_maj and b_min from radians to arcseconds. (Omega_MB is in sr)
#
# JYPERK = [2*k*Omega_MB / lambda**2 / eta_mb / eta_q] * sqrt(2) * eta_q
#         last term "sqrt(2)*eta_q" is from MIRIAD history
#        =  2*k*Omega_MB / lambda**2 / eta_mb * sqrt(2)
#
#     dS = 2*k*Omega_MB / lambda**2 * dTmb
#        = 2*k*Omega_MB / lambda**2 / eta_mb * dTa
#        =[2*k*Omega_MB / lambda**2 / eta_mb / eta_q] * Tsys/Sqrt(B*t)
#
#     JIN SAYS THERE IS A SQRT(2) IN THE DEFINITION, BUT I DO NOT UNDERSTAND WHY - JMC
#     JYPERK = dS * [sqrt(2)*eta_q]  -- strange definiton, but correct
#     
#     1 steradian=(206265 arcsec)^2=4.255*10^10
#     1 Jy = 10^-26 W/m2/Hz = 10^-23 erg/s/cm2/Hz
#     1/13.6 = 0.73535
#     1/13.6*sqrt(2) = 0.10399
# ------------------------------------------------------
#  set cjyknro = `calc "0.07354*($fwhmnro/$lambda)**2/$effmb"`
  set cjyknro = `calc "0.10399*($fwhmnro/$lambda)**2/1.414"` # try removing the sqrt(2) factor, see if the fluxscale ratio change or not
  set cjyknro = `calc "0.10399*($fwhmnro/$lambda)**2"` # map is already converted to TMB
  set jyperk  = `calc "0.10399*($fwhmnro/$lambda)**2/$effmb/1.414"` # XXX
  set jyperk  = `calc "0.10399*($fwhmnro/$lambda)**2/$effmb"` # XXX
  if sigk != "" then
     set sigjy = `calc "$sigk*$cjyknro"` # calculate noise from sigk
  endif

# Print params
# ------------
echo "##"
echo "## NRO45 tel:"
echo "##     eff_mb     = " $effmb
echo "##     FWHM       = " $fwhmnro
echo "## NRO45 map:"
echo "##     nx,ny,nz   = " $nxnro,$nynro,$nznro
echo "##     cell[asec] = " $cellnro
echo "##     Jy/K[Ta*]  = " $cjyknro
echo "##     JYPERK     = " $jyperk
echo "##     CARMA/NRO Scale Factor = " $scalefac 
echo "## CARMA map:"
echo "##     nx,ny,nz   = " $nxcar,$nycar,$nzcar
echo "##     cell[asec] = " $cellcar
echo "##"
