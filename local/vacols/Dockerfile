FROM store/oracle/database-enterprise:12.2.0.1-slim

COPY vacols_copy* /ORCL/
COPY setup_vacols.sql /ORCL/

ENV DB_SID=BVAP

USER oracle

COPY dockerInitWithSchema.sh /home/oracle/setup/dockerInitWithSchema.sh
COPY loadSchema.sh /home/oracle/setup/loadSchema.sh

RUN mkdir -p /u01/app/oracle/oradata/BVAP

HEALTHCHECK --interval=2m --timeout=3s --retries=10 \
    CMD grep "schema loading completed" /home/oracle/setup/log/dockerInit.log || exit 1

CMD ["bash", "-c", "/home/oracle/setup/dockerInitWithSchema.sh"]
