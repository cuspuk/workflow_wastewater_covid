from snakemake.utils import validate
from snakemake.io import glob_wildcards


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


### Layer for adapting other workflows  ###############################################################################


def get_fastq_for_mapping(wildcards):
    return reads_workflow.get_final_fastq_for_sample(wildcards.sample)


def get_sample_names():
    return reads_workflow.get_sample_names()


## GLOBAL SPACE #################################################################

MAPPING_REF = os.path.basename(os.path.realpath(config["mapping_ref"]))


def get_constraints():
    return {
        "sample": "|".join(get_sample_names()),
    }


def get_bwa_index_for_mapping():
    return multiext(
        os.path.join(config["mapping_ref"], "bwa_index", MAPPING_REF),
        ".amb",
        ".ann",
        ".bwt",
        ".pac",
        ".sa",
    )


def get_reference_fasta():
    return os.path.join(config["mapping_ref"], f"{MAPPING_REF}.fa")


def get_reference_faidx():
    return os.path.join(config["mapping_ref"], f"{MAPPING_REF}.fa.fai")


def get_reference_dict():
    return os.path.join(config["mapping_ref"], f"{MAPPING_REF}.dict")


#### COMMON STUFF #################################################################


def sample_has_enough_mapped_reads(sample_name: str):
    with checkpoints.samtools__view_number_of_reads.get(sample=sample_name).output[0].open() as f:
        num = int(f.read().strip())
    return num >= 1


def get_passed_sample_names():
    return [sample for sample in get_sample_names() if sample_has_enough_mapped_reads(sample)]


def get_relevant_outputs(wildcards):
    base_outputs = [
        "results/mapping/deduplicated/{sample}.bam",
    ]

    if not sample_has_enough_mapped_reads(wildcards.sample):
        return base_outputs

    return base_outputs + [
        "results/mapping/deduplicated/bamqc/{sample}",
        "results/freyja/{sample}/summary.csv",
    ]


def get_outputs():
    sample_names = get_sample_names()
    outputs = {
        "graceful_success": expand("results/.success/{sample}.txt", sample=sample_names),
    }

    if len(sample_names) > 1:
        outputs["multiqc"] = ("results/_aggregation/multiqc.html",)
    return outputs


### RESOURCES


def get_mem_mb_for_picard(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["picard_mem_mb"] * attempt)


def get_mem_mb_for_qualimap(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["qualimap_mem_mb"] * attempt)


def get_mem_mb_for_mapping(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping_mem_mb"] * attempt)


def get_mem_mb_for_bam_index(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["bam_index_mem_mb"] * attempt)
