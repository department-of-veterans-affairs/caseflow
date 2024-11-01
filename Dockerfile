FROM ruby:2.7.3

# Set up environment variables
ENV APP_HOME=/caseflow \
    ORACLE_HOME=/opt/oracle \
    BUILD="build-essential postgresql-client zlib1g-dev libpq-dev libsqlite3-dev ca-certificates git libaio1 libaio-dev nodejs fastjar" \
    NVM_DIR="/usr/local/nvm" \
    NODE_VERSION="16.16.0" \
    PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    LANG="C.UTF-8"

# Install base dependencies
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends $BUILD && \
    rm -rf /var/lib/apt/lists/*


ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_19_24" \
ORACLE_HOME="/opt/oracle/instantclient_19_24" \
OCI_DIR="/opt/oracle/instantclient_19_24"

WORKDIR /opt/oracle
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linux-arm64.zip
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linux-arm64.zip
RUN curl -O https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linux-arm64.zip
RUN jar xvf instantclient-basic-linux-arm64.zip
RUN jar xvf instantclient-sqlplus-linux-arm64.zip
RUN jar xvf instantclient-sdk-linux-arm64.zip

# fix for oracle client
RUN rm /opt/oracle/instantclient_19_24/libclntsh.so
WORKDIR /opt/oracle/instantclient_19_24
RUN ln -s libclntsh.so.19.1 libclntsh.so

COPY . $APP_HOME

WORKDIR $APP_HOME

# Set up NVM and Node
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION

# Install compatible Bundler version and gems
COPY Gemfile* .
RUN echo "gem: --no-rdoc --no-ri" >> ~/.gemrc
RUN gem install bundler -v 2.4.22 && bundle install

# Run the app
ENTRYPOINT ["/bin/bash", "-c", "/caseflow/docker-bin/startup.sh"]

