set -euo pipefail

# Downloading hyphy-analyses.
FOLDER="hyphy-analyses"
URL="https://github.com/veg/hyphy-analyses.git"

if [ ! -d "$FOLDER" ] ; then
    git clone "$URL" "$FOLDER"
fi

# Set up logs directory
LOGS="logs"

if [ ! -d "$LOGS" ] ; then
    mkdir -p $LOGS
fi

printf "# Running LIPSA workflow \n"

#source 'conda activate AOC'

# Initial phase, quality control, alignment, recombination-detection.
# Run Selection Analyses on recombination-free files
snakemake \
      -s SnakefileLIPSA-MGA-develop \
      --cluster-config cluster.json \
      --jobs 4 \
      --rerun-incomplete \
      --keep-going \
      --latency-wait 300

exit 0  


# End of file


