# Qual exam curriculum learning experiment

Instructions for running the experiment:

## Contents

* <a href='#environment'>Environment</a>
* <a href='#data'>Data</a>
* <a href='#train-and-predict'>Train and predict</a>
* <a href='#monitor-progress'>Monitor progress</a>
* <a href='#archive-and-compress-results'>Archive and compress results</a>
* <a href='#visualize-results'>Visualize results</a>

<h2 id='environment'>Environment</h2>

### Debugging on a compute node

ssh into a Carbonate login node with
```sh
ssh <username>@carbonate.uits.iu.edu
```

For use with [Slurm](https://en.wikipedia.org/wiki/Slurm_Workload_Manager),
add the line
```sh
export ACCOUNT=<account_id>
```
to your `~/.bashrc` file, then run
```sh
. ~/.bashrc
```

Next request that a compute node be allocated to you
(this command can be saved in a shell script):
```sh
srun \
    --account=$ACCOUNT \
    --partition=gpu \
    --gres=gpu:1 \
    --nodes=1 \
    --time=12:00:00 \
    --pty bash
```
However, when eventually dispatching sbatch scripts,
make sure that this is done from a login node, because
doing it from a compute node will fail with a potentially difficult
to debug error message.

### Create venv and install dependencies

Clone the experiment repository:
```sh
git clone git@github.com:striebel/curriculum_learning_qual_experiment.git
```

Next, via
[Environment Modules](https://en.wikipedia.org/wiki/Environment_Modules_(software)),
load a recent version of Python 3:
```sh
module load python/3.9.8
```

cd into the cloned repo and
open `set_vars.sh` in a text editor and update the variables
as desired. Then run
```sh
. set_vars.sh
```

Run
```sh
scripts/setup/venv.sh
```
to create a Python virtual environment into which the parser will be installed
(or, more accurately, because the parser is not distributed as a Python package,
the parser will not be installed into the venv: just the parser's list of
dependencies will be installed, and later we will invoke the parser's train and
predict scripts directly with fully qualified paths).

A modified version of the Machamp parser is included in this repository at
[./parser/machamp-0.2](./parser/machamp-0.2).

Install the parser's dependencies with
```sh
scripts/setup/install.sh
```

<h2 id='data'>Data</h2>

First download the treebanks:
```sh
scripts/setup/data/download.bash
```
The above downloads both EWT and GUM, although in the experiments we only
used EWT.

Convert the treebanks from CONLLU format to CONLL, simplifying them, for example,
by removing multiword token summary lines:
```sh
scripts/setup/data/simplify.sh
```

Calculate the difficulty functions for each training sentence, and
add that information above each sentence in a comment, which will be
read during training by our custom data loader:
```sh
scripts/setup/data/preprocess.sh
```

Count and print the number of sentences in the train, dev, and test partitions
in EWT and GUM
```sh
scripts/setup/data/stats.sh
```
(The above script doesn't do anything other than print the stats to the terminal.)


<h2 id='train-and-predict'>Train and predict</h2>

Generate all the config files and scripts needed to both train the models and
run predict on the test data:
```sh
scripts/setup/generate_scripts.sh
```


Execute
```sh
scripts/train/ewt/train.sh
```
in order to submit all of the jobs to Slurm for training and running predict
on the test data.


<h2 id='monitor-progress'>Monitor progress</h2>

In total 396 models must be trained.
Once the `scripts/train/ewt/train.sh` script has been executed,
training progress can be monitored by running:
```sh
scripts/progress/check.sh
```

<h2 id='archive-and-compress-results'>Archive and compress results</h2>

Once all the models have finished training
and running inference on the test data,
execute the following script:
```sh
scripts/archive_and_compress/generate.sh
```

And then execute
```sh
sbatch scripts/archive_and_compress/results.sbatch
```

Run
```sh
squeue -u <username>
```
to observe when the script finishes running.


<h2 id='visualize-results'>Visualize results</h2>

See [https://github.com/striebel/qual\_exam\_curriculum\_learning\_charts](
https://github.com/striebel/qual_exam_curriculum_learning_charts).
This repo also provides a script for copying the tarred and gzipped
results directory to local.
