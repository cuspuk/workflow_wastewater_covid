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


rule bwa__filter_reads_from_reference_pe:
    input:
        r1="results/reads/trimmed/{sample}_R1.fastq.gz",
        r2="results/reads/trimmed/{sample}_R2.fastq.gz",
        index=get_bwa_index_for_decontamination(),
    output:
        r1="results/reads/decontaminated/{sample}_R1.fastq.gz",
        r2="results/reads/decontaminated/{sample}_R2.fastq.gz",
    params:
        indices=lambda w, input: [os.path.splitext(input.index[0])[0]],
        keep_param="-F 2",
        sample=lambda w, input: os.path.basename(input.r1).replace("_R1.fastq.gz", ""),
    threads: min(config["threads"]["decontamination"], config["max_threads"])
    log:
        "logs/bwa/filter_reads_from_reference/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.9/wrappers/bwa/filter"


rule fastqc__quality_report:
    input:
        read="results/reads/{step}/{fastq}.fastq.gz",
    output:
        html=report(
            "results/reads/{step}/fastqc/{fastq}.html",
            category="Reports",
            labels={
                "Type": "Fastqc",
                "Name": "{fastq}",
            },
        ),
        zip="results/reads/{step}/fastqc/{fastq}.zip",
        qc_data="results/reads/{step}/fastqc/{fastq}/fastqc_data.txt",
        summary_txt="results/reads/{step}/fastqc/{fastq}/summary.txt",
    threads: min(config["threads"]["fastqc"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_fastqc,
    log:
        "logs/fastqc/{step}/{fastq}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.5.4/wrappers/fastqc/quality"
