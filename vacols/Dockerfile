FROM store/oracle/database-enterprise:12.2.0.1-slim

COPY vacols_copy* /ORCL/
COPY setup_vacols.sql /ORCL/
COPY dockerInitWithoutWait.sh /home/oracle/setup/dockerInitWithoutWait.sh

ENV DB_SID=BVAP

RUN mkdir -p /u01/app/oracle/oradata/BVAP 

EXEC ["/bin/bash", "-c", "/home/oracle/setup/dockerInitWithoutWait.sh"]
