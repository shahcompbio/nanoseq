/*
 * Transfer read tags from one BAM to another
 */

include { SAMTOOLS_LEXSORT as SAMTOOLS_LEXSORT_ALIGNED } from '../../modules/local/samtools_lexsort'
include { SAMTOOLS_LEXSORT as SAMTOOLS_LEXSORT_TAGGED } from '../../modules/local/samtools_lexsort'
include { GATK_TRANSFER_READ_TAGS } from '../../modules/local/gatk_transfer_read_tags'


workflow TRANSFER_READ_TAGS{
    take:
    aligned_bam // channel: [ val(meta), path(aligned_bam) ]
    ref_fasta // channel: [ val(meta), path(ref_fasta) ]
    tagged_bam // channel: [ val(meta), path(tagged_bam) ]

    main:
    ch_versions = Channel.empty()

    sorted_aligned_bam = SAMTOOLS_LEXSORT_ALIGNED(aligned_bam).bam
    ch_versions = ch_versions.mix(SAMTOOLS_LEXSORT_ALIGNED.out.versions)

    sorted_tagged_bam = SAMTOOLS_LEXSORT_TAGGED(tagged_bam).bam
    ch_versions = ch_versions.mix(SAMTOOLS_LEXSORT_TAGGED.out.versions)

    bams_ch = sorted_aligned_bam.join(sorted_tagged_bam, by: [0]).join(ref_fasta, by: [0])

    tagged_bam = GATK_TRANSFER_READ_TAGS(bams_ch).bam
    ch_versions = ch_versions.mix(GATK_TRANSFER_READ_TAGS.out.versions)

    emit:
    tagged_bam
    ch_versions
}


