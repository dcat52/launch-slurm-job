# Launch Slurm Job

## Components
```
|-- README.md
|-- launch_job.sbatch
|-- task_script.sh
|-- exit_codes.sh
|-- generate_params.sh
|-- param_files
    `-- sleep_tasks.csv
```

- `launch_job.sbatch` is the core component. Used for launching the job on the HPC
- `task_script.sh` is called by `launch_job.sbatch` in a parallel distributed manner, once for each subtask
- `exit_codes.sh` is sourced by `launch_job.sbatch`. It contains some default exit codes and can be populated with more. These are used by the `trap` command
- `generate_params.sh` is used before running a job to create the parameter list
- `sleep_tasks.csv` is generated with from `generate_params.sh` and then referenced by `launch_job.sbatch` for each subtask

## How to Use
- Follow the Parallel config setup below (only needed once)
- Copy contents of repository into `my_project/hpc`
- Create a `my_project/runs` directory
- Modify `task_script.sh` with the necessary task components
- Generate a relevant set of parameters by modifying and executing `generate_params.sh`
- Modify the sbatch options at top of `launch_job.sbatch`
- Run launch job

## Running launch_job
```Bash
sbatch hpc/launch_job.sbatch param_file [unique_name]
sbatch hpc/launch_job.sbatch hpc/param_files/sleep_tasks.csv sleep_1
```


## Setting up and using Parallel (GNU)

### Adding parallel config
Create this file: `~/.parallel/config`

Add the following line:
```C++
--rpl '{0#} 1 $f=1+int((log(total_jobs())/log(10))); $_=sprintf("%0${f}d",seq())'
```

### Generating a CSV
To generate a csv to run jobs, do something like this (Note: the `{0#}` requires the configuration above or aditional arguments):
```C++
echo "JN, ARGS, SUBDIR" > example_sleep_tasks.csv
parallel echo {0#}, --param {1} --seed {2}, p_{1} ::: {0..3} ::: {1..10} >> example_sleep_tasks.csv
```

### Leveraging the CSV file
The CSV file is directly used by `launch_job.sbatch` but the for illustrative purposes, the CSV can be used like so:
```C++
parallel --header : --colsep ', ' echo JOB: {JN}    ARGS: {ARGS}    SUBDIR: {SUBDIR} :::: example_sleep_tasks.csv
```

With this method, the parameters are defined at dataset generation time, not at script runtime. This means any parameter not mentioned will take the default (except for few that may be explicitly defined in the task script).