FROM ruby:2.7.3
FROM --platform=linux/amd64 node:16.3.0

# Set up environment variables
ENV APP_HOME=/caseflow \
    ORACLE_HOME=/opt/oracle \
    LD_LIBRARY_PATH=/opt/oracle/instantclient_23_5 \
    BUILD="build-essential postgresql-client libpq-dev libsqlite3-dev curl ca-certificates wget git zip unzip libaio1 libaio-dev nodejs fastjar" \
    NVM_DIR="/usr/local/nvm" \
    NODE_VERSION="16.16.0" \
    PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    LANG="C.UTF-8"

COPY . $APP_HOME

RUN mkdir -p $ORACLE_HOME
WORKDIR $ORACLE_HOME

RUN jar xvf $APP_HOME/docker-bin/oracle_libs/instantclient-basic-linux.zip
RUN jar xvf $APP_HOME/docker-bin/oracle_libs/instantclient-sdk-linux.zip
RUN jar xvf $APP_HOME/docker-bin/oracle_libs/instantclient-sqlplus-linux.zip

RUN echo "gem: --no-rdoc --no-ri" >> ~/.gemrc

WORKDIR $APP_HOME

# Install base dependencies
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends $BUILD && \
    rm -rf /var/lib/apt/lists/*

# Set up NVM and Node
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION

# Install compatible Bundler version and gems
COPY Gemfile* .
RUN gem install bundler && bundle install

# Expose the Rails port
ARG DEFAULT_PORT=3000
EXPOSE ${DEFAULT_PORT}

# Start the Rails application
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
