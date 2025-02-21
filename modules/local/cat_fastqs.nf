process CAT_FASTQS {
    tag "$cat_fastqs"
    label 'process_low'

    conda 'pandas'
    input:
    path samplesheet

    output:
    path"*.fastq.gz"   , emit: fastq
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    script:
    """
    merge_fastqs.py \\
        $samplesheet \\
        merged.fastq.gz \\
        merged_samplesheet.csv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
