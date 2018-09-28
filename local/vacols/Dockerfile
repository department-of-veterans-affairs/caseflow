FROM store/oracle/database-enterprise:12.2.0.1-slim

COPY vacols_copy* /ORCL/
COPY setup_vacols.sql /ORCL/

ENV DB_SID=BVAP

USER oracle

COPY dockerInitWithSchema.sh /home/oracle/setup/dockerInitWithSchema.sh
COPY loadSchema.sh /home/oracle/setup/loadSchema.sh

RUN mkdir -p /u01/app/oracle/oradata/BVAP &&  \
    mkdir -p /ORCL/u01/app/oracle/diag && \
    mkdir -p /u01/app/oracle/diag/rdbms/bvap/BVAP/trace/ && \
    touch /u01/app/oracle/diag/rdbms/bvap/BVAP/trace/alert_BVAP.log

RUN bash -c /home/oracle/setup/dockerInitWithSchema.sh

CMD ["/home/oracle/setup/dockerInit.sh"]