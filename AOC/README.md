# Analysis Of Orthologous Collections (AOC)

`Alpha version 0.04 (2024)`

# About this repository

This repository expands on work oringally done for https://github.com/aglucaci/GeneInvestigator. A simple application to interrogate the molecular evolution of a single gene. AOC allows for the inclusion of recombination detection, a powerful force in shaping gene evolution and interpreting analytic results. As well, it allows for lineage assignment and annotation. This feature (lineage assignment) allows between group comparison of selective pressures.


## Installation and dependencies
This application is currently designed to run in an HPC environment due to the computational cost of selection analyse.

There is an assumption that the freely available Anaconda software is installed on your machine.

You will also need to download the standalone hyphy-analyses repository (https://github.com/veg/hyphy-analyses). Make sure to modify the config.yml file to point to the correct directory on your system

### To install -- Steps necessary to complete before running
1. `git clone https://github.com/aglucaci/AnalysisOfOrthologousCollections.git AOC`
2. `cd AOC`
3. `conda env create -f environment.yml`. This will create a virtual environment called (AOC) with the necessary dependencies.
    *NOTE* For those with arm64 CPU architecures (Apple M1/M2), compatibility errors may arise during installation with conda, in order to circumvent this issue try this command before creating the conda environment `conda config --env --set subdir osx-64`
4. At this point, run `conda activate AOC` and your environment will be ready to go.

## Data retrieval via NCBI Orthologs
Here, we rely on the NCBI Ortholog database. For example, if we are interested in the TP53 gene: https://www.ncbi.nlm.nih.gov/gene/7157/ortholog/?scope=117570&term=TP53

Download all information: Tabular data, RefSeq Transcripts, and RefSeq Protein. 

This is typically done as one gene per species, but all transcripts per species is also available.

## Pipeline

**Step 1.** Codon-aware alignment from protein and gene transcript files \
**Step 2.** Recombination detection (via GARD) \
**Step 3.** Tree inference (ML Tree inference, preferably IQ-TREE or RAxML). \
**Step 4.** Selection analyses: this includes (MEME, FEL, FUBAR, BUSTED Model testing, MEME, aBSREL, SLAC, BGM, FMM, etc) \
**Step 4.** Lineage assignment and tree annotation (Custom script) \
**Step 5.** Selection analyses on lineages (RELAX, CFEL) 

## Example dataset and results

### Preparation
As an example of the AOC pipeline, we explore the evolutionary history of the primate ACE2 protein. Data was accessed from NCBI via the Ortholog data base at https://www.ncbi.nlm.nih.gov/gene/59272/ortholog/?scope=9443&term=ACE2. Where, we downloaded FASTA files with RefSeq Transcripts and RefSeq Proteins (one sequence per specices) and metadata in tabular form (CSV))

This data was placed in the `data` folder using the `PrimateACE2` tag to create a `PrimateACE2` folder.  
Our data folder structure should look like this:

```
── data
│   ├── PrimateACE2
│   |   ├── ACE2_refseq_transcript.fasta
│   |   ├── ACE2_refseq_protein.fasta
│   |   ├── ACE2_orthologs.csv
```

We will ammend YAML formatted configuration file called `config.yml` file where the `Label` variable will also be `PrimateACE2`. We will also modify the `Nucleotide`, `Protein`, and `CSV` variables with the names of our downloaded data files.

Our `config.yml` file should look like this:

```
# User settings for data files and gene label

# Primate ACE2
Nucleotide: ACE2_refseq_transcript.fasta
Protein: ACE2_refseq_protein.fasta
CSV: ACE2_orthologs.csv
Label: PrimateACE2

# User settings for NCBI Entrez
EMAIL: "test@test.com"
```

We will ammend our cluster.json file to correspond to the number of available compute power for our system.

```
{"__default__": 
  {
  "cluster" : "qsub",
  "nodes": 1,
  "ppn": 4,
  "name": "epyc2"
}}
```

Most important, if you are running locally, modify the `ppn` variable, otherwise for HPC deployment check with your system administration for requirements or use your best judgement.

We can now execute our program with `bash run_AOC_Local.sh`

This command performs the entire analysis.

### Results
The following are JSON files produced by HyPhy analyses. These can be visualized by the appropriate module from HyPhy Vision (http://vision.hyphy.org/). Analysis file names contain the method used (SLAC, FEL, PRIME, FADE, MEME, CFEL, etc), and if appropriate -- the set of branches to which the analysis was applied.

```
── results/PrimateACE2
│   ├── PrimateACE2_codons.SA.fasta.FEL.json
│   ├── PrimateACE2_codons.SA.fasta.FUBAR.json
│   ├── PrimateACE2_codons.SA.fasta.MEME.json
│   ├── PrimateACE2_codons.SA.fasta.ABSREL.json
│   ├── PrimateACE2_codons.SA.fasta.SLAC.json
│   ├── PrimateACE2_codons.SA.fasta.BGM.json
│   ├── PrimateACE2_codons.SA.fasta.PRIME.json
│   ├── PrimateACE2_codons.SA.fasta.FMM.json
│   ├── PrimateACE2_codons.SA.fasta.ABSREL.json
|   ├── PrimateACE2_codons.SA.fasta.ABSRELS.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDSMH.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTED.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDMH.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDS.json
```

## Removing the AOC environment from conda
```conda env remove --name AOC```

## Starting a tmux session for AOC
```tmux new -s AOC ```
