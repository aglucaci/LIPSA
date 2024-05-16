
#srun -n1 --pty --partition=panda --mem=32G bash -i

srun --pty --cpus-per-task=16 --partition=panda --mem=32G bash -i


exit 0 
