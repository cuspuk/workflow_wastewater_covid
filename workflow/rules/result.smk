rule evaluate__final_result_for_sample:
    input:
        get_relevant_outputs,
    output:
        temp("results/.success/{sample}.txt"),
    log:
        "logs/.success/{sample}.log",
    localrule: True
    conda:
        "../envs/coreutils.yaml"
    shell:
        "touch {output} > {log} 2>&1"


rule multiqc__report:
    input:
        cutadapt=expand("results/reads/trimming/{sample}.qc.txt", sample=get_sample_names()),
        fastqc=expand(
            "results/reads/{step}/fastqc/{sample}_{pair}/fastqc_data.txt",
            sample=get_sample_names(),
            step=config["reads"]["_generate_fastqc_for"],
            pair=["R1", "R2"],
        ),
        kraken=expand("results/kraken/{sample}.kreport2", sample=get_sample_names()),
        picard_dedup=expand("results/mapping/deduplicated/{sample}.stats", sample=get_sample_names()),
        qualimap=expand("results/mapping/deduplicated/bamqc/{sample}", sample=get_sample_names()),
    output:
        "results/_aggregation/multiqc.html",
    params:
        use_input_files_only=True,
        extra=f"--config {workflow.basedir}/resources/multiqc.yaml",  # Optional: extra parameters for multiqc.
    log:
        "logs/multiqc/all.log",
    wrapper:
        "v3.5.1/bio/multiqc"
