rule evaluate__final_result_for_sample:
    input:
        get_relevant_outputs,
    output:
        temp("results/.success/{sample}.txt"),
    log:
        "logs/.success/{sample}.log",
    conda:
        "../envs/coreutils.yaml"
    shell:
        "touch {output} > {log} 2>&1"
