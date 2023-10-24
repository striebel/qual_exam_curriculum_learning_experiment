#!/usr/bin/env bash


if [ ! -v DATA_DIR ]
then
    echo 'error: DATA_DIR variable not set, exiting'
    exit
fi

if [ ! -v REPO_DIR ]
then
    echo 'error: REPO_DIR variable not set, exiting'
    exit
fi

if [ ! -v VENV_NAME ]
then
    echo 'error: VENV_NAME variable not set, exiting'
    exit
fi

if [ ! -v ACCOUNT ]
then
    echo 'error: slurm ACCOUNT variable not set, exiting'
    exit
fi


# treebank
for tb in 'ewt' 'gum'
do
    # difficulty function 
    for df in 'len_in_words' 'len_in_chars' 'dep_len' 'dep_len_norm' 'n_deprels' 'n_deprels_norm'
    do
        # competence function
        for cf in 'linear' 'fancy'
        do
            # curriculum duration
            for cd in \
                '00_000' '02_500' '05_000' '07_500' \
                '10_000' '12_500' '15_000' '17_500' \
                '20_000' '22_500' '25_000' '27_500' \
                '30_000' '32_500' '35_000' '37_500' \
                '40_000' '42_500' '45_000' '47_500' \
                '50_000' '52_500' '55_000' '57_500' \
                '60_000' '62_500' '65_000' '67_500' \
                '70_000' '72_500' '75_000' '77_500' \
                '80_000'
            do
                # training run
                for tr in 'a'
                do
                    CONFIG_DIR_PATH=${REPO_DIR}/configs/bin/${tb}/${df}/${cf}/${cd}/${tr}
                    DATA_CONFIG_FILE_PATH=${CONFIG_DIR_PATH}/data.json
                    MODEL_NAME=model_${tb}_${df}_${cf}_${cd}_${tr}
                    mkdir --parents ${CONFIG_DIR_PATH}
                    echo '{'                                                                                              > ${DATA_CONFIG_FILE_PATH} 
                    echo '    "'${MODEL_NAME}'" : {'                                                                     >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        "train_data_path"      : "'${DATA_DIR}'/treebanks/'${tb}'/preprocessed/train.conllu",' >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        "validation_data_path" : "'${DATA_DIR}'/treebanks/'${tb}'/clean/dev.conllu",'          >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        "word_idx"             : 1,'                                                           >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        "tasks"                : {'                                                            >> ${DATA_CONFIG_FILE_PATH} 
                    echo '            "dependency_task_name" : {'                                                        >> ${DATA_CONFIG_FILE_PATH} 
                    echo '                "task_type"  : "dependency",'                                                  >> ${DATA_CONFIG_FILE_PATH} 
                    echo '                "column_idx" : 6'                                                              >> ${DATA_CONFIG_FILE_PATH} 
                    echo '            }'                                                                                 >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        },'                                                                                    >> ${DATA_CONFIG_FILE_PATH} 
                    echo '        "difficulty_function" : "'${df}'",'                                                    >> ${DATA_CONFIG_FILE_PATH}  
                    echo '        "competence_function" : "'${cf},${cd}'"'                                               >> ${DATA_CONFIG_FILE_PATH}  
                    echo '    }'                                                                                         >> ${DATA_CONFIG_FILE_PATH} 
                    echo '}'                                                                                             >> ${DATA_CONFIG_FILE_PATH} 
                    
                    PARAMS_CONFIG_FILE_PATH=${CONFIG_DIR_PATH}/params.json
                    TRAIN_SCRIPT_DIR_PATH=${REPO_DIR}/scripts/train/${tb}/${df}/${cf}/${cd}/${tr}
                    TRAIN_SCRIPT_FILE_PATH=${TRAIN_SCRIPT_DIR_PATH}/train.sh
                    mkdir --parents ${TRAIN_SCRIPT_DIR_PATH}
                    echo '#!/usr/bin/env sh'                                                                    > ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '# build the config file'                                                             >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                          \'                      >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}/scripts/utils/translate_jsonnet_to_json.py' \'                      >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${REPO_DIR}/configs/src/params.jsonnet'             \'                      >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${PARAMS_CONFIG_FILE_PATH}                                                  >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: build config file failed"'                                          >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '# train the model'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                                               \' >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}/parser/machamp-${MACHAMP_VERSION}/train.py'                      \' >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--name' '${MODEL_NAME}'                                                  \' >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--dataset_config'      '${DATA_CONFIG_FILE_PATH}'                        \' >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--parameters_config' '${PARAMS_CONFIG_FILE_PATH}'                        \' >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '--device' '0'                                                             ' >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: training the model failed"'                                         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '# run predict on the test data'                                                      >> ${TRAIN_SCRIPT_FILE_PATH}  
                    OUT_DIR_NAME=${DATA_DIR}/predictions/${domain}/${proportion}/${fold}
                    echo 'mkdir --parents '${OUT_DIR_NAME}                                                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'MODEL_DIR_NAME=`ls -1 '${REPO_DIR}'/logs/'${MODEL_NAME}' | tail -n 1`'               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                                           \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    '${REPO_DIR}/parser/machamp-${MACHAMP_VERSION}/predict.py'                \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '${REPO_DIR}/logs/${MODEL_NAME}/'${MODEL_DIR_NAME}'/model.tar.gz'     \'     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${DATA_DIR}/treebanks/folds/${fold}/test/${domain}.conllu'           \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '${OUT_DIR_NAME}/test.conllu'                                         \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '--device' '0                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: predicting with the model failed"'                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '# save the per epoch training progress before deleting the model dir'                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'mkdir --parents '${RSLT_DIR}/${domain}/${proportion}/${fold}                         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'cp                                                                     \'            >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}'/logs/'${MODEL_NAME}'/${MODEL_DIR_NAME}/metrics*.json \'            >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${RSLT_DIR}/${domain}/${proportion}/${fold}/'                      '            >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: copying the per-epoch log files failed"'                            >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '# delete the model since we can not afford to keep 2010 850M models on disk'         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'rm -rf '${REPO_DIR}/logs/${MODEL_NAME}/'${MODEL_DIR_NAME}'                           >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: deleting the model failed"'                                         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '# run the official ud eval script'                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                                           \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    '${REPO_DIR}/scripts/ud_tools/eval.py'                                    \'     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '${DATA_DIR}/treebanks/folds/${fold}/test/${domain}.conllu'           \'     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${OUT_DIR_NAME}/test.conllu'                                         \'     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        > '${RSLT_DIR}/${domain}/${proportion}/${fold}/test.txt                      >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'RETCODE=$?'                                                                          >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                               >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                                >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: running the official UD eval script failed"'                        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    chmod 700                                                                                     ${TRAIN_SCRIPT_FILE_PATH}
                done
            done
            
            echo '#!/usr/bin/env sh'                                                     > ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            echo ''                                                                     >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            echo 'for fold in "a" "b" "c" "d" "e" "f" "g" "h" "i" "j"'                  >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh 
            echo 'do'                                                                   >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            echo '    '${REPO_DIR}/scripts/train/${domain}/${proportion}/'${fold}'.sh   >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            echo 'done'                                                                 >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            chmod 700                                                                      ${REPO_DIR}/scripts/train/${domain}/${proportion}.sh
            
            mkdir --parents ${REPO_DIR}/logs/sbatch
            echo '#!/usr/bin/env sh'                                                     > ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --account '${ACCOUNT}                                         >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --job-name '${proportion}${domain}                            >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --partition gpu'                                              >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --output '${REPO_DIR}/logs/sbatch/${MODEL_NAME}.out           >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --error  '${REPO_DIR}/logs/sbatch/${MODEL_NAME}.err           >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --mail-type=ALL'                                              >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --mail-user=jstrieb@indiana.edu'                              >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --gres=gpu:1'                                                 >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --nodes=1'                                                    >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --time=1-00:00:00'                                            >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --mem=128G'                                                   >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo '#SBATCH --cpus-per-task=1'                                            >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo 'module load python/3.9.8'                                             >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
            echo 'srun '${REPO_DIR}/scripts/train/${domain}/${proportion}.sh            >> ${REPO_DIR}/scripts/train/${domain}/${proportion}.sbatch
        done
        
        echo '#!/usr/bin/env sh'                                                                      > ${REPO_DIR}/scripts/train/${domain}_dispatch.sh 
        echo ''                                                                                      >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh 
        echo 'for proportion in "000" "005" "010" "015" "020" "025" "030" "035" "040" "045"       \' >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh 
        echo '                  "050" "055" "060" "065" "070" "075" "080" "085" "090" "095" "100"  ' >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh
        echo 'do'                                                                                    >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh
        echo '    'sbatch ${REPO_DIR}/scripts/train/${domain}/'${proportion}'.sbatch                 >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh 
        echo 'done'                                                                                  >> ${REPO_DIR}/scripts/train/${domain}_dispatch.sh 
        chmod 700                                                                                       ${REPO_DIR}/scripts/train/${domain}_dispatch.sh
    done
done





