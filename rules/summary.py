def freyja_tsv(file_path: str, sample_name: str, out_path: str):
    '''Rewritten previous rule to remove unnecessary reliance on pandas and numpy'''
    occurrences: dict[str, dict[str, str]] = {}
    sample_res: dict[str, str] = {}
    line = ''
    with open(file_path) as file:
        line = file.read()
        file.close()

    lineages = line.split('\n')[2].split()[1:]
    abundances = line.split('\n')[3].split()[1:]
    assert len(lineages) == len(abundances)

    for i in range(len(lineages)):
        sample_res[lineages[i]] = abundances[i]

    occurrences[sample_name] = sample_res

    header = ','+','.join(occurrences[sample_name].keys())
    row = f'{sample_name},'+','.join(occurrences[sample_name].values())
    with open(out_path, 'w') as file:
        file.write(header)
        file.write('\n')
        file.write(row)
        file.write('\n')


freyja_tsv(snakemake.input.demix, snakemake.wildcards.sample, snakemake.output.summary)  # type: ignore # noqa: F821
