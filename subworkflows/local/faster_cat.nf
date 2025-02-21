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
    CAT_FASTQS(samplesheet)
    /*
     * Check samplesheet is valid
     */
    SAMPLESHEET_CHECK ( samplesheet, input_path )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { get_sample_info(it, params.genomes) }
        .map { it -> [ it[0], it[2], it[3], it[4], it[5], it[6], it[1] , it[7] ] }
        .set { ch_sample }

    ch_cat_fastqs = CAT_FASTQS.out.fastq

    emit:
    ch_sample // [ sample, barcode, fasta, gtf, is_transcripts, annotation_str ]
    ch_cat_fastqs
}

// Function to resolve fasta and gtf file if using iGenomes
// Returns [ sample, input_file, barcode, fasta, gtf, is_transcripts, annotation_str, nanopolish_fast5 ]
def get_sample_info(LinkedHashMap sample, LinkedHashMap genomeMap) {
    def meta = [:]
    meta.id  = sample.sample

    // Resolve fasta and gtf file if using iGenomes
    def fasta = false
    def gtf   = false
    if (sample.fasta) {
        if (genomeMap && genomeMap.containsKey(sample.fasta)) {
            fasta = file(genomeMap[sample.fasta].fasta, checkIfExists: true)
            gtf   = file(genomeMap[sample.fasta].gtf, checkIfExists: true)
        } else {
            fasta = file(sample.fasta, checkIfExists: true)
        }
    }

    // Check if input file and gtf file exists
    input_file = sample.input_file ? file(sample.input_file, checkIfExists: true) : null
    gtf        = sample.gtf        ? file(sample.gtf, checkIfExists: true)        : gtf

    return [ meta, input_file, sample.barcode, fasta, gtf, sample.is_transcripts.toBoolean(), fasta.toString()+';'+gtf.toString(), sample.nanopolish_fast5 ]
}
