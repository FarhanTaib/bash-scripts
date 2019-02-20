#!/bin/bash
###################################################################
# Script Name	: postgres_lib.sh                                                                                           
# Purpose     : My postgresql secret server bash library
# License       : license under GPL v3.0                                                                                         
# Author       	: Mohd Farhan Taib                                                
# Email         : mohdfarhantaib@gmail.com
# GitHub        : https://github.com/FarhanTaib                                    
###################################################################

readonly PG_LIB_DIR=$(dirname "$(readlink -f "$0")")
export PATH=$PATH:$PG_LIB_DIR

readonly PG_HOST=""
readonly PG_USER=""
readonly PG_DB=""

# .pgpass content format ==> HOSTNAME:5432:DBNAME:USERNAME:PASSWORD
# chmod 600 $PG_LIB_DIR/.pgpass

readonly PG_TOOL_S="PGPASSFILE=$PG_LIB_DIR/.pgpass psql -qtAX -h ${PG_HOST} -U ${PG_USER} -d ${PG_DB}"
readonly PG_TOOL_V="PGPASSFILE=$PG_LIB_DIR/.pgpass psql -h ${PG_HOST} -U ${PG_USER} -d ${PG_DB}"

#
# Function to get the last row content
# Passing parameters "col_name_1,col_name_2,...,col_name_N" "table_name"
#
function f_pg_get_lastrowcontent(){
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
# Function Search
# Passing parameters "col_name" "value" "table_name"
#
function f_pg_search(){
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



