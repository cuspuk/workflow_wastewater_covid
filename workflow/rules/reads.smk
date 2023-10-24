rule cutadapt__trim_reads_pe:
    input:
        get_fastq_paths,
    output:
        r1=temp("results/reads/trimmed/{sample}_R1.fastq.gz"),
        r2=temp("results/reads/trimmed/{sample}_R2.fastq.gz"),
        report=temp("results/reads/trimmed/{sample}_cutadapt.json"),
    params:
        overlap=config["reads__trimming"]["overlap"],
        error_rate=config["reads__trimming"]["error_rate"],
        times=config["reads__trimming"]["times"],
        action=config["reads__trimming"]["action"],
        extra=get_cutadapt_extra_pe(),
    resources:
        mem_mb=get_mem_mb_for_trimming,
    threads: min(config["threads"]["trimming"], config["max_threads"])
    log:
        "logs/cutadapt/trim_reads_pe/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.9/wrappers/cutadapt/paired"


rule kraken__decontaminate:
    input:
        r1="results/reads/trimmed/{sample}_R1.fastq.gz",
        r2="results/reads/trimmed/{sample}_R2.fastq.gz",
        kraken_output="results/kraken/{sample}.kraken",
        kraken_report="results/kraken/{sample}.kreport2",
    output:
        r1="results/reads/decontaminated/{sample}_R1.fastq.gz",
        r2="results/reads/decontaminated/{sample}_R2.fastq.gz",
        std_out=temp("results/reads/decontaminated/{sample}_decontamination.out"),
    params:
        taxid=" ".join(str(taxa_id) for taxa_id in config["reads__decontamination"]["exclude_taxa_ids"]),
        extra=get_kraken_decontamination_params(),
    log:
        "logs/kraken/decontaminate/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.7.0/wrappers/kraken/decontaminate_pe"


rule fastqc__quality_report:
    input:
        read=infer_read_path,
    output:
        html=report(
            "results/reads/{step}/fastqc/{sample}_{strand}.html",
            category="{sample}",
            labels={
                "Type": "Fastqc {strand} - {step}",
            },
        ),
        zip="results/reads/{step}/fastqc/{sample}_{strand}.zip",
        qc_data="results/reads/{step}/fastqc/{sample}_{strand}/fastqc_data.txt",
        summary_txt="results/reads/{step}/fastqc/{sample}_{strand}/summary.txt",
    threads: min(config["threads"]["fastqc"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_fastqc,
    log:
        "logs/fastqc/{step}/{sample}_{strand}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.4/wrappers/fastqc/quality"
