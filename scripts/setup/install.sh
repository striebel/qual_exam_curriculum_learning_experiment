#!/usr/bin/env bash

if [ ! -v MACHAMP_VERSION ]; then
    echo "ERROR: MACHAMP_VERSION not set, exiting"
    exit
fi

if [ ! -v REPO_DIR ]; then
    echo "ERROR: REPO_DIR not set, exiting"
    exit
fi

if [ ! -v VENV_NAME ]; then
    echo "ERROR: VENV_NAME not set, exiting"
    exit
fi

$REPO_DIR/$VENV_NAME/bin/python -m pip install \
    "allennlp==1.3" \
    "transformers==4.0.0" \
    "torch==1.7.1" \
    "networkx" \
    "jsonnet" \
    "conllu" \
    "statsmodels" \
    "mlxtend"

