// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process CONCAT_VCF {
    tag "$meta.id"
    label 'process_medium'
    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    conda (params.enable_conda ? "bioconda::htslib=1.12" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/htslib:1.12--hd3b49d5_0"
    } else {
        container "quay.io/biocontainers/htslib:1.12--hd3b49d5_0"
    }

    input:
        tuple val(meta), path(vcf)
        path fai
        path bed

    output:
        tuple val(meta), path("*_*.vcf.gz"), path("*_*.vcf.gz.tbi"), emit: vcf

    script:
    name = options.suffix ? "${options.suffix}_${meta.id}" : "${meta.id}"
    target_options = params.target_bed ? "-t ${bed}" : ""
    interval_options = params.no_intervals ? "-n" : ""
    """
    concatenateVCFs.sh -i ${fai} -c ${task.cpus} -o ${name}.vcf ${target_options} ${interval_options}
    """
}