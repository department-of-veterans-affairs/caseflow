#!/bin/sh
#
# $Header: dbaas/docker/build/dbsetup/setup/configDB.sh rduraisa_docker_122_image/2 2017/03/02 13:26:06 rduraisa Exp $
#
# configDB.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      configDB.sh - configure database as root
#
#    DESCRIPTION
#      rename the DB to customized name
#
#    NOTES
#      run as root and call renameDBora.sh inside
#
#    MODIFIED   (MM/DD/YY)
#    rduraisa    03/02/17 - Modify scripts to build for 12102 and 12201
#    xihzhang    10/25/16 - Remove EE bundles
#    xihzhang    08/08/16 - Remove privilege mode
#    xihzhang    05/23/16 - Creation
#

set -x

echo `date`
echo "Start Docker DB configuration"

# basic parameters
ENV_FILE=/home/oracle/setup/DB_ENV
BASH_RC=/home/oracle/.bashrc
ORA_TAB=/etc/oratab

# set env
source $ENV_FILE

ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1

# set env for oracle user
echo "export ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1" >> $BASH_RC
echo "export OH=$ORACLE_HOME" >> $BASH_RC
echo "export PATH=$PATH:$ORACLE_HOME/bin" >> $BASH_RC
echo "export TNS_ADMIN=$ORACLE_HOME/admin/${DB_SID}" >> $BASH_RC
echo "export ORACLE_SID=$DB_SID;" >> $BASH_RC

source $BASH_RC

# configure database
echo "Call configDBora.sh to configure database"
DB_RENAMER="/bin/bash -x /home/oracle/setup/configDBora.sh"
RENAME_ATTEMPTS=0
$DB_RENAMER
while [ $? -ne 0 ]; do
  $DB_RENAMER
  RENAME_ATTEMPTS=$[RENAME_ATTEMPTS + 1]
  if [ "$RENAME_ATTEMPTS" == "5" ]
  then
    break
  fi
done

# remove passwd info
echo "Remove password info"
sed -i '/DB_PASSWD/d' $ENV_FILE
unset DB_PASSWD

echo "Docker DB configuration is complete !"

# end
