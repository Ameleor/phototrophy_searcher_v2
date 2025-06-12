import os
from glob import glob
import pandas as pd

configfile: "config.yaml"

DATASET = config["dataset"]
DIR_IN = config["dir_in"]
DIR_OUT = config["dir_out"]

DATASET_IN = f"{DIR_IN}/{DATASET}"

GENOMES = [os.path.basename(genome) for genome in glob(f"{DATASET_IN}/GC*")]

# Règle pour vérifier si tous les fichiers de sortie existent
rule all:
    input:
        expand("{dir_out}/{dataset}/{genome}/PGCfinder", genome=GENOMES, dir_out=DIR_OUT, dataset=DATASET),
        expand("{dir_out}/{dataset}/{genome}/PGCfinder/info.txt", genome=GENOMES, dir_out=DIR_OUT, dataset=DATASET),
        f"{DIR_OUT}/lists/list_organisms.csv",
        f"{DIR_OUT}/lists/list_PGC_infos.csv",
        f"{DIR_OUT}/lists/list_organisms_merged.csv"

# Rule to launch PGCfinder with the correct parameters on all the genomes
rule PGCfinder:
    input:
        lambda wildcards: f"{DATASET_IN}/{wildcards.genome}/{wildcards.genome}_protein.faa.gz"
    output:
        PGCFinder_output = directory("{dir_out}/{dataset}/{genome}/PGCfinder"),
        best_solution = "{dir_out}/{dataset}/{genome}/PGCfinder/best_solution.tsv"
    shell:
        """
        mkdir -p {output.PGCFinder_output}
        macsyfinder --mute --db-type ordered_replicon --sequence-db {input} --models PGCFinder all -o {output.PGCFinder_output} --cfg-file macsyfinder.conf
        """

# Rule to create a file with all the names of the genomes that have been given previously
rule list_creator:
    input:
        PGCFinder_output = expand("{dir_out}/{dataset}/{genome}/PGCfinder", genome=GENOMES, dir_out=DIR_OUT, dataset=DATASET)
    output:
        f"{DIR_OUT}/lists/list_organisms.csv"
    shell:
        """
        find {DIR_OUT}/{DATASET} -maxdepth 1 -mindepth 1 -type d -exec basename {{}} \; > {output}
        """

# Rule that processes each genome and retrieves important information from PGCfinder outputs
rule infos_retriever_genome:
    input:
        "{DIR_OUT}/{DATASET}/{genome}/PGCfinder/best_solution.tsv"
    output:
        "{DIR_OUT}/{DATASET}/{genome}/PGCfinder/info.txt"
    shell:
        """
        touch {output}
        if [[ -f {input} ]] && [[ $(grep -v "^#" {input} | wc -l) -ge 1 ]]; then
            python3 scripts/collect_infos_PGCfinder.py {wildcards.genome} {DIR_IN}/{DATASET} {DIR_OUT}/{DATASET} > {output}
        fi
        """

# Rule that gathers all the individual genome information into a single file
rule infos_retriever:
    input:
        expand("{dir_out}/{dataset}/{genome}/PGCfinder/info.txt", genome=GENOMES, dir_out=DIR_OUT, dataset=DATASET)
    output:
        "{DIR_OUT}/lists/list_PGC_infos.csv"
    shell:
        """
        cat {input} > {output}
        """

rule list_merger:
    input:
        PGC_infos = f"{DIR_OUT}/lists/list_PGC_infos.csv",
        list_with_tax = f"{DIR_IN}/lists/list_with_taxonomy.csv",
        organisms = f"{DIR_OUT}/lists/list_organisms.csv"
    output:
        f"{DIR_OUT}/lists/list_organisms_merged.csv"
    shell:
        """
        python3 scripts/merge_csv.py {input.PGC_infos} {input.list_with_tax} {input.organisms} {output}
        """
