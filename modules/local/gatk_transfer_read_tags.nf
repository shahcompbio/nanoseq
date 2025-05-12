process GATK_TRANSFER_READ_TAGS {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/gatk4:4.6.2.0--py310hdfd78af_0"

    input:
    tuple val(meta), path(aligned_bam), path(tagged_bam), path(ref_fasta)

    output:
    tuple val(meta), path("*tagged_aligned.bam"), emit: bam
    path  "versions.yml", emit: versions

    script:
    """
    mkdir -p tmp

    gatk CreateSequenceDictionary \\
        -R $ref_fasta \\
        -O ${ref_fasta.simpleName}.dict

    gatk --java-options "-Xmx30g -Xms4g" MergeBamAlignment \\
        -UNMAPPED_BAM $tagged_bam \\
        -ALIGNED_BAM $aligned_bam \\
        -O ${meta.id}.tagged_aligned.bam \\
        -R $ref_fasta \\
        --VALIDATION_STRINGENCY LENIENT \\
        --SORT_ORDER queryname

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}

