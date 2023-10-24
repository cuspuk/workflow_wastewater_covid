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
        "https://github.com/xsitarcik/wrappers/raw/v1.5.0/wrappers/bwa/index"


rule custom__infer_and_store_read_group:
    input:
        get_one_fastq_file,
    output:
        read_group="results/reads/original/read_group/{sample}.txt",
    params:
        sample_id=lambda wildcards: wildcards.sample,
    log:
        "logs/custom/infer_and_store_read_group/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.11.0/wrappers/custom/read_group"


rule bwa__map_reads_to_reference:
    input:
        reads=[
            "results/reads/decontaminated/{sample}_R1.fastq.gz",
            "results/reads/decontaminated/{sample}_R2.fastq.gz",
        ],
        index=get_bwa_index_for_mapping(),
        read_group="results/reads/original/read_group/{sample}.txt",
    output:
        bam=temp("results/mapping/mapped/{sample}.bam"),
    threads: min(config["threads"]["mapping"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_mapping,
    log:
        "logs/bwa/map_reads_to_reference/{sample}.log",
    benchmark:
        "benchmarks/bwa/map_reads_to_reference/{sample}.benchmark"
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.7/wrappers/bwa/map"


rule samtools__bam_index:
    input:
        bam="results/mapping/{step}/{sample}.bam",
    output:
        bai="results/mapping/{step}/{sample}.bam.bai",
    benchmark:
        "benchmarks/samtools/bam_index/{step}/{sample}.benchmark"
    threads: min(config["threads"]["bam_index"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_bam_index,
    log:
        "logs/samtools/bam_index/{step}/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.0/wrappers/samtools/index"


rule picard__mark_duplicates:
    input:
        bams="results/mapping/mapped/{sample}.bam",
        bai="results/mapping/mapped/{sample}.bam.bai",
    output:
        bam="results/mapping/deduplicated/{sample}.bam",
        metrics=temp("results/mapping/deduplicated/{sample}.stats"),
    params:
        extra="--VALIDATION_STRINGENCY SILENT",
    resources:
        mem_mb=get_mem_mb_for_picard,
    log:
        "logs/picard/mark_duplicates/{sample}.log",
    benchmark:
        "benchmarks/picard/mark_duplicates/{sample}.benchmark"
    wrapper:
        "v2.1.1/bio/picard/markduplicates"


rule qualimap__mapping_quality_report:
    input:
        bam="results/mapping/{step}/{sample}.bam",
        bai="results/mapping/{step}/{sample}.bam.bai",
    output:
        report_dir=report(
            directory("results/mapping/{step}/{sample}/bamqc"),
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
        "https://github.com/xsitarcik/wrappers/raw/v1.5.0/wrappers/qualimap/bamqc"
