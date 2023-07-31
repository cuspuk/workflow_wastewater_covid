# wastewater_covid

Snakemake workflow for analysis of wastewater covid samples

## Installation

```sh
conda config --add channels bioconda
conda config --add channels g2554711
conda config --add channels g2554711/label/bioconda
conda config --add channels conda-forge
conda config --add channels agbiome
conda config --add channels rsmulktis
conda config --add channels moustik

mamba create --name snakelines_env -c bioconda snakelines
```

## Configuration file

See [config.yaml](config.yaml)
