#!/bin/bash
###################################################################
# Script Name	  : utils_lib.sh                                                                                           
# Purpose	      : My standard bash function library
# License       : license under GPL v3.0                                                                                         
# Author       	: Mohd Farhan Taib                                                
# Email         : mohdfarhantaib@gmail.com                                           
###################################################################

# About:
# set LOGFILE to the full path of your desired logfile; make sure
# you have write permissions there. set RETAIN_NUM_LINES to the
# maximum number of lines that should be retained at the beginning
# of your program execution.
# execute 'logsetup' once at the beginning of your script, then
# use 'log' how many times you like.

# Requirement:
# Place below lines in your main script before using this utils library
# readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# readonly SCRIPT_NAME=$(basename -- "$(readlink -f -- "$0")")

# How to use:
# To use this log function just do f_log "your logs ${vars}"

RETAIN_NUM_LINES=100

if [ -z "$SCRIPT_DIR" ] || [ -z "$SCRIPT_NAME" ]; then
    readonly SCRIPT_NAME=$(basename ${BASH_SOURCE[1]})
    readonly LOGFILE=/tmp/${SCRIPT_NAME}.log
else
    readonly LOGFILE=$SCRIPT_DIR/${SCRIPT_NAME}.log
fi

function f_logsetup {
    TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}" > $LOGFILE
    exec > >(tee -a $LOGFILE)
    exec 2>&1
}   
f_logsetup

function f_log {
    echo "[$(date --rfc-3339=seconds)] ${SCRIPT_NAME} : $*"
}
