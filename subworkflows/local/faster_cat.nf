/*
 * Check input samplesheet and concatenate fastqs
 */

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

include { CAT_FASTQS } from '../../modules/local/cat_fastqs'

workflow FASTER_CAT {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    /*
     * concatenate fastq files
     */
    CAT_FASTQS(samplesheet)
    ch_sample = CAT_FASTQS.out.csv
    ch_cat_fastqs = CAT_FASTQS.out.fastq

    emit:
    ch_sample
    ch_cat_fastqs
}
