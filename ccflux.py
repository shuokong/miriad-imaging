import matplotlib.pyplot as plt
import numpy as np
"""
Plots for evaluating the state of CLEANing.
"""


def plot(infile='clean_region.log', plotfile='ccflux_region.pdf',
         flux_str='Total CLEANed flux', cc_str='Steer'):
    """

    """
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


def plot_ratio_image(clean_map, nro_regridded_map, ratio_image='cm_nro_ratio.pdf'):
    from astropy.io import fits


def main():
    """
    If called in a shell script, run plot.
    """
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-infile", type=str, default='clean_region.log',
                        help="Path to the CLEAN log file.")
    parser.add_argument("-plotfile", type=str, default='ccflux_region.pdf',
                        help="Path for the output plot.")
    parser.add_argument("-flux_str", type=str, default='Total CLEANed flux',
                        help="Y-axis label")
    parser.add_argument("-cc_str", type=str, default='Steer',
                        help="X-axis label.")

    args = parser.parse_args()
    print("running main()")
    plot(infile=args.infile, plotfile=args.plotfile, flux_str=args.flux_str,
         cc_str=args.cc_str)

if __name__ == "__main__":
    #print("This program is running by itself")
    main()
