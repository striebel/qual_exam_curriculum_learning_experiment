# Curriculum learning qual experiment

Instructions for running the experiment:

## Contents

* <a href='#environment'>Environment</a>
* <a href='#data'>Data</a>
* <a href='#train-and-predict'>Train and predict</a>
* <a href='#evaluate'>Evaluate</a>
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

First download the treebanks (UD EWT and GUM):
```sh
scripts/setup/data/download.bash
```

Convert the treebanks from CONLLU format to CONLL, simplifying them, for example,
by removing multiword token summary lines:
```sh
scripts/setup/data/simplify.sh
```

Generate a mapping from each sentence in EWT and GUM to its source domain
by inspecting each sentence's metadata:
```sh
scripts/setup/data/annotate_domain.sh
```

Print domain statistics (the number of domains in EWT and in GUM and the
number of sentences in each domain) by running the following script, but this script
doesn't do anything other than print the stats to the terminal:
```sh
scripts/setup/data/stats.sh
```

This experiment uses 10-fold cross-validation and the folds that were previously used
are included in the `<repo_root>/folds` dir.
However, folds can be regenerated by running the following script:
```sh
scripts/setup/data/make_folds.sh
```
Running the above scripts will 
randomly select the data that will be used in the experiments.
1,000 sentences are selected from each of the five domains in EWT.
GUM has 11 domains, but only five of them have more than 1,000
sentences, so these five domains are used and 1,000 sentences are
randomly selected from each.
The result is ten domains with 1,000 sentences each,
so 10,000 sentences
total are available to create train, dev, and test partitions.
The script `make_folds.sh` will do nothing if the dir
`$REPO_DIR/folds` already exists, so if you would like to randomly
select a new set of sentences to use in the experiments,
`rm -rf $REPO_DIR/folds` should be run first.
(The name `make_folds` may be kind of misleading, because
the script only makes the folds indirectly; that is,
it samples 10,000 sentences as described above and gives them
a specific order with the partition points for the folds later
used between indices being:
999 and 1000; 1999 and 2000; ...; 8999 and 9000; 9999 and 0.)

Then actually generate the ten folds of train, dev, and test conllu files with
the following:
```sh
scripts/setup/data/generate_conllu_files.sh
```

<h2 id='train-and-predict'>Train and predict</h2>

Generate all the config files and scripts needed to both train the models and
run predict on the test data:
```sh
scripts/setup/generate_scripts.sh
```

Execute
```sh
scripts/train/dispatch_all.sh
```
in order to submit all of the jobs to Slurm for training and running predict
on the test data.

If debugging debugging is required, first try executing one of the individual
model scripts; for example:
```sh
scripts/train/answer/010/a.sh
```

Then try submitting a slurm job which will run the train script for all ten
folds for a certain proportion; for example:
```sh
sbatch scripts/train/answer/010.sbatch
```

Check the status of the job with
```sh
squeue -u <username>
```
(Make sure that you submit the job from a login node and not a compute
node, because doing the latter will produce a hard-to-debug failure.)

One can dispatch all the slurm jobs for a given domain (all 21 proportions):
```sh
scripts/train/answer_dispatch.sh
```

And then all the jobs can be submitted with the already mentioned script:
```sh
scripts/train/dispatch_all.sh
```

<h2 id='evaluate'>Evaluate</h2>

Execute
```sh
scripts/eval/eval_c.sh
```
followed by
```sh
scripts/eval/eval_d.sh
```

Then archive and compress the `$RSLT_DIR` dir and copy it to your local
machine.
The tar and gzip part can be done by executing
```sh
scripts/eval/generate_archive_and_compress_script.sh
```
followed by
```sh
sbatch scripts/eval/archive_and_compress_results.sbatch
```

<h2 id='visualize-results'>Visualize results</h2>

See [https://github.com/striebel/domain\_adaptation\_charts](
https://github.com/striebel/domain_adaptation_charts).
This repo also provides a script for copying the tarred and gzipped
results directory to local.
