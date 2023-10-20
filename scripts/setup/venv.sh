#!/usr/bin/env bash

if [ ! -v REPO_DIR ]; then
    echo "ERROR: REPO_DIR is not set, exiting"
    exit
fi

if [ ! -v VENV_NAME ]; then
    echo "ERROR: VENV_NAME is not set, exiting"
    exit
fi

if [ -v VIRTUAL_ENV ]; then
    echo "ERROR: Another virtual environment is active, exiting"
    exit
fi

if [ -d "$REPO_DIR/$VENV_NAME" ]; then
    echo "ERROR: The specified virtual environment directory to create already exists, exiting"
    exit
fi

if [ ! -v PYTHON_VERSION ]; then
    echo "ERROR: PYTHON_VERSION is not set, exiting"
    exit
fi

if [ "$PYTHON_VERSION" != "`python -V`" ]; then
    echo "ERROR:"
    echo "    expected python version ${PYTHON_VERSION}"
    echo "    but got version         `python -V`"
    exit
fi

python -m venv $REPO_DIR/$VENV_NAME
