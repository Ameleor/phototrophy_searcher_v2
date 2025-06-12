import pandas as pd
import sys
import re

# Inputs
PGC_infos = sys.argv[1]
list_with_taxonomy = sys.argv[2]
organisms = sys.argv[3]
output = sys.argv[4]

try:
# Reading of the files
df_PGC_infos = pd.read_csv(PGC_infos, header=None)
df_list_with_tax = pd.read_csv(list_with_taxonomy, low_memory=False)
df_organisms = pd.read_csv(organisms, header=None)

# Creation of a "to_merge" column for each DataFrame to keep only the accession number
df_PGC_infos["to_merge"] = df_PGC_infos[0].str.extract(r'GC[FA]_(\d+\.\d+)')
df_list_with_tax["to_merge"] = df_list_with_tax["Assembly Accession"].str.extract(r'GC[FA]_(\d+\.\d+)')
df_organisms["to_merge"] = df_organisms[0].str.extract(r'GC[FA]_(\d+\.\d+)')

# Merging of all the df
df_new_list = pd.merge(df_organisms, df_list_with_tax, on="to_merge", how="left")
df_new_list = pd.merge(df_new_list, df_PGC_infos, on="to_merge", how="left")

# Cleaning of the columns
df_new_list = df_new_list.rename(columns={'0_x': 'Dir name'})
df_new_list = df_new_list.drop(columns=['0_y', 'to_merge'])

# Output
df_new_list.to_csv(output)
