rule samtools__mpileup_depth:
    input:
        bam="results/mapping/deduplicated/{sample}.bam",
        bai="results/mapping/deduplicated/{sample}.bam.bai",
        fasta=get_reference_fasta(),
    output:
        "results/freyja/{sample}/freyja.depth",
    conda:
        "../envs/samtools.yaml"
    log:
        "logs/samtools/mpileup_depth/{sample}.log",
    shell:
        "(samtools mpileup -aa -A -d 600000 -Q 20 -q 0 -B -f {input.fasta} {input.bam} | cut -f1-4 > {output} ) 2> {log}"


rule freyja__variants:
    input:
        fasta=get_reference_fasta(),
        bam="results/mapping/deduplicated/{sample}.bam",
        bai="results/mapping/deduplicated/{sample}.bam.bai",
        depths="results/freyja/{sample}/freyja.depth",
    output:
        "results/freyja/{sample}/variants.tsv",
    conda:
        "../envs/freyja.yaml"
    log:
        "logs/freyja/variants/{sample}.log",
    shell:
        "freyja variants {input.bam} --variants {output} --depths {input.depths} --ref {input.fasta} > {log} 2>&1"


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
        "(mkdir -p {params.outdir} && freyja update && freyja update --outdir {params.outdir}) > {log} 2>&1"


rule freyja__demix:
    input:
        variants="results/freyja/{sample}/variants.tsv",
        depths="results/freyja/{sample}/freyja.depth",
        lineages=os.path.join(config["lineages_dir"], "curated_lineages.json"),
        barcodes=os.path.join(config["lineages_dir"], "usher_barcodes.csv"),
    output:
        "results/freyja/{sample}/freyja.demix",
    params:
        depth_cutoff="--depthcutoff {val}".format(val=config["freyja__params"]["depth_cutoff"])
        if config["freyja__params"]["depth_cutoff"] != 0
        else "",
        min_lineage_abundance="--eps {val}".format(val=config["freyja__params"]["min_lineage_abundance"])
        if config["freyja__params"]["min_lineage_abundance"] != 0
        else "",
        confirmed_only="--confirmedonly" if config["freyja__params"]["only_confirmed_lineages"] else "",
    log:
        "logs/freyja/demix/{sample}.log",
    conda:
        "../envs/freyja.yaml"
    shell:
        "freyja demix {params.depth_cutoff} {input.variants} {input.depths} --output {output}"
        " {params.min_lineage_abundance} --meta {input.lineages} --barcodes {input.barcodes} > {log} 2>&1"


rule freyja__summary:
    input:
        demix="results/freyja/{sample}/freyja.demix",
    output:
        summary="results/freyja/{sample}/summary.csv",
    conda:
        "../envs/python.yaml"
    log:
        "logs/freyja/summary/{sample}.log",
    script:
        "../scripts/summary.py"
