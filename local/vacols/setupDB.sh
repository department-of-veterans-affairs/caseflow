#!/bin/sh
#
# $Header: dbaas/docker/build/dbsetup/setup/setupDB.sh rduraisa_docker_122_image/2 2017/03/02 13:26:08 rduraisa Exp $
#
# setupDB.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      setupDB.sh - setup database
#
#    DESCRIPTION
#      setup Oracle db12c at the first running
#
#    NOTES
#      run as root
#
#    MODIFIED   (MM/DD/YY)
#    rduraisa    03/02/17 - Modify scripts to build for 12102 and 12201
#    xihzhang    10/25/16 - Remove EE bundles
#    xihzhang    09/06/16 - Optimize build
#    xihzhang    08/08/16 - Remove privilege mode
#    xihzhang    05/23/16 - Creation
#

set -x

# timing
SECONDS=0

# dir and log parameters
SETUP_DIR=/home/oracle/setup
LOG_DIR=$SETUP_DIR/log
SETUP_LOG=$LOG_DIR/setupDB.log
PARAM_LOG=$LOG_DIR/paramChk.log
UNTAR_LOG=$LOG_DIR/untarDB.log
CONFIG_LOG=$LOG_DIR/configDB.log

if [[ `ls -A /ORCL` && `ls -A /ORCL/${ORACLE_HOME}/dbs` && `ls -A /ORCL/u02/app/oracle/oradata/ORCLCDB` ]];
then
  export EXISTING_DB=true;
else
  export EXISTING_DB=false;
fi

echo "Oracle Database 12.2.0.1 Setup"
echo "Oracle Database 12.2.0.1 Setup" >> $SETUP_LOG
echo `date`
echo `date` >> $SETUP_LOG
echo ""
echo "" >> $SETUP_LOG

# parameter check
echo "Check parameters ......"
echo "Check parameters ......" >> $SETUP_LOG
echo "log file is : $PARAM_LOG"
echo "log file is : $PARAM_LOG" >> $SETUP_LOG
/bin/bash $SETUP_DIR/paramChk.sh 2>&1 >> $PARAM_LOG
echo "paramChk.sh is done at $SECONDS sec"
echo "paramChk.sh is done at $SECONDS sec" >> $SETUP_LOG
echo ""
echo "" >> $SETUP_LOG

# untar bits
echo "untar DB bits ......"
echo "untar DB bits ......" >> $SETUP_LOG
echo "log file is : $UNTAR_LOG"
echo "log file is : $UNTAR_LOG" >> $SETUP_LOG
/bin/bash $SETUP_DIR/untarDB.sh 2>&1 >> $UNTAR_LOG

# check errors
if grep -q ": Error" $UNTAR_LOG
then
    echo "ERROR : untar DB bits failed, please check log $UNTAR_LOG for details!"
    echo "ERROR : untar DB bits failed, please check log $UNTAR_LOG for details!" >> $UNTAR_LOG
    exit 1
else
    echo "untarDB.sh is done at $SECONDS sec"
    echo "untarDB.sh is done at $SECONDS sec" >> $SETUP_LOG
fi
echo ""
echo "" >> $SETUP_LOG

# configure DB
date
echo "config DB ......"
echo "config DB ......" >> $SETUP_LOG
echo "log file is : $CONFIG_LOG"
echo "log file is : $CONFIG_LOG" >> $SETUP_LOG
/bin/bash $SETUP_DIR/configDB.sh 2>&1 >> $CONFIG_LOG

# clean history
echo "configDB.sh complete"
echo "cleaning history"
unset DB_PASSWD
echo "DB_PASSWD unset"
history -w
echo "history -w complete"
history -c
echo "history -c complete"

cat $CONFIG_LOG

# check errors
if grep -q "\(ORA-\)\|\(OPW-\)" $CONFIG_LOG
then
    echo "ERROR : config DB failed, please check log $CONFIG_LOG for details!"
    echo "ERROR : config DB failed, please check log $CONFIG_LOG for details!" >> $SETUP_LOG
    exit 1
else
    echo "configDB.sh is done at $SECONDS sec"
    echo "configDB.sh is done at $SECONDS sec" >> $SETUP_LOG
    echo ""
    echo "" >> $SETUP_LOG
    echo "Done ! The database is ready for use ."
    echo "Done ! The database is ready for use ." >> $SETUP_LOG
    /bin/bash $SETUP_DIR/tnsentry.sh
    exit 0
fi

# end
