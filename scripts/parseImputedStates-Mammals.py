#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 21 10:59:05 2024

@author: agl4001
"""

import os
import sys
import pandas as pd
import json
import numpy as np

# =============================================================================
# Declares
# =============================================================================

#inputFile = sys.argv[1] # MEME JSON FILE

inputFile = os.path.join("..", 
                         "results", 
                         "MammalianMGA", 
                         "MammalianMGA.RD.SA.codons.cln.fa.MEME.json")

tag = "MammalianMGA"

HumanID = "NM_001400225_1_Homo_sapiens_MAX_dimerization_protein_MGA_MGA_transcript_variant_3_mRNA"

# =============================================================================
# Functions
# =============================================================================

def readJSON(jsonFile):
    with open(jsonFile, "r") as fh:
        jsonData = json.load(fh)
    return jsonData

# =============================================================================
# Main
# =============================================================================

data = readJSON(inputFile)

imputedStates = data["MLE"]["Imputed States"]

dfDict = {}

count = 1
for k in sorted(imputedStates["0"].keys()):
    #print(k)
    siteData = imputedStates["0"].get(k, np.nan)
    
    if type(siteData) != dict: continue

    siteData = siteData.get(HumanID, np.nan)
    
    #print(siteData, "\n")
    
    observedCodon = np.nan
    
    if len(list(siteData["observed"].keys())) > 0:
        observedCodon = list(siteData["observed"].keys())[0]
    
    Support = siteData["support"]
    
    for imputedCodon in siteData["imputed"].keys():
        dfDict[count] = {"HumanSite": 0, 
                         "AlignmentSite": k,
                         "ObservedCodon": observedCodon,
                         "Support": Support,
                         "ImputedCodon": imputedCodon,
                         "ImputedSupport": siteData["imputed"][imputedCodon]
                        }
        count += 1
# end for
      
    
df = pd.DataFrame.from_dict(dfDict, orient='index')

df_AlnMap = pd.read_csv("MammalianMGA-AlignmentMap.csv") # CHANGE THIS!

for index, row in df.iterrows():
    AlnSite = row["AlignmentSite"]
    HumanSite = df_AlnMap[df_AlnMap["AlignmentSite"] == int(AlnSite)]
    
    #print(HumanSite["HumanSite"].to_numpy())
    HumanSite = HumanSite["HumanSite"].to_numpy()
    if len(HumanSite) > 0:
        df.loc[index, "HumanSite"] = int(HumanSite[0])
    else:
        df.loc[index, "HumanSite"] = np.nan


# Drop rows without HumanSite
df.dropna(subset=["HumanSite"], inplace=True)

# Sort by HumanSite
df = df.sort_values(by=['HumanSite'])

df = df.reset_index()
df.drop('index', axis=1, inplace=True)
df.index += 1

df = df.astype({"HumanSite": int})

outputFile = tag + "-MEME-ImputedStates.csv"

df.to_csv(outputFile, index=False)

# =============================================================================
# End of file
# =============================================================================
