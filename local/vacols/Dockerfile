# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 12c Release 2
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) linuxx64_12201_database.zip
#     Download Oracle Database 12c Release 12 Enterprise Edition or Standard Edition 2 for Linux x64
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run:
#      $ docker build -t oracle/database:12.2.0.1-${EDITION} .
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim as base

# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/12.2.0.1/dbhome_1 \
    INSTALL_DIR=/opt/install \
    INSTALL_FILE_1="linuxx64_12201_database.zip" \
    INSTALL_RSP="db_inst.rsp" \
    CONFIG_RSP="dbca.rsp.tmpl" \
    PWD_FILE="setPassword.sh" \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    CHECK_DB_FILE="checkDBStatus.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    RUN_FILE_1="firstPass.sh" \
    DB_EDITION="se2"

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY $SETUP_LINUX_FILE $CHECK_SPACE_FILE $INSTALL_DIR/
COPY $RUN_FILE $RUN_FILE_1 $START_FILE $CREATE_DB_FILE $CONFIG_RSP $PWD_FILE $CHECK_DB_FILE $USER_SCRIPTS_FILE $ORACLE_BASE/

RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    rm -rf $INSTALL_DIR



#############################################
# -------------------------------------------
# Start new stage for installing the database
# -------------------------------------------
#############################################

FROM base AS builder

ARG DB_EDITION

# Install unzip for unzip operation
RUN yum -y install unzip

# Copy DB install file
COPY --chown=oracle:dba $INSTALL_FILE_1 $INSTALL_RSP $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE $DB_EDITION && \
    rm -rf $INSTALL_FILE_1



#############################################
# -------------------------------------------
# Start new layer for database runtime
# -------------------------------------------
#############################################

FROM base

USER oracle
COPY --chown=oracle:dba --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh && \
    rm -rf $INSTALL_FILE_1

USER oracle
WORKDIR /home/oracle

EXPOSE 1521 5500
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

# Custom
ENV ORACLE_SID=BVAP
ENV ORACLE_PWD=Oradoc_db1

# Copy FACOLS files
ADD setup_vacols.sql /opt/oracle/scripts/setup/
ADD vacols_copy* /ORCL/

# Start everything up and install FACOLS then remove the setup files
RUN $ORACLE_BASE/$RUN_FILE_1 && \
    rm -rf /opt/oracle/scripts/setup/setup_vacols.sql

# Define default command to start Oracle Database.
CMD exec $ORACLE_BASE/$RUN_FILE
