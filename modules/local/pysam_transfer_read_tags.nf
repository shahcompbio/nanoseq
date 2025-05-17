process PYSAM_TRANSFER_READ_TAGS {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/pysam:0.23.0--py311hb456a96_0"

    input:
    tuple val(meta), path(aligned_bam), path(tagged_bam)

    output:
    tuple val(meta), path("*tagged_aligned.bam"), emit: bam
    path  "versions.yml", emit: versions

    script:
    """
    transfer_readtags.py \\
        $tagged_bam \\
        $aligned_bam \\
        ${meta.id}.tagged_aligned.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pysam: \$(python -c 'import pysam;print(pysam.__version__)')
    END_VERSIONS
    """
}

