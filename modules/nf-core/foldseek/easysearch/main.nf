process FOLDSEEK_EASYSEARCH {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/foldseek:9.427df8a--pl5321hb365157_0':
        'biocontainers/foldseek:9.427df8a--pl5321hb365157_0' }"

    input:
    tuple val(meta)   , path(pdb)
    tuple val(meta_db), path(db)

    output:
    tuple val(meta), path("${meta.id}.tsv"), path("${meta.id}.html"), emit: aln
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def convert_args = task.ext.convert_args ?: ''
    def search_args = task.ext.search_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """  
    foldseek createdb ${pdb} qdb
    
    foldseek \\
        search \\
        qdb \\
        ${db}/${meta_db.id} \\
        ${prefix} \\
        ${search_args} \\
        tmpFolder 

    foldseek \\
        convertalis \\
        qdb \\
        ${db}/${meta_db.id} \\
        ${prefix} \\
        ${prefix}.tsv \\
        ${convert_args}

    foldseek \\
        convertalis \\
        qdb \\
        ${db}/${meta_db.id} \\
        ${prefix} \\
        ${prefix}.html \\
        --format-mode 3

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        foldseek: \$(foldseek --help | grep Version | sed 's/.*Version: //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.m8

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        foldseek: \$(foldseek --help | grep Version | sed 's/.*Version: //')
    END_VERSIONS
    """
}
