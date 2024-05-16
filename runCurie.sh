set -euo pipefail

# Downloading hyphy-analyses.
FOLDER="hyphy-analyses"
URL="https://github.com/veg/hyphy-analyses.git"

if [ ! -d "$FOLDER" ] ; then
    git clone "$URL" "$FOLDER"
fi

# Set up logs directory
LOGS="logs_curie"

if [ ! -d "$LOGS" ] ; then
    mkdir -p $LOGS
fi

printf "# Running AOC Snakemake pipeline \n"

# Initial phase, quality control, alignment, recombination-detection.
# Run Selection Analyses on recombination-free files
snakemake \
      -s Snakefile \
      --cluster-config cluster.json \
      --cluster "sbatch --partition=panda --job-name=aoc_curie --mem-per-cpu 8G --cpus-per-task=16 --time 168:00:00 --nodes=1 --output logs_curie/slurm_%A_%a_%j.out --error logs_curie/slurm_%A_%a_%j.err" \
      --jobs 8 \
      --rerun-incomplete \
      --keep-going \
      --latency-wait 300

#exit 0  

# Run Selection Analyses on recombination-free files
snakemake \
      -s Snakefile_Recombinants \
      --cluster-config cluster.json \
      --cluster "sbatch --partition=panda --job-name=aoc_curie --mem-per-cpu 8G --cpus-per-task=16 --time 168:00:00 --nodes=1 --output logs_curie/slurm_%A_%a_%j.out --error logs_curie/slurm_%A_%a_%j.err" \
      --jobs 8 \
      --rerun-incomplete \
      --keep-going \
      --reason \
      --latency-wait 300

exit 0

# End of file


