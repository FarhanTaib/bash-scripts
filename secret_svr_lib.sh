#!/bin/bash
###################################################################
# Script Name	: secret_svr_lib.sh                                                                                           
# Purpose	: My Tychotic secret server bash library
# License       : license under GPL v3.0                                                                                         
# Author       	: Mohd Farhan Taib                                                
# Email         : mohdfarhantaib@gmail.com
# GitHub        : https://github.com/FarhanTaib                                    
###################################################################

## Credential form template for "../.ty_credential":
# TY_USERNAME=
# TY_PASSWD=
# TY_URL=
# chmod 600 $TY_LIB_DIR/.ty_credential

## Remark:
# If the password have special characters refer this link on ASCII Hex code https://www.ascii.cl/htmlcodes.htm
# Example:
# if empersend "%" is equivalent to ASCII Hex "%25" ( p4ssw0rd%123 → p4ssw0rd%25123 )
# if exclamation mark "!" is equivalent to ASCII Hex "%21" ( p4ssw0rd!123 → p4ssw0rd%21123 )
# Or you may use postman to generate the curl code https://learning.getpostman.com/docs/postman/sending_api_requests/generate_code_snippets/

# Initialize variable
readonly TY_LIB_DIR=$(dirname "$(readlink -f "$0")")
export PATH=$PATH:$TY_LIB_DIR
readonly TY_CREDS="$TY_LIB_DIR/.ty_credential"
#readonly TY_SECRETID=""

function f_ty_prechecks(){
    if [ ! -f "${TY_CREDS}" ]; then
        printf "[%s] %s ERROR: Secret server credential not found (${TY_CREDS}).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        printf "[%s] %s ERROR: Use below format:\n\nTY_USERNAME=\"\"\nTY_PASSWD=\"\"\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        printf "TY_URL=\"\"\n\n"
        exit 1
    fi
    if [ $(stat -c '%a' ${TY_CREDS}) -ne 600 ]; then
        printf "[%s] %s ERROR: %s Permission is not correct. It must be in 600 (${TY_CREDS}).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
    if [[ -f ${TY_CREDS} && $(basename -- "$(readlink -f -- "${TY_CREDS}")") == ^. ]]; then
        printf "[%s] %s ERROR: %s It must be hidden (ex: .ty_credential).\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
    source ${TY_CREDS}
    if [ -z "$TY_USERNAME" ] || [ -z "$TY_PASSWD" ] || [ -z "$TY_URL" ]; then
        printf "[%s] %s ERROR: %s Credentials must not empty.\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
        exit 1
    fi
}
#f_ty_prechecks

function f_ty_chkparms(){
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

function f_ty_cleanup(){
    printf "[%s] %s INFO: %s Cleanup Tychotic function....\n" "$(date --rfc-3339=seconds)"  "${BASH_SOURCE[0]}"
    rm -vf /tmp/token.json
}

function f_ty_get_token(){
    curl -k -X POST \
    "${TY_URL}/oauth2/token" \
    -o '/tmp/token.json' \
    -d "username=${TY_USERNAME}&password=${TY_PASSWD}&grant_type=password&domain=NA&undefined="
}

function f_ty_get_passwd(){   # This function requires passing value: secret id/entry number
    local TY_SECRETID="${1}"
    f_ty_chkparms $TY_SECRETID "1"
    curl -k -X GET \
    "${TY_URL}/api/v1/secrets/${TY_SECRETID}/fields/password" \
    -H "Authorization: Bearer $(jq -r '.access_token' /tmp/token.json)"
}

function f_ty_list_fieldname(){ # This function requires passing value: secret id/entry number
    local TY_SECRETID="${1}"
    f_ty_chkparms $TY_SECRETID "1"
    curl -k -X GET \
    "${TY_URL}/api/v1/secrets/${TY_SECRETID}" \
    -H "Authorization: Bearer $(jq -r '.access_token' /tmp/token.json)"
}

function f_ty_downlod_key(){ # This function requires passing value: secret id/entry number
    local TY_SECRETID="${1}"
    f_ty_chkparms $TY_SECRETID "1"
    curl -k -X GET \
    "${TY_URL}/api/v1/secrets/${TY_SECRETID}/fields/private-key-file" \
    -o '/tmp/id_test_rsa' \
    -H "Authorization: Bearer $(jq -r '.access_token' /tmp/token.json)"
}
