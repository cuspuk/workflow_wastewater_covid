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
    log:
        "logs/custom/infer_and_store_read_group/{sample}.log",
    conda:
        "../envs/python.yaml"
    script:
        "../scripts/save_read_group.py"


rule bwa__map_reads_to_reference:
    input:
        reads=[
            "results/reads/trimmed/{sample}_R1.fastq.gz",
            "results/reads/trimmed/{sample}_R2.fastq.gz",
        ],
        index=get_bwa_index_for_mapping(),
        read_group="results/reads/original/read_group/{sample}.txt",
    output:
        bam=temp("results/mapping/{sample}/mapped/{reference}.bam"),
    threads: min(config["threads"]["mapping"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_mapping,
    log:
        "logs/bwa/map_reads_to_reference/{sample}/{reference}.log",
    benchmark:
        "benchmarks/bwa/map_reads_to_reference/{sample}/{reference}.benchmark"
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.7/wrappers/bwa/map"


rule samtools__bam_index:
    input:
        bam="results/mapping/{sample}/{step}/{reference}.bam",
    output:
        bai="results/mapping/{sample}/{step}/{reference}.bam.bai",
    benchmark:
        "benchmarks/samtools/bam_index/{step}/{reference}/{sample}.benchmark"
    threads: min(config["threads"]["bam_index"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_bam_index,
    log:
        "logs/samtools/bam_index/{sample}/{reference}_{step}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.0/wrappers/samtools/index"


rule picard__mark_duplicates:
    input:
        bams="results/mapping/{sample}/mapped/{reference}.bam",
        bai="results/mapping/{sample}/mapped/{reference}.bam.bai",
    output:
        bam="results/mapping/{sample}/deduplicated/{reference}.bam",
        metrics=temp("results/mapping/{sample}/deduplicated/{reference}.stats"),
    params:
        extra="--VALIDATION_STRINGENCY SILENT",
    resources:
        mem_mb=get_mem_mb_for_picard,
    log:
        "logs/picard/mark_duplicates/{sample}/{reference}.log",
    benchmark:
        "benchmarks/picard/mark_duplicates/{sample}/{reference}.benchmark"
    wrapper:
        "v2.1.1/bio/picard/markduplicates"


rule qualimap__mapping_quality_report:
    input:
        bam="results/mapping/{sample}/{step}/{reference}.bam",
        bai="results/mapping/{sample}/{step}/{reference}.bam.bai",
    output:
        report_dir=report(
            directory("results/mapping/{sample}/{step}/bamqc/{reference}"),
            category="Reports",
            labels={
                "Type": "Qualimap",
                "Name": "{reference}",
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
        "logs/qualimap/mapping_quality_report/{sample}/{step}/{reference}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.0/wrappers/qualimap/bamqc"
