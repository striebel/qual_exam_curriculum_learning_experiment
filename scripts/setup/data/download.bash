#!/usr/bin/env bash


# Download the three partitions for EWT and GUM
# and make copies for use in the next script,
# which will rewrite the copies in place


RELEASE="r2.12"

if ! [ -v DATA_DIR ]; then
    echo "variable DATA_DIR not set, exiting"
    exit
fi

for treebank in 'ewt' 'gum'
do
    raw_dir=${DATA_DIR}/treebanks/${treebank}/raw
    clean_dir=${DATA_DIR}/treebanks/${treebank}/clean
    
    rm -rf $raw_dir
    rm -rf $clean_dir
    
    mkdir --parents $raw_dir
    mkdir --parents $clean_dir
    
    all_name='all.conllu'
    printf '' > ${raw_dir}/${all_name}
    
    for data_partition_name in "test" "dev" "train"
    do
        raw_name=${data_partition_name}.conllu
        wget \
            --output-document ${raw_dir}/${raw_name} \
            $(
    	        echo \
    	            "https://raw.githubusercontent.com/UniversalDependencies/UD_English-${treebank^^}/" \
    	            "${RELEASE}/en_${treebank}-ud-${data_partition_name}.conllu" \
    	        | tr -d " ","\n"
    	    )
        cat ${raw_dir}/${raw_name} >> ${raw_dir}/${all_name}
        cp ${raw_dir}/${raw_name} ${clean_dir}/${clean_name}
    done
    cp ${raw_dir}/${all_name} ${clean_dir}/${all_name}
done
