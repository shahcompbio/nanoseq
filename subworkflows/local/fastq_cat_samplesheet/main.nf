// concat ONT fastqs and emit a samplesheet for processing

include { samplesheetToList } from 'plugin/nf-schema'

workflow FASTQ_CAT_SAMPLESHEET {
    take:
    input //  string: Path to input samplesheet

    main:
    //
    // Create channel from input file provided through params.input
    //

    channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { meta, fastq_1, fastq_dir ->
            if (fastq_1 && !fastq_dir) {
                return [meta.id, meta + [single_end: true], [fastq_1]]
            }
            else if (!fastq_1 && fastq_dir) {
                return [meta.id, meta + [single_end: false], [fastq_dir]]
            }
            else {
                println("invalid input for ${meta.id}")
            }
        }
        .groupTuple()
        .map { samplesheet ->
            validateInputSamplesheet(samplesheet)
        }
        .map { meta, fastqs ->
            return [meta, fastqs.flatten()]
        }
        .set { ch_samplesheet }

    emit:
    bam = SAMTOOLS_SORT.out.bam // channel: [ val(meta), [ bam ] ]
    bai = SAMTOOLS_INDEX.out.bai // channel: [ val(meta), [ bai ] ]
    csi = SAMTOOLS_INDEX.out.csi // channel: [ val(meta), [ csi ] ]
}
//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    def (metas, fastqs) = input[1..2]

    // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
    def endedness_ok = metas.collect { meta -> meta.single_end }.unique().size == 1
    if (!endedness_ok) {
        error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or directories of unmerged fastqs: ${metas[0].id}")
    }

    return [metas[0], fastqs]
}
