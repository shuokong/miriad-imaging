#! usr/bin/python
def mir2fits(pattern='*'):
    """
    Apply the regex in `pattern` to generate fits files for the corresponding MIRIAD files.
    """
    import glob
    import os
    for f in glob.glob(pattern):
        os.system('fits in={0} out={1} op=xyout'.format(f, f))


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-pattern", type=str, default='*')
    args = parser.parse_args()
    mir2fits(pattern=args.pattern)

if __name__ == "__main__":
    #print("This program is running by itself")
    main()
