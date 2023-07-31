import os
dynamic_output = []

include: "rules/snakelines/snakelines.snake"
include: "rules/freyja.snake"


rule all:
    input:
        **get_files(outputs),
        freyja_output = os.path.join(
            "freyja",
            config['reference'],
            config['sample'],
            'deduplicated',
            '_freyja.csv'
        ),
