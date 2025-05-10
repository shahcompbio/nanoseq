process SAMTOOLS_LEXSORT {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/samtools:1.21--h96c455f_1"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*lexsorted.bam"), emit: bam
    path  "versions.yml", emit: versions

    script:
    """
    samtools sort -N -@ $task.cpus -o ${bam.simpleName}.lexsorted.bam -T $meta.id $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
