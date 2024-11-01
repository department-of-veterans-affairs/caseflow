FROM metabase/metabase:v0.50.21

ENV MB_PLUGINS_DIR /app/plugins

WORKDIR /app
RUN addgroup --gid 2000 --system metabase
RUN adduser --disabled-password -u 2000 --ingroup metabase metabase
RUN mkdir plugins && chmod g-w plugins
RUN cd plugins && curl -sLO https://download.oracle.com/otn-pub/otn_software/jdbc/235/ojdbc8.jar

RUN chown -R metabase:metabase /app/plugins

ENTRYPOINT ["/app/run_metabase.sh"]
