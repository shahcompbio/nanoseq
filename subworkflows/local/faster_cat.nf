/*
 * Check input samplesheet and concatenate fastqs
 */

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

include { CAT_FASTQS } from '../../modules/local/cat_fastqs'

workflow FASTER_CAT {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    input_path

    main:
    /*
     * concatenate fastq files
     */
    CAT_FASTQS(samplesheet, input_path)

    CAT_FASTQS.out.fastq
        .set { ch_cat_fastqs } // Save the concatenated fastq files

    // Get the path of the CSV file from the output of CAT_FASTQS
    csv_ch = CAT_FASTQS.out.csv
    /*
     * Check samplesheet is valid
     */
    SAMPLESHEET_CHECK ( csv_ch, input_path )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { it -> [ it[0], it[2], it[3], it[4], it[5], it[6], it[1] , it[7] ] }
        .set { ch_sample }

    emit:
    ch_sample // [ sample, barcode, fasta, gtf, is_transcripts, annotation_str ]
    ch_cat_fastqs // Save the concatenated fastq files
}
