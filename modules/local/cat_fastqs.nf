process CAT_FASTQS {
    tag "$cat_fastqs"
    label 'process_low'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"
    beforeScript 'chmod g+w .'
    input:
    path samplesheet

    output:
    path"*.fastq.gz"   , emit: fastq
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    script:
    """
    cat
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
