FROM store/oracle/database-enterprise:12.2.0.1-slim

COPY vacols_copy* /ORCL/
COPY setup_vacols.sql /ORCL/

ENV DB_SID=BVAP

RUN mkdir -p /u01/app/oracle/oradata/BVAP 
