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
                    MODEL_NAME=model__${tb}__${df}__${cf}__${cd}__${tr}
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
                    echo '#!/usr/bin/env sh'                                                                   > ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '# build the config file'                                                            >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                          \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}/scripts/utils/translate_jsonnet_to_json.py' \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${REPO_DIR}/configs/src/params.jsonnet'             \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${PARAMS_CONFIG_FILE_PATH}                                                 >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: build config file failed"'                                         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    echo '# train the model'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                          \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}/parser/machamp-${MACHAMP_VERSION}/train.py' \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--name' '${MODEL_NAME}'                             \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--dataset_config'      '${DATA_CONFIG_FILE_PATH}'   \'                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '--parameters_config' '${PARAMS_CONFIG_FILE_PATH}'   \'                     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '--device' '0'                                        '                     >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: training the model failed"'                                        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    PREDICTIONS_DIR_PATH=${DATA_DIR}/treebanks/${tb}/predictions/${df}/${cf}/${cd}/${tr}
                    echo '# run predict on the test data'                                                     >> ${TRAIN_SCRIPT_FILE_PATH}  
                    echo 'mkdir --parents '${PREDICTIONS_DIR_PATH}                                            >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'MODEL_DIR_NAME=`ls -1 '${REPO_DIR}'/logs/'${MODEL_NAME}' | tail -n 1`'              >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'MODEL_DIR_PATH='${REPO_DIR}'/logs/'${MODEL_NAME}/'${MODEL_DIR_NAME}'                >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'MODEL_FILE_PATH=${MODEL_DIR_PATH}/model.tar.gz'                                     >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'echo "info: MODEL_DIR_NAME : ${MODEL_DIR_NAME}"'                                    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'echo "info: MODEL_DIR_PATH : ${MODEL_DIR_PATH}"'                                    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'echo "info: MODEL_FILE_PATH: ${MODEL_FILE_PATH}"'                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                                       \'        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    '${REPO_DIR}/parser/machamp-${MACHAMP_VERSION}/predict.py'            \'        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        ${MODEL_FILE_PATH}                                                \'        >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${DATA_DIR}/treebanks/${tb}/clean/test.conllu'                   \'        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '${PREDICTIONS_DIR_PATH}/test.conllu'                             \'        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '--device' '0                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: predicting with the model failed"'                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    echo '# save the per-epoch training progress before deleting the model dir'               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'cp                                                                     \'           >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${REPO_DIR}'/logs/'${MODEL_NAME}'/${MODEL_DIR_NAME}/metrics*.json \'           >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '    '${PREDICTIONS_DIR_PATH}/'                                         '            >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: copying the per-epoch log files failed"'                           >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    echo '# delete the model since we can not afford to keep hundreds of 850M models on disk' >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'rm -rf ${MODEL_DIR_PATH}'                                                           >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: deleting the model failed"'                                        >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    echo '# run the official ud eval script'                                                  >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo ${REPO_DIR}/${VENV_NAME}/bin/python'                                           \'    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    '${REPO_DIR}/scripts/ud_tools/eval.py'                                    \'    >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '        '${DATA_DIR}/treebanks/${tb}/clean/test.conllu'                       \'    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        '${PREDICTIONS_DIR_PATH}/test.conllu'                                 \'    >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo '        > '${PREDICTIONS_DIR_PATH}/test.txt                                         >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo ''                                                                                   >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'RETCODE=$?'                                                                         >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'if [ 0 -ne $RETCODE ]'                                                              >> ${TRAIN_SCRIPT_FILE_PATH} 
                    echo 'then'                                                                               >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    echo "error: running the official UD eval script failed"'                       >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo '    exit $RETCODE'                                                                  >> ${TRAIN_SCRIPT_FILE_PATH}
                    echo 'fi'                                                                                 >> ${TRAIN_SCRIPT_FILE_PATH}
                    
                    chmod 700                                                                                    ${TRAIN_SCRIPT_FILE_PATH}
                done
                
                TRAIN_SCRIPT_CD_DIR_PATH=${REPO_DIR}/scripts/train/${tb}/${df}/${cf}/${cd}
                TRAIN_SCRIPT_CD_FILE_PATH=${TRAIN_SCRIPT_CD_DIR_PATH}/train.sh
                echo '#!/usr/bin/env sh'                                 > ${TRAIN_SCRIPT_CD_FILE_PATH}
                echo ''                                                 >> ${TRAIN_SCRIPT_CD_FILE_PATH} 
                echo '# training run'                                   >> ${TRAIN_SCRIPT_CD_FILE_PATH}
                echo 'for tr in "a"'                                    >> ${TRAIN_SCRIPT_CD_FILE_PATH}
                echo 'do'                                               >> ${TRAIN_SCRIPT_CD_FILE_PATH}
                echo '    '${TRAIN_SCRIPT_CD_DIR_PATH}/'${tr}'/train.sh >> ${TRAIN_SCRIPT_CD_FILE_PATH}
                echo 'done'                                             >> ${TRAIN_SCRIPT_CD_FILE_PATH}
                chmod 700                                                  ${TRAIN_SCRIPT_CD_FILE_PATH}  
            done
            
            TRAIN_SCRIPT_CF_DIR_PATH=${REPO_DIR}/scripts/train/${tb}/${df}/${cf}
            TRAIN_SCRIPT_CF_FILE_PATH=${TRAIN_SCRIPT_CF_DIR_PATH}/train.sh
            echo '#!/usr/bin/env sh'                                 > ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo ''                                                 >> ${TRAIN_SCRIPT_CF_FILE_PATH} 
            echo '# curriculum duration'                            >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo 'for cd in \'                                      >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "00_000" "02_500" "05_000" "07_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "10_000" "12_500" "15_000" "17_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "20_000" "22_500" "25_000" "27_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "30_000" "32_500" "35_000" "37_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "40_000" "42_500" "45_000" "47_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "50_000" "52_500" "55_000" "57_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "60_000" "62_500" "65_000" "67_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "70_000" "72_500" "75_000" "77_500" \'        >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    "80_000"'                                     >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo 'do'                                               >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo '    '${TRAIN_SCRIPT_CF_DIR_PATH}/'${cd}'/train.sh >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            echo 'done'                                             >> ${TRAIN_SCRIPT_CF_FILE_PATH}
            chmod 700                                                  ${TRAIN_SCRIPT_CF_FILE_PATH}
            
            TRAIN_SBATCH_CF_FILE_PATH=${TRAIN_SCRIPT_CF_DIR_PATH}/train.sbatch
            JOB_NAME=${tb}__${df}__${cf}
            mkdir --parents ${REPO_DIR}/logs/sbatch/${JOB_NAME}
            echo '#!/usr/bin/env sh'                                  > ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --account '${ACCOUNT}                      >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --job-name '${JOB_NAME}                    >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --partition gpu'                           >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --output '${REPO_DIR}/logs/${JOB_NAME}/out >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --error  '${REPO_DIR}/logs/${JOB_NAME}/err >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --mail-type=ALL'                           >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --mail-user=jstrieb@indiana.edu'           >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --gres=gpu:1'                              >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --nodes=1'                                 >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --time=1-00:00:00'                         >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --mem=128G'                                >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo '#SBATCH --cpus-per-task=1'                         >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo 'module load python/3.9.8'                          >> ${TRAIN_SBATCH_CF_FILE_PATH}
            echo 'srun '${TRAIN_SCRIPT_CF_FILE_PATH}                 >> ${TRAIN_SBATCH_CF_FILE_PATH}
        done
        
        TRAIN_SCRIPT_DF_DIR_PATH=${REPO_DIR}/scripts/train/${tb}/${df}
        TRAIN_SCRIPT_DF_FILE_PATH=${TRAIN_SCRIPT_DF_DIR_PATH}/train.sh
        echo '#!/usr/bin/env sh'                                              > ${TRAIN_SCRIPT_DF_FILE_PATH}
        echo 'for cf in "linear" "fancy"'                                    >> ${TRAIN_SCRIPT_DF_FILE_PATH} 
        echo 'do'                                                            >> ${TRAIN_SCRIPT_DF_FILE_PATH}
        echo '    'sbatch' '${TRAIN_SCRIPT_DF_DIR_PATH}/'${cf}'/train.sbatch >> ${TRAIN_SCRIPT_DF_FILE_PATH}
        echo 'done'                                                          >> ${TRAIN_SCRIPT_DF_FILE_PATH}
        chmod 700                                                               ${TRAIN_SCRIPT_DF_FILE_PATH}
    done
    
    TRAIN_SCRIPT_TB_DIR_PATH=${REPO_DIR}/scripts/train/${tb}
    TRAIN_SCRIPT_TB_FILE_PATH=${TRAIN_SCRIPT_TB_DIR_PATH}/train.sh
    echo '#!/usr/bin/env sh'                                 > ${TRAIN_SCRIPT_TB_FILE_PATH}
    echo ''                                                 >> ${TRAIN_SCRIPT_TB_FILE_PATH}
    echo 'for df in                           \'            >> ${TRAIN_SCRIPT_TB_FILE_PATH} 
    echo '    "len_in_words" "len_in_chars"   \'            >> ${TRAIN_SCRIPT_TB_FILE_PATH}
    echo '    "dep_len"      "dep_len_norm"   \'            >> ${TRAIN_SCRIPT_TB_FILE_PATH}
    echo '    "n_deprels"    "n_deprels_norm"  '            >> ${TRAIN_SCRIPT_TB_FILE_PATH}  
    echo 'do'                                               >> ${TRAIN_SCRIPT_TB_FILE_PATH} 
    echo '    '${TRAIN_SCRIPT_TB_DIR_PATH}/'${df}'/train.sh >> ${TRAIN_SCRIPT_TB_FILE_PATH}  
    echo 'done'                                             >> ${TRAIN_SCRIPT_TB_FILE_PATH}  
    chmod 700                                                  ${TRAIN_SCRIPT_TB_FILE_PATH}
done





