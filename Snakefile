import os
from glob import glob
import pandas as pd

configfile: "config.yaml"

DATASET = config["dataset"]
DIR_IN = config["dir_in"]
DIR_OUT =config["dir_out"]

DATASET_IN = f"{DIR_IN}/{DATASET}"

GENOMES = [os.path.basename(genome) for genome in glob(f"{DATASET_IN}/GC*")]

# Règle pour vérifier si tous les fichiers de sortie existent
rule all:
    input:
        expand("results/genomes/{genome}/PGCfinder", genome=GENOMES),
        expand("results/genomes/{genome}/PGCfinder/info.txt", genome=GENOMES),
        "results/lists/list_organisms.csv",
        "results/lists/list_PGC_infos.csv",
        "results/lists/list_organisms_merged.csv"

# Rule to launch PGCfinder with the correct parameters on all the genomes
rule PGCfinder:
    input:
        lambda wildcards: f"{DATASET_IN}/{wildcards.genome}/{wildcards.genome}_protein.faa.gz"
    output:
        directory("results/genomes/{genome}/PGCfinder"),
        "results/genomes/{genome}/PGCfinder/best_solution.tsv"
    shell:
        """
        mkdir -p {output[0]}
        macsyfinder --mute --db-type ordered_replicon --sequence-db {input} --models PGCFinder all -o {output[0]} --cfg-file macsyfinder.conf
        """

# Rule to create a file with all the names of the genomes that have been given previously
rule list_creator:
    input:
        expand("results/genomes/{genome}/PGCfinder", genome=GENOMES)
    output:
        "results/lists/list_organisms.csv"
    shell:
        """
        find results/genomes -maxdepth 1 -mindepth 1 -type d -exec basename {{}} \; > {output}
        """

# Rule that processes each genome and retrieves important information from PGCfinder outputs
rule infos_retriever_genome:
    input:
        "results/genomes/{genome}/PGCfinder/best_solution.tsv"
    output:
        "results/genomes/{genome}/PGCfinder/info.txt"
    shell:
        """
        touch {output}
        if [[ -f {input} ]] && [[ $(grep -v "^#" {input} | wc -l) -ge 1 ]]; then
            python3 scripts/collect_infos_PGCfinder.py {wildcards.genome} > {output}
        fi
        """

# Rule that gathers all the individual genome information into a single file
rule infos_retriever:
    input:
        expand("results/genomes/{genome}/PGCfinder/info.txt", genome=GENOMES)
    output:
        "results/lists/list_PGC_infos.csv"
    shell:
        """
        cat {input} > {output}
        """

rule list_merger:
    input:
        "results/lists/list_PGC_infos.csv",
        "data/lists/list_with_taxonomy_GTDB.csv",
        "results/lists/list_organisms.csv"
    output:
        "results/lists/list_organisms_merged.csv"
    shell:
        "python3 scripts/merge_csv.py"
