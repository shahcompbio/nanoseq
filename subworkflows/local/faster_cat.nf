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

    // Extract the CSV file path (as a Path, not a channel)
    ch_csv_path = CAT_FASTQS.out.csv.first()
    /*
     * Check samplesheet is valid
     */
    // Capture the csv channel output from SAMPLESHEET_CHECK
    def samplesheet_csv = SAMPLESHEET_CHECK(ch_csv_path, input_path).csv

    // Now process that channel step by step
    samplesheet_csv = samplesheet_csv.splitCsv(header: true, sep: ',')
    samplesheet_csv = samplesheet_csv.map { row ->
        def sample_info = get_sample_info(row, params.genomes)
        return [ sample_info[0], sample_info[2], sample_info[3], sample_info[4],
                 sample_info[5], sample_info[6], sample_info[1], sample_info[7] ]
    }
    samplesheet_csv.set { ch_sample }

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
