rule samtools__mpileup_depth:
    input:
        bam="results/mapping/{sample}/deduplicated/{reference}.bam",
        fasta=get_reference_fasta,
    output:
        "results/freyja/{sample}/{reference}.depth",
    conda:
        "../envs/samtools.yaml"
    log:
        "logs/samtools/mpileup_depth/{reference}/{sample}.log",
    shell:
        "samtools mpileup -aa -A -d 600000 -Q 20 -q 0 -B -f {input.fasta} {input.bam} | cut -f1-4 > {output}"


rule freyja__variants:
    input:
        fasta=get_reference_fasta,
        bam="results/mapping/{sample}/deduplicated/{reference}.bam",
        depths="results/freyja/{sample}/{reference}.depth",
    output:
        "results/freyja/{sample}/{reference}_variants.tsv",
    conda:
        "../envs/freyja.yaml"
    log:
        "logs/freyja/variants/{reference}/{sample}.log",
    shell:
        "freyja variants {input.bam} --variants {output} --depths {input.depths} --ref {input.fasta}"


rule freyja__update_lineages:
    output:
        lineages=protected("{prefix_dir}/curated_lineages.json"),
        barcodes=protected("{prefix_dir}/usher_barcodes.csv"),
    params:
        outdir=lambda wildcards, output: os.path.dirname(output.lineages),
    conda:
        "../envs/freyja.yaml"
    log:
        "{prefix_dir}/logs/freyja_update.log",
    shell:
        "mkdir -p {params.outdir} && freyja update --outdir {params.outdir} > {log} 2>&1"


rule freyja__demix:
    input:
        variants="results/freyja/{sample}/{reference}_variants.tsv",
        depths="results/freyja/{sample}/{reference}.depth",
        lineages=os.path.join(config["lineages_dir"], "curated_lineages.json"),
        barcodes=os.path.join(config["lineages_dir"], "usher_barcodes.csv"),
    output:
        demix="results/freyja/{sample}/{reference}.demix",
    log:
        "logs/freyja/demix/{reference}/{sample}.log",
    conda:
        "../envs/freyja.yaml"
    shell:
        "freyja demix {input.variants} {input.depths} --output {output} --meta {input.lineages} --barcodes {input.barcodes}"


rule mixture_composition_freyja_summary:
    input:
        demix="results/freyja/{sample}/{reference}.demix",
    output:
        summary="results/freyja/{sample}/{reference}.csv",
    conda:
        "../envs/python.yaml"
    log:
        "logs/freyja/summary/{reference}/{sample}.log",
    script:
        "../scripts/summary.py"
