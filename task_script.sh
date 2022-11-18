#!/bin/bash

SECONDS=0

# Parse parameters into variables
SLURM_JOB_ID=$1
task_num=$2
args=$3
task_path=$4

# Initial setup
mkdir -p ${task_path}
echo "Submitting # ${task_num}"

# Redirect stdout and stderr to std.out
exec 11<&1
exec 12<&2
exec &>${task_path}/std.out

# Here we print some general details
echo subtask of job ${SLURM_JOB_ID}
echo task: ${task_num} seq: ${PARALLEL_SEQ} host: $(hostname) date: $(date)
echo args: ${args}
echo task loc: ${task_path}

tmp_dir="/dev/shm/${USER}_${SLURM_JOB_ID}_${task_num}"
task_dir="${task_path}"

mkdir ${tmp_dir}

# Source a set of exit codes
source ./hpc/exit_codes.sh

function cleanup()
{
    # Log that cleanup is beginning
    echo "Cleaning up task"

    # Log the exit reason
    exit_reason=$1
    echo "Exit Reason: ${exit_reason}"

    # Perform cleanup
    mv ${tmp_dir}/* ${task_dir}
    rm -rf ${tmp_dir}

    # Redirect stdout and stderr to where they belong
    exec 1<&11
    exec 2<&12

    # Log a final message
    echo "Done # ${task_num}"

    # Exit the task
    exit ${exit_reason}
}

# Trap(s)
trap 'cleanup ${ERROR_TIME_LIMIT}' $ERROR_TIME_LIMIT
trap 'cleanup 1' TERM

# Run Task
# ==================================================
echo "hello world!" > ${tmp_dir}/hello.txt
echo "Beginning Sleep. Zzzzz."
# Sleep a random amount of time 10-15 sec
sleepsecs=$[ ( $RANDOM % 5 ) + 10 ]s
sleep $sleepsecs
echo "Ahh, well rested!"
# ==================================================

# Write how long the execution took
echo "Time Running (s): ${SECONDS} for task ${task_num}"

# Run cleanup function
cleanup
