FROM postgres:14.15

ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_23_5" \
    ORACLE_HOME="/opt/oracle/instantclient_23_5" \
    OCI_DIR="/opt/oracle/instantclient_23_5" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LC_CTYPE="en_US.UTF-8"

# Install ZScaler root certificate
COPY ZscalerRootCertificate-2048-SHA256.crt /etc/ssl/certs/

RUN true \
  && apt-get update \
  && apt-get install ca-certificates \
  && update-ca-certificates --fresh

# Install InstantClient
WORKDIR /opt/oracle

RUN chown $(whoami) /opt/oracle \
  && export PATH="/opt/oracle/instantclient_23_5:$PATH"
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip
RUN jar xvf instantclient-basic-linuxx64.zip
RUN jar xvf instantclient-sqlplus-linuxx64.zip
RUN jar xvf instantclient-sdk-linuxx64.zip
RUN rm instantclient-basic-linuxx64.zip instantclient-sqlplus-linuxx64.zip instantclient-sdk-linuxx64.zip

RUN rm -f /opt/oracle/instantclient_23_5/libclntsh.so
WORKDIR /opt/oracle/instantclient_23_5
RUN ln -s libclntsh.so.23.1 libclntsh.so

# Install other dependencies
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
  locales-all

# Install oracle_fdw
RUN true \
  && git clone https://github.com/laurenz/oracle_fdw \
  && cd oracle_fdw \
  && make \
  && make install

# Place init script
COPY setup_extensions.sql docker-entrypoint-initdb.d/

USER postgres

RUN locale-gen en_US.UTF-8

RUN initdb

# Open up to all addresses for local development
RUN echo "local all all trust" >> /var/lib/postgresql/data/pg_hba.conf \
  && echo "host all all 0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf

EXPOSE 5432

CMD postgres -c listen_addresses='*'
