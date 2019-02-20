#!/bin/bash
###################################################################
# Script Name	: postgres_lib.sh                                                                                           
# Purpose	: My postgresql secret server bash library
# License       : license under GPL v3.0                                                                                         
# Author       	: Mohd Farhan Taib                                                
# Email         : mohdfarhantaib@gmail.com
# GitHub        : https://github.com/FarhanTaib                                    
###################################################################

## Credential form template for "../.pgpass"
# HOSTNAME:5432:DBNAME:USERNAME:PASSWORD
## chmod 600 $PG_LIB_DIR/.pgpass

# Initialize variable
readonly PG_LIB_DIR=$(dirname "$(readlink -f "$0")")
export PATH=$PATH:$PG_LIB_DIR
readonly PG_PASS="$PG_LIB_DIR/.pgpass"

function f_pg_prechecks(){
    if [ ! -f "$PG_PASS" ]; then
        printf "[%s] %s ERROR: Postgres credential (.pgpass) not found ($PG_PASS).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        printf "[%s] %s ERROR: Use below format:\nHOSTNAME:5432:DBNAME:USERNAME:PASSWORD\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
    if [ $(stat -c '%a' $PG_PASS) -ne 600 ]; then
        printf "[%s] %s ERROR: .pgpass permission is not correct. It must be in 600 ($PG_PASS).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
    if [[ -f "$PG_PASS" && $(basename -- "$(readlink -f -- "$PG_PASS")") == ^. ]]; then
        printf "[%s] %s ERROR: .pgpass must be hidden (ex: .pgpass).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
    if [ -z $PG_HOST ] || [ -z $PG_USER ] || [ -z $PG_DB ]; then
       printf "[%s] %s ERROR: Below variable need to be declared first in your main script.\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
       printf "\nPG_HOST=\"\"\nPG_USER=\"\"\nPG_DB=\"\"\n\n"
       exit 1
    fi
}
f_pg_prechecks

function f_pg_chkparms(){
    local array=( "$@" )
    local first_key=(${!array[@]})
    local last_key=(${#array[-1]})
    local last_key_val=(${array[-1]})
    local sum_key=(${#array[@]})
    local actual_arg_sum=$((${sum_key}-1))
    if [[ -z "$@" ]]; then
        printf "[%s] %s ERROR: Function ${FUNCNAME[1]}() requires arguments.\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    elif [ $actual_arg_sum -ne $last_key_val ]; then
        printf "[%s] %s ERROR: Function ${FUNCNAME[1]}() requires $last_key_val arguments.\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
    fi
}

readonly PG_TOOL_S="PGPASSFILE=$PG_PASS psql -qtAX -h ${PG_HOST} -U ${PG_USER} -d ${PG_DB}"
readonly PG_TOOL_V="PGPASSFILE=$PG_PASS psql -h ${PG_HOST} -U ${PG_USER} -d ${PG_DB}"

#
# Function to get the last row content
# Passing parameters "col_name_1,col_name_2,...,col_name_N" "table_name"
#
function f_pg_get_lastrowcontent(){
        f_pg_chkparms "${@}" "2"
	local _columns=${1}
	local _table_name=${2}
	eval $PG_TOOL_S<<EOF
SELECT ${_columns} FROM ${_table_name} ORDER BY id DESC LIMIT 1;
EOF
}
#
# Example:
# f_pg_get_lastrowcontent "uid" "public.ldap_user_ids"

#
# Function add new row
# Passing parameters "(col_name_1,col_name_2,...,col_name_N)" "(values)" "table_name"
#
function f_pg_add_newrow(){
        f_pg_chkparms "${@}" "3"
	local _columns=${1}
	local _values=${2}
	local _table_name=${3}
	eval $PG_TOOL_V<<EOF
INSERT INTO public.${_table_name} ${_columns}
VALUES ${_values};
EOF
}
#
# Example:
# f_pg_add_newrow "(\"user\",uid,gid,unix_local,full_name)" "('TESTUSR1',13677,1,true,'Test row 1')" "public.ldap_user_ids"
#

#
# Function Search
# Passing parameters "col_name" "value" "table_name"
#
function f_pg_search(){
        f_pg_chkparms "${@}" "3"
	local _column=${1}
	local _value=${2}
	local _table_name=${3}
	eval $PG_TOOL_V<<EOF
SELECT * FROM ${_table_name}
WHERE ${1} = '${_value}';
EOF
}
#
# Example:
# f_pg_search "\"user\"" "MYJHDM8" "public.ldap_user_ids"
#
