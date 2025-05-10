process GATK_TRANSFER_READ_TAGS {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/gatk4:4.6.2.0--py310hdfd78af_0"

    input:
    tuple val(meta), path(aligned_bam), path(tagged_bam)

    output:
    tuple val(meta), path("*tagged_aligned.bam"), emit: bam
    path  "versions.yml", emit: versions

    script:
    """
    mkdir -p tmp
    gatk --java-options "-Xmx30g -Xms4g" TransferReadTags \\
        --input $aligned_bam \\
        --output ${meta.id}.tagged_aligned.bam \\
        --unmapped-sam $tagged_bam \\
        --tmp-dir tmp \\
        --read-tags MM

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}

