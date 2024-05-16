"""

Snakemake file that runs the AOC application

Written by Alexander G Lucaci, 2024

"""

# =============================================================================
# Imports
# =============================================================================

import itertools
import os
import sys
import csv
import json
from pathlib import Path
from snakemake.utils import min_version
from Bio import SeqIO
from ete3 import Tree
from Bio import Entrez
from ete3 import NCBITaxa
import pandas as pd
pd.options.mode.chained_assignment = None

# =============================================================================
# Configuration
# =============================================================================

configfile: 'config.yml'

print("# Loaded config yaml file")

with open("cluster.json", "r") as fh:
  cluster = json.load(fh)
  fh.close()
#end with

BASEDIR = os.getcwd()

print("# Loaded cluster json file")

Email = config["Email"]

Label = config["Label"]
#GENE = config["Label"]

Nucleotide_file = os.path.join(BASEDIR,
                               "data",
                               Label,
                               config["Nucleotide"])
                               
Protein_file    = os.path.join(BASEDIR,
                               "data",
                               Label,
                               config["Protein"])
                            
CSV             = os.path.join(BASEDIR,
                               "data",
                               Label,
                               config["CSV"])
                               
# Print to user
print("# Using nucleotide data from:", Nucleotide_file)
print("# Using protein data from:", Protein_file)
print("# Using the analysis label:", Label)
print("# Using the metadata from:", CSV)

# Batch files
PREMSA  = os.path.join(BASEDIR,
                       "hyphy-analyses",
                       "codon-msa",
                       "pre-msa.bf")
                      
POSTMSA = os.path.join(BASEDIR,
                       "hyphy-analyses",
                       "codon-msa",
                       "post-msa.bf")

# Set output directory
print("# We are operating out of base directory:", BASEDIR)
       
OUTDIR_RESULTS = os.path.join(BASEDIR,
                              "results")
       
OUTDIR = os.path.join(BASEDIR,
                      "results",
                      Label)

print("# We will create and store results in:", OUTDIR)

# Create output dir.
os.makedirs(OUTDIR_RESULTS,
            exist_ok = True)
            
print("# Directory '% s' created" % OUTDIR_RESULTS)

os.makedirs(OUTDIR,
            exist_ok = True)
            
print("# Directory '% s' created" % OUTDIR)

# Set up configuration
PPN = cluster["__default__"]["ppn"]

# Hard-coded HyPhy settings
HYPHY = "hyphy"
HYPHYMPI = "HYPHYMPI"

CODON_OUTPUT   = os.path.join(OUTDIR, Label)
REMOVE_DUPS_BF = os.path.join("hyphy-analyses", "remove-duplicates", "remove-duplicates.bf")
CODONS_PY      = os.path.join("scripts", "codons.py")
STRIKE_AMBIGS_BF = os.path.join("scripts", "strike-ambigs.bf")

# =============================================================================
# Helper functions
# =============================================================================

def match_transcript_to_tree(TREE_NEWICK, accession):
    t = Tree(TREE_NEWICK, format=1)
    for leafname in t.get_leaf_names():
        if accession in leafname:
            return leafname
        #end if
    #end for
#end match

def ProcessLineages(transcript_accessions, DATA_DICT, TREE_NEWICK):
    count = 1
    for ACCESSION in transcript_accessions:
        skip = False
        
        for i in DATA_DICT.keys():
            if ACCESSION == DATA_DICT[i]["ACCESSION"]:
                skip = True
                break
            #end if
        #end for
        if skip == True:
            count += 1
            continue
        #end if
        try:
            handle = Entrez.esummary(db="nucleotide", id=ACCESSION, rettype="gb", retmode="text", retmax=1)
            records = Entrez.parse(handle)
        except Exception as e:
            print("# Error, sleeping", e)
            time.sleep(5)
            handle = Entrez.esummary(db="nucleotide", id=ACCESSION, rettype="gb", retmode="text", retmax=1)
            records = Entrez.parse(handle)
        #end try
        
        try:
            for record in records:
                TAXON_ID = record["TaxId"]
                print("#", count, "Processing transcript accession:", 
                                   str(ACCESSION), 
                                   "with NCBI Taxon ID:", 
                                   str(TAXON_ID))
                ncbi = NCBITaxa()
                lineage = ncbi.get_lineage(TAXON_ID)
                names = ncbi.get_taxid_translator(lineage)
                leafname = ""
                leafname = match_transcript_to_tree(TREE_NEWICK, 
                                                    ACCESSION.replace(".", "_"))
                                                    
                DATA_DICT[str(count)] = {"ACCESSION": ACCESSION, 
                                         "TAXON_ID": TAXON_ID,
                                         "LINEAGE": [names[taxid] for taxid in lineage],
                                         "TITLE": record["Title"], 
                                         "LEAFNAME": leafname}
                count += 1
            #end inner for
            handle.close
        except Exception as e:
            print("# Error (main):", ACCESSION, e, "\n")
        #end try
    #end outer for
    return DATA_DICT
#end method

def get_LineageColumn(lineages, loc):
    result = []
    for item in lineages:
        result.append(item[loc])
    #end for
    return result
#end method

# Helper functions
def GardParser(label, best_gard, codon_MSA_in):    
    global BASEDIR
    data = [d.strip() for d in open(best_gard).readlines() if "CHARSET" in d]
    coords = []
    if len(data) > 1:
        for pos, i in enumerate(data):
            ## hyphy coordinates are 1 indexed and INCLUSIVE ##
            ## so to get to "true" python coords you need to -1 to start and -1 to stop ##
            ## then you need to +1 to python "stop" coord to get the actual length ## 
            start = int(i.split(" ")[-1].split(";")[0].split("-")[0])-1
            stop = int(i.split(" ")[-1].split(";")[0].split("-")[1])-1
            coords.append((start,stop))        
        #end for
    ## print out fasta file
    else:
        print(data)
    #end if
    ## now use the coords to pull out seqs in the codon aware MSA ##
    ## write a json for partition and indices associated ## 
    index_data = {}
    for pos, c in enumerate(coords):
        temp_dict = {}
        ## want list of 3 ##
        n = 3
        recs = list(rec for rec in SeqIO.parse(codon_MSA_in, "fasta"))      
        ## actual codons ##
        index_map = [list(range(len(recs[0].seq)))[i*n:(i+1) *n] for i in range((len(list(recs[0].seq)) + n - 1) // n )]
        old_start = c[0]
        old_stop = c[1]
        new_start = ''
        new_stop = ''
        ## getting new start ##
        for imap in index_map:
            if old_start in imap:
                for p, j in enumerate(imap):
                    if old_start == j:
                        if p !=0:
                            new_start = imap[2]+1
                        else:
                            new_start = imap[0]
                        #end if
                    #end if
                #end for
            elif old_stop in imap:
                new_stop = imap[0]
            else:
                continue 
            #end if
        #end for
        ## sanity check 
        print(f"# Sanity check: OLD {old_start}, {old_stop} | NEW {new_start}, {new_stop} | NEW div by 3 {(int(new_stop)-int(new_start))/3}")
        temp_dict[pos+1] = [i+1 for i in list(range(int(new_start),int(new_stop)))]
        index_data.update(temp_dict)
        ### ~ CHANGE TO PLACE YOU WANT OUTPUT ~ ###
        codon_out = os.path.join(BASEDIR, "results", label, "%s.%s.codon.fas" % (label, str(pos+1)))
        print("# Saving partition to:", codon_out)
        with open(codon_out, "w") as out_f:
            for record in recs:
                partition = record[int(new_start): int(new_stop)]
                out_f.write(">{}\n{}\n".format(partition.id, partition.seq))
            #end for
        #end with
#end method

# =============================================================================
# Rule all
# =============================================================================

rule all:
    input:
        CODON_OUTPUT,
        #expand(os.path.join(OUTDIR, "{GENE}_codons.trim.fa"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}_aa.trim.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.codons.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.aa.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.codons.cln.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.SA.codons.cln.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa"), GENE = Label),
        expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.treefile"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.json"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta.GARD.json"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta.best-gard"), GENE = Label),
        #expand(os.path.join(OUTDIR, "{GENE}.1.codon.fas"), GENE=Label),
        expand(os.path.join(OUTDIR, "{GENE}_Annotated.csv"), GENE=Label)
#end rule all

print("# Moving on to processing rules")

ruleorder: get_codons > macse > cln > strike_ambigs_msa > remove_duplicates_msa

wildcard_constraints:
    GENE=Label,

# =============================================================================
# Rules
# =============================================================================

rule get_codons:
    input:
        input = Nucleotide_file
    output:
        output = CODON_OUTPUT
    params:
        Nuc = Nucleotide_file,
        Prot = Protein_file,
        Out = CODON_OUTPUT
    script:
        "scripts/codons.py"
#end rule

# =============================================================================
# Quality Control (QC) and Codon-aware alignment
# =============================================================================

"""
rule macse_trim:
    input:
        input = rules.get_codons.output.output
    output:
        codons = os.path.join(OUTDIR, "{GENE}.MACSE.codons.trim.fa"),
        aa     = os.path.join(OUTDIR, "{GENE}.MACSE.aa.trim.fa")
    shell:
        "macse -prog trimNonHomologousFragments -seq {input.input} -min_homology_to_keep_seq 0.4 -out_NT {output.codons} -out_AA {output.aa}"
#end rule
"""

rule macse:
    input:
        #input = rules.macse_trim.output.codons
        input = rules.get_codons.output.output
    output:
        codons = os.path.join(OUTDIR, "{GENE}.codons.fa"),
        aa     = os.path.join(OUTDIR, "{GENE}.aa.fa")
    shell:
        """
        macse -prog alignSequences -seq {input.input} -out_NT {output.codons} -out_AA {output.aa} -max_refine_iter 3 -local_realign_init 0.3 -local_realign_dec 0.2
        sed -i 's/!/N/g' {output.codons}
        """
#end rule

# Get rid of internal stop codons
rule cln:
   input:
       input = rules.macse.output.codons
   output:
       output = os.path.join(OUTDIR, "{GENE}.codons.cln.fa")
   shell:
       "{HYPHY} CLN Universal {input.input} 'No/No' {output.output}"
#end rule

rule strike_ambigs_msa:
   input:
       input_msa = rules.cln.output.output
   output:
       output = os.path.join(OUTDIR, "{GENE}.SA.codons.cln.fa")
   shell:
      "{HYPHY} {STRIKE_AMBIGS_BF} --alignment {input.input_msa} --output {output.output}"
#end rule

rule remove_duplicates_msa:
   input:
       input_msa = rules.strike_ambigs_msa.output.output
   output:
       output = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa")
   shell:
      "{HYPHY} {REMOVE_DUPS_BF} --msa {input.input_msa} --output {output.output} ENV='DATA_FILE_PRINT_FORMAT=9'"
#end rule

# =============================================================================
# IQ-TREE for ML tree inference
# =============================================================================

rule iqtree: # Unrooted
    input:
        codons_fas = rules.remove_duplicates_msa.output.output
    output:
        tree = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.treefile")
    shell:
        # "iqtree -s {input.codons_fas} -T AUTO -B 1000 --redo-tree"
        "iqtree -s {input.codons_fas} -T AUTO -B 1000"
#end rule iqtree

# =============================================================================
# Downsample for GARD
# =============================================================================

# Threshold needs a step up procedure
rule tn93_cluster:
    input:
        input = rules.remove_duplicates_msa.output.output
    output:
        output = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.json")
    shell:
        "tn93-cluster -f -o {output.output} -t 0.4 {input.input}" 
#end rule

rule cluster_to_fasta:
   input: 
       input = rules.tn93_cluster.output.output
   output:
       output = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta")
   shell:
       "python scripts/cluster_to_fasta.py -i {input.input} -o {output.output}"
#end rule

# =============================================================================
# Recombination detection
# =============================================================================

rule recombination:
    input:
        input = rules.cluster_to_fasta.output.output
    output:
        output   = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta.GARD.json"),
        bestgard = os.path.join(OUTDIR, "{GENE}.RD.SA.codons.cln.fa.cluster.fasta.best-gard")
    shell:
        #"mpirun --use-hwthread-cpus {HYPHYMPI} GARD --alignment {input.input} --rv GDD --output {output.output}"
        # --oversubscribe
        # "mpirun -np {PPN} {HYPHYMPI} GARD --alignment {input.input} --rv GDD --output {output.output}"
        "mpirun --use-hwthread-cpus {HYPHYMPI} GARD --alignment {input.input} --rv GDD --output {output.output}"
#end rule

# =============================================================================
# Split out GARD partitions
# Based on code originally written by Jordan Zehr, Ph.D.
# =============================================================================

rule ParseGARD:
    input:
        input  = rules.recombination.output.bestgard,
        msa    = rules.remove_duplicates_msa.output.output
    output:    
        output = os.path.join(OUTDIR, "{GENE}.1.codon.fas")
        #outputTree = os.path.join(OUTDIR, "{GENE}.1.codon.nwk")
    run:
        #label = {Label}
        GardParser(Label, input.input, input.msa)
    #end run
#end rule

# Infer a new tree.. in the next snakefile

# =============================================================================
# Lineages
# =============================================================================

rule GatherLineages:
    input:
        input_csv = CSV,
        tree      = rules.iqtree.output.tree
    params:
        email = Email,
        OUTDIR = OUTDIR
    output:
        output = os.path.join(OUTDIR,"{GENE}_Annotated.csv")
        # Also outputs .clade files
    run:
        Entrez.email = params.email
        df = pd.read_csv(input.input_csv)
        df.index += 1
        DATA_DICT = {}
        transcript_accessions = df['RefSeq Transcript accessions'].tolist()
        
        with open(input.tree, "r") as fh:
            TREE_NEWICK = fh.read()
        #end with
        
        DATA_DICT = ProcessLineages(transcript_accessions, DATA_DICT, TREE_NEWICK)
        df2 = pd.DataFrame.from_dict(DATA_DICT, orient="index")
        lineages = df2['LINEAGE'].tolist()
        
        # Default parameter, this is a cutoff for how many taxa to include in a clade-file,
        # meaning if a clade has less than this integer it is not included in the final annotated tree.
        num_taxa = 5
        
        print("# Optimizing clade labels")
        count = 0
        BreakOut = False

        while True:
            lineageColumn = get_LineageColumn(lineages, count)
            lineageSet = set(lineageColumn)
            CountsLineageSet = []
            for animal in lineageSet:
                setCount = lineageColumn.count(animal)
                CountsLineageSet.append(setCount)
                #print(animal, setCount)
            #end for
            
            if min(CountsLineageSet) <= 5:
                break
            #end if
            
            count += 1
        #end while

        df2["CladeLabel"] = ""
        
        for index, row in df2.iterrows():
            #print(row['c1'], row['c2'])
            lineage = row['LINEAGE']
            for item in lineage:
                if item in lineageSet:
                    df2["CladeLabel"][index] = item
                #end if
            #end for
        #end for
                  
        print("# Saving Lineages:", output.output)
        df2.to_csv(output.output)
        
        # Output .clade files
        for index, row in df2.iterrows():
            leaf  = row["LEAFNAME"]
            CladeLabel = row["CladeLabel"]
            
            with open(os.path.join(OUTDIR, CladeLabel + ".clade"), "a") as fh:
                fh.write(str(leaf) + "\n")
                fh.close()
            #end with
        #end for
    #end run
#end rule

# =============================================================================
# End of file
# =============================================================================

