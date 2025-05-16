import click
from pysam import AlignmentFile, AlignedSegment
from typing import Tuple
from itertools import groupby


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
    source_read: AlignedSegment, target_read: AlignedSegment, tags: Tuple[str]
):
    """
    Copies a tag from the source_read
    """
    if not (target_read.is_supplementary or target_read.is_secondary):
        for tag in tags:
            target_read.set_tag(tag, source_read.get_tag(tag))
    return target_read


def transfer_read_groups(source_read: AlignedSegment, target_read: AlignedSegment):
    """
    Copies the read group from the source_read to the target_read
    """
    target_read.set_tag("RG", source_read.get_tag("RG"))
    return target_read


@click.command()
@click.argument("ubam")
@click.argument("aligned_bam")
@click.argument("out_bam")
@click.option(
    "--tags",
    default=("MM", "MN", "ML"),
    multiple=True,
    help="Any number of string tags.",
)
# @click.option('--flags', default=(0, 16), type=int, multiple=True, help='Target flags to transfer tags to. Default: (0, 16)')
def process_bams(ubam, aligned_bam, out_bam, tags):
    """
    Process the input UBAM and ALIGNED_BAM files.

    UBAM: Path to the unmapped BAM file.
    ALIGNED_BAM: Path to the aligned BAM file.
    """
    click.echo(f"UBAM file: {ubam}")
    click.echo(f"Aligned BAM file: {aligned_bam}")
    click.echo(f"Output BAM file: {out_bam}")
    click.echo(f"Tags to transfer: {tags}")
    click.echo("Processing BAM files...")

    with (
        AlignmentFile(ubam, "rb", check_sq=False) as ubam_handle,
        AlignmentFile(aligned_bam, "rb") as bam_handle,
        AlignmentFile(out_bam, "wb", template=bam_handle) as out_handle,
    ):
        for ubam_read, bam_read in iter_read_pairs(ubam_handle, bam_handle):
            read_with_tags = transfer_read_tags(ubam_read, bam_read, tags=tags)
            read_with_rg_with_tags = transfer_read_groups(ubam_read, read_with_tags)
            out_handle.write(read_with_rg_with_tags)


if __name__ == "__main__":
    process_bams()
