FROM postgres:14.9

ENV ORACLE_HOME=/opt/oracle/instantclient_12_2 \
    LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2 \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LC_CTYPE="en_US.UTF-8"

COPY instantclient-basic-linux.x64-12.2.0.1.0.zip \
  instantclient-sdk-linux.x64-12.2.0.1.0.zip \
  instantclient-sqlplus-linux.x64-12.2.0.1.0.zip \
  oracle_libs/

# Install ZScaler root certificate
COPY ZscalerRootCertificate-2048-SHA256.crt /etc/ssl/certs/

RUN true \
  && apt-get update \
  && apt-get install ca-certificates \
  && update-ca-certificates --fresh

# Install dependencies
RUN true \
  && apt-get install -y libaio1 \
  libaio-dev \
  unzip \
  git \
  make \
  gcc \
  libpq-dev \
  postgresql-server-dev-14 \
  build-essential \
  locales \
  locales-all \
  && mkdir /opt/oracle \
  && chown $(whoami) /opt/oracle \
  && unzip oracle_libs/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /opt/oracle \
  && unzip oracle_libs/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /opt/oracle \
  && unzip oracle_libs/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /opt/oracle \
  && ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
  && export PATH="/opt/oracle/instantclient_12_2:$PATH"

# Install oracle_fdw
RUN true \
  && git clone https://github.com/laurenz/oracle_fdw \
  && cd oracle_fdw \
  && make \
  && make install

# Place init script
COPY setup_oracle_fdw.sql docker-entrypoint-initdb.d/

USER postgres

RUN locale-gen en_US.UTF-8

RUN initdb

# Open up to all addresses for local development
RUN echo "local all all trust" >> /var/lib/postgresql/data/pg_hba.conf \
  && echo "host all all 0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf

EXPOSE 5432

CMD postgres -c listen_addresses='*'
