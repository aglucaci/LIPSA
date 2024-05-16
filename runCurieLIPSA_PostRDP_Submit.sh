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
#snakemake \
#      -s Snakefile \
#      --cluster-config cluster.json \
#      --jobs 4 \
#      --rerun-incomplete \
#      --keep-going \
#      --latency-wait 300
#exit 0  

# Run Selection Analyses on recombination-free files
snakemake \
      -s Snakefile_Recombinants \
      --cluster-config cluster.json \
      --cluster "sbatch --partition=panda --job-name=lipsa --mem-per-cpu 8G --cpus-per-task=8 --time 168:00:00 --nodes=1 --output logs/slurm_%A_%a_%j.out --error logs/slurm_%A_%a_%j.err" \
      --jobs 8 \
      --rerun-incomplete \
      --keep-going \
      --reason \
      --latency-wait 300




exit 0

# End of file


