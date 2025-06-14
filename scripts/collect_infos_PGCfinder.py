import pandas as pd
import os
import sys

# Getting the name of each genome thanks to the snakefile
genome = sys.argv[1]
dir_in = sys.argv[2]
dir_out = sys.argv[3]

# Read of the ouput necessary
data_genome = os.path.join(dir_in, genome)
results_genome = os.path.join(dir_out, genome, 'PGCfinder')

# Try to pass all the genome that don't have a PGC found by PGCfinder
try:
    # Read of the necessary files that exist
    best_solution = pd.read_csv(os.path.join(results_genome, 'best_solution.tsv'), sep='\t', comment='#')
    best_solution_summary = pd.read_csv(os.path.join(results_genome, 'best_solution_summary.tsv'), sep='\t', comment='#', index_col=0)
    genome_gff = pd.read_csv(os.path.join(data_genome, genome)+"_protein_gff.tsv.gz", sep='\t')

    # Getting the number of genes hit for each PGC
    nbr_genes_hit = best_solution.shape[0]

    # Getting the number of PGC found (one or more)
    nbr_PGC = best_solution_summary.iloc[0, 0]

    # Storing the location on the genome of each gene
    genes_place = pd.DataFrame(best_solution.iloc[:, 1])
    genes_place.columns = ['prot_id_unique']

    # Merge the DataFrames and add suffixes to the overlapping columns
    replicon_type = genes_place.merge(genome_gff[['prot_id_unique', 'replicon_type']], how='left', on='prot_id_unique')
    replicons_unique = replicon_type['replicon_type'].unique()

    # Gather the different types of replicon which has atleast one gene hit on it
    replicons_diff = ""
    for replicon in replicons_unique:
        # Creation of a way to store the different replicons type if it exist so that I can split them easilly in other scripts
        if replicons_diff:
            replicons_diff += "/" + replicon
        else:
            replicons_diff = replicon

    # Get back the name of the genome to merge with the list
    genome_split = genome.split('_')
    genome_name = "_".join(genome_split[:2])

    # Create a variable that will be used to create a ".csv"
    to_merge_data = (genome_name + ',' + str(nbr_PGC) + ',' + str(nbr_genes_hit) + ',' + replicons_diff)

    print(to_merge_data)

except pd.errors.EmptyDataError:
    pass
