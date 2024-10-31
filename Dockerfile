FROM ruby:2.7.3

# Set up environment variables
ENV APP_HOME=/caseflow \
    ORACLE_HOME=/opt/oracle \
    BUILD="build-essential postgresql-client zlib1g-dev libpq-dev libsqlite3-dev ca-certificates git libaio1 libaio-dev nodejs" \
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

# Expose the Rails port
ARG DEFAULT_PORT=3000
EXPOSE ${DEFAULT_PORT}

# Start the Rails application
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
