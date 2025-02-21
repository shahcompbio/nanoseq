#!/usr/bin/env python
import os
import sys
import argparse
import pandas as pd
import shutil


def parse_args(args=None):
    Description = "merge input fastqs and create a valid samplesheet for nf-core."
    Epilog = "Example usage: python merge_fastqs.py <SAMPLESHEET_IN> <SAMPLESHEET_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("MERGED_FASTQ", help="path to merged fastq")
    parser.add_argument("SAMPLESHEET_OUT", help="Output samplesheet")
    return parser.parse_args(args)

def main(args=None):
    args = parse_args(args)
    # read in same sheet
    sample_df = pd.read_csv(args.FILE_IN)
    with open(args.MERGED_FASTQ, 'wb') as outfile:
        for _, row in sample_df.iterrows():
            fname = row["input_file"]
            with open(fname, 'rb') as infile:
                shutil.copyfileobj(infile, outfile)
    # write samplesheet for merged file
    with open(args.SAMPLESHEET_OUT) as outfile:
        outfile.write("group,replicate,barcode,input_file,fasta,gtf\n")
        outfile.write(f"{row['group']},{row['replicate']},{row['barcode']},"
                      f"{args.MERGED_FASTQ},{row['fasta']},{row['gtf']}")




if __name__ == '__main__':
    sys.exit(main())


