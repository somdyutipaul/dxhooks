#!/bin/sh 
#
# Copyright (c) 2017, 2018 by Delphix. All rights reserved.
#
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
# Copyright (c) 2015,2016,2017,2018 by Delphix. All rights reserved.
#
# Program Name     : dxh_runsql.sh
# Description      : Delphix Oracle hook template script
# Author           : Edward de los Santos
# Created          : Feb 2018


BASEDIR=$(dirname $0)
PROGNAME=$(basename $0)
DBNAME=""
dte=`date '+%Y%m%d' | tr -d '\n'`
OPERATION="config-clone|pre-refresh|post-refresh|pre-snapshot|post-snapshot|pre-rewind|post-rewind|pre-start|post-stop"

. ${BASEDIR}/dxh_hook_profile.sh
. ${BASEDIR}/dxh_hook_functions.sh


usage() {
   echo
   echo "usage: $0 -o ${OPERATION} -s {SERVICE_NAME|ORACLE_SID} -u {USERNAME} -p {PASSWORD} -t {SQL_SCRIPT}"
   echo
   exit 1
}
   

####################################
# Main Program
####################################


# rotate logfile each time the script is invoked
if [ -r "${LOGFILE}" ]; then
    mv ${LOGFILE} ${LOGFILE}.1
fi

for i in $*
do
   case $1 in
      -o) hook_op=$2; shift 2;;
      -s) service_name=$2; shift 2;;
      -u) username=$2; shift 2;;
      -p) password=$2; shift 2;;
      -t) sql_script=$2; shift 2;;
      -*) usage; exit 1;;
   esac
done

if [ -z "${hook_op}" ]; then
   usage
   exit 1
fi

if [ $(echo ${hook_op} | egrep -c ${OPERATION}) -eq 0 ]; then
   usage
   exit 1
fi

# ORACLE_HOME is set when script is configure in Delphix post hook operation
if [ -z ${ORACLE_HOME} ] &&  [ -z ${ORACLE_SID} ]; then
    echo "Error: ORACLE_HOME and ORACLE_SID variable not set."
    echo "       Make sure to configure the ${ORACLE_HOME} when running the script outside of Delphix post hook operation!"
    exit 1
fi

exec_sqlplus_get_dbname

RETCODE=$?
if [[ ${RETCODE} -gt 0 ]]; then
    echo "Error: Failed to execute the query. Please check if the instance is UP or ORACLE_SID is correct."
    exit 1
fi


SQLDIR="${BASEDIR}/${DBNAME}/${hook_op}/sql"
SCRIPTDIR="${BASEDIR}/${DBNAME}/${hook_op}/scripts"
LOGDIR="${BASEDIR}/${DBNAME}/logs"
LOGFILE="${LOGDIR}/${PROGNAME}.${hook_op}.log"
export SQLDIR LOGDIR LOGFILE SCRIPTDIR BASEDIR 


# rotate logfile 
[ -r ${LOGFILE} ] && mv ${LOGFILE} ${LOGFILE}.1

log_echo "${PROGNAME} execution started"

# Check if directories exists
check_dir_exists "${LOGDIR}"

log_echo "executing ${hook_op} ${sql_script}"
exec_sqlplus_script "${SQLDIR}/${sql_script}" "${service_name}" "${username}" "${password}" 

log_echo "${PROGNAME} execution completed."

exit 0




  

