#!/bin/bash
#SBATCH --partition=componc_cpu,componc_gpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=nanoseqtest
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_snkmk.out


## activate nf-core conda environment
source /home/preskaa/miniconda3/bin/activate nf-core

## load modules
module load singularity/3.7.1
module load java/20.0.1
## example samplesheet
## technical replicates get merged ...
samplesheet=${HOME}/nanoseq/resources/test_samplesheet.csv
## specify path to out directory
outdir=/data1/shahs3/users/preskaa/APS022_Archive/240516_nanoseq_test

nextflow run apsteinberg/nanoseq \
  -c ${PWD}/conf/iris.config \
  -profile singularity,slurm \
  --input ${samplesheet} \
  --outdir ${outdir} \
  -work-dir ${outdir}/work \
  -params-file nf-params.json \

#nextflow run apsteinberg/nanoseq -resume 6c03bf60-99ea-41cd-a949-c30986899f14

