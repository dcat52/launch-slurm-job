echo "JN, ARGS, SUBDIR" > hpc/param_files/sleep_tasks.csv
parallel echo {0#}, --param {1} --seed {2}, p_{1} ::: {0..3} ::: {1..10} >> hpc/param_files/sleep_tasks.csv
