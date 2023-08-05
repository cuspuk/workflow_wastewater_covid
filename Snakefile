import os
dynamic_output = []

include: "rules/snakelines/snakelines.snake"
include: "rules/freyja.snake"


all_samples = []
for sample_configuration in config.get('samples'):
    samples = []
    if 'name' in sample_configuration:
        location = 'reads/original/{}_R1.fastq.gz'
        location = location.replace('{}', '{sample, %s}' % sample_configuration['name'])
        wildcards = glob_wildcards(location)
        samples = wildcards.sample
        all_samples.extend(samples)

rule all:
    input:
        **get_files(outputs),
        freyja_output = expand(f"freyja/{reference}/{sample}/deduplicatred/_freyja.csv", sample=set(all_samples)),

