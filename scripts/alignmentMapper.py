#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 21 12:35:33 2024

@author: agl4001
"""

# Imports

import os
import sys
import pandas as pd
from pandas.plotting import scatter_matrix
import random
from matplotlib import pyplot as plt
import itertools
import numpy as np
from matplotlib.pyplot import figure
from Bio.Seq import Seq
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord

HUMAN_ID = "NM_001400225_1_Homo_sapiens_MAX_dimerization_protein_MGA_MGA_transcript_variant_3_mRNA"

FASTA = os.path.join("..", 
                     "results", 
                     "PrimateMGA", 
                     "PrimateMGA.RD.SA.codons.cln.fa")

def process_sites(input_file):                                
    fasta_sequence = SeqIO.parse(open(input_file),'fasta')
    fasta_dict = {}                                                   #init
    for record in fasta_sequence:                                     #loops over each species
        ID, SEQ, site_count, nt_num = record.id, record.seq, 1, 0
        fasta_dict[ID] = {}                                             #init
        while SEQ[nt_num:nt_num+3]:                                     # loop over codons
            codon = str(SEQ[nt_num:nt_num+3])
            fasta_dict[ID][site_count] = codon
            site_count += 1
            nt_num += 3
         #end while
    #end for
    return fasta_dict
#end method

a = process_sites(FASTA)

MAP_ALIGNMENT_TO_HUMAN = []

for site in a[HUMAN_ID].keys():
    codon = a[HUMAN_ID][site]
    if "-" in codon and codon != "---":
        print(codon) # look for ambiguous codons visually.
    # end if
    
    if codon != "---": # not a gap site.
        #print(site, codon)
        MAP_ALIGNMENT_TO_HUMAN.append(site)
    #end if
#end for

output_dict = {}

A = []
B = []

for n, item in enumerate(MAP_ALIGNMENT_TO_HUMAN):
    A.append(n+1)
    B.append(item)
#end for

output_dict["HumanSite"] = A
output_dict["AlignmentSite"] = B

df = pd.DataFrame.from_dict(output_dict)
df.index += 1


df.to_csv("PrimateMGA-AlignmentMap.csv", index=False)