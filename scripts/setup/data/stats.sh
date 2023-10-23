#!/usr/bin/env sh

if ! [ -v DATA_DIR ]; then
    echo "error: DATA_DIR variable not set, exiting"
    exit
fi

$REPO_DIR/$VENV_NAME/bin/python \
    $REPO_DIR/scripts/setup/data/stats.py

RETCODE=$?
if [ $RETCODE -ne 0 ]
then
    echo "error: python script returned nonzero code: $RETCODE"
    exit
fi
