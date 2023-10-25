#!/usr/bin/env bash


if [ ! -v REPO_DIR ]
then
    echo 'error: REPO_DIR variable not set, exiting'
    exit 1
fi

if [ ! -v DATA_DIR ]
then
    echo 'error: DATA_DIR variable not set, exiting'
    exit 2
fi

if [ ! -v ACCOUNT ]
then
    echo 'error: slurm ACCOUNT variable not set, exiting'
    exit 3
fi


SCRIPT_FILE_PATH=${REPO_DIR}/scripts/archive_and_compress/results.bash
echo '#!/usr/bin/env bash'                            > ${SCRIPT_FILE_PATH} 
echo '(                                           \' >> ${SCRIPT_FILE_PATH}  
echo '    cd '${DATA_DIR}'/..                     \' >> ${SCRIPT_FILE_PATH} 
echo '    && tar czf `basename '${DATA_DIR}'`.tgz \' >> ${SCRIPT_FILE_PATH} 
echo '               `basename '${DATA_DIR}'`     \' >> ${SCRIPT_FILE_PATH} 
echo ')'                                             >> ${SCRIPT_FILE_PATH} 
chmod 700                                               ${SCRIPT_FILE_PATH} 


SBATCH_FILE_PATH=${REPO_DIR}/scripts/archive_and_compress/results.sbatch
LOGS_DIR_PATH=${REPO_DIR}/scripts/archive_and_compress/logs
mkdir --parents ${LOGS_DIR_PATH}
echo '#!/usr/bin/env sh'                        > ${SBATCH_FILE_PATH}
echo '#SBATCH --account '${ACCOUNT}            >> ${SBATCH_FILE_PATH}
echo '#SBATCH --job-name tar_czf'              >> ${SBATCH_FILE_PATH}
echo '#SBATCH --partition gpu'                 >> ${SBATCH_FILE_PATH}
echo '#SBATCH --output '${LOGS_DIR_PATH}'/out' >> ${SBATCH_FILE_PATH}
echo '#SBATCH --error  '${LOGS_DIR_PATH}'/err' >> ${SBATCH_FILE_PATH}
echo '#SBATCH --mail-type=ALL'                 >> ${SBATCH_FILE_PATH}
echo '#SBATCH --mail-user=jstrieb@indiana.edu' >> ${SBATCH_FILE_PATH}
echo '#SBATCH --gres=gpu:1'                    >> ${SBATCH_FILE_PATH}
echo '#SBATCH --nodes=1'                       >> ${SBATCH_FILE_PATH}
echo '#SBATCH --time=1-00:00:00'               >> ${SBATCH_FILE_PATH}
echo '#SBATCH --mem=128G'                      >> ${SBATCH_FILE_PATH}
echo '#SBATCH --cpus-per-task=1'               >> ${SBATCH_FILE_PATH}
echo 'srun '${SCRIPT_FILE_PATH}                >> ${SBATCH_FILE_PATH}






