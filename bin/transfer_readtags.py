#!/usr/bin/env python

import argparse
from pysam import AlignmentFile, AlignedSegment, AlignmentHeader
from typing import Tuple
from typing import List
import random
from itertools import groupby
from argparse import ArgumentParser

def iter_read_pairs(unaligned_bam: AlignmentFile, aligned_bam: AlignmentFile):
    """
    Assuming two lexsorted bam files, one unaligned and one aligned, iterates over the read pairs.
    Assumes each file is only present once in the unaligned_bam but may be present multiple times in the aligned_bam.

    Parameters
    ----------
    unaligned_bam: AlignmentFile
        lexsorted unaligned bam file, each read name should only be present once
    aligned_bam: AlignmentFile
        lexsorted aligned bam file, reads can be present multiple times
    """
    grouped_ubam = groupby(unaligned_bam, lambda record: record.query_name)
    grouped_bam = groupby(aligned_bam, lambda record: record.query_name)
    for index, readpair in enumerate(zip(grouped_ubam, grouped_bam), start=1):
        (ubam_read_name, ubam_reads_it), (bam_read_name, bam_reads_it) = readpair
        ubam_reads = tuple(ubam_reads_it)
        # it's assumed the files are lexsorted and contain the same readnames:
        if ubam_read_name != bam_read_name:
            raise ValueError(
                f"read {index} has different names for ubam and bam:\nubam\n{ubam_read_name}\nbam\n{bam_read_name}"
            )
        if len(ubam_reads) > 1:
            raise ValueError(
                f"read {index} has multiple reads for ubam read name {ubam_read_name}"
            )
        ubam_read = ubam_reads[0]
        for bam_read in bam_reads_it:
            yield ubam_read, bam_read


def transfer_read_tags(
    source_read: AlignedSegment, target_read: AlignedSegment, tags: Tuple[str], primary_only_tags: Tuple[str]
):
    """
    Copies a tag from the source_read
    """
    for tag in tags:
        target_read.set_tag(tag, source_read.get_tag(tag))
    if not (target_read.is_supplementary or target_read.is_secondary):
        for tag in primary_only_tags:
            target_read.set_tag(tag, source_read.get_tag(tag))
    return target_read


def transfer_read_groups(source_read: AlignedSegment, target_read: AlignedSegment):
    """
    Copies the read group from the source_read to the target_read
    """
    target_read.set_tag("RG", source_read.get_tag("RG"))
    return target_read

def append_pg_suffix(header: dict, suffix: str = "ubam") -> dict:
    """
    Appends a suffix to the PG field in the header.
    """
    if "PG" not in header:
        return header
    pg_field = header["PG"]
    for pg in header["PG"]:
        pg["ID"] = f"{pg['ID']}.{suffix}"
        if 'PP' in pg:
            pg["PP"] = f"{pg['PP']}.{suffix}"
    header["PG"] = pg_field
    return header

def merge_headers(
    source_bam: AlignmentFile, target_bam: AlignmentFile,
    fields: Tuple[str] = ("RG", "PG")
) -> AlignmentHeader:
    """
    Merges the headers of two BAM files.
    """
    source_header = source_bam.header.to_dict()
    source_header = append_pg_suffix(source_header)
    target_header = target_bam.header.to_dict()

    # Add read groups from the source header to the merged header
    for field in fields:
        for element in source_header[field]:
            if field not in target_header:
                target_header[field] = []
            target_header[field].append(element)

    # Check for duplicate PG IDs
    pg_ids = set()
    for pg in target_header.get("PG", []):
        if pg["ID"] in pg_ids:
            raise ValueError(f"Duplicate PG ID found: {pg['ID']}")
        pg_ids.add(pg["ID"])

    return AlignmentHeader.from_dict(target_header)

default_tags = [
    "qs", # :f – Mean Phred Q-score for the read.
    "ts", # :i – Samples trimmed from the start of the raw signal (noise at the pore open).
    "ns", # :i – Index of the last sample kept (so ns − ts ≈ raw signal length used).
    "mx", # :i – Mux group (0-3) that the pore/channel was assigned to.
    "ch", # :i – Physical channel number on the flowcell.
    "rn", # :i – Read number (counter that increments within each channel).
    "st", # :Z – Read start time in ISO-8601 UTC.
    "du", # :f – Read duration in seconds.
    "fn", # :Z – Source POD5/FAST5 file name.
    "sm", # :f - Signal-scaling midpoint (convert ADC units → pA).
    "sd", # :f - Signal-scaling dispersion (convert ADC units → pA).
    "sv", # :Z – Signal-scaling version (convert ADC units → pA).
    "dx", # :i – Duplex flag (1 = duplex, 0 = simple).
]

default_primary_only_tags = [
    "MM", # :Z – String that encodes every base modification in the read (e.g., 5-mC, 6-mA),
          # giving the reference base, mod code and zero-based offsets along the read. 
    "MN", # :i – Length of SEQ at the moment the MM/ML tags were written; if later clipping
          # changes SEQ length, MM/ML are stale and MN will no longer match, acting as a sanity check. 
    "ML", # :B:C – Byte array (0–255) of per-site probabilities that the corresponding
          # modifications listed in MM are truly present, in the same order as they appear in MM. 
]

def main():
    parser = argparse.ArgumentParser(
        description="Transfer selected tags and read group from unaligned BAM to aligned BAM."
    )
    parser.add_argument("ubam", help="Path to the unmapped BAM file.")
    parser.add_argument("aligned_bam", help="Path to the aligned BAM file.")
    parser.add_argument("out_bam", help="Path to the output BAM file.")
    parser.add_argument(
        "--tags",
        nargs="+",
        default=default_tags,
        help=f"Tags to transfer from unaligned to aligned BAM only for primary alignment (default: {default_tags}).",
    )
    parser.add_argument(
        "--primary_only_tags",
        nargs="+",
        default=default_primary_only_tags,
        help=f"Tags to transfer from unaligned to aligned BAM only for primary alignment (default: {default_primary_only_tags}).",
    )

    args = parser.parse_args()

    print(f"UBAM file: {args.ubam}")
    print(f"Aligned BAM file: {args.aligned_bam}")
    print(f"Output BAM file: {args.out_bam}")
    print(f"Tags to transfer: {args.tags}")
    print(f"Tags to transfer to primary alignment only: {args.primary_only_tags}")
    print("Processing BAM files...")

    with (
        AlignmentFile(args.ubam, "rb", check_sq=False, require_index=False) as ubam_handle,
        AlignmentFile(args.aligned_bam, "rb", require_index=False) as bam_handle,
    ):
        out_header = merge_headers(ubam_handle, bam_handle)
        with AlignmentFile(args.out_bam, "wb", header=out_header) as out_handle:
            for ubam_read, bam_read in iter_read_pairs(ubam_handle, bam_handle):
                read_with_tags = transfer_read_tags(ubam_read, bam_read, tags=args.tags, primary_only_tags=args.primary_only_tags)
                read_with_rg_with_tags = transfer_read_groups(ubam_read, read_with_tags)
                out_handle.write(read_with_rg_with_tags)


if __name__ == "__main__":
    main()