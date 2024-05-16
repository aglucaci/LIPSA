#!/bin/sh
# properties = {"type": "single", "rule": "iqtree", "local": false, "input": ["/athena/melnicklab/users/scratch/agl4001/AOC/results/GnathostomataBCL6/GnathostomataBCL6.RD.SA.codons.cln.fa"], "output": ["/athena/melnicklab/users/scratch/agl4001/AOC/results/GnathostomataBCL6/GnathostomataBCL6.RD.SA.codons.cln.fa.treefile"], "wildcards": {"GENE": "GnathostomataBCL6"}, "params": {}, "log": [], "threads": 1, "resources": {"mem_mb": 1000, "mem_mib": 954, "disk_mb": 1000, "disk_mib": 954, "tmpdir": "<TBD>"}, "jobid": 11, "cluster": {"cluster": "sbatch", "nodes": 1, "ppn": 16, "name": "panda", "walltime": "168:00:00"}}
cd /athena/melnicklab/users/scratch/agl4001/AOC && /home/agl4001/mambaforge/envs/AOC/bin/python3.10 -m snakemake --snakefile '/athena/melnicklab/users/scratch/agl4001/AOC/Snakefile' --target-jobs 'iqtree:GENE=GnathostomataBCL6' --allowed-rules 'iqtree' --cores 'all' --attempt 1 --force-use-threads  --resources 'mem_mb=1000' 'mem_mib=954' 'disk_mb=1000' 'disk_mib=954' --wait-for-files '/athena/melnicklab/users/scratch/agl4001/AOC/.snakemake/tmp.pvdu027r' '/athena/melnicklab/users/scratch/agl4001/AOC/results/GnathostomataBCL6/GnathostomataBCL6.RD.SA.codons.cln.fa' --force --keep-target-files --keep-remote --max-inventory-time 0 --nocolor --notemp --no-hooks --nolock --ignore-incomplete --rerun-triggers 'mtime' 'params' 'input' 'software-env' 'code' --skip-script-cleanup  --conda-frontend 'mamba' --wrapper-prefix 'https://github.com/snakemake/snakemake-wrappers/raw/' --latency-wait 300 --scheduler 'ilp' --scheduler-solver-path '/home/agl4001/mambaforge/envs/AOC/bin' --default-resources 'mem_mb=max(2*input.size_mb, 1000)' 'disk_mb=max(2*input.size_mb, 1000)' 'tmpdir=system_tmpdir' --mode 2 && touch '/athena/melnicklab/users/scratch/agl4001/AOC/.snakemake/tmp.pvdu027r/11.jobfinished' || (touch '/athena/melnicklab/users/scratch/agl4001/AOC/.snakemake/tmp.pvdu027r/11.jobfailed'; exit 1)

