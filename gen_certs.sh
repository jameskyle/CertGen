#!/bin/bash

###############################################################################
# NOTICE: This script is intended to be used in conjunction with a openssl.cnf
#         template such as this one: 
#         https://gist.github.com/jameskyle/8106d4d5c6dfa5395cef
# (C) Copyright 2014 James A. Kyle.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

set -ex
OPENSSL=${OPENSSL:-/usr/local/Cellar/openssl/1.0.1h/bin/openssl}
ROOT=${ROOT:-certs}
DOMAIN=${DOMAIN:-tfoundry.com}
COUNTRY=${COUNTRY:-US}
STATE=${STATE:-California}
CITY=${CITY:-Palo Alto}
ORG=${ORG:-AT&T}
UNIT=${UNIT:-Foundry}
EMAIL=${EMAIL:-jk328n@att.com}

SUBJECT_AlT_TYPE=DNS  # Other option is IP
if [[ ! -z $ALT_NAMES ]];then
    old_ifs=$IFS
    IFS=',' read -a ALT_NAMES <<< "$ALT_NAMES"
else
    declare -a ALT_NAMES=(
        "dock1.${DOMAIN}"
        "dock2.${DOMAIN}"
        "dock3.${DOMAIN}"
        "dock4.${DOMAIN}"
    )
fi


##############################################################################
# Should Not Need To Edit Below This Line 
##############################################################################

export ORG
export COUNTRY
export STATE
export EMAIL
export UNIT
export ROOT
export CITY

CONFIG_TEMPLATE=${CONFIG_TEMPLATE:-./templates/openssl.cnf.template}
CONFIG=${CONFIG:-/tmp/openssl.cnf}

cp ${CONFIG_TEMPLATE} ${CONFIG}

ALT_TAG="# ALT_NAMES"
for (( i = 0; i < ${#ALT_NAMES[@]}; i++ )); do
    count=$(($i + 1))
    sed -i.bak "s|^${ALT_TAG}|${SUBJECT_AlT_TYPE}.${count}=${ALT_NAMES[i]}\\
${ALT_TAG}|" ${CONFIG}
done


echo "Please provide a client id..."
read client_id

CLIENT_SUBJECT="/C=${COUNTRY}/ST=${STATE}/O=${ORG}/OU=${UNIT}/"
CLIENT_SUBJECT="${CLIENT_SUBJECT}CN=${client_id}.${DOMAIN}"

mkdir -p ${ROOT}

if [[ ! -e ${ROOT}/index.txt ]];then
    echo "Creating index file..."
    touch ${ROOT}/index.txt
fi

if [[ ! -e ${ROOT}/serial ]];then
    echo "Creating server keys..."
    echo 01 > ${ROOT}/serial
fi

if [[ ! -e ${ROOT}/ca.key ]];then
    echo "No certificate authority key found, creating key/cert pair...."
    ${OPENSSL} req -batch -nodes -new -x509 -keyout ${ROOT}/ca.key -out \
        ${ROOT}/ca.crt -days 3650 -config ${CONFIG} 2>&1 > /dev/null
fi

if [[ ! -e ${ROOT}/ca.crt && -e ${ROOT}/ca.key ]];then
    echo "No certificate authority signed cert found, creating...."
    ${OPENSSL} req -new -x509 -days 3650 -key ${ROOT}/ca.key -out \
        ${ROOT}/ca.crt -config ${CONFIG} 2>&1 > /dev/null
fi

if [[ ! -e ${ROOT}/server.key ]];then
    echo "Creating server key & cert...."
    ${OPENSSL} req -batch -nodes -new -extensions server -keyout \
        ${ROOT}/server.key -out ${ROOT}/server.csr -config \
        ${CONFIG} 2>&1 > /dev/null
fi

if [[ ! -e ${ROOT}/server-key.pem ]];then
    echo "Removing server key password..."
    ${OPENSSL} rsa -in ${ROOT}/server.key -out ${ROOT}/server-key.pem
fi

if [[ ! -e ${ROOT}/server.crt ]];then
    ${OPENSSL} ca -batch -extensions server -out ${ROOT}/server.crt -in \
        ${ROOT}/server.csr -config ${CONFIG} 2>&1 > /dev/null
fi

if [[ ! -z $client_id ]];then
    echo "Creating client certificate..."
    ${OPENSSL} req -batch -days 3650 -new -keyout ${ROOT}/${client_id}.key -subj \
        ${CLIENT_SUBJECT} -out ${ROOT}/${client_id}.csr -config ${CONFIG}
    ${OPENSSL} ca -batch -days 3650 -out ${ROOT}/${client_id}.crt -in \
        ${ROOT}/${client_id}.csr -config ${CONFIG}
    echo "Removing client key password..."
    ${OPENSSL} rsa -in ${ROOT}/${client_id}.key -out ${ROOT}/${client_id}-key.pem
fi


