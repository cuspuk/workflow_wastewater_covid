rule bwa__build_index:
    input:
        "{reference_dir}/{fasta}.fa",
    output:
        idx=protected(multiext("{reference_dir}/bwa_index/{fasta}", ".amb", ".ann", ".bwt", ".pac", ".sa")),
    params:
        prefix=lambda wildcards, output: os.path.splitext(output.idx[0])[0],
        approach="bwtsw",
    log:
        "{reference_dir}/bwa_index/logs/{fasta}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.12.7/wrappers/bwa/index"


rule custom__infer_read_group:
    input:
        get_fastq_for_mapping,
    output:
        read_group="results/reads/.read_groups/{sample}.txt",
    params:
        sample_id=lambda wildcards: wildcards.sample,
    log:
        "logs/custom/infer_and_store_read_group/{sample}.log",
    localrule: True
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.12.12/wrappers/custom/read_group"


rule bwa__map_reads_to_reference:
    input:
        reads=get_fastq_for_mapping,
        index=get_bwa_index_for_mapping(),
        read_group="results/reads/.read_groups/{sample}.txt",
    output:
        bam=temp("results/mapping/mapped/{sample}.bam"),
    threads: min(config["threads"]["mapping"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_mapping,
    log:
        "logs/bwa/map_reads_to_reference/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.12.12/wrappers/bwa/map"


rule samtools__bam_index:
    input:
        "results/mapping/mapped/{sample}.bam",
    output:
        "results/mapping/mapped/{sample}.bam.bai",
    benchmark:
        "benchmarks/samtools/bam_index/mapped/{sample}.benchmark"
    threads: min(config["threads"]["bam_index"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_bam_index,
    log:
        "logs/samtools/bam_index/mapped/{sample}.log",
    wrapper:
        "v3.10.2/bio/samtools/index"


rule picard__mark_duplicates:
    input:
        bams="results/mapping/mapped/{sample}.bam",
        bai="results/mapping/mapped/{sample}.bam.bai",
    output:
        bam="results/mapping/deduplicated/{sample}.bam",
        idx="results/mapping/deduplicated/{sample}.bam.bai",
        metrics="results/mapping/deduplicated/{sample}.stats",
    resources:
        mem_mb=get_mem_mb_for_picard,
    log:
        "logs/picard/mark_duplicates/{sample}.log",
    benchmark:
        "benchmarks/picard/mark_duplicates/{sample}.benchmark"
    wrapper:
        "v3.10.2/bio/picard/markduplicates"


checkpoint samtools__view_number_of_reads:
    input:
        "results/mapping/deduplicated/{sample}.bam",
    output:
        "results/mapping/deduplicated/{sample}.count",
    log:
        "logs/samtools/view_number_of_reads/{sample}.log",
    conda:
        "../envs/samtools.yaml"
    shell:
        "samtools view -c {input} > {output} 2> {log}"


rule qualimap__mapping_quality_report:
    input:
        bam="results/mapping/{step}/{sample}.bam",
        bai="results/mapping/{step}/{sample}.bam.bai",
    output:
        report_dir=report(
            directory("results/mapping/{step}/bamqc/{sample}"),
            category="{sample}",
            labels={
                "Type": "Qualimap for {step}",
            },
            htmlindex="qualimapReport.html",
        ),
    params:
        extra=[
            "--paint-chromosome-limits",
            "-outformat PDF:HTML",
        ],
    resources:
        mem_mb=get_mem_mb_for_qualimap,
    log:
        "logs/qualimap/mapping_quality_report/{step}/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.12.12/wrappers/qualimap/bamqc"
