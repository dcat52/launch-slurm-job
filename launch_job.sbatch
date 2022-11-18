#!/bin/bash

# Direct std output here
#SBATCH --output=./runs/slurm_%j_out

# Direct std error here (defaults to same as output if not specified)
#SBATCH --error=./runs/slurm_%j_err

# Use `sinfo` to see available partitions (quick, short, long)
#SBATCH --partition=short

# Send signal 5, 300 seconds before job time limit
#SBATCH --signal=5@300

# Hoe much memory per CPU core, note this has upper bounds
#SBATCH --mem-per-cpu=2500M

# Job time limit days-hrs:min:sec
#SBATCH --time=0-00:7:00

# CPU cores per task
#SBATCH --cpus-per-task=1

# Number of tasks to run at once
#SBATCH --ntasks=5

#
# Usage:
#     sbatch hpc/launch_job.sbatch param_file [unique_name]
#     sbatch hpc/launch_job.sbatch hpc/param_files/sleep_tasks.csv sleep_1
#

# Parse parameters into variables
param_file=$1
simple_name=$2

# Setup the storage directory
time=`date +%Y.%m.%d`
store_dir=./runs/${time}__${simple_name}

# Check if directory name is used, if so, add `_1`, `_2`, etc
count=0
TEMP=${store_dir}
while [ -d "${TEMP}" ] 
do
    echo "Directory ${store_dir} exists, attempting to increment." 
    count=$((count+1))
    TEMP=${store_dir}_${count}
done
store_dir=${TEMP}

# Make the valid directory
mkdir -p ${store_dir}

# Source a set of exit codes
source ./hpc/exit_codes.sh

function cleanup()
{
    # Log that cleanup is beginning
    echo "Cleaning up job!"

    # Log the exit reason
    exit_reason=$1
    echo "Exit Reason: ${exit_reason}"

    # Wait for all children
    wait

    # Cleanup the runs folder for future jobs
    mv runs/slurm_${SLURM_JOB_ID}_out $store_dir/std.out
    mv runs/slurm_${SLURM_JOB_ID}_err $store_dir/std.err
    mv runs/slurm_${SLURM_JOB_ID}_log $store_dir/job.log

    # Exit the entire job
    exit ${exit_reason}
}

# Trap(s)
trap 'cleanup ${ERROR_TIME_LIMIT}' ${ERROR_TIME_LIMIT}
trap 'cleanup 1' ERR

# Load the default version of GNU parallel.
module load parallel

# Increase the user process limit
ulimit -n `ulimit -Hn`

# Setup parallel tmpdir
parallel_tmpdir=${HOME}/.parallel_tmpdir
mkdir -p ${parallel_tmpdir}

# Setup srun command (the slurm run of each task)
srun="srun --exclusive -N1 -n1 -c ${SLURM_CPUS_PER_TASK}"

# Commonly modified:
# Setup where the data for that task will be stored
task_dir="${store_dir}/{SUBDIR}/{JN}"

# Commonly modified:
# Setup some task
my_task="./hpc/task_script.sh ${SLURM_JOB_ID} {JN} {ARGS} ${task_dir}"

# To kill running tasks, use `--halt now,fail=1`
# To let running tasks finish, use `--halt soon,fail=1`
# Setup parallel to allow many tasks (parallel jobs) to be run simultaneously.
parallel="parallel --header : --line-buffer -j ${SLURM_NTASKS} --halt now,fail=1 --joblog runs/slurm_${SLURM_JOB_ID}_log"

# Do final printouts before running
echo "Using file ${param_file}"
echo "Running ${SLURM_NTASKS} jobs at once."

# Start the tasks with the parallel command, keep track of how long it takes to run the entire job
SECONDS=0
$parallel --colsep ', ' "$srun $my_task" :::: ${param_file}
echo "Time running the job (s): ${SECONDS}"

# Run cleanup function
cleanup
